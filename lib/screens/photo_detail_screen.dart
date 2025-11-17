import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/gallery/gallery_bloc.dart';
import '../models/photo.dart';

class PhotoDetailScreen extends StatelessWidget {
  final Photo photo;

  const PhotoDetailScreen({
    super.key,
    required this.photo,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNegative = photo.status == PhotoStatus.negative;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image principale
          Center(
            child: Transform(
              alignment: Alignment.center,
              transform: isNegative
                  ? (Matrix4.identity()
                    ..rotateX(3.14159)
                    ..rotateY(3.14159))
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
                        onTap: () => _showDeleteConfirmation(context),
                      ),

                      // Bouton Développer (seulement pour les négatifs)
                      if (isNegative)
                        _buildActionButton(
                          icon: Icons.developer_mode,
                          label: 'Développer',
                          color: Colors.amber,
                          isPrimary: true,
                          onTap: () => _developPhoto(context),
                        ),

                      // Bouton Partager (seulement pour les photos développées)
                      if (!isNegative)
                        _buildActionButton(
                          icon: Icons.share_outlined,
                          label: 'Partager',
                          color: Colors.blue,
                          onTap: () => _sharePhoto(context),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

  void _developPhoto(BuildContext context) {
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
              Navigator.pop(context);

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

  void _showDeleteConfirmation(BuildContext context) {
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
              Navigator.pop(context);
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

  void _sharePhoto(BuildContext context) {
    // Implémentation du partage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonction de partage à implémenter'),
        duration: Duration(seconds: 2),
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
      default:
        return '';
    }
  }
}