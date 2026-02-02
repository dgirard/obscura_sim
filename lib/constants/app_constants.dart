// Constantes centralisées pour l'application Obscura.
// Regroupe les magic numbers dispersés dans le code pour faciliter
// la maintenance et la configuration.

/// Configuration de la capture photo
abstract class CaptureConstants {
  /// Durée de la capture longue (3 secondes)
  static const Duration longCaptureDuration = Duration(milliseconds: 3000);

  /// Intervalle de mise à jour du timer de capture
  static const Duration captureTimerInterval = Duration(milliseconds: 100);

  /// Intervalle de simulation du développement
  static const Duration developmentInterval = Duration(milliseconds: 100);

  /// Incrément de progression du développement (10% par tick)
  static const double developmentProgressIncrement = 0.1;

  /// Délai après capture avant retour à l'état ready
  static const Duration postCaptureDelay = Duration(seconds: 1);
}

/// Configuration du traitement d'image
abstract class ImageProcessingConstants {
  /// Seuil de motion blur au-dessus duquel le flou est appliqué
  static const double motionBlurThreshold = 0.5;

  /// Qualité JPEG pour les images traitées (0-100)
  static const int jpegQuality = 90;

  /// Dimension maximale d'une image (largeur ou hauteur)
  static const int maxImageDimension = 2048;

  /// Largeur des miniatures
  static const int thumbnailWidth = 150;

  /// Qualité JPEG des miniatures
  static const int thumbnailQuality = 70;

  /// Qualité JPEG des images encadrées pour partage
  static const int framedImageQuality = 95;
}

/// Configuration des filtres photographiques
abstract class FilterConstants {
  // Monochrome
  static const double monochromeContrast = 1.3;
  static const double monochromeGrainProbability = 0.1; // 10% des pixels

  // Sepia
  static const double sepiaContrast = 1.1;

  // Glass Plate
  static const double glassPlateContrast = 1.5;
  static const double glassPlateVignetteIntensity = 0.7;

  // Cyanotype
  static const double cyanotypeContrast = 1.2;

  // Daguerreotype
  static const double daguerreotypeContrast = 1.4;
  static const double daguerreotypeBrightness = 1.1;
  static const double daguerreotypeVignetteIntensity = 0.6;
}

/// Configuration de l'interface utilisateur
abstract class UIConstants {
  /// Durée d'affichage de l'indicateur de focus
  static const Duration focusIndicatorDuration = Duration(seconds: 1);

  /// Durée d'affichage des snackbars
  static const Duration snackbarDuration = Duration(seconds: 1);

  /// Durée de l'écran splash
  static const Duration splashDuration = Duration(seconds: 3);

  /// Taille du bouton de capture
  static const double captureButtonSize = 80.0;

  /// Épaisseur de la bordure du bouton de capture
  static const double captureButtonBorderWidth = 4.0;
}

/// Configuration du nettoyage de fichiers
abstract class FileCleanupConstants {
  /// Âge maximum des fichiers temporaires avant suppression
  static const Duration maxTempFileAge = Duration(hours: 24);

  /// Préfixe des fichiers temporaires
  static const String tempFilePrefix = 'obscura_temp_';
}
