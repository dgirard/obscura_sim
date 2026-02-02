import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../bloc/camera/camera_bloc.dart';
import '../bloc/camera/camera_event.dart';
import '../bloc/camera/camera_state.dart';
import '../bloc/filter/filter_bloc.dart';
import '../bloc/gallery/gallery_bloc.dart';
import '../bloc/settings/settings_bloc.dart';
import '../models/photo.dart';
import '../navigation/app_router.dart';
import '../services/logger_service.dart';
import '../theme/colors.dart';

class SimpleViewfinderScreen extends StatefulWidget {
  const SimpleViewfinderScreen({super.key});

  @override
  State<SimpleViewfinderScreen> createState() => _SimpleViewfinderScreenState();
}

class _SimpleViewfinderScreenState extends State<SimpleViewfinderScreen>
    with WidgetsBindingObserver {
  Orientation? _deviceOrientation;
  Offset? _focusPoint;
  Timer? _focusTimer;

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
    _focusTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _handleFocusTap(TapUpDetails details, BoxConstraints constraints) {
    if (context.read<CameraBloc>().state is! CameraReady) return;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );

    // Inversion des coordonnées si le viseur est inversé
    final isInverted = context.read<SettingsBloc>().state.isInvertedViewfinder;
    final sensorPoint = isInverted
        ? Offset(1.0 - offset.dx, 1.0 - offset.dy)
        : offset;

    context.read<CameraBloc>().add(SetFocusPoint(sensorPoint));

    // Feedback visuel
    setState(() {
      _focusPoint = details.localPosition;
    });

    // Cacher l'indicateur après 1s
    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _focusPoint = null;
        });
      }
    });
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
        backgroundColor: ObscuraColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ObscuraColors.background,
      body: MultiBlocListener(
        listeners: [
          BlocListener<CameraBloc, CameraState>(
            listener: (context, state) {
              if (state is CameraError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: ObscuraColors.error,
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
                    else if (state is CameraPermissionDenied)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.no_photography, color: ObscuraColors.error, size: 64),
                            const SizedBox(height: 16),
                            const Text(
                              'Permission caméra requise',
                              style: TextStyle(color: ObscuraColors.textPrimary),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => openAppSettings(),
                              child: const Text('Ouvrir les paramètres'),
                            ),
                          ],
                        ),
                      )
                    else
                      const Center(
                        child: CircularProgressIndicator(color: ObscuraColors.textSubtle),
                      ),
// ...

                    // Focus Indicator
                    if (_focusPoint != null)
                      Positioned(
                        left: _focusPoint!.dx - 25,
                        top: _focusPoint!.dy - 25,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: ObscuraColors.focusIndicator, width: 1.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                    // Capture Overlay
                    if (state is CameraCapturing)
                      Positioned.fill(
                        child: Container(
                          color: state.isInstant ? ObscuraColors.background : ObscuraColors.overlayLight,
                          child: state.isInstant
                              ? const Center(
                                  child: Text(
                                    'Capture...',
                                    style: TextStyle(
                                      color: ObscuraColors.textHint,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      
                    // Developing Overlay
                    if (state is CameraDeveloping)
                      _buildDevelopingOverlay(context, state),

                    // Motion Indicator
                    if (state is CameraCapturing && state.motionLevel > 1.0)
                      _buildMotionWarning(),

                    // Filter Indicator
                    _buildFilterIndicator(),

                    // Exposure Slider
                    if (state is CameraReady)
                      Positioned(
                        right: 10,
                        top: 100,
                        bottom: 150,
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: SizedBox(
                            height: 40,
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: ObscuraColors.primary,
                                inactiveTrackColor: ObscuraColors.textSubtle,
                                thumbColor: ObscuraColors.primary,
                                trackHeight: 2.0,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                              ),
                              child: Slider(
                                value: state.currentExposure,
                                min: state.minExposure,
                                max: state.maxExposure,
                                onChanged: (value) {
                                  context.read<CameraBloc>().add(SetExposureOffset(value));
                                },
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Zoom Slider (Horizontal)
                    if (state is CameraReady && state.maxZoom > state.minZoom)
                      Positioned(
                        left: 50,
                        right: 50,
                        bottom: 120,
                        child: Row(
                          children: [
                            const Icon(Icons.zoom_out, color: ObscuraColors.textHint, size: 20),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: ObscuraColors.textPrimary,
                                  inactiveTrackColor: ObscuraColors.textSubtle,
                                  thumbColor: ObscuraColors.textPrimary,
                                  trackHeight: 2.0,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
                                ),
                                child: Slider(
                                  value: state.currentZoom,
                                  min: state.minZoom,
                                  max: state.maxZoom,
                                  onChanged: (value) {
                                    context.read<CameraBloc>().add(SetZoomLevel(value));
                                  },
                                ),
                              ),
                            ),
                            const Icon(Icons.zoom_in, color: ObscuraColors.textHint, size: 20),
                          ],
                        ),
                      ),

                    // Flash Button
                    if (state is CameraReady)
                      Positioned(
                        top: 50,
                        left: 20,
                        child: IconButton(
                          onPressed: () => context.read<CameraBloc>().add(ToggleFlash()),
                          icon: Icon(
                            _getFlashIcon(state.flashMode),
                            color: state.flashMode == FlashMode.off ? ObscuraColors.flashInactive : ObscuraColors.flashActive,
                            size: 28,
                          ),
                        ),
                      ),

                    // Settings Button
                    Positioned(
                      top: 50,
                      left: 70,
                      child: IconButton(
                        onPressed: () => context.push(AppRoutes.settings),
                        icon: const Icon(
                          Icons.settings,
                          color: ObscuraColors.textDisabled,
                          size: 28,
                        ),
                      ),
                    ),

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
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return Transform(
            alignment: Alignment.center,
            transform: settingsState.isInvertedViewfinder
                ? (Matrix4.identity()..rotateZ(3.14159)) // 180° rotation
                : Matrix4.identity(),
            child: AspectRatio(
              aspectRatio: orientation == Orientation.portrait
                  ? 1 / controller!.value.aspectRatio
                  : controller!.value.aspectRatio,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapUp: (details) => _handleFocusTap(details, constraints),
                    behavior: HitTestBehavior.opaque,
                    child: CameraPreview(controller!),
                  );
                },
              ),
            ),
          );
        },
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
            color: ObscuraColors.motionWarningOverlay,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Stabilisez l\'appareil',
            style: TextStyle(
              color: ObscuraColors.textPrimary,
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
                color: ObscuraColors.overlayMedium,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getFilterName(filterState.selectedFilter),
                style: const TextStyle(color: ObscuraColors.textSecondary, fontSize: 12),
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
          colors: [Colors.transparent, ObscuraColors.overlayDark],
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
              onPressed: () => context.push(AppRoutes.gallery),
              icon: const Icon(Icons.photo_library),
              iconSize: 30,
              color: ObscuraColors.textSecondary,
            ),
          ),

          // Capture Button
          GestureDetector(
            onTap: () {
              if (!isCapturing) {
                AppLogger.perf('Button tapped at ${DateTime.now().millisecondsSinceEpoch}');
                context.read<CameraBloc>().add(
                  InstantCapture(isPortrait: isPortrait)
                );
              }
            },
            onLongPressStart: (_) {
              if (!isCapturing) {
                AppLogger.perf('Long press start at ${DateTime.now().millisecondsSinceEpoch}');
                context.read<CameraBloc>().add(
                  StartCapture(isPortrait: isPortrait)
                );
              }
            },
            onLongPressEnd: (_) => context.read<CameraBloc>().add(const StopCapture(abort: false)),
            onLongPressCancel: () => context.read<CameraBloc>().add(const StopCapture(abort: true)),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ObscuraColors.captureButtonBorder, width: 4),
              ),
              child: isCapturing
                  ? Padding(
                      padding: const EdgeInsets.all(4),
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 3,
                        backgroundColor: ObscuraColors.textSubtle,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          (state is CameraCapturing && state.motionLevel > 1.0)
                              ? ObscuraColors.error
                              : ObscuraColors.textPrimary
                        ),
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: ObscuraColors.textPrimary,
                      ),
                    ),
            ),
          ),

          // Filter Button
          Transform.rotate(
            angle: isPortrait ? 0 : -1.5708,
            child: IconButton(
              onPressed: () => context.push(AppRoutes.filterSelection),
              icon: const Icon(Icons.filter_vintage),
              iconSize: 30,
              color: ObscuraColors.textSecondary,
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

  IconData _getFlashIcon(FlashMode mode) {
    switch (mode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.torch:
        return Icons.highlight;
      case FlashMode.always:
        return Icons.flash_on;
    }
  }

  Widget _buildDevelopingOverlay(BuildContext context, CameraDeveloping state) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: ObscuraColors.background),
        // Text indicator to show immediate feedback while image loads/fades
        const Center(
          child: Text(
            'Développement...',
            style: TextStyle(
              color: ObscuraColors.textHint,
              fontSize: 16,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
            ),
          ),
        ),
        Center(
          child: Opacity(
            opacity: state.progress,
            child: Image.file(
              File(state.tempImagePath),
              fit: BoxFit.contain,
              gaplessPlayback: true, // Prevent flickering
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        ),
      ],
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