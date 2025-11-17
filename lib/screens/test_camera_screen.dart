import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class TestCameraScreen extends StatefulWidget {
  const TestCameraScreen({super.key});

  @override
  State<TestCameraScreen> createState() => _TestCameraScreenState();
}

class _TestCameraScreenState extends State<TestCameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _status = 'Getting cameras...';
      });

      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _status = 'No cameras found';
        });
        return;
      }

      setState(() {
        _status = 'Found ${cameras.length} cameras';
      });

      final camera = cameras.first;

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      setState(() {
        _status = 'Initializing controller...';
      });

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;

      setState(() {
        _status = 'Camera ready!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_controller != null)
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  // Show normal camera preview
                  return Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: CameraPreview(_controller!),
                    ),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                }
              },
            ),

          // Status overlay
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Camera',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Status: $_status',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  if (_controller != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Initialized: ${_controller!.value.isInitialized}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Back button
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}