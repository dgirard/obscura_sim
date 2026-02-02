import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';

/// Configuration du thème Obscura.
///
/// Fournit un thème sombre cohérent pour toute l'application,
/// inspiré de l'esthétique de la chambre noire photographique.
abstract class ObscuraTheme {
  /// Thème sombre principal de l'application
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        // Couleurs de base
        primaryColor: ObscuraColors.primary,
        scaffoldBackgroundColor: ObscuraColors.background,

        // Schéma de couleurs
        colorScheme: const ColorScheme.dark(
          primary: ObscuraColors.primary,
          secondary: ObscuraColors.primary,
          surface: ObscuraColors.surface,
          error: ObscuraColors.error,
          onPrimary: ObscuraColors.background,
          onSecondary: ObscuraColors.background,
          onSurface: ObscuraColors.textPrimary,
          onError: ObscuraColors.textPrimary,
        ),

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: ObscuraColors.background,
          foregroundColor: ObscuraColors.textSecondary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: ObscuraColors.textSecondary,
            fontSize: 18,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
          ),
          iconTheme: IconThemeData(
            color: ObscuraColors.textSecondary,
          ),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: ObscuraColors.background,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
        ),

        // Textes
        textTheme: const TextTheme(
          // Titres
          displayLarge: TextStyle(
            color: ObscuraColors.textPrimary,
            fontWeight: FontWeight.w200,
            letterSpacing: 6,
          ),
          displayMedium: TextStyle(
            color: ObscuraColors.textPrimary,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
          headlineLarge: TextStyle(
            color: ObscuraColors.textPrimary,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
          ),
          headlineMedium: TextStyle(
            color: ObscuraColors.textPrimary,
            fontWeight: FontWeight.w300,
          ),
          titleLarge: TextStyle(
            color: ObscuraColors.textPrimary,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
          ),
          titleMedium: TextStyle(
            color: ObscuraColors.textPrimary,
            fontWeight: FontWeight.w400,
          ),
          // Corps de texte
          bodyLarge: TextStyle(
            color: ObscuraColors.textSecondary,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: ObscuraColors.textSecondary,
            fontSize: 14,
          ),
          bodySmall: TextStyle(
            color: ObscuraColors.textTertiary,
            fontSize: 12,
          ),
          // Labels
          labelLarge: TextStyle(
            color: ObscuraColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          labelMedium: TextStyle(
            color: ObscuraColors.textHint,
          ),
          labelSmall: TextStyle(
            color: ObscuraColors.textDisabled,
          ),
        ),

        // Boutons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: ObscuraColors.primary,
            foregroundColor: ObscuraColors.background,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: ObscuraColors.primary,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: ObscuraColors.textSecondary,
            side: const BorderSide(color: ObscuraColors.textSubtle),
          ),
        ),

        // Inputs
        inputDecorationTheme: InputDecorationTheme(
          fillColor: ObscuraColors.surface,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: ObscuraColors.textHint),
        ),

        // Sliders
        sliderTheme: const SliderThemeData(
          activeTrackColor: ObscuraColors.primary,
          inactiveTrackColor: ObscuraColors.textSubtle,
          thumbColor: ObscuraColors.primary,
          overlayColor: Colors.transparent,
          trackHeight: 2,
        ),

        // Switch
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return ObscuraColors.primary;
            }
            return ObscuraColors.textDisabled;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return ObscuraColors.primary.withValues(alpha: 0.5);
            }
            return ObscuraColors.textSubtle;
          }),
        ),

        // Progress indicators
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: ObscuraColors.primary,
          circularTrackColor: ObscuraColors.progressIndicator,
        ),

        // TabBar
        tabBarTheme: const TabBarThemeData(
          labelColor: ObscuraColors.negative,
          unselectedLabelColor: ObscuraColors.textDisabled,
          indicatorColor: ObscuraColors.negative,
          dividerColor: Colors.transparent,
        ),

        // Dividers
        dividerTheme: const DividerThemeData(
          color: ObscuraColors.textFaint,
          thickness: 1,
        ),

        // Dialogs
        dialogTheme: const DialogThemeData(
          backgroundColor: ObscuraColors.surface,
          titleTextStyle: TextStyle(
            color: ObscuraColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          contentTextStyle: TextStyle(
            color: ObscuraColors.textSecondary,
          ),
        ),

        // BottomSheet
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: ObscuraColors.surface,
          modalBackgroundColor: ObscuraColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ),

        // SnackBar
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: ObscuraColors.surface,
          contentTextStyle: TextStyle(color: ObscuraColors.textPrimary),
          behavior: SnackBarBehavior.floating,
        ),

        // ListTile
        listTileTheme: const ListTileThemeData(
          iconColor: ObscuraColors.textSecondary,
          textColor: ObscuraColors.textPrimary,
        ),

        // Icons
        iconTheme: const IconThemeData(
          color: ObscuraColors.textSecondary,
        ),

        // Dropdown
        dropdownMenuTheme: const DropdownMenuThemeData(
          menuStyle: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(ObscuraColors.surface),
          ),
        ),
      );

  /// Style de la barre de statut système
  static const SystemUiOverlayStyle systemOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: ObscuraColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  );
}
