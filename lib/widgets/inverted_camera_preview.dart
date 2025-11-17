import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class InvertedCameraPreview extends StatelessWidget {
  final CameraController controller;

  const InvertedCameraPreview({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white24,
        ),
      );
    }

    // Camera obscura effect - double inversion
    return Container(
      color: Colors.black,
      child: Center(
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateZ(3.14159), // Rotation 180° (effet camera obscura complet)
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}