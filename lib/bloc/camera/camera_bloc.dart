import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../repositories/camera_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../services/image_processing_service.dart';
import '../../services/audio_service.dart';
import '../../services/logger_service.dart';
import 'camera_event.dart';
import 'camera_state.dart';
import 'delegates/camera_controls_delegate.dart';
import 'delegates/capture_delegate.dart';
import 'delegates/motion_delegate.dart';

/// BLoC principal de gestion de la caméra.
///
/// Utilise des delegates pour séparer les responsabilités :
/// - [CameraControlsDelegate] : Focus, Exposure, Zoom, Flash
/// - [CaptureDelegate] : Capture photo, timer, développement
/// - [MotionDelegate] : Détection de mouvement via accéléromètre
class CameraBloc extends Bloc<CameraEvent, CameraState> {
  final CameraRepository _cameraRepository;
  final SettingsRepository _settingsRepository;

  // Delegates
  final CameraControlsDelegate _controlsDelegate;
  final CaptureDelegate _captureDelegate;
  final MotionDelegate _motionDelegate;

  CameraController? _controller;
  List<CameraDescription>? _cameras;

  CameraBloc({
    required ImageProcessingService imageProcessingService,
    required CameraRepository cameraRepository,
    required SettingsRepository settingsRepository,
    required AudioService audioService,
  })  : _cameraRepository = cameraRepository,
        _settingsRepository = settingsRepository,
        _controlsDelegate = CameraControlsDelegate(),
        _captureDelegate = CaptureDelegate(
          imageProcessingService: imageProcessingService,
          cameraRepository: cameraRepository,
          audioService: audioService,
        ),
        _motionDelegate = MotionDelegate(cameraRepository: cameraRepository),
        super(CameraInitial()) {
    // Enregistrement des handlers d'événements
    on<InitializeCamera>(_onInitializeCamera);
    on<DisposeCamera>(_onDisposeCamera);
    on<StartCapture>(_onStartCapture);
    on<InstantCapture>(_onInstantCapture);
    on<StopCapture>(_onStopCapture);
    on<UpdateMotionLevel>(_onUpdateMotionLevel);
    on<SetFocusPoint>(_onSetFocusPoint);
    on<SetExposureOffset>(_onSetExposureOffset);
    on<SetZoomLevel>(_onSetZoomLevel);
    on<ToggleFlash>(_onToggleFlash);
    on<UpdateCaptureProgress>(_onUpdateCaptureProgress);
    on<FinishCapture>(_onFinishCapture);

    // Configuration des callbacks des delegates
    _setupDelegateCallbacks();
  }

  void _setupDelegateCallbacks() {
    _captureDelegate.onCaptureProgress = (progress, elapsedSeconds) {
      add(UpdateCaptureProgress(progress, elapsedSeconds));
    };

    _captureDelegate.onCaptureFinished = () {
      add(FinishCapture());
    };

    _motionDelegate.onMotionUpdate = (motion) {
      add(UpdateMotionLevel(motion));
    };
  }

  // ============================================
  // INITIALISATION & DISPOSE
  // ============================================

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

      // Tenter d'initialiser avec plusieurs résolutions en cas d'échec
      _controller = await _initializeControllerWithFallback(camera);

      if (_controller == null) {
        emit(const CameraError('Impossible d\'initialiser la caméra'));
        return;
      }

      // Mettre à jour les delegates avec le contrôleur
      _controlsDelegate.setController(_controller);
      _captureDelegate.setController(_controller);

      // Initialiser les contrôles
      await _controlsDelegate.initializeAutoFocus();
      await _controlsDelegate.initializeFlash();

      // Récupérer les bornes d'exposition et zoom
      final (minExp, maxExp) = await _controlsDelegate.getExposureBounds();
      final (minZoom, maxZoom) = await _controlsDelegate.getZoomBounds();

      // Initialiser le zoom à 1.0 (ou minZoom si > 1.0)
      final initialZoom = minZoom > 1.0 ? minZoom : 1.0.clamp(minZoom, maxZoom);
      await _controlsDelegate.setZoomLevel(initialZoom);

      emit(CameraReady(
        _controller!,
        minExposure: minExp,
        maxExposure: maxExp,
        currentExposure: 0.0,
        flashMode: FlashMode.off,
        minZoom: minZoom,
        maxZoom: maxZoom,
        currentZoom: initialZoom,
      ));
    } catch (e) {
      emit(CameraError('Erreur d\'initialisation: ${e.toString()}'));
    }
  }

  Future<CameraController?> _initializeControllerWithFallback(
    CameraDescription camera,
  ) async {
    final preset = _settingsRepository.imageQuality;
    final presetsToTry = [
      preset,
      ResolutionPreset.high,
      ResolutionPreset.medium,
      ResolutionPreset.low,
    ].toSet().toList();

    for (final p in presetsToTry) {
      try {
        final controller = _cameraRepository.createController(
          camera,
          p,
          enableAudio: false,
        );

        await controller.initialize();
        AppLogger.camera('Initialized with preset: $p');
        return controller;
      } catch (e) {
        AppLogger.camera('Failed to initialize with preset $p: $e');
      }
    }

    return null;
  }

  Future<void> _onDisposeCamera(
    DisposeCamera event,
    Emitter<CameraState> emit,
  ) async {
    await _controller?.dispose();
    _motionDelegate.dispose();
    _captureDelegate.dispose();
    emit(CameraInitial());
  }

  // ============================================
  // CONTRÔLES CAMÉRA (via delegate)
  // ============================================

  Future<void> _onSetFocusPoint(
    SetFocusPoint event,
    Emitter<CameraState> emit,
  ) async {
    await _controlsDelegate.setFocusPoint(event.point);
  }

  Future<void> _onSetZoomLevel(
    SetZoomLevel event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;

    // Mise à jour optimiste de l'UI
    emit(_controlsDelegate.updateZoom(state as CameraReady, event.zoom));
    await _controlsDelegate.setZoomLevel(event.zoom);
  }

  Future<void> _onSetExposureOffset(
    SetExposureOffset event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;

    // Mise à jour optimiste de l'UI
    emit(_controlsDelegate.updateExposure(state as CameraReady, event.offset));
    await _controlsDelegate.setExposureOffset(event.offset);
  }

  Future<void> _onToggleFlash(
    ToggleFlash event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;

    final currentMode = (state as CameraReady).flashMode;
    final newMode = await _controlsDelegate.cycleFlashMode(currentMode);

    if (newMode != null) {
      emit(_controlsDelegate.updateFlashMode(state as CameraReady, newMode));
    }
  }

  // ============================================
  // CAPTURE (via delegates)
  // ============================================

  Future<void> _onStartCapture(
    StartCapture event,
    Emitter<CameraState> emit,
  ) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    // Démarrer la surveillance du mouvement
    _motionDelegate.startMonitoring();

    // Démarrer le timer de capture
    final started = _captureDelegate.startLongCapture(isPortrait: event.isPortrait);
    if (!started) return;

    // Emit initial capturing state
    emit(CameraCapturing(
      controller: _controller!,
      progress: 0.0,
      motionLevel: 0.0,
      isInstant: false,
    ));
  }

  Future<void> _onUpdateCaptureProgress(
    UpdateCaptureProgress event,
    Emitter<CameraState> emit,
  ) async {
    if (event.progress >= 1.0) {
      // Le timer a expiré, sera géré par FinishCapture
      return;
    }

    final motionLevel = event.elapsedSeconds > 0
        ? _motionDelegate.getAverageMotion(event.elapsedSeconds)
        : 0.0;

    emit(CameraCapturing(
      controller: _controller!,
      progress: event.progress,
      motionLevel: motionLevel,
      isInstant: false,
    ));
  }

  Future<void> _onFinishCapture(
    FinishCapture event,
    Emitter<CameraState> emit,
  ) async {
    _motionDelegate.stopMonitoring();

    final averageMotion = _motionDelegate.getAverageMotion(3.0);
    await _performCapture(
      emit,
      isPortrait: _captureDelegate.isPortrait,
      motionBlur: averageMotion,
    );
  }

  Future<void> _onInstantCapture(
    InstantCapture event,
    Emitter<CameraState> emit,
  ) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    // Feedback immédiat
    emit(CameraCapturing(
      controller: _controller!,
      progress: 0.0,
      motionLevel: 0.0,
      isInstant: true,
    ));

    await _performCapture(emit, isPortrait: event.isPortrait, motionBlur: 0);
  }

  Future<void> _onStopCapture(
    StopCapture event,
    Emitter<CameraState> emit,
  ) async {
    final captureInfo = _captureDelegate.stopCapture();
    _motionDelegate.stopMonitoring();

    if (!event.abort && captureInfo != null && captureInfo.wasCapturing) {
      // Relâché avant 3s mais pas annulé -> Prendre la photo
      final averageMotion = _motionDelegate.getAverageMotion(captureInfo.elapsedSeconds);

      await _performCapture(
        emit,
        isPortrait: captureInfo.isPortrait,
        motionBlur: averageMotion,
      );
    } else {
      // Annulation
      if (!emit.isDone && _controller != null) {
        emit(CameraReady(_controller!));
      }
    }

    _motionDelegate.reset();
  }

  Future<void> _performCapture(
    Emitter<CameraState> emit, {
    required bool isPortrait,
    required double motionBlur,
  }) async {
    final result = await _captureDelegate.capturePhoto(
      isPortrait: isPortrait,
      motionBlur: motionBlur,
      onDevelopingProgress: (tempPath, progress) {
        if (!emit.isDone) {
          emit(CameraDeveloping(
            controller: _controller!,
            tempImagePath: tempPath,
            progress: progress,
          ));
        }
      },
    );

    if (result.success) {
      if (!emit.isDone) {
        AppLogger.perf('Emitting CameraCaptured at ${DateTime.now().millisecondsSinceEpoch}');
        emit(CameraCaptured(
          imagePath: result.imagePath,
          totalMotion: result.totalMotion,
        ));
      }

      await Future.delayed(const Duration(seconds: 1));
      if (!emit.isDone && _controller != null) {
        emit(CameraReady(_controller!));
      }
    } else {
      if (!emit.isDone) {
        emit(CameraError(result.error ?? 'Erreur de capture'));
      }
    }
  }

  void _onUpdateMotionLevel(
    UpdateMotionLevel event,
    Emitter<CameraState> emit,
  ) {
    // Géré implicitement via le delegate
  }

  // ============================================
  // LIFECYCLE
  // ============================================

  @override
  Future<void> close() {
    _controller?.dispose();
    _motionDelegate.dispose();
    _captureDelegate.dispose();
    return super.close();
  }
}
