import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'camera_event.dart';
import 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  StreamSubscription? _accelerometerSubscription;
  Timer? _captureTimer;
  double _totalMotion = 0;
  double _captureProgress = 0;

  CameraBloc() : super(CameraInitial()) {
    on<InitializeCamera>(_onInitializeCamera);
    on<DisposeCamera>(_onDisposeCamera);
    on<StartCapture>(_onStartCapture);
    on<StopCapture>(_onStopCapture);
    on<UpdateMotionLevel>(_onUpdateMotionLevel);
  }

  Future<void> _onInitializeCamera(
    InitializeCamera event,
    Emitter<CameraState> emit,
  ) async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        emit(const CameraError('Aucune caméra disponible'));
        return;
      }

      // Utiliser la caméra arrière
      final camera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
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
    _accelerometerSubscription = userAccelerometerEventStream().listen((event) {
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
        await _capturePhoto();
      } else {
        emit(CameraCapturing(
          controller: _controller!,
          progress: _captureProgress,
          motionLevel: _totalMotion / (elapsed / 1000),
        ));
      }
    });
  }

  Future<void> _capturePhoto() async {
    try {
      final XFile photo = await _controller!.takePicture();

      // Sauvegarder dans le dossier de l'app
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'obscura_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savedPath = '${appDir.path}/$fileName';

      await photo.saveTo(savedPath);

      emit(CameraCaptured(
        imagePath: savedPath,
        totalMotion: _totalMotion / 3, // Moyenne sur 3 secondes
      ));

      // Retour à l'état prêt après capture
      await Future.delayed(const Duration(seconds: 1));
      emit(CameraReady(_controller!));
    } catch (e) {
      emit(CameraError('Erreur de capture: ${e.toString()}'));
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
    // Mise à jour gérée dans StartCapture
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