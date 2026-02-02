import 'dart:typed_data';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:obscura_sim/bloc/gallery/gallery_bloc.dart';
import 'package:obscura_sim/models/photo.dart';
import 'package:obscura_sim/services/database_service.dart';
import 'package:obscura_sim/services/image_processing_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockImageProcessingService extends Mock implements ImageProcessingService {}

void main() {
  late MockDatabaseService mockDatabaseService;
  late MockImageProcessingService mockImageService;

  final testNegativePhoto = Photo(
    id: 1,
    path: '/test/negative.jpg',
    timestamp: DateTime(2024, 1, 1),
    filter: FilterType.monochrome,
    status: PhotoStatus.negative,
    motionBlur: 0.1,
    isPortrait: true,
  );

  final testDevelopedPhoto = Photo(
    id: 2,
    path: '/test/developed.jpg',
    timestamp: DateTime(2024, 1, 2),
    filter: FilterType.sepia,
    status: PhotoStatus.developed,
    motionBlur: 0.0,
    isPortrait: false,
  );

  setUpAll(() {
    registerFallbackValue(FilterType.none);
    registerFallbackValue(testNegativePhoto);
  });

  setUp(() {
    mockDatabaseService = MockDatabaseService();
    mockImageService = MockImageProcessingService();

    // Default setup
    when(() => mockDatabaseService.getAllPhotos()).thenAnswer((_) async => []);
    when(() => mockDatabaseService.insertPhoto(any())).thenAnswer((_) async {});
    when(() => mockDatabaseService.updatePhoto(any())).thenAnswer((_) async {});
    when(() => mockDatabaseService.deletePhoto(any())).thenAnswer((_) async {});
    when(() => mockImageService.processImage(any(), any(), any(),
            invert: any(named: 'invert'), rotateQuarterTurns: any(named: 'rotateQuarterTurns')))
        .thenAnswer((_) async => '/test/processed.jpg');
    when(() => mockImageService.createThumbnail(any())).thenAnswer((_) async => Uint8List(0));
  });

  group('GalleryBloc', () {
    test('initial state is GalleryInitial', () {
      final bloc = GalleryBloc(
        databaseService: mockDatabaseService,
        imageService: mockImageService,
      );
      expect(bloc.state, isA<GalleryInitial>());
      bloc.close();
    });

    blocTest<GalleryBloc, GalleryState>(
      'emits [GalleryLoading, GalleryLoaded] when LoadPhotos succeeds with empty list',
      build: () => GalleryBloc(
        databaseService: mockDatabaseService,
        imageService: mockImageService,
      ),
      act: (bloc) => bloc.add(LoadPhotos()),
      expect: () => [
        isA<GalleryLoading>(),
        isA<GalleryLoaded>().having(
          (state) => state.negatives,
          'negatives',
          isEmpty,
        ).having(
          (state) => state.developed,
          'developed',
          isEmpty,
        ),
      ],
    );

    blocTest<GalleryBloc, GalleryState>(
      'emits [GalleryLoading, GalleryLoaded] with separated photos when LoadPhotos succeeds',
      setUp: () {
        when(() => mockDatabaseService.getAllPhotos())
            .thenAnswer((_) async => [testNegativePhoto, testDevelopedPhoto]);
      },
      build: () => GalleryBloc(
        databaseService: mockDatabaseService,
        imageService: mockImageService,
      ),
      act: (bloc) => bloc.add(LoadPhotos()),
      expect: () => [
        isA<GalleryLoading>(),
        isA<GalleryLoaded>().having(
          (state) => state.negatives.length,
          'negatives count',
          1,
        ).having(
          (state) => state.developed.length,
          'developed count',
          1,
        ),
      ],
    );

    blocTest<GalleryBloc, GalleryState>(
      'emits [GalleryLoading, GalleryError] when LoadPhotos fails',
      setUp: () {
        when(() => mockDatabaseService.getAllPhotos())
            .thenThrow(Exception('Database error'));
      },
      build: () => GalleryBloc(
        databaseService: mockDatabaseService,
        imageService: mockImageService,
      ),
      act: (bloc) => bloc.add(LoadPhotos()),
      expect: () => [
        isA<GalleryLoading>(),
        isA<GalleryError>().having(
          (state) => state.message,
          'message',
          contains('Database error'),
        ),
      ],
    );

    blocTest<GalleryBloc, GalleryState>(
      'emits GalleryError when AddPhoto fails',
      setUp: () {
        when(() => mockImageService.processImage(any(), any(), any(),
                invert: any(named: 'invert'), rotateQuarterTurns: any(named: 'rotateQuarterTurns')))
            .thenThrow(Exception('Processing error'));
      },
      build: () => GalleryBloc(
        databaseService: mockDatabaseService,
        imageService: mockImageService,
      ),
      act: (bloc) => bloc.add(const AddPhoto(
        path: '/test/input.jpg',
        filter: FilterType.monochrome,
        motionBlur: 0.1,
        isPortrait: true,
      )),
      expect: () => [
        isA<GalleryError>().having(
          (state) => state.message,
          'message',
          contains('Processing error'),
        ),
      ],
    );

    blocTest<GalleryBloc, GalleryState>(
      'emits GalleryError when DeletePhoto fails',
      setUp: () {
        when(() => mockDatabaseService.deletePhoto(any()))
            .thenThrow(Exception('Delete error'));
      },
      build: () => GalleryBloc(
        databaseService: mockDatabaseService,
        imageService: mockImageService,
      ),
      act: (bloc) => bloc.add(DeletePhoto(testNegativePhoto)),
      expect: () => [
        isA<GalleryError>().having(
          (state) => state.message,
          'message',
          contains('Delete error'),
        ),
      ],
    );
  });

  group('GalleryEvent', () {
    test('LoadPhotos props are empty', () {
      final event = LoadPhotos();
      expect(event.props, isEmpty);
    });

    test('AddPhoto props are correct', () {
      const event = AddPhoto(
        path: '/test/path.jpg',
        filter: FilterType.sepia,
        motionBlur: 0.5,
        isPortrait: true,
      );
      expect(event.props, ['/test/path.jpg', FilterType.sepia, 0.5, true]);
    });

    test('AddPhoto equality', () {
      const event1 = AddPhoto(
        path: '/test/path.jpg',
        filter: FilterType.sepia,
        motionBlur: 0.5,
        isPortrait: true,
      );
      const event2 = AddPhoto(
        path: '/test/path.jpg',
        filter: FilterType.sepia,
        motionBlur: 0.5,
        isPortrait: true,
      );
      const event3 = AddPhoto(
        path: '/test/other.jpg',
        filter: FilterType.sepia,
        motionBlur: 0.5,
        isPortrait: true,
      );

      expect(event1, equals(event2));
      expect(event1, isNot(equals(event3)));
    });

    test('DevelopPhoto props are correct', () {
      final event = DevelopPhoto(testNegativePhoto);
      expect(event.props, [testNegativePhoto]);
    });

    test('DeletePhoto props are correct', () {
      final event = DeletePhoto(testNegativePhoto);
      expect(event.props, [testNegativePhoto]);
    });
  });

  group('GalleryState', () {
    test('GalleryInitial props are empty', () {
      final state = GalleryInitial();
      expect(state.props, isEmpty);
    });

    test('GalleryLoading props are empty', () {
      final state = GalleryLoading();
      expect(state.props, isEmpty);
    });

    test('GalleryLoaded props are correct', () {
      final state = GalleryLoaded(
        negatives: [testNegativePhoto],
        developed: [testDevelopedPhoto],
      );
      expect(state.props, [
        [testNegativePhoto],
        [testDevelopedPhoto],
      ]);
    });

    test('GalleryLoaded equality', () {
      final state1 = GalleryLoaded(
        negatives: [testNegativePhoto],
        developed: [testDevelopedPhoto],
      );
      final state2 = GalleryLoaded(
        negatives: [testNegativePhoto],
        developed: [testDevelopedPhoto],
      );
      const state3 = GalleryLoaded(
        negatives: [],
        developed: [],
      );

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    test('GalleryError props are correct', () {
      const state = GalleryError('Test error message');
      expect(state.props, ['Test error message']);
    });

    test('GalleryError equality', () {
      const state1 = GalleryError('Error 1');
      const state2 = GalleryError('Error 1');
      const state3 = GalleryError('Error 2');

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });
  });
}
