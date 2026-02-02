import 'package:flutter_test/flutter_test.dart';
import 'package:obscura_sim/models/photo.dart';

void main() {
  group('Photo Model for Pagination', () {
    test('Photo can be created with all required fields', () {
      final photo = Photo(
        id: 1,
        path: '/test/photo.jpg',
        timestamp: DateTime(2024, 1, 1),
        filter: FilterType.monochrome,
        status: PhotoStatus.negative,
      );

      expect(photo.id, 1);
      expect(photo.path, '/test/photo.jpg');
      expect(photo.filter, FilterType.monochrome);
      expect(photo.status, PhotoStatus.negative);
    });

    test('Photo can be created with optional fields', () {
      final photo = Photo(
        id: 2,
        path: '/test/photo2.jpg',
        timestamp: DateTime(2024, 1, 2),
        filter: FilterType.sepia,
        status: PhotoStatus.developed,
        motionBlur: 0.5,
        isPortrait: true,
      );

      expect(photo.motionBlur, 0.5);
      expect(photo.isPortrait, true);
    });

    test('PhotoStatus enum has correct values', () {
      expect(PhotoStatus.values.length, 2);
      expect(PhotoStatus.negative.index, 0);
      expect(PhotoStatus.developed.index, 1);
    });

    test('FilterType enum has all expected values', () {
      expect(FilterType.values.contains(FilterType.none), true);
      expect(FilterType.values.contains(FilterType.monochrome), true);
      expect(FilterType.values.contains(FilterType.sepia), true);
      expect(FilterType.values.contains(FilterType.glassPlate), true);
      expect(FilterType.values.contains(FilterType.cyanotype), true);
      expect(FilterType.values.contains(FilterType.daguerreotype), true);
    });

    test('Photo copyWith creates new instance with updated values', () {
      final original = Photo(
        id: 1,
        path: '/test/photo.jpg',
        timestamp: DateTime(2024, 1, 1),
        filter: FilterType.monochrome,
        status: PhotoStatus.negative,
      );

      final developed = original.copyWith(status: PhotoStatus.developed);

      expect(developed.id, original.id);
      expect(developed.path, original.path);
      expect(developed.status, PhotoStatus.developed);
      expect(original.status, PhotoStatus.negative); // Original unchanged
    });
  });
}
