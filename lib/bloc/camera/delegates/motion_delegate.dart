import 'dart:async';
import '../../../repositories/camera_repository.dart';

/// Delegate responsable de la détection de mouvement via l'accéléromètre.
///
/// Encapsule la logique de surveillance du mouvement pendant la capture
/// pour réduire la complexité du CameraBloc principal.
class MotionDelegate {
  final CameraRepository _cameraRepository;

  StreamSubscription? _accelerometerSubscription;
  double _totalMotion = 0;
  double _currentMotionLevel = 0;

  /// Callback appelé quand un nouveau niveau de mouvement est détecté.
  void Function(double motionLevel)? onMotionUpdate;

  MotionDelegate({
    required CameraRepository cameraRepository,
  }) : _cameraRepository = cameraRepository;

  /// Démarre la surveillance de l'accéléromètre.
  void startMonitoring() {
    _totalMotion = 0;
    _currentMotionLevel = 0;

    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = _cameraRepository.accelerometerEvents.listen((event) {
      final motion = (event.x.abs() + event.y.abs() + event.z.abs()) / 3;
      _totalMotion += motion;
      _currentMotionLevel = motion;
      onMotionUpdate?.call(motion);
    });
  }

  /// Arrête la surveillance de l'accéléromètre.
  void stopMonitoring() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }

  /// Réinitialise les compteurs de mouvement.
  void reset() {
    _totalMotion = 0;
    _currentMotionLevel = 0;
  }

  /// Calcule le niveau de mouvement moyen sur la période.
  ///
  /// [elapsedSeconds] durée de la capture en secondes.
  double getAverageMotion(double elapsedSeconds) {
    if (elapsedSeconds <= 0) return 0;
    return _totalMotion / elapsedSeconds;
  }

  /// Getter pour le mouvement total accumulé.
  double get totalMotion => _totalMotion;

  /// Getter pour le niveau de mouvement actuel.
  double get currentMotionLevel => _currentMotionLevel;

  /// Indique si le mouvement dépasse le seuil d'avertissement.
  ///
  /// [threshold] seuil au-delà duquel le mouvement est considéré excessif.
  bool isExcessiveMotion({double threshold = 1.0}) {
    return _currentMotionLevel > threshold;
  }

  /// Libère les ressources.
  void dispose() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }
}
