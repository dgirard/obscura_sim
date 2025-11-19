import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:obscura_sim/bloc/camera/camera_bloc.dart';
import 'package:obscura_sim/bloc/camera/camera_event.dart';
import 'package:obscura_sim/bloc/camera/camera_state.dart';
import 'package:obscura_sim/models/photo.dart';
import 'package:obscura_sim/repositories/camera_repository.dart';
import 'package:obscura_sim/services/image_processing_service.dart';
import 'package:sensors_plus/sensors_plus.dart';

// Mocks
class MockCameraRepository extends Mock implements CameraRepository {}
class MockImageProcessingService extends Mock implements ImageProcessingService {}
class MockCameraController extends Mock implements CameraController {}
class MockXFile extends Mock implements XFile {}
class MockDirectory extends Mock implements Directory {}

void main() {
  late CameraBloc cameraBloc;
  late MockCameraRepository mockCameraRepository;
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
    
    // Ensure we trigger the flash mode check
    when(() => mockCameraController.value).thenReturn(
      const CameraValue.uninitialized(CameraDescription(
        name: '0', 
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 90
      )).copyWith(
        isInitialized: true,
        flashMode: FlashMode.auto, 
      )
    );

    cameraBloc = CameraBloc(
      cameraRepository: mockCameraRepository,
      imageProcessingService: mockImageProcessingService,
    );
  });

  tearDown(() {
    cameraBloc.close();
  });

  group('CameraBloc', () {
    test('initial state is CameraInitial', () {
      expect(cameraBloc.state, equals(CameraInitial()));
    });

    blocTest<CameraBloc, CameraState>(
      'emits [CameraReady] when InitializeCamera succeeds',
      build: () {
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
        verify(() => mockCameraController.initialize()).called(1);
      },
    );

    blocTest<CameraBloc, CameraState>(
      'emits [CameraError] when InitializeCamera fails',
      build: () {
        when(() => mockCameraRepository.getAvailableCameras())
            .thenThrow(Exception('Camera error'));
        return cameraBloc;
      },
      act: (bloc) => bloc.add(InitializeCamera()),
      expect: () => [isA<CameraError>()],
    );
    
    blocTest<CameraBloc, CameraState>(
      'emits [CameraReady, CameraCaptured, CameraReady] when InstantCapture succeeds (Landscape)',
      build: () {
        // Setup initialization
        final camera = const CameraDescription(
          name: '0',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        );
        when(() => mockCameraRepository.getAvailableCameras())
            .thenAnswer((_) async => [camera]);
        when(() => mockCameraRepository.createController(any(), any(), enableAudio: any(named: 'enableAudio')))
            .thenReturn(mockCameraController);

        // Setup capture
        final mockPhoto = MockXFile();
        when(() => mockPhoto.saveTo(any())).thenAnswer((_) async {});
        when(() => mockCameraController.takePicture())
            .thenAnswer((_) async => mockPhoto);

        return cameraBloc;
      },
      act: (bloc) async {
        bloc.add(InitializeCamera());
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 10)); 
        bloc.add(const InstantCapture(isPortrait: false));
      },
      wait: const Duration(seconds: 2),
      expect: () => [
        isA<CameraReady>(), // From InitializeCamera
        isA<CameraCaptured>().having(
          (state) => state.totalMotion,
          'totalMotion',
          0.0
        ),
        isA<CameraReady>() // From InstantCapture completion
      ],
    );

    blocTest<CameraBloc, CameraState>(
      'emits [CameraReady, CameraCaptured, CameraReady] when InstantCapture succeeds (Portrait with rotation)',
      build: () {
        // Setup initialization
        final camera = const CameraDescription(
          name: '0',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        );
        when(() => mockCameraRepository.getAvailableCameras())
            .thenAnswer((_) async => [camera]);
        when(() => mockCameraRepository.createController(any(), any(), enableAudio: any(named: 'enableAudio')))
            .thenReturn(mockCameraController);

        // Setup capture
        final mockPhoto = MockXFile();
        when(() => mockPhoto.saveTo(any())).thenAnswer((_) async {});
        when(() => mockCameraController.takePicture())
            .thenAnswer((_) async => mockPhoto);

        // Setup image processing
        when(() => mockImageProcessingService.processImage(
          any(), 
          any(), 
          any(), 
          invert: any(named: 'invert'), 
          rotateQuarterTurns: 1
        )).thenAnswer((_) async => '/test/path/rotated.jpg');

        return cameraBloc;
      },
      act: (bloc) async {
        bloc.add(InitializeCamera());
        await Future.delayed(const Duration(milliseconds: 10));
        bloc.add(const InstantCapture(isPortrait: true));
      },
      wait: const Duration(seconds: 2),
      expect: () => [
        isA<CameraReady>(),
        isA<CameraCaptured>().having(
            (state) => state.imagePath,
            'imagePath',
            '/test/path/rotated.jpg'
        ),
        isA<CameraReady>()
      ],
      verify: (_) {
        verify(() => mockImageProcessingService.processImage(
          any(), 
          FilterType.none, 
          0, 
          rotateQuarterTurns: 1
        )).called(1);
      },
    );
  });
}
