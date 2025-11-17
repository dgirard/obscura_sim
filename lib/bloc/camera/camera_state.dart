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

  const CameraReady(this.controller);

  @override
  List<Object?> get props => [controller];
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