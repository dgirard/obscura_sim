import 'package:equatable/equatable.dart';

abstract class CameraEvent extends Equatable {
  const CameraEvent();

  @override
  List<Object?> get props => [];
}

class InitializeCamera extends CameraEvent {}

class DisposeCamera extends CameraEvent {}

class StartCapture extends CameraEvent {}

class StopCapture extends CameraEvent {}

class UpdateMotionLevel extends CameraEvent {
  final double level;

  const UpdateMotionLevel(this.level);

  @override
  List<Object?> get props => [level];
}