import 'package:flutter_test/flutter_test.dart';
import 'package:obscura_sim/navigation/app_router.dart';
import 'package:obscura_sim/models/photo.dart';

void main() {
  group('AppRoutes', () {
    test('splash route is /', () {
      expect(AppRoutes.splash, '/');
    });

    test('onboarding route is /onboarding', () {
      expect(AppRoutes.onboarding, '/onboarding');
    });

    test('camera route is /camera', () {
      expect(AppRoutes.camera, '/camera');
    });

    test('gallery route is /gallery', () {
      expect(AppRoutes.gallery, '/gallery');
    });

    test('photoDetail route is /photo-detail', () {
      expect(AppRoutes.photoDetail, '/photo-detail');
    });

    test('settings route is /settings', () {
      expect(AppRoutes.settings, '/settings');
    });

    test('filterSelection route is /filter-selection', () {
      expect(AppRoutes.filterSelection, '/filter-selection');
    });
  });

  group('PhotoDetailParams', () {
    test('stores photos and initialIndex correctly', () {
      final photos = [
        Photo(
          id: 1,
          path: '/test/photo1.jpg',
          timestamp: DateTime(2024, 1, 1),
          filter: FilterType.monochrome,
          status: PhotoStatus.negative,
        ),
        Photo(
          id: 2,
          path: '/test/photo2.jpg',
          timestamp: DateTime(2024, 1, 2),
          filter: FilterType.sepia,
          status: PhotoStatus.developed,
        ),
      ];

      final params = PhotoDetailParams(photos: photos, initialIndex: 1);

      expect(params.photos.length, 2);
      expect(params.initialIndex, 1);
      expect(params.photos[0].id, 1);
      expect(params.photos[1].id, 2);
    });
  });
}
