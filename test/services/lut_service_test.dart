import 'package:flutter_test/flutter_test.dart';
import 'package:obscura_sim/services/lut_service.dart';

void main() {
  late LutService lutService;

  setUp(() {
    lutService = LutService();
    lutService.clearCache(); // Clear cache before each test
  });

  group('LutService', () {
    group('Sepia LUT', () {
      test('generates LUT with correct size (256 entries * 3 channels)', () {
        final lut = lutService.getSepiaLut();
        expect(lut.length, 256 * 3);
      });

      test('returns cached LUT on second call', () {
        final lut1 = lutService.getSepiaLut();
        final lut2 = lutService.getSepiaLut();
        expect(identical(lut1, lut2), true);
      });

      test('produces valid RGB values (0-255)', () {
        final lut = lutService.getSepiaLut();
        for (int i = 0; i < lut.length; i++) {
          expect(lut[i], greaterThanOrEqualTo(0));
          expect(lut[i], lessThanOrEqualTo(255));
        }
      });

      test('sepia effect produces warm tones (R >= G >= B)', () {
        final lut = lutService.getSepiaLut();
        // Check middle gray value (128)
        final r = lut[128 * 3];
        final g = lut[128 * 3 + 1];
        final b = lut[128 * 3 + 2];
        expect(r, greaterThanOrEqualTo(g));
        expect(g, greaterThanOrEqualTo(b));
      });
    });

    group('Cyanotype LUT', () {
      test('generates LUT with correct size', () {
        final lut = lutService.getCyanotypeLut();
        expect(lut.length, 256 * 3);
      });

      test('returns cached LUT on second call', () {
        final lut1 = lutService.getCyanotypeLut();
        final lut2 = lutService.getCyanotypeLut();
        expect(identical(lut1, lut2), true);
      });

      test('produces valid RGB values (0-255)', () {
        final lut = lutService.getCyanotypeLut();
        for (int i = 0; i < lut.length; i++) {
          expect(lut[i], greaterThanOrEqualTo(0));
          expect(lut[i], lessThanOrEqualTo(255));
        }
      });

      test('cyanotype effect produces blue tones (B >= G >= R)', () {
        final lut = lutService.getCyanotypeLut();
        // Check middle gray value (128)
        final r = lut[128 * 3];
        final g = lut[128 * 3 + 1];
        final b = lut[128 * 3 + 2];
        expect(b, greaterThanOrEqualTo(g));
        expect(g, greaterThanOrEqualTo(r));
      });
    });

    group('Daguerreotype LUT', () {
      test('generates LUT with correct size', () {
        final lut = lutService.getDaguerreotypeLut();
        expect(lut.length, 256 * 3);
      });

      test('returns cached LUT on second call', () {
        final lut1 = lutService.getDaguerreotypeLut();
        final lut2 = lutService.getDaguerreotypeLut();
        expect(identical(lut1, lut2), true);
      });

      test('produces valid RGB values (0-255)', () {
        final lut = lutService.getDaguerreotypeLut();
        for (int i = 0; i < lut.length; i++) {
          expect(lut[i], greaterThanOrEqualTo(0));
          expect(lut[i], lessThanOrEqualTo(255));
        }
      });

      test('daguerreotype produces warm metallic tones (R >= G >= B)', () {
        final lut = lutService.getDaguerreotypeLut();
        // Check middle gray value (128)
        final r = lut[128 * 3];
        final g = lut[128 * 3 + 1];
        final b = lut[128 * 3 + 2];
        expect(r, greaterThanOrEqualTo(g));
        expect(g, greaterThanOrEqualTo(b));
      });
    });

    group('Contrast LUT', () {
      test('generates LUT with 256 entries', () {
        final lut = lutService.getContrastLut(1.3);
        expect(lut.length, 256);
      });

      test('returns cached LUT on second call', () {
        final lut1 = lutService.getContrastLut(1.3);
        final lut2 = lutService.getContrastLut(1.3);
        expect(identical(lut1, lut2), true);
      });

      test('produces valid grayscale values (0-255)', () {
        final lut = lutService.getContrastLut(1.5);
        for (int i = 0; i < lut.length; i++) {
          expect(lut[i], greaterThanOrEqualTo(0));
          expect(lut[i], lessThanOrEqualTo(255));
        }
      });

      test('middle gray stays near middle', () {
        final lut = lutService.getContrastLut(1.0);
        // At contrast 1.0, 128 should stay around 128
        expect(lut[128], closeTo(128, 10));
      });
    });

    group('Vignette Map', () {
      test('generates map with correct size', () {
        final map = lutService.generateVignetteMap(100, 100, 0.7);
        expect(map.length, 100 * 100);
      });

      test('center has maximum brightness (1.0)', () {
        final map = lutService.generateVignetteMap(100, 100, 0.7);
        final centerIndex = 50 * 100 + 50;
        expect(map[centerIndex], closeTo(1.0, 0.01));
      });

      test('corners are darker than center', () {
        final map = lutService.generateVignetteMap(100, 100, 0.7);
        final centerIndex = 50 * 100 + 50;
        final cornerIndex = 0; // Top-left corner
        expect(map[cornerIndex], lessThan(map[centerIndex]));
      });

      test('produces values between 0 and 1', () {
        final map = lutService.generateVignetteMap(100, 100, 0.7);
        for (int i = 0; i < map.length; i++) {
          expect(map[i], greaterThanOrEqualTo(0.0));
          expect(map[i], lessThanOrEqualTo(1.0));
        }
      });
    });

    group('Cache Management', () {
      test('clearCache removes all cached LUTs', () {
        // Generate and cache some LUTs
        lutService.getSepiaLut();
        lutService.getCyanotypeLut();
        lutService.getDaguerreotypeLut();

        // Clear cache
        lutService.clearCache();

        // After clearing, new calls should generate new LUTs
        // (We can't directly test this without accessing private cache,
        // but we can verify the LUTs are still generated correctly)
        final sepia = lutService.getSepiaLut();
        final cyan = lutService.getCyanotypeLut();
        final dag = lutService.getDaguerreotypeLut();

        expect(sepia.length, 256 * 3);
        expect(cyan.length, 256 * 3);
        expect(dag.length, 256 * 3);
      });
    });
  });
}
