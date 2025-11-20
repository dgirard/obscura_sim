import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/photo.dart';
import '../../repositories/camera_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../services/image_processing_service.dart';
import '../../services/audio_service.dart';
import 'camera_event.dart';
import 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  final ImageProcessingService _imageProcessingService;
  final CameraRepository _cameraRepository;
  final SettingsRepository _settingsRepository;
  final AudioService _audioService;
  
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  StreamSubscription? _accelerometerSubscription;
  Timer? _captureTimer;
  double _totalMotion = 0;
  double _captureProgress = 0;
  bool _isPortrait = false;
  double _elapsedSeconds = 0;

  CameraBloc({
    required ImageProcessingService imageProcessingService,
    required CameraRepository cameraRepository,
    required SettingsRepository settingsRepository,
    required AudioService audioService,
  })  : _imageProcessingService = imageProcessingService,
        _cameraRepository = cameraRepository,
        _settingsRepository = settingsRepository,
        _audioService = audioService,
        super(CameraInitial()) {
    on<InitializeCamera>(_onInitializeCamera);
    on<DisposeCamera>(_onDisposeCamera);
    on<StartCapture>(_onStartCapture);
    on<InstantCapture>(_onInstantCapture);
    on<StopCapture>(_onStopCapture);
    on<UpdateMotionLevel>(_onUpdateMotionLevel);
    on<SetFocusPoint>(_onSetFocusPoint);
    on<SetExposureOffset>(_onSetExposureOffset);
    on<ToggleFlash>(_onToggleFlash);
  }

  Future<void> _onSetFocusPoint(
    SetFocusPoint event,
    Emitter<CameraState> emit,
  ) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _controller!.setFocusPoint(event.point);
      await _controller!.setExposurePoint(event.point);
    } catch (e) {
      print('Erreur de focus: $e');
    }
  }

  Future<void> _onInitializeCamera(
    InitializeCamera event,
    Emitter<CameraState> emit,
  ) async {
    try {
      final status = await _cameraRepository.requestCameraPermission();
      if (!status.isGranted) {
        emit(CameraPermissionDenied());
        return;
      }

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
        _settingsRepository.imageQuality,
        enableAudio: false,
      );

      await _controller!.initialize();

      // Activer l'autofocus par défaut
      try {
        await _controller!.setFocusMode(FocusMode.auto);
      } catch (e) {
        // Ignorer si non supporté
      }

      // Activer le flash si disponible
      // On force Off au démarrage pour l'état initial
      try {
        await _controller!.setFlashMode(FlashMode.off);
      } catch (e) {
        // Certains appareils n'ont pas de flash ou ne supportent pas setFlashMode
      }

      // Récupérer les bornes d'exposition
      final minExposure = await _controller!.getMinExposureOffset();
      final maxExposure = await _controller!.getMaxExposureOffset();

      emit(CameraReady(
        _controller!,
        minExposure: minExposure,
        maxExposure: maxExposure,
        currentExposure: 0.0,
        flashMode: FlashMode.off,
      ));
    } catch (e) {
      emit(CameraError('Erreur d\'initialisation: ${e.toString()}'));
    }
  }

  Future<void> _onToggleFlash(
    ToggleFlash event,
    Emitter<CameraState> emit,
  ) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state is! CameraReady) return;

    final currentMode = (state as CameraReady).flashMode;
    FlashMode nextMode;

    // Cycle: Off -> Auto -> Torch -> Off
    // Note: Torch est souvent mieux que "Always" pour une app créative
    switch (currentMode) {
      case FlashMode.off:
        nextMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        nextMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        nextMode = FlashMode.off;
        break;
      default:
        nextMode = FlashMode.off;
    }

    try {
      await _controller!.setFlashMode(nextMode);
      emit((state as CameraReady).copyWith(flashMode: nextMode));
    } catch (e) {
      print('Erreur flash: $e');
      // Revenir à off en cas d'erreur (pas de flash supporté)
      emit((state as CameraReady).copyWith(flashMode: FlashMode.off));
    }
  }



  Future<void> _onSetExposureOffset(
    SetExposureOffset event,
    Emitter<CameraState> emit,
  ) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state is! CameraReady) return;

    try {
      await _controller!.setExposureOffset(event.offset);
      emit((state as CameraReady).copyWith(currentExposure: event.offset));
    } catch (e) {
      print('Erreur exposition: $e');
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
    _elapsedSeconds = 0;
    _isPortrait = event.isPortrait;

    // Démarrer la surveillance de l'accéléromètre
    _accelerometerSubscription = _cameraRepository.accelerometerEvents.listen((event) {
      final motion = (event.x.abs() + event.y.abs() + event.z.abs()) / 3;
      _totalMotion += motion;
      add(UpdateMotionLevel(motion));
    });

    // Timer de 3 secondes pour l'exposition
    const duration = Duration(seconds: 3);
    const updateInterval = Duration(milliseconds: 100);
    int elapsedMs = 0;

    _captureTimer = Timer.periodic(updateInterval, (timer) async {
      elapsedMs += updateInterval.inMilliseconds;
      _elapsedSeconds = elapsedMs / 1000.0;
      _captureProgress = elapsedMs / duration.inMilliseconds;

      if (_captureProgress >= 1.0) {
        timer.cancel();
        await _capturePhoto(emit, isPortrait: event.isPortrait, motionBlur: _totalMotion / 3);
      } else {
        emit(CameraCapturing(
          controller: _controller!,
          progress: _captureProgress,
          motionLevel: _totalMotion / (elapsedMs / 1000),
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
      await _audioService.playShutter();
      final XFile photo = await _controller!.takePicture();

      // Sauvegarder temporairement
      final Directory appDir = await _cameraRepository.getDocumentsDirectory();
      final String fileName = 'obscura_temp_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savedPath = '${appDir.path}/$fileName';
      await photo.saveTo(savedPath);

      // Lancer le traitement en arrière-plan (rotation, etc.)
      // Note: On ne redimensionne pas ici si ce n'est pas nécessaire, 
      // mais le service le fera si > 2048px.
      final processingFuture = _imageProcessingService.processImage(
        savedPath,
        FilterType.none,
        0,
        rotateQuarterTurns: isPortrait ? 1 : 0,
      );

      // Phase de développement (Simulation)
      double progress = 0.0;
      final completer = Completer<void>();
      
      // Réutiliser le stream accéléromètre ou en créer un nouveau
      _accelerometerSubscription?.cancel();
      _accelerometerSubscription = _cameraRepository.accelerometerEvents.listen((event) {
        double motion = (event.x.abs() + event.y.abs() + event.z.abs()) / 3;
        // Agiter le téléphone accélère le développement
        if (motion > 2.0) {
           progress += 0.05; // Bonus
        }
      });

      // Timer pour la progression naturelle + émission d'état
      final timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
        progress += 0.02; // 2% par 100ms = 5 secondes total sans secouer
        
        if (progress >= 1.0) {
           t.cancel();
           if (!completer.isCompleted) completer.complete();
        } else {
           if (!emit.isDone) {
             emit(CameraDeveloping(
               controller: _controller!,
               tempImagePath: savedPath,
               progress: progress.clamp(0.0, 1.0),
             ));
           } else {
             t.cancel();
             if (!completer.isCompleted) completer.complete(); 
           }
        }
      });

      await completer.future;
      timer.cancel(); // Sécurité
      _accelerometerSubscription?.cancel();

      // Attendre la fin réelle du traitement
      final processedPath = await processingFuture;
      
      await _audioService.playDeveloping();

      if (!emit.isDone) {
        emit(CameraCaptured(
          imagePath: processedPath,
          totalMotion: motionBlur,
        ));
      }

      // Retour à l'état prêt
      await Future.delayed(const Duration(seconds: 1));
      if (!emit.isDone) {
         emit(CameraReady(_controller!));
      }
    } catch (e) {
      print(e);
      if (!emit.isDone) {
        emit(CameraError('Erreur de capture: ${e.toString()}'));
      }
    }
  }

  Future<void> _onStopCapture(
    StopCapture event,
    Emitter<CameraState> emit,
  ) async {
    final bool wasCapturing = _captureTimer?.isActive ?? false;
    _captureTimer?.cancel();
    _accelerometerSubscription?.cancel();

    if (!event.abort && wasCapturing) {
      // Relâché avant 3s mais pas annulé -> Prendre la photo
      // Calculer le flou moyen sur le temps écoulé
      final double averageMotion = _elapsedSeconds > 0 ? (_totalMotion / _elapsedSeconds) : 0;
      
      await _capturePhoto(
        emit, 
        isPortrait: _isPortrait, 
        motionBlur: averageMotion
      );
    } else {
      // Annulation ou fin normale gérée ailleurs (si timer fini)
      // Si le timer est fini, _capturePhoto a déjà été appelé, donc on est bon.
      // Si c'est un abort explicit, on reset.
      if (emit.isDone) return; // Si capturePhoto a déjà emit
      
      if (_controller != null) {
        emit(CameraReady(_controller!));
      }
    }

    _totalMotion = 0;
    _captureProgress = 0;
    _elapsedSeconds = 0;
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