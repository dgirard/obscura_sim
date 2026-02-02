import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/settings/settings_bloc.dart';
import '../models/photo.dart';
import '../screens/simple_viewfinder_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/gallery_screen.dart';
import '../screens/photo_detail_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/filter_selection_screen.dart';

/// Routes de l'application
abstract class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String camera = '/camera';
  static const String gallery = '/gallery';
  static const String photoDetail = '/photo-detail';
  static const String settings = '/settings';
  static const String filterSelection = '/filter-selection';
}

/// Configuration du routeur go_router
class AppRouter {
  final SettingsBloc settingsBloc;

  AppRouter({required this.settingsBloc});

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Camera (Main Screen)
      GoRoute(
        path: AppRoutes.camera,
        builder: (context, state) => const SimpleViewfinderScreen(),
      ),

      // Gallery
      GoRoute(
        path: AppRoutes.gallery,
        builder: (context, state) => const GalleryScreen(),
      ),

      // Photo Detail
      GoRoute(
        path: AppRoutes.photoDetail,
        builder: (context, state) {
          final extra = state.extra as PhotoDetailParams;
          return PhotoDetailScreen(
            photos: extra.photos,
            initialIndex: extra.initialIndex,
          );
        },
      ),

      // Settings
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),

      // Filter Selection
      GoRoute(
        path: AppRoutes.filterSelection,
        builder: (context, state) => const FilterSelectionScreen(),
      ),
    ],

    // Redirect logic
    redirect: (context, state) {
      // Si on est sur splash et que l'animation est terminée,
      // rediriger vers onboarding ou camera selon l'état
      // Note: La redirection depuis splash est gérée par le SplashScreen lui-même
      return null;
    },
  );
}

/// Paramètres pour PhotoDetailScreen
class PhotoDetailParams {
  final List<Photo> photos;
  final int initialIndex;

  const PhotoDetailParams({
    required this.photos,
    required this.initialIndex,
  });
}

/// SplashScreen avec navigation go_router
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _controller.forward();

    // Navigation vers l'écran principal après l'animation
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final settingsBloc = context.read<SettingsBloc>();
        final isOnboardingCompleted = settingsBloc.state.isOnboardingCompleted;

        if (isOnboardingCompleted) {
          context.go(AppRoutes.camera);
        } else {
          context.go(AppRoutes.onboarding);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey[700]!,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 60,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'OBSCURASIM',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 6,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Camera Obscura',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Extension pour faciliter la navigation avec go_router
extension NavigationExtension on BuildContext {
  /// Navigue vers la galerie
  void goToGallery() => go(AppRoutes.gallery);

  /// Navigue vers les paramètres
  void goToSettings() => go(AppRoutes.settings);

  /// Navigue vers la caméra
  void goToCamera() => go(AppRoutes.camera);

  /// Navigue vers le détail d'une photo
  void goToPhotoDetail(List<Photo> photos, int initialIndex) {
    go(
      AppRoutes.photoDetail,
      extra: PhotoDetailParams(photos: photos, initialIndex: initialIndex),
    );
  }

  /// Navigue vers la sélection de filtre
  void goToFilterSelection() => go(AppRoutes.filterSelection);
}
