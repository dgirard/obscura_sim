import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bloc/camera/camera_bloc.dart';
import 'bloc/filter/filter_bloc.dart';
import 'bloc/gallery/gallery_bloc.dart';
import 'bloc/settings/settings_bloc.dart';
import 'navigation/app_router.dart';
import 'repositories/camera_repository.dart';
import 'repositories/settings_repository.dart';
import 'services/database_service.dart';
import 'services/image_processing_service.dart';
import 'services/audio_service.dart';
import 'theme/obscura_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();

  // Ne pas restreindre les orientations - laisser le système gérer automatiquement
  // Cela permet une rotation libre de l'application

  // Style de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(ObscuraTheme.systemOverlayStyle);

  runApp(ObscuraSimApp(prefs: prefs));
}

class ObscuraSimApp extends StatefulWidget {
  final SharedPreferences prefs;

  const ObscuraSimApp({super.key, required this.prefs});

  @override
  State<ObscuraSimApp> createState() => _ObscuraSimAppState();
}

class _ObscuraSimAppState extends State<ObscuraSimApp> {
  late final SettingsRepository _settingsRepository;
  late final SettingsBloc _settingsBloc;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _settingsRepository = SettingsRepository(widget.prefs);
    _settingsBloc = SettingsBloc(repository: _settingsRepository);
    _appRouter = AppRouter(settingsBloc: _settingsBloc);
  }

  @override
  void dispose() {
    _settingsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => DatabaseService()),
        RepositoryProvider(create: (context) => ImageProcessingService()),
        RepositoryProvider(create: (context) => AudioService()),
        RepositoryProvider<CameraRepository>(create: (context) => CameraRepositoryImpl()),
        RepositoryProvider.value(value: _settingsRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _settingsBloc),
          BlocProvider(
            create: (context) => CameraBloc(
              imageProcessingService: context.read<ImageProcessingService>(),
              cameraRepository: context.read<CameraRepository>(),
              settingsRepository: context.read<SettingsRepository>(),
              audioService: context.read<AudioService>(),
            ),
          ),
          BlocProvider(
            create: (context) => FilterBloc(
              repository: context.read<SettingsRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => GalleryBloc(
              databaseService: context.read<DatabaseService>(),
              imageService: context.read<ImageProcessingService>(),
            ),
          ),
        ],
        child: MaterialApp.router(
          title: 'Obscura',
          debugShowCheckedModeBanner: false,
          theme: ObscuraTheme.dark,
          routerConfig: _appRouter.router,
        ),
      ),
    );
  }
}