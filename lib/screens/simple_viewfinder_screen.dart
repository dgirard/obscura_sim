import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/camera/camera_bloc.dart';
import '../bloc/camera/camera_event.dart';
import '../bloc/camera/camera_state.dart';
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
  Orientation? _deviceOrientation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    context.read<CameraBloc>().add(InitializeCamera());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bloc = context.read<CameraBloc>();
    if (state == AppLifecycleState.inactive) {
      bloc.add(DisposeCamera());
    } else if (state == AppLifecycleState.resumed) {
      bloc.add(InitializeCamera());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onCaptureSuccess(BuildContext context, CameraCaptured state) {
    // Add to gallery
    final filterState = context.read<FilterBloc>().state;
    final FilterType selectedFilter = (filterState is FilterSelected)
        ? filterState.selectedFilter
        : FilterType.none;

    context.read<GalleryBloc>().add(
      AddPhoto(
        path: state.imagePath,
        filter: selectedFilter,
        motionBlur: state.totalMotion,
        isPortrait: _deviceOrientation == Orientation.portrait,
      ),
    );

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo sauvegardée'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: MultiBlocListener(
        listeners: [
          BlocListener<CameraBloc, CameraState>(
            listener: (context, state) {
              if (state is CameraError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (state is CameraCaptured) {
                _onCaptureSuccess(context, state);
              }
            },
          ),
        ],
        child: OrientationBuilder(
          builder: (context, orientation) {
            _deviceOrientation = orientation;
            return BlocBuilder<CameraBloc, CameraState>(
              builder: (context, state) {
                return Stack(
                  children: [
                    // Camera Preview
                    if (state is CameraReady || state is CameraCapturing)
                      _buildCameraPreview(context, state, orientation)
                    else
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white24),
                      ),

                    // Capture Overlay
                    if (state is CameraCapturing)
                      Positioned.fill(
                        child: Container(color: Colors.black.withOpacity(0.3)),
                      ),

                    // Motion Indicator
                    if (state is CameraCapturing && state.motionLevel > 1.0)
                      _buildMotionWarning(),

                    // Filter Indicator
                    _buildFilterIndicator(),

                    // Controls
                    _buildControls(context, state, orientation),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCameraPreview(BuildContext context, CameraState state, Orientation orientation) {
    CameraController? controller;
    if (state is CameraReady) controller = state.controller;
    if (state is CameraCapturing) controller = state.controller;

    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..rotateZ(3.14159), // 180° rotation
        child: AspectRatio(
          aspectRatio: orientation == Orientation.portrait
              ? 1 / controller.value.aspectRatio
              : controller.value.aspectRatio,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  Widget _buildMotionWarning() {
    return Positioned(
      top: 50,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    );
  }

  Widget _buildFilterIndicator() {
    return BlocBuilder<FilterBloc, FilterState>(
      builder: (context, filterState) {
        if (filterState is FilterSelected &&
            filterState.selectedFilter != FilterType.none) {
          return Positioned(
            top: 50,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getFilterName(filterState.selectedFilter),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildControls(BuildContext context, CameraState state, Orientation orientation) {
    final isPortrait = orientation == Orientation.portrait;
    
    // Calculate capture progress
    double progress = 0;
    bool isCapturing = false;
    if (state is CameraCapturing) {
      progress = state.progress;
      isCapturing = true;
    }

    final controls = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPortrait ? 0 : 20,
        vertical: isPortrait ? 20 : 0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isPortrait ? Alignment.topCenter : Alignment.centerLeft,
          end: isPortrait ? Alignment.bottomCenter : Alignment.centerRight,
          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
        ),
      ),
      child: Flex(
        direction: isPortrait ? Axis.horizontal : Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery Button
          Transform.rotate(
            angle: isPortrait ? 0 : -1.5708,
            child: IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GalleryScreen()),
              ),
              icon: const Icon(Icons.photo_library),
              iconSize: 30,
              color: Colors.white70,
            ),
          ),

          // Capture Button
          GestureDetector(
            onTap: () {
              if (!isCapturing) {
                context.read<CameraBloc>().add(
                  InstantCapture(isPortrait: isPortrait)
                );
              }
            },
            onLongPressStart: (_) {
              if (!isCapturing) {
                context.read<CameraBloc>().add(
                  StartCapture(isPortrait: isPortrait)
                );
              }
            },
            onLongPressEnd: (_) => context.read<CameraBloc>().add(StopCapture()),
            onLongPressCancel: () => context.read<CameraBloc>().add(StopCapture()),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: isCapturing
                  ? Padding(
                      padding: const EdgeInsets.all(4),
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 3,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          (state is CameraCapturing && state.motionLevel > 1.0) 
                              ? Colors.red 
                              : Colors.white
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

          // Filter Button
          Transform.rotate(
            angle: isPortrait ? 0 : -1.5708,
            child: IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FilterSelectionScreen()),
              ),
              icon: const Icon(Icons.filter_vintage),
              iconSize: 30,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );

    return Positioned(
      left: isPortrait ? 0 : null,
      right: 0,
      top: isPortrait ? null : 0,
      bottom: 0,
      child: SafeArea(child: controls),
    );
  }

  String _getFilterName(FilterType filter) {
    switch (filter) {
      case FilterType.monochrome: return 'Monochrome';
      case FilterType.sepia: return 'Sépia';
      case FilterType.glassPlate: return 'Plaque de Verre';
      case FilterType.cyanotype: return 'Cyanotype';
      case FilterType.daguerreotype: return 'Daguerréotype';
      default: return '';
    }
  }
}