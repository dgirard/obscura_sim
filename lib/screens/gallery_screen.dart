import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/gallery/gallery_bloc.dart';
import '../models/photo.dart';
import '../navigation/app_router.dart';
import '../theme/colors.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _negativesScrollController = ScrollController();
  final ScrollController _developedScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<GalleryBloc>().add(LoadPhotos());

    // Listener pour charger plus de négatifs
    _negativesScrollController.addListener(() {
      if (_negativesScrollController.position.pixels >=
          _negativesScrollController.position.maxScrollExtent - 200) {
        context.read<GalleryBloc>().add(const LoadMorePhotos(PhotoStatus.negative));
      }
    });

    // Listener pour charger plus de développées
    _developedScrollController.addListener(() {
      if (_developedScrollController.position.pixels >=
          _developedScrollController.position.maxScrollExtent - 200) {
        context.read<GalleryBloc>().add(const LoadMorePhotos(PhotoStatus.developed));
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _negativesScrollController.dispose();
    _developedScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ObscuraColors.backgroundElevated,
      appBar: AppBar(
        backgroundColor: ObscuraColors.surface,
        elevation: 0,
        title: const Text(
          'La Chambre Noire',
          style: TextStyle(
            color: ObscuraColors.negative,
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ObscuraColors.textSecondary),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ObscuraColors.negative,
          indicatorWeight: 1,
          labelColor: ObscuraColors.negative,
          unselectedLabelColor: ObscuraColors.textDisabled,
          tabs: const [
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
                color: ObscuraColors.negative,
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
                    color: ObscuraColors.negative,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: ObscuraColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          if (state is GalleryLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                // Tab Négatifs
                _buildPhotoGrid(
                  context,
                  state.negatives,
                  isNegative: true,
                  scrollController: _negativesScrollController,
                  hasMore: state.hasMoreNegatives,
                  isLoadingMore: state.isLoadingMore,
                ),
                // Tab Développées
                _buildPhotoGrid(
                  context,
                  state.developed,
                  isNegative: false,
                  scrollController: _developedScrollController,
                  hasMore: state.hasMoreDeveloped,
                  isLoadingMore: state.isLoadingMore,
                ),
              ],
            );
          }

          return const Center(
            child: Text(
              'Aucune photo',
              style: TextStyle(color: ObscuraColors.textDisabled),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoGrid(
    BuildContext context,
    List<Photo> photos,
    {required bool isNegative,
    required ScrollController scrollController,
    required bool hasMore,
    required bool isLoadingMore}
  ) {
    if (photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNegative ? Icons.camera_alt : Icons.photo,
              color: ObscuraColors.textSubtle,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              isNegative
                  ? 'Aucun négatif\nPrenez des photos pour commencer'
                  : 'Aucune photo développée\nDéveloppez vos négatifs',
              style: const TextStyle(
                color: ObscuraColors.textDisabled,
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
        // +1 pour l'indicateur de chargement si nécessaire
        final int itemCount = photos.length + (hasMore ? 1 : 0);

        return GridView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            // Indicateur de chargement à la fin
            if (index >= photos.length) {
              return Center(
                child: isLoadingMore
                    ? const CircularProgressIndicator(
                        color: ObscuraColors.negative,
                        strokeWidth: 2,
                      )
                    : const SizedBox.shrink(),
              );
            }

            final photo = photos[index];
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                context.push(
                  AppRoutes.photoDetail,
                  extra: PhotoDetailParams(photos: photos, initialIndex: index),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isNegative ? ObscuraColors.negativeOverlay : ObscuraColors.textFaint,
                    width: 1,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image inversée pour les négatifs (effet visuel uniquement)
                    Transform(
                      alignment: Alignment.center,
                      transform: isNegative
                          ? (Matrix4.identity()..rotateZ(3.14159)) // Rotation 180° standard
                          : Matrix4.identity(),
                      child: Image(
                        image: ResizeImage(
                          FileImage(File(photo.path)),
                          width: 200, // Optimize for grid
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: ObscuraColors.overlayLight,
                            child: const Icon(
                              Icons.broken_image,
                              color: ObscuraColors.textSubtle,
                            ),
                          );
                        },
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
                              ObscuraColors.negative.withValues(alpha: 0.1),
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
                            color: ObscuraColors.overlayMedium,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            _getFilterIcon(photo.filter),
                            size: 16,
                            color: ObscuraColors.textHint,
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
      case FilterType.cyanotype:
        return Icons.water_drop;
      case FilterType.daguerreotype:
        return Icons.brightness_high;
      default:
        return Icons.filter_none;
    }
  }
}
