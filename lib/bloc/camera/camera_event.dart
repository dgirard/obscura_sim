import 'dart:ui';
import 'package:equatable/equatable.dart';

abstract class CameraEvent extends Equatable {
  const CameraEvent();

  @override
  List<Object?> get props => [];
}
// ... existing events
class SetFocusPoint extends CameraEvent {
  final Offset point;

  const SetFocusPoint(this.point);

  @override
  List<Object?> get props => [point];
}

class SetExposureOffset extends CameraEvent {
  final double offset;

  const SetExposureOffset(this.offset);

  @override
  List<Object?> get props => [offset];
}

class SetZoomLevel extends CameraEvent {
  final double zoom;

  const SetZoomLevel(this.zoom);

  @override
  List<Object?> get props => [zoom];
}

class ToggleFlash extends CameraEvent {}

class UpdateDevelopingProgress extends CameraEvent {
  final double progress;
  const UpdateDevelopingProgress(this.progress);
  @override
  List<Object> get props => [progress];
}

class InitializeCamera extends CameraEvent {}
// ...

class DisposeCamera extends CameraEvent {}

class StartCapture extends CameraEvent {
  final bool isPortrait;

  const StartCapture({required this.isPortrait});

  @override
  List<Object?> get props => [isPortrait];
}

class UpdateCaptureProgress extends CameraEvent {
  final double progress;
  final double elapsedSeconds;
  const UpdateCaptureProgress(this.progress, this.elapsedSeconds);
  @override
  List<Object> get props => [progress, elapsedSeconds];
}

class FinishCapture extends CameraEvent {}

class InstantCapture extends CameraEvent {
  final bool isPortrait;

  const InstantCapture({required this.isPortrait});

  @override
  List<Object?> get props => [isPortrait];
}

class StopCapture extends CameraEvent {
  final bool abort;

  const StopCapture({this.abort = false});

  @override
  List<Object?> get props => [abort];
}

class UpdateMotionLevel extends CameraEvent {
  final double level;

  const UpdateMotionLevel(this.level);

  @override
  List<Object?> get props => [level];
}