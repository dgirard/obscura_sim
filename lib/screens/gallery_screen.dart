import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/gallery/gallery_bloc.dart';
import '../models/photo.dart';
import 'photo_detail_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GalleryBloc>().add(LoadPhotos());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          title: const Text(
            'La Chambre Noire',
            style: TextStyle(
              color: Colors.red,
              fontSize: 20,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.2,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.red,
            indicatorWeight: 1,
            labelColor: Colors.red,
            unselectedLabelColor: Colors.white38,
            tabs: [
              Tab(text: 'Négatifs'),
              Tab(text: 'Développées'),
            ],
          ),
        ),
        body: BlocBuilder<GalleryBloc, GalleryState>(
          builder: (context, state) {
            if (state is GalleryLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.red,
                ),
              );
            }

            if (state is GalleryError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              );
            }

            if (state is GalleryLoaded) {
              return TabBarView(
                children: [
                  // Tab Négatifs
                  _buildPhotoGrid(
                    context,
                    state.negatives,
                    isNegative: true,
                  ),
                  // Tab Développées
                  _buildPhotoGrid(
                    context,
                    state.developed,
                    isNegative: false,
                  ),
                ],
              );
            }

            return const Center(
              child: Text(
                'Aucune photo',
                style: TextStyle(color: Colors.white38),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(
    BuildContext context,
    List<Photo> photos,
    {required bool isNegative}
  ) {
    if (photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNegative ? Icons.camera_alt : Icons.photo,
              color: Colors.white24,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              isNegative
                  ? 'Aucun négatif\nPrenez des photos pour commencer'
                  : 'Aucune photo développée\nDéveloppez vos négatifs',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Adapter le nombre de colonnes selon l'orientation
    return OrientationBuilder(
      builder: (context, orientation) {
        final int crossAxisCount = orientation == Orientation.portrait ? 3 : 5;

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1,
          ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PhotoDetailScreen(photo: photo),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isNegative ? Colors.red.withOpacity(0.3) : Colors.white12,
                width: 1,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image inversée pour les négatifs avec détection d'orientation
                Transform(
                  alignment: Alignment.center,
                  transform: isNegative
                      ? (Matrix4.identity()
                        ..rotateX(3.14159)
                        ..rotateY(3.14159))
                      : Matrix4.identity(),
                  child: RotatedBox(
                    quarterTurns: photo.isPortrait ? 1 : 0,  // Rotate 90° if portrait
                    child: photo.thumbnailData != null
                        ? Image.memory(
                            photo.thumbnailData!,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(photo.path),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.black26,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.white24,
                                ),
                              );
                            },
                          ),
                  ),
                ),
                // Overlay pour les négatifs
                if (isNegative)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.red.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                // Badge de filtre
                if (photo.filter != FilterType.none)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        _getFilterIcon(photo.filter),
                        size: 16,
                        color: Colors.white54,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
      },
    );
  }


  IconData _getFilterIcon(FilterType filter) {
    switch (filter) {
      case FilterType.monochrome:
        return Icons.filter_b_and_w;
      case FilterType.sepia:
        return Icons.gradient;
      case FilterType.glassPlate:
        return Icons.lens;
      default:
        return Icons.filter_none;
    }
  }
}