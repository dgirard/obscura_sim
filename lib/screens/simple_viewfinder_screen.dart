import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:image/image.dart' as img;
import '../bloc/filter/filter_bloc.dart';
import '../bloc/gallery/gallery_bloc.dart';
import '../models/photo.dart';
import 'filter_selection_screen.dart';
import 'gallery_screen.dart';

class SimpleViewfinderScreen extends StatefulWidget {
  const SimpleViewfinderScreen({super.key});

  @override
  State<SimpleViewfinderScreen> createState() => _SimpleViewfinderScreenState();
}

class _SimpleViewfinderScreenState extends State<SimpleViewfinderScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCapturing = false;
  double _captureProgress = 0;
  double _motionLevel = 0;
  Timer? _captureTimer;
  StreamSubscription? _accelerometerSubscription;
  double _totalMotion = 0;
  String _debugStatus = "Initializing...";
  DeviceOrientation? _currentOrientation;
  Orientation? _deviceOrientation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _debugStatus = "Getting cameras...";
      });

      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _debugStatus = "No cameras found!";
        });
        return;
      }

      setState(() {
        _debugStatus = "Found ${cameras.length} cameras";
      });

      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,  // Changed to medium for better performance
        enableAudio: false,
      );

      setState(() {
        _debugStatus = "Initializing controller...";
      });

      await _controller!.initialize();

      if (_controller!.value.hasError) {
        setState(() {
          _debugStatus = "Controller error: ${_controller!.value.errorDescription}";
        });
        return;
      }

      await _controller!.setFlashMode(FlashMode.off);

      if (mounted) {
        setState(() {
          _debugStatus = "Camera ready! Initialized: ${_controller!.value.isInitialized}";
        });
      }
    } catch (e) {
      print('Camera initialization error: $e');
      setState(() {
        _debugStatus = "Error: ${e.toString()}";
      });
    }
  }

  Future<void> _startCapture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
      _captureProgress = 0;
      _totalMotion = 0;
    });

    // Start motion detection
    _accelerometerSubscription = userAccelerometerEventStream().listen((event) {
      final motion = (event.x.abs() + event.y.abs() + event.z.abs()) / 3;
      _totalMotion += motion;
      setState(() {
        _motionLevel = motion;
      });
    });

    // 3-second capture timer
    const duration = Duration(seconds: 3);
    const updateInterval = Duration(milliseconds: 100);
    int elapsed = 0;

    _captureTimer = Timer.periodic(updateInterval, (timer) async {
      elapsed += updateInterval.inMilliseconds;
      setState(() {
        _captureProgress = elapsed / duration.inMilliseconds;
      });

      if (_captureProgress >= 1.0) {
        timer.cancel();
        await _capturePhoto();
      }
    });

    HapticFeedback.lightImpact();
  }

  void _stopCapture() {
    _captureTimer?.cancel();
    _accelerometerSubscription?.cancel();
    setState(() {
      _isCapturing = false;
      _captureProgress = 0;
      _motionLevel = 0;
    });
  }

  Future<void> _capturePhoto() async {
    try {
      final XFile photo = await _controller!.takePicture();

      // Save to app directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'obscura_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savedPath = '${appDir.path}/$fileName';

      // Check if we need to rotate the image for portrait mode
      if (_deviceOrientation == Orientation.portrait) {
        // The camera always captures in landscape, so we need to rotate for portrait
        final bytes = await photo.readAsBytes();
        final img.Image? image = img.decodeImage(bytes);

        if (image != null) {
          // Rotate 90 degrees clockwise for portrait
          final img.Image rotated = img.copyRotate(image, angle: 90);

          // Save the rotated image
          final File file = File(savedPath);
          await file.writeAsBytes(img.encodeJpg(rotated));
        } else {
          // Fallback if image decoding fails
          await photo.saveTo(savedPath);
        }
      } else {
        // Landscape mode - save as is
        await photo.saveTo(savedPath);
      }

      // Add to gallery
      final filterState = context.read<FilterBloc>().state as FilterSelected;
      context.read<GalleryBloc>().add(
        AddPhoto(
          path: savedPath,
          filter: filterState.selectedFilter,
          motionBlur: _totalMotion / 3,
        ),
      );

      HapticFeedback.mediumImpact();
      _stopCapture();
    } catch (e) {
      print('Capture error: $e');
      _stopCapture();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _captureTimer?.cancel();
    _accelerometerSubscription?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: OrientationBuilder(
        builder: (context, orientation) {
          _deviceOrientation = orientation; // Store current orientation
          return Stack(
            children: [
              // Camera Preview - Avec effet camera obscura
              if (_controller != null && _controller!.value.isInitialized)
                Center(
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateZ(3.14159), // Rotation 180° pour effet camera obscura
                    child: AspectRatio(
                      aspectRatio: orientation == Orientation.portrait
                          ? 1 / _controller!.value.aspectRatio // Inverser en portrait
                          : _controller!.value.aspectRatio,   // Normal en paysage
                      child: CameraPreview(_controller!),
                    ),
                  ),
                ),

          // Capture overlay
          if (_isCapturing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),

          // Motion indicator
          if (_isCapturing && _motionLevel > 1.0)
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Stabilisez l\'appareil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

          // Filter indicator
          BlocBuilder<FilterBloc, FilterState>(
            builder: (context, filterState) {
              if (filterState is FilterSelected &&
                  filterState.selectedFilter != FilterType.none) {
                return Positioned(
                  top: 50,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getFilterName(filterState.selectedFilter),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

              // Controls - Position based on orientation
              _buildControls(context, orientation),

          // Debug status overlay (hidden for production)
          // Uncomment for debugging
          /*
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_debugStatus, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
          */

              // Loading indicator
              if (_controller == null || !_controller!.value.isInitialized)
                const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white24,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildControls(BuildContext context, Orientation orientation) {
    final isPortrait = orientation == Orientation.portrait;

    // Controls widget
    final controls = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPortrait ? 0 : 20,
        vertical: isPortrait ? 20 : 0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isPortrait ? Alignment.topCenter : Alignment.centerLeft,
          end: isPortrait ? Alignment.bottomCenter : Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Flex(
        direction: isPortrait ? Axis.horizontal : Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery button
          Transform.rotate(
            angle: isPortrait ? 0 : -1.5708, // Rotate 90° in landscape
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GalleryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.photo_library),
              iconSize: 30,
              color: Colors.white70,
            ),
          ),

          // Capture button
          GestureDetector(
            onTapDown: (_) => _startCapture(),
            onTapUp: (_) => _stopCapture(),
            onTapCancel: _stopCapture,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
              ),
              child: _isCapturing
                  ? Padding(
                      padding: const EdgeInsets.all(4),
                      child: CircularProgressIndicator(
                        value: _captureProgress,
                        strokeWidth: 3,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _motionLevel > 1.0 ? Colors.red : Colors.white,
                        ),
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          // Filter button
          Transform.rotate(
            angle: isPortrait ? 0 : -1.5708, // Rotate 90° in landscape
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FilterSelectionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.filter_vintage),
              iconSize: 30,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );

    // Position controls based on orientation
    if (isPortrait) {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          child: controls,
        ),
      );
    } else {
      return Positioned(
        right: 0,
        top: 0,
        bottom: 0,
        child: SafeArea(
          child: controls,
        ),
      );
    }
  }

  String _getFilterName(FilterType filter) {
    switch (filter) {
      case FilterType.monochrome:
        return 'Monochrome';
      case FilterType.sepia:
        return 'Sépia';
      case FilterType.glassPlate:
        return 'Plaque de Verre';
      default:
        return '';
    }
  }
}