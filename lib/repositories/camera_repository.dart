import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';

abstract class CameraRepository {
  Future<List<CameraDescription>> getAvailableCameras();
  
  CameraController createController(
    CameraDescription camera,
    ResolutionPreset? resolutionPreset, {
    bool enableAudio = true,
  });
  
  Stream<UserAccelerometerEvent> get accelerometerEvents;
  
  Future<Directory> getDocumentsDirectory();

  Future<PermissionStatus> requestCameraPermission();
}

class CameraRepositoryImpl implements CameraRepository {
  @override
  Future<List<CameraDescription>> getAvailableCameras() => availableCameras();

  @override
  CameraController createController(
    CameraDescription camera,
    ResolutionPreset? resolutionPreset, {
    bool enableAudio = true,
  }) {
    return CameraController(
      camera,
      resolutionPreset ?? ResolutionPreset.medium,
      enableAudio: enableAudio,
    );
  }

  @override
  Stream<UserAccelerometerEvent> get accelerometerEvents =>
      userAccelerometerEventStream();

  @override
  Future<Directory> getDocumentsDirectory() => getApplicationDocumentsDirectory();

  @override
  Future<PermissionStatus> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status;
  }
}
