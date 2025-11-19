import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bloc/camera/camera_bloc.dart';
import 'bloc/filter/filter_bloc.dart';
import 'bloc/gallery/gallery_bloc.dart';
import 'repositories/camera_repository.dart';
import 'screens/viewfinder_screen.dart';
import 'screens/simple_viewfinder_screen.dart';
import 'services/database_service.dart';
import 'services/image_processing_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ne pas restreindre les orientations - laisser le système gérer automatiquement
  // Cela permet une rotation libre de l'application

  // Style de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ObscuraSimApp());
}

class ObscuraSimApp extends StatelessWidget {
  const ObscuraSimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => DatabaseService()),
        RepositoryProvider(create: (context) => ImageProcessingService()),
        RepositoryProvider<CameraRepository>(create: (context) => CameraRepositoryImpl()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => CameraBloc(
              imageProcessingService: context.read<ImageProcessingService>(),
              cameraRepository: context.read<CameraRepository>(),
            ),
          ),
          BlocProvider(create: (context) => FilterBloc()),
          BlocProvider(
            create: (context) => GalleryBloc(
              databaseService: context.read<DatabaseService>(),
              imageService: context.read<ImageProcessingService>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'ObscuraSim',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Colors.black,
            scaffoldBackgroundColor: Colors.black,
            fontFamily: GoogleFonts.sourceCodePro().fontFamily,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              elevation: 0,
              titleTextStyle: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.2,
              ),
              iconTheme: IconThemeData(
                color: Colors.white70,
              ),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white70),
              bodyMedium: TextStyle(color: Colors.white70),
              titleLarge: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.2,
              ),
            ),
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

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
  Timer? _navigationTimer;

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
    _navigationTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SimpleViewfinderScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _navigationTimer?.cancel();
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
                          color: Colors.white24,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 60,
                        color: Colors.white24,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'OBSCURASIM',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 24,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 6,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Camera Obscura',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                        color: Colors.white38,
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