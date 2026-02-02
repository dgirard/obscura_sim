import 'dart:ui';
import 'package:camera/camera.dart';
import '../../../services/logger_service.dart';
import '../camera_state.dart';

/// Delegate responsable des contrôles caméra : Focus, Exposure, Zoom, Flash.
///
/// Encapsule toute la logique des ajustements caméra pour réduire
/// la complexité du CameraBloc principal.
class CameraControlsDelegate {
  CameraController? _controller;

  /// Met à jour le contrôleur caméra.
  void setController(CameraController? controller) {
    _controller = controller;
  }

  /// Définit le point de focus et d'exposition.
  ///
  /// Retourne true si l'opération a réussi.
  Future<bool> setFocusPoint(Offset point) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return false;
    }

    try {
      await _controller!.setFocusPoint(point);
      await _controller!.setExposurePoint(point);
      return true;
    } catch (e) {
      AppLogger.error('Erreur de focus', e);
      return false;
    }
  }

  /// Définit le niveau de zoom.
  ///
  /// Retourne true si l'opération a réussi.
  Future<bool> setZoomLevel(double zoom) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return false;
    }

    try {
      await _controller!.setZoomLevel(zoom);
      return true;
    } catch (e) {
      AppLogger.error('Erreur zoom', e);
      return false;
    }
  }

  /// Définit l'offset d'exposition.
  ///
  /// Retourne true si l'opération a réussi.
  Future<bool> setExposureOffset(double offset) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return false;
    }

    try {
      await _controller!.setExposureOffset(offset);
      return true;
    } catch (e) {
      AppLogger.error('Erreur exposition', e);
      return false;
    }
  }

  /// Cycle le mode flash : Off -> Auto -> Torch -> Off.
  ///
  /// Retourne le nouveau mode flash ou null en cas d'erreur.
  Future<FlashMode?> cycleFlashMode(FlashMode currentMode) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    FlashMode nextMode;
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
      return nextMode;
    } catch (e) {
      AppLogger.error('Erreur flash', e);
      // Revenir à off en cas d'erreur (pas de flash supporté)
      return FlashMode.off;
    }
  }

  /// Initialise le mode flash à Off.
  Future<void> initializeFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _controller!.setFlashMode(FlashMode.off);
    } catch (e) {
      // Certains appareils n'ont pas de flash
    }
  }

  /// Initialise l'autofocus.
  Future<void> initializeAutoFocus() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _controller!.setFocusMode(FocusMode.auto);
    } catch (e) {
      // Ignorer si non supporté
    }
  }

  /// Récupère les bornes d'exposition.
  ///
  /// Retourne (min, max) ou (-1.0, 1.0) par défaut si non supporté.
  Future<(double min, double max)> getExposureBounds() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return (-1.0, 1.0);
    }

    try {
      final min = await _controller!.getMinExposureOffset();
      final max = await _controller!.getMaxExposureOffset();
      return (min, max);
    } catch (e) {
      AppLogger.camera('Exposition non supportée: $e');
      return (-1.0, 1.0);
    }
  }

  /// Récupère les bornes de zoom.
  ///
  /// Retourne (min, max) ou (1.0, 1.0) par défaut si non supporté.
  Future<(double min, double max)> getZoomBounds() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return (1.0, 1.0);
    }

    try {
      final min = await _controller!.getMinZoomLevel();
      final max = await _controller!.getMaxZoomLevel();
      return (min, max);
    } catch (e) {
      AppLogger.camera('Zoom non supporté: $e');
      return (1.0, 1.0);
    }
  }

  /// Met à jour l'état CameraReady avec le nouveau zoom.
  CameraReady updateZoom(CameraReady state, double zoom) {
    return state.copyWith(currentZoom: zoom);
  }

  /// Met à jour l'état CameraReady avec la nouvelle exposition.
  CameraReady updateExposure(CameraReady state, double exposure) {
    return state.copyWith(currentExposure: exposure);
  }

  /// Met à jour l'état CameraReady avec le nouveau mode flash.
  CameraReady updateFlashMode(CameraReady state, FlashMode mode) {
    return state.copyWith(flashMode: mode);
  }
}
