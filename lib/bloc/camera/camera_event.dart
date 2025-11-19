import 'package:equatable/equatable.dart';

abstract class CameraEvent extends Equatable {
  const CameraEvent();

  @override
  List<Object?> get props => [];
}

class InitializeCamera extends CameraEvent {}

class DisposeCamera extends CameraEvent {}

class StartCapture extends CameraEvent {
  final bool isPortrait;

  const StartCapture({required this.isPortrait});

  @override
  List<Object?> get props => [isPortrait];
}

class InstantCapture extends CameraEvent {
  final bool isPortrait;

  const InstantCapture({required this.isPortrait});

  @override
  List<Object?> get props => [isPortrait];
}

class StopCapture extends CameraEvent {}

class UpdateMotionLevel extends CameraEvent {
  final double level;

  const UpdateMotionLevel(this.level);

  @override
  List<Object?> get props => [level];
}