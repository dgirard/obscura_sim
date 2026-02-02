import 'package:flutter/material.dart';

/// Palette de couleurs centralisée pour l'application Obscura.
///
/// Toutes les couleurs de l'application doivent être référencées ici
/// pour garantir la cohérence visuelle et faciliter les changements.
abstract class ObscuraColors {
  // ============================================
  // BACKGROUNDS - Hiérarchie de surfaces sombres
  // ============================================

  /// Fond principal (noir pur)
  static const Color background = Colors.black;

  /// Surface légèrement élevée
  static const Color backgroundElevated = Color(0xFF0D0D0D);

  /// Surface de carte/dialog
  static const Color surface = Color(0xFF1A1A1A);

  /// Surface avec plus d'élévation
  static const Color surfaceVariant = Color(0xFF2A2A2A);

  // ============================================
  // ACCENT PRIMAIRE - Ambre/Or (interactions)
  // ============================================

  /// Couleur d'accent primaire
  static const Color primary = Colors.amber;

  /// Variante plus claire de l'accent
  static const Color primaryLight = Color(0xFFFFD54F);

  /// Variante plus sombre de l'accent
  static const Color primaryDark = Color(0xFFFF8F00);

  // ============================================
  // COULEURS SÉMANTIQUES
  // ============================================

  /// Erreur / Danger / Suppression
  static const Color error = Colors.red;

  /// Succès
  static const Color success = Colors.green;

  /// Avertissement
  static const Color warning = Colors.orange;

  /// Information
  static const Color info = Colors.blue;

  /// Partage
  static const Color share = Colors.blue;

  /// Couleur des négatifs (photos non développées)
  static const Color negative = Colors.red;

  // ============================================
  // TEXTES - Hiérarchie de lisibilité
  // ============================================

  /// Texte principal (haute importance)
  static const Color textPrimary = Colors.white;

  /// Texte secondaire (importance moyenne)
  static const Color textSecondary = Colors.white70;

  /// Texte tertiaire (labels, sous-titres)
  static const Color textTertiary = Colors.white60;

  /// Texte désactivé / hint
  static const Color textHint = Colors.white54;

  /// Texte très discret
  static const Color textDisabled = Colors.white38;

  /// Séparateurs et bordures subtiles
  static const Color textSubtle = Colors.white24;

  /// Éléments à peine visibles
  static const Color textFaint = Colors.white12;

  /// Éléments très faibles
  static const Color textGhost = Colors.white10;

  // ============================================
  // OVERLAYS - Superpositions semi-transparentes
  // ============================================

  /// Overlay léger
  static const Color overlayLight = Colors.black26;

  /// Overlay moyen
  static const Color overlayMedium = Colors.black54;

  /// Overlay dense
  static const Color overlayDark = Colors.black87;

  /// Overlay pour le motion warning
  static Color get motionWarningOverlay => Colors.red.withValues(alpha: 0.7);

  /// Overlay pour les négatifs
  static Color get negativeOverlay => Colors.red.withValues(alpha: 0.3);

  // ============================================
  // COULEURS DES FILTRES PHOTOGRAPHIQUES
  // ============================================

  /// Aucun filtre
  static const Color filterNone = Colors.grey;

  /// Monochrome
  static const Color filterMonochrome = Colors.blueGrey;

  /// Sépia
  static const Color filterSepia = Colors.brown;

  /// Glass Plate
  static const Color filterGlassPlate = Colors.indigo;

  /// Cyanotype
  static const Color filterCyanotype = Colors.cyan;

  /// Daguerréotype
  static const Color filterDaguerreotype = Colors.amber;

  // ============================================
  // UI SPÉCIFIQUE
  // ============================================

  /// Bordure du bouton de capture
  static const Color captureButtonBorder = Colors.white;

  /// Indicateur de focus
  static const Color focusIndicator = Colors.amber;

  /// Barre de progression
  static const Color progressIndicator = Colors.white24;

  /// Indicateur de flash actif
  static const Color flashActive = Colors.amber;

  /// Indicateur de flash inactif
  static const Color flashInactive = Colors.white38;
}
