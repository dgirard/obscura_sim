import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import '../../../models/photo.dart';
import '../../../repositories/camera_repository.dart';
import '../../../services/image_processing_service.dart';
import '../../../services/audio_service.dart';
import '../../../services/logger_service.dart';

/// Résultat d'une capture photo.
class CaptureResult {
  final String imagePath;
  final double totalMotion;
  final bool success;
  final String? error;

  const CaptureResult({
    required this.imagePath,
    required this.totalMotion,
    this.success = true,
    this.error,
  });

  const CaptureResult.failure(this.error)
      : imagePath = '',
        totalMotion = 0,
        success = false;
}

/// Callback pour la progression du développement.
typedef DevelopingProgressCallback = void Function(String tempPath, double progress);

/// Delegate responsable de la capture photo.
///
/// Gère la capture instantanée et longue exposition, le timer,
/// et le post-traitement des images.
class CaptureDelegate {
  final ImageProcessingService _imageProcessingService;
  final CameraRepository _cameraRepository;
  final AudioService _audioService;

  CameraController? _controller;
  Timer? _captureTimer;
  Timer? _developingTimer;

  // État de la capture en cours
  double _captureProgress = 0;
  bool _isPortrait = false;
  double _elapsedSeconds = 0;

  /// Callback appelé quand le timer de capture progresse.
  void Function(double progress, double elapsedSeconds)? onCaptureProgress;

  /// Callback appelé quand la capture est terminée (timer expiré).
  void Function()? onCaptureFinished;

  CaptureDelegate({
    required ImageProcessingService imageProcessingService,
    required CameraRepository cameraRepository,
    required AudioService audioService,
  })  : _imageProcessingService = imageProcessingService,
        _cameraRepository = cameraRepository,
        _audioService = audioService;

  /// Met à jour le contrôleur caméra.
  void setController(CameraController? controller) {
    _controller = controller;
  }

  /// Démarre une capture longue exposition.
  ///
  /// Retourne true si la capture a démarré avec succès.
  bool startLongCapture({required bool isPortrait}) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return false;
    }

    _captureProgress = 0;
    _elapsedSeconds = 0;
    _isPortrait = isPortrait;

    // Timer de 3 secondes pour l'exposition
    const updateInterval = Duration(milliseconds: 100);
    int elapsedMs = 0;

    _captureTimer?.cancel();
    _captureTimer = Timer.periodic(updateInterval, (timer) {
      elapsedMs += updateInterval.inMilliseconds;
      _elapsedSeconds = elapsedMs / 1000.0;
      _captureProgress = elapsedMs / 3000.0; // 3 seconds duration

      onCaptureProgress?.call(_captureProgress, _elapsedSeconds);

      if (_captureProgress >= 1.0) {
        timer.cancel();
        onCaptureFinished?.call();
      }
    });

    return true;
  }

  /// Arrête la capture en cours.
  ///
  /// Retourne les informations de la capture si elle était active.
  ({bool wasCapturing, double elapsedSeconds, bool isPortrait})? stopCapture() {
    final wasCapturing = _captureTimer?.isActive ?? false;
    _captureTimer?.cancel();

    if (wasCapturing) {
      return (
        wasCapturing: true,
        elapsedSeconds: _elapsedSeconds,
        isPortrait: _isPortrait,
      );
    }

    _resetState();
    return null;
  }

  /// Réinitialise l'état interne.
  void _resetState() {
    _captureProgress = 0;
    _elapsedSeconds = 0;
  }

  /// Capture la photo actuelle.
  ///
  /// [isPortrait] indique l'orientation de l'appareil.
  /// [motionBlur] niveau de flou de mouvement détecté.
  /// [onDevelopingProgress] callback pour la progression du développement.
  Future<CaptureResult> capturePhoto({
    required bool isPortrait,
    required double motionBlur,
    DevelopingProgressCallback? onDevelopingProgress,
  }) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const CaptureResult.failure('Caméra non initialisée');
    }

    final start = DateTime.now().millisecondsSinceEpoch;
    AppLogger.perf('_capturePhoto started at $start');

    try {
      // Jouer le son sans attendre (fire-and-forget) pour ne pas bloquer la capture
      _audioService.playShutter().ignore();

      AppLogger.perf('calling takePicture at ${DateTime.now().millisecondsSinceEpoch}');
      final XFile photo = await _controller!.takePicture();
      AppLogger.perf('takePicture done at ${DateTime.now().millisecondsSinceEpoch}');

      // Sauvegarder temporairement
      final Directory appDir = await _cameraRepository.getDocumentsDirectory();
      final String fileName = 'obscura_temp_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savedPath = '${appDir.path}/$fileName';

      AppLogger.perf('saving to $savedPath at ${DateTime.now().millisecondsSinceEpoch}');
      await photo.saveTo(savedPath);
      AppLogger.perf('saveTo done at ${DateTime.now().millisecondsSinceEpoch}');

      // Lancer le traitement en arrière-plan (rotation, etc.)
      final processingFuture = _imageProcessingService.processImage(
        savedPath,
        FilterType.none,
        0,
        rotateQuarterTurns: isPortrait ? 1 : 0,
      );

      // Phase de développement (Simulation)
      if (onDevelopingProgress != null) {
        await _simulateDeveloping(savedPath, onDevelopingProgress);
      }

      AppLogger.perf('Waiting for image processing at ${DateTime.now().millisecondsSinceEpoch}');
      final processedPath = await processingFuture;
      AppLogger.perf('Image processing finished at ${DateTime.now().millisecondsSinceEpoch}');

      _resetState();

      return CaptureResult(
        imagePath: processedPath,
        totalMotion: motionBlur,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Erreur de capture', e, stackTrace);
      _resetState();
      return CaptureResult.failure('Erreur de capture: ${e.toString()}');
    }
  }

  /// Simule la phase de développement avec progression.
  Future<void> _simulateDeveloping(
    String tempImagePath,
    DevelopingProgressCallback onProgress,
  ) async {
    double progress = 0.0;
    final completer = Completer<void>();

    AppLogger.perf('Emitting CameraDeveloping at ${DateTime.now().millisecondsSinceEpoch}');

    _developingTimer?.cancel();
    _developingTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      progress += 0.1; // 1 second duration (fast development)

      if (progress >= 1.0) {
        t.cancel();
        if (!completer.isCompleted) completer.complete();
      } else {
        onProgress(tempImagePath, progress.clamp(0.0, 1.0));
      }
    });

    AppLogger.perf('Waiting for development simulation at ${DateTime.now().millisecondsSinceEpoch}');
    await completer.future;
    AppLogger.perf('Simulation finished at ${DateTime.now().millisecondsSinceEpoch}');
    _developingTimer?.cancel();
  }

  /// Getter pour la progression actuelle de la capture.
  double get captureProgress => _captureProgress;

  /// Getter pour les secondes écoulées.
  double get elapsedSeconds => _elapsedSeconds;

  /// Getter pour l'orientation de capture.
  bool get isPortrait => _isPortrait;

  /// Libère les ressources.
  void dispose() {
    _captureTimer?.cancel();
    _developingTimer?.cancel();
  }
}
