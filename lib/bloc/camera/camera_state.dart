import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';

abstract class CameraState extends Equatable {
  const CameraState();

  @override
  List<Object?> get props => [];
}

class CameraInitial extends CameraState {}

class CameraReady extends CameraState {
  final CameraController controller;
  final double minExposure;
  final double maxExposure;
  final double currentExposure;
  final FlashMode flashMode;

  const CameraReady(
    this.controller, {
    this.minExposure = 0.0,
    this.maxExposure = 0.0,
    this.currentExposure = 0.0,
    this.flashMode = FlashMode.off,
  });

  @override
  List<Object?> get props => [controller, minExposure, maxExposure, currentExposure, flashMode];

  CameraReady copyWith({
    CameraController? controller,
    double? minExposure,
    double? maxExposure,
    double? currentExposure,
    FlashMode? flashMode,
  }) {
    return CameraReady(
      controller ?? this.controller,
      minExposure: minExposure ?? this.minExposure,
      maxExposure: maxExposure ?? this.maxExposure,
      currentExposure: currentExposure ?? this.currentExposure,
      flashMode: flashMode ?? this.flashMode,
    );
  }
}

class CameraCapturing extends CameraState {
  final CameraController controller;
  final double progress;  // 0.0 to 1.0
  final double motionLevel;  // Niveau de mouvement détecté

  const CameraCapturing({
    required this.controller,
    required this.progress,
    required this.motionLevel,
  });

  @override
  List<Object?> get props => [controller, progress, motionLevel];
}

class CameraDeveloping extends CameraState {
  final CameraController controller;
  final String tempImagePath;
  final double progress; // 0.0 to 1.0

  const CameraDeveloping({
    required this.controller,
    required this.tempImagePath,
    required this.progress,
  });

  @override
  List<Object?> get props => [controller, tempImagePath, progress];
}

class CameraCaptured extends CameraState {
  final String imagePath;
  final double totalMotion;

  const CameraCaptured({
    required this.imagePath,
    required this.totalMotion,
  });

  @override
  List<Object?> get props => [imagePath, totalMotion];
}

class CameraError extends CameraState {
  final String message;

  const CameraError(this.message);

  @override
  List<Object?> get props => [message];
}

class CameraPermissionDenied extends CameraState {}