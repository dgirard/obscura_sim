import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/photo.dart';
import '../../repositories/camera_repository.dart';
import '../../services/image_processing_service.dart';
import 'camera_event.dart';
import 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  final ImageProcessingService _imageProcessingService;
  final CameraRepository _cameraRepository;
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  StreamSubscription? _accelerometerSubscription;
  Timer? _captureTimer;
  double _totalMotion = 0;
  double _captureProgress = 0;

  CameraBloc({
    required ImageProcessingService imageProcessingService,
    required CameraRepository cameraRepository,
  })  : _imageProcessingService = imageProcessingService,
        _cameraRepository = cameraRepository,
        super(CameraInitial()) {
    on<InitializeCamera>(_onInitializeCamera);
    on<DisposeCamera>(_onDisposeCamera);
    on<StartCapture>(_onStartCapture);
    on<InstantCapture>(_onInstantCapture);
    on<StopCapture>(_onStopCapture);
    on<UpdateMotionLevel>(_onUpdateMotionLevel);
  }

  Future<void> _onInitializeCamera(
    InitializeCamera event,
    Emitter<CameraState> emit,
  ) async {
    try {
      _cameras = await _cameraRepository.getAvailableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        emit(const CameraError('Aucune caméra disponible'));
        return;
      }

      // Utiliser la caméra arrière
      final camera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = _cameraRepository.createController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      // Activer le flash si disponible
      if (_controller!.value.flashMode != FlashMode.off) {
        await _controller!.setFlashMode(FlashMode.off);
      }

      emit(CameraReady(_controller!));
    } catch (e) {
      emit(CameraError('Erreur d\'initialisation: ${e.toString()}'));
    }
  }

  Future<void> _onStartCapture(
    StartCapture event,
    Emitter<CameraState> emit,
  ) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    _totalMotion = 0;
    _captureProgress = 0;

    // Démarrer la surveillance de l'accéléromètre
    _accelerometerSubscription = _cameraRepository.accelerometerEvents.listen((event) {
      final motion = (event.x.abs() + event.y.abs() + event.z.abs()) / 3;
      _totalMotion += motion;
      add(UpdateMotionLevel(motion));
    });

    // Timer de 3 secondes pour l'exposition
    const duration = Duration(seconds: 3);
    const updateInterval = Duration(milliseconds: 100);
    int elapsed = 0;

    _captureTimer = Timer.periodic(updateInterval, (timer) async {
      elapsed += updateInterval.inMilliseconds;
      _captureProgress = elapsed / duration.inMilliseconds;

      if (_captureProgress >= 1.0) {
        timer.cancel();
        await _capturePhoto(emit, isPortrait: event.isPortrait, motionBlur: _totalMotion / 3);
      } else {
        emit(CameraCapturing(
          controller: _controller!,
          progress: _captureProgress,
          motionLevel: _totalMotion / (elapsed / 1000),
        ));
      }
    });
  }

  Future<void> _onInstantCapture(
    InstantCapture event,
    Emitter<CameraState> emit,
  ) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    await _capturePhoto(emit, isPortrait: event.isPortrait, motionBlur: 0);
  }

  Future<void> _capturePhoto(
    Emitter<CameraState> emit, {
    required bool isPortrait,
    required double motionBlur,
  }) async {
    try {
      final XFile photo = await _controller!.takePicture();

      // Sauvegarder dans le dossier de l'app
      final Directory appDir = await _cameraRepository.getDocumentsDirectory();
      final String fileName = 'obscura_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savedPath = '${appDir.path}/$fileName';

      // Si portrait, on doit pivoter l'image
      if (isPortrait) {
        // On sauvegarde temporairement pour le traitement
        await photo.saveTo(savedPath);
        
        // Utiliser le service pour la rotation (via compute)
        final processedPath = await _imageProcessingService.processImage(
          savedPath,
          FilterType.none, // Pas de filtre ici
          0, // Pas de flou ici, on le stocke en métadonnée
          rotateQuarterTurns: 1, // Rotation 90 degrés
        );
        
        emit(CameraCaptured(
          imagePath: processedPath,
          totalMotion: motionBlur,
        ));
      } else {
        await photo.saveTo(savedPath);
        emit(CameraCaptured(
          imagePath: savedPath,
          totalMotion: motionBlur,
        ));
      }

      // Retour à l'état prêt après capture
      await Future.delayed(const Duration(seconds: 1));
      if (!emit.isDone) {
         emit(CameraReady(_controller!));
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(CameraError('Erreur de capture: ${e.toString()}'));
      }
    }
  }

  void _onStopCapture(
    StopCapture event,
    Emitter<CameraState> emit,
  ) {
    _captureTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _totalMotion = 0;
    _captureProgress = 0;

    if (_controller != null) {
      emit(CameraReady(_controller!));
    }
  }

  void _onUpdateMotionLevel(
    UpdateMotionLevel event,
    Emitter<CameraState> emit,
  ) {
    // Mise à jour gérée dans StartCapture via le state CameraCapturing
  }

  Future<void> _onDisposeCamera(
    DisposeCamera event,
    Emitter<CameraState> emit,
  ) async {
    await _controller?.dispose();
    _accelerometerSubscription?.cancel();
    _captureTimer?.cancel();
    emit(CameraInitial());
  }

  @override
  Future<void> close() {
    _controller?.dispose();
    _accelerometerSubscription?.cancel();
    _captureTimer?.cancel();
    return super.close();
  }
}