import 'package:bloc_test/bloc_test.dart';
import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:obscura_sim/bloc/camera/camera_bloc.dart';
import 'package:obscura_sim/bloc/camera/camera_event.dart';
import 'package:obscura_sim/bloc/camera/camera_state.dart';
import 'package:obscura_sim/models/photo.dart';
import 'package:obscura_sim/repositories/camera_repository.dart';
import 'package:obscura_sim/repositories/settings_repository.dart';
import 'package:obscura_sim/services/audio_service.dart';
import 'package:obscura_sim/services/image_processing_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

// Mocks
class MockCameraRepository extends Mock implements CameraRepository {}
class MockSettingsRepository extends Mock implements SettingsRepository {}
class MockAudioService extends Mock implements AudioService {}
class MockImageProcessingService extends Mock implements ImageProcessingService {}
class MockCameraController extends Mock implements CameraController {}
class MockXFile extends Mock implements XFile {}
class MockDirectory extends Mock implements Directory {}

void main() {
  late CameraBloc cameraBloc;
  late MockCameraRepository mockCameraRepository;
  late MockSettingsRepository mockSettingsRepository;
  late MockAudioService mockAudioService;
  late MockImageProcessingService mockImageProcessingService;
  late MockCameraController mockCameraController;
  late MockDirectory mockDirectory;

  setUpAll(() {
    registerFallbackValue(FilterType.none);
    registerFallbackValue(const CameraDescription(
      name: '0',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    ));
    registerFallbackValue(ResolutionPreset.medium);
    registerFallbackValue(FlashMode.off);
  });

  setUp(() {
    mockCameraRepository = MockCameraRepository();
    mockSettingsRepository = MockSettingsRepository();
    mockAudioService = MockAudioService();
    mockImageProcessingService = MockImageProcessingService();
    mockCameraController = MockCameraController();
    mockDirectory = MockDirectory();

    // Setup default behaviors
    when(() => mockCameraRepository.getDocumentsDirectory())
        .thenAnswer((_) async => mockDirectory);
    when(() => mockDirectory.path).thenReturn('/test/path');
    
    when(() => mockCameraController.initialize()).thenAnswer((_) async {});
    when(() => mockCameraController.setFlashMode(any())).thenAnswer((_) async {});
    when(() => mockCameraController.dispose()).thenAnswer((_) async {});
    when(() => mockCameraController.value).thenReturn(
      const CameraValue.uninitialized(CameraDescription(
        name: '0', 
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 90
      )).copyWith(isInitialized: true)
    );

    when(() => mockSettingsRepository.imageQuality).thenReturn(ResolutionPreset.high);

    cameraBloc = CameraBloc(
      cameraRepository: mockCameraRepository,
      imageProcessingService: mockImageProcessingService,
      settingsRepository: mockSettingsRepository,
      audioService: mockAudioService,
    );
  });

  tearDown(() {
    cameraBloc.close();
  });

  group('CameraBloc Permissions', () {
    blocTest<CameraBloc, CameraState>(
      'emits [CameraPermissionDenied] when requestCameraPermission returns denied',
      build: () {
        when(() => mockCameraRepository.requestCameraPermission())
            .thenAnswer((_) async => PermissionStatus.denied);
        return cameraBloc;
      },
      act: (bloc) => bloc.add(InitializeCamera()),
      expect: () => [isA<CameraPermissionDenied>()],
      verify: (_) {
        verifyNever(() => mockCameraRepository.getAvailableCameras());
      },
    );

    blocTest<CameraBloc, CameraState>(
      'emits [CameraReady] when requestCameraPermission returns granted',
      build: () {
        when(() => mockCameraRepository.requestCameraPermission())
            .thenAnswer((_) async => PermissionStatus.granted);
        
        final camera = const CameraDescription(
          name: '0',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        );
        when(() => mockCameraRepository.getAvailableCameras())
            .thenAnswer((_) async => [camera]);
            
        when(() => mockCameraRepository.createController(any(), any(), enableAudio: any(named: 'enableAudio')))
            .thenReturn(mockCameraController);

        return cameraBloc;
      },
      act: (bloc) => bloc.add(InitializeCamera()),
      expect: () => [isA<CameraReady>()],
      verify: (_) {
        verify(() => mockCameraRepository.requestCameraPermission()).called(1);
        verify(() => mockCameraRepository.getAvailableCameras()).called(1);
      },
    );
  });
}