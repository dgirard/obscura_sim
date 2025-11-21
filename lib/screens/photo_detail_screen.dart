import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import '../bloc/gallery/gallery_bloc.dart';
import '../models/photo.dart';
import '../services/image_processing_service.dart';

class PhotoDetailScreen extends StatefulWidget {
  final List<Photo> photos;
  final int initialIndex;

  const PhotoDetailScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure we don't go out of bounds if list is empty (shouldn't happen if accessed correctly)
    if (widget.photos.isEmpty) return const SizedBox.shrink();
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return _buildPhotoItem(widget.photos[index]);
        },
      ),
    );
  }

  Widget _buildPhotoItem(Photo photo) {
    final bool isNegative = photo.status == PhotoStatus.negative;

    return Stack(
      children: [
        // Image principale
        Center(
          child: Transform(
            alignment: Alignment.center,
            // Rotation 180° uniquement pour l'effet "Négatif/Obscura"
            transform: isNegative
                ? (Matrix4.identity()
                  ..rotateZ(3.14159)) // RotateZ est plus standard pour une rotation 2D
                : Matrix4.identity(),
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(
                File(photo.path),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white24,
                        size: 64,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // Overlay gradient en haut
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black87,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Bouton retour
        Positioned(
          top: 40,
          left: 16,
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white70,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        // Titre
        Positioned(
          top: 50,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              isNegative ? 'Négatif' : 'Photo Développée',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),

        // Informations et actions en bas
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black,
                  Colors.black87,
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Informations de la photo
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (photo.filter != FilterType.none) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getFilterName(photo.filter),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (photo.motionBlur != null && photo.motionBlur! > 0.5)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.blur_on,
                              size: 14,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Flou de mouvement',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // Boutons d'action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Bouton Supprimer
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      label: 'Supprimer',
                      color: Colors.red,
                      onTap: () => _showDeleteConfirmation(context, photo),
                    ),

                    // Bouton Développer (seulement pour les négatifs)
                    if (isNegative)
                      _buildActionButton(
                        icon: Icons.developer_mode,
                        label: 'Développer',
                        color: Colors.amber,
                        isPrimary: true,
                        onTap: () => _developPhoto(context, photo),
                      ),

                    // Bouton Partager (seulement pour les photos développées)
                    if (!isNegative)
                      _buildActionButton(
                        icon: Icons.share_outlined,
                        label: 'Partager',
                        color: Colors.blue,
                        onTap: () => _sharePhoto(context, photo),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isPrimary ? color : color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: color,
            width: isPrimary ? 0 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.black : color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.black : color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _developPhoto(BuildContext context, Photo photo) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Développer le Négatif',
          style: TextStyle(
            color: Colors.amber,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Cette photo va être développée et redressée.\n\nLe processus simule le développement chimique d\'une plaque photographique.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<GalleryBloc>().add(DevelopPhoto(photo));
              Navigator.pop(dialogContext);
              Navigator.pop(context); // Pop detail screen as the photo status changed

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Photo en cours de développement...'),
                  backgroundColor: Colors.amber,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
            ),
            child: const Text(
              'Développer',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Photo photo) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Supprimer la Photo',
          style: TextStyle(
            color: Colors.red,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Cette action est irréversible.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<GalleryBloc>().add(DeletePhoto(photo));
              Navigator.pop(dialogContext);
              Navigator.pop(context); // Pop detail screen on delete
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePhoto(BuildContext context, Photo photo) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: Colors.white),
                title: const Text('Partager l\'original', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _performShare(context, photo.path, photo);
                },
              ),
              ListTile(
                leading: const Icon(Icons.crop_free, color: Colors.amber),
                title: const Text('Partager avec cadre (Polaroid)', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Ajoute la date et le filtre utilisé', style: TextStyle(color: Colors.white54)),
                onTap: () {
                  Navigator.pop(context);
                  _generateAndShareFramed(context, photo);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generateAndShareFramed(BuildContext context, Photo photo) async {
    // Show loading
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Génération du cadre...'), duration: Duration(seconds: 1)),
    );

    try {
      final dateStr = "${photo.timestamp.day}/${photo.timestamp.month}/${photo.timestamp.year}";
      final filterName = _getFilterName(photo.filter);
      final title = "OBSCURA - $dateStr";
      
      final processingService = context.read<ImageProcessingService>();
      final framedPath = await processingService.generateFramedImage(
        photo.path,
        title,
        filterName.isEmpty ? "Sans Filtre" : filterName,
      );

      if (context.mounted) {
        _performShare(context, framedPath, photo);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _performShare(BuildContext context, String filePath, Photo photo) async {
    const platform = MethodChannel('com.obscurasim.app/mediastore');

    try {
      final file = File(filePath);

      if (!await file.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de partager: fichier introuvable'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Sauvegarder dans la galerie publique (MediaStore) comme Google Photos
      // Cela permet à Flickr d'accéder à l'image
      final String fileName = 'obscura_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final String? contentUri = await platform.invokeMethod('saveToMediaStore', {
        'filePath': filePath,
        'displayName': fileName,
      });

      if (contentUri == null || contentUri.isEmpty) {
        throw Exception('Échec de la sauvegarde dans la galerie');
      }

      // Utiliser l'Intent Android natif pour partager (comme la galerie système)
      await platform.invokeMethod('shareWithNativeIntent', {
        'contentUri': contentUri,
        'text': 'Photo Obscura${photo.filter != FilterType.none ? ' - ${_getFilterName(photo.filter)}' : ''}',
        'subject': 'Ma photo ObscuraSim',
      });

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
      case FilterType.cyanotype:
        return 'Cyanotype';
      case FilterType.daguerreotype:
        return 'Daguerréotype';
      default:
        return '';
    }
  }
}