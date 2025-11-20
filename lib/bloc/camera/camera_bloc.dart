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
    on<SetZoomLevel>(_onSetZoomLevel);
    on<ToggleFlash>(_onToggleFlash);
    on<UpdateCaptureProgress>(_onUpdateCaptureProgress);
    on<FinishCapture>(_onFinishCapture);
  }

  Future<void> _onSetZoomLevel(
    SetZoomLevel event,
    Emitter<CameraState> emit,
  ) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state is! CameraReady) return;

    try {
      // Optimistic update
      emit((state as CameraReady).copyWith(currentZoom: event.zoom));
      await _controller!.setZoomLevel(event.zoom);
    } catch (e) {
      print('Erreur zoom: $e');
    }
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

      // Tenter d'initialiser avec plusieurs résolutions en cas d'échec
      // (Fix pour le bug "No supported surface combination" sur certains appareils)
      ResolutionPreset preset = _settingsRepository.imageQuality;
      final List<ResolutionPreset> presetsToTry = [
        preset,
        ResolutionPreset.high,
        ResolutionPreset.medium,
        ResolutionPreset.low,
      ];
      // Remove duplicates
      final uniquePresets = presetsToTry.toSet().toList();

      bool initialized = false;
      String lastError = '';

      for (final p in uniquePresets) {
        try {
          // Dispose old controller if exists (though unlikely in this flow unless retrying)
          if (_controller != null) {
             // Note: dispose is async but we might just overwrite it if it failed to init. 
             // If init failed, usually it's not fully initialized.
             // But safe to just create new one.
          }

          _controller = _cameraRepository.createController(
            camera,
            p,
            enableAudio: false,
          );

          await _controller!.initialize();
          initialized = true;
          print('Camera initialized with preset: $p');
          break; // Success!
        } catch (e) {
          print('Failed to initialize with preset $p: $e');
          lastError = e.toString();
          // Continue to next preset
        }
      }

      if (!initialized) {
        throw Exception('Impossible d\'initialiser la caméra: $lastError');
      }

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
      double minExposure = -1.0;
      double maxExposure = 1.0;
      try {
        minExposure = await _controller!.getMinExposureOffset();
        maxExposure = await _controller!.getMaxExposureOffset();
      } catch (e) {
        // Certains appareils ne supportent pas les contrôles d'exposition
        print('Exposition non supportée: $e');
      }

      // Récupérer les bornes de zoom
      double minZoom = 1.0;
      double maxZoom = 1.0;
      try {
        minZoom = await _controller!.getMinZoomLevel();
        maxZoom = await _controller!.getMaxZoomLevel();
      } catch (e) {
        print('Zoom non supporté: $e');
      }

      emit(CameraReady(
        _controller!,
        minExposure: minExposure,
        maxExposure: maxExposure,
        currentExposure: 0.0,
        flashMode: FlashMode.off,
        minZoom: minZoom,
        maxZoom: maxZoom,
        currentZoom: minZoom,
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

    // Mise à jour optimiste de l'UI pour la fluidité du slider
    emit((state as CameraReady).copyWith(currentExposure: event.offset));

    try {
      await _controller!.setExposureOffset(event.offset);
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

    // Emit initial capturing state for long press
    emit(CameraCapturing(
      controller: _controller!,
      progress: 0.0,
      motionLevel: 0.0,
      isInstant: false,
    ));

    // Timer de 3 secondes pour l'exposition
    const updateInterval = Duration(milliseconds: 100);
    int elapsedMs = 0;

    _captureTimer?.cancel();
    _captureTimer = Timer.periodic(updateInterval, (timer) {
      elapsedMs += updateInterval.inMilliseconds;
      final elapsedSeconds = elapsedMs / 1000.0;
      final progress = elapsedMs / 3000.0; // 3 seconds duration
      
      add(UpdateCaptureProgress(progress, elapsedSeconds));
    });
  }

  Future<void> _onUpdateCaptureProgress(
    UpdateCaptureProgress event,
    Emitter<CameraState> emit,
  ) async {
    _elapsedSeconds = event.motionLevel; // hacking reused param name for elapsedSeconds
    _captureProgress = event.progress;
    
    if (_captureProgress >= 1.0) {
      _captureTimer?.cancel();
      add(FinishCapture());
    } else {
      emit(CameraCapturing(
        controller: _controller!,
        progress: _captureProgress,
        motionLevel: _elapsedSeconds > 0 ? (_totalMotion / _elapsedSeconds) : 0,
        isInstant: false,
      ));
    }
  }

  Future<void> _onFinishCapture(
    FinishCapture event,
    Emitter<CameraState> emit,
  ) async {
     await _capturePhoto(emit, isPortrait: _isPortrait, motionBlur: _totalMotion / 3);
  }

  Future<void> _onInstantCapture(
    InstantCapture event,
    Emitter<CameraState> emit,
  ) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    // Feedback immédiat
    emit(CameraCapturing(
      controller: _controller!,
      progress: 0.0,
      motionLevel: 0.0,
      isInstant: true,
    ));
    
    await _capturePhoto(emit, isPortrait: event.isPortrait, motionBlur: 0);
  }

  Future<void> _capturePhoto(
    Emitter<CameraState> emit, {
    required bool isPortrait,
    required double motionBlur,
  }) async {
    final start = DateTime.now().millisecondsSinceEpoch;
    print('LOG_PERF: _capturePhoto started at $start');

    try {
      // Jouer le son sans attendre (fire-and-forget) pour ne pas bloquer la capture
      _audioService.playShutter().ignore();
      
      print('LOG_PERF: calling takePicture at ${DateTime.now().millisecondsSinceEpoch}');
      final XFile photo = await _controller!.takePicture();
      print('LOG_PERF: takePicture done at ${DateTime.now().millisecondsSinceEpoch}');

      // Sauvegarder temporairement
      final Directory appDir = await _cameraRepository.getDocumentsDirectory();
      final String fileName = 'obscura_temp_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savedPath = '${appDir.path}/$fileName';
      
      print('LOG_PERF: saving to $savedPath at ${DateTime.now().millisecondsSinceEpoch}');
      await photo.saveTo(savedPath);
      print('LOG_PERF: saveTo done at ${DateTime.now().millisecondsSinceEpoch}');

      // Lancer le traitement en arrière-plan (rotation, etc.)
      final processingFuture = _imageProcessingService.processImage(
        savedPath,
        FilterType.none,
        0,
        rotateQuarterTurns: isPortrait ? 1 : 0,
      );

      // Phase de développement (Simulation)
      double progress = 0.0;
      final completer = Completer<void>();
      
      print('LOG_PERF: Emitting CameraDeveloping at ${DateTime.now().millisecondsSinceEpoch}');
      
      final timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
        progress += 0.1; // 1 second duration (fast development)
        
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

      print('LOG_PERF: Waiting for development simulation at ${DateTime.now().millisecondsSinceEpoch}');
      await completer.future;
      print('LOG_PERF: Simulation finished at ${DateTime.now().millisecondsSinceEpoch}');
      timer.cancel();

      print('LOG_PERF: Waiting for image processing at ${DateTime.now().millisecondsSinceEpoch}');
      final processedPath = await processingFuture;
      print('LOG_PERF: Image processing finished at ${DateTime.now().millisecondsSinceEpoch}');
      
      // Suppression de la lecture du son de développement selon la demande de l'utilisateur
      // _audioService.playDeveloping().ignore();

      if (!emit.isDone) {
        print('LOG_PERF: Emitting CameraCaptured at ${DateTime.now().millisecondsSinceEpoch}');
        emit(CameraCaptured(
          imagePath: processedPath,
          totalMotion: motionBlur,
        ));
      }

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
      // Relâché avant 3s mais pas annulé -> Prendre la photo (Early release)
      final double averageMotion = _elapsedSeconds > 0 ? (_totalMotion / _elapsedSeconds) : 0;
      
      await _capturePhoto(
        emit, 
        isPortrait: _isPortrait, 
        motionBlur: averageMotion
      );
    } else {
      // Annulation ou fin normale gérée via FinishCapture
      if (emit.isDone) return; 
      
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