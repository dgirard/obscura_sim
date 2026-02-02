import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/camera/camera_bloc.dart';
import '../bloc/camera/camera_event.dart';
import '../bloc/camera/camera_state.dart';
import '../bloc/filter/filter_bloc.dart';
import '../bloc/gallery/gallery_bloc.dart';
import '../models/photo.dart';
import '../services/logger_service.dart';
import '../widgets/inverted_camera_preview.dart';
import 'filter_selection_screen.dart';
import 'gallery_screen.dart';

class ViewfinderScreen extends StatefulWidget {
  const ViewfinderScreen({super.key});

  @override
  State<ViewfinderScreen> createState() => _ViewfinderScreenState();
}

class _ViewfinderScreenState extends State<ViewfinderScreen> {
  @override
  void initState() {
    super.initState();
    // Masquer la barre de statut pour une expérience immersive
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Initialiser la caméra
    context.read<CameraBloc>().add(InitializeCamera());
  }

  @override
  void dispose() {
    context.read<CameraBloc>().add(DisposeCamera());
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<CameraBloc, CameraState>(
        listener: (context, state) {
          if (state is CameraCaptured) {
            // Ajouter la photo à la galerie
            final filterState = context.read<FilterBloc>().state as FilterSelected;
            context.read<GalleryBloc>().add(
              AddPhoto(
                path: state.imagePath,
                filter: filterState.selectedFilter,
                motionBlur: state.totalMotion,
                isPortrait: false, // Default for legacy viewfinder
              ),
            );

            // Jouer un son de capture
            HapticFeedback.mediumImpact();
          }
        },
        builder: (context, state) {
          // Debug pour voir l'état
          AppLogger.camera('State: $state');
          if (state is CameraReady) {
            AppLogger.camera('Controller initialized: ${state.controller.value.isInitialized}');
          }

          return Stack(
            children: [
              // Fond noir pour debug
              Container(color: Colors.black),

              // Prévisualisation inversée
              if (state is CameraReady || state is CameraCapturing)
                Positioned.fill(
                  child: InvertedCameraPreview(
                    controller: state is CameraReady
                        ? state.controller
                        : (state as CameraCapturing).controller,
                  ),
                ),

              // Overlay sombre pendant la capture
              if (state is CameraCapturing)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),

              // Indicateur de mouvement
              if (state is CameraCapturing && state.motionLevel > 1.0)
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

              // Contrôles en bas
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.only(bottom: 40, top: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Bouton Galerie
                      IconButton(
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

                      // Bouton de capture
                      GestureDetector(
                        onTapDown: (_) {
                          if (state is CameraReady) {
                            final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
                            context.read<CameraBloc>().add(StartCapture(isPortrait: isPortrait));
                            HapticFeedback.lightImpact();
                          }
                        },
                        onTapUp: (_) {
                          if (state is CameraCapturing) {
                            context.read<CameraBloc>().add(StopCapture());
                          }
                        },
                        onTapCancel: () {
                          if (state is CameraCapturing) {
                            context.read<CameraBloc>().add(StopCapture());
                          }
                        },
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
                          child: state is CameraCapturing
                              ? Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: CircularProgressIndicator(
                                    value: state.progress,
                                    strokeWidth: 3,
                                    backgroundColor: Colors.white24,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      state.motionLevel > 1.0
                                          ? Colors.red
                                          : Colors.white,
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

                      // Bouton Filtres
                      IconButton(
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
                    ],
                  ),
                ),
              ),

              // Indicateur de filtre actif
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

              // Message d'erreur
              if (state is CameraError)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _getFilterName(FilterType filter) {
    switch (filter) {
      case FilterType.monochrome:
        return 'Monochrome';
      case FilterType.sepia:
        return 'Sépia';
      case FilterType.glassPlate:
        return 'Plaque de Verre';
      case FilterType.cyanotype:
        return 'Cyanotype';
      case FilterType.daguerreotype:
        return 'Daguerréotype';
      default:
        return '';
    }
  }
}