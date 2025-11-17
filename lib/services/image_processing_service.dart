import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/photo.dart';

class ImageProcessingService {

  Future<String> processImage(
    String imagePath,
    FilterType filter,
    double motionBlur,
    {bool invert = false}
  ) async {
    // Lire l'image
    final File imageFile = File(imagePath);
    final Uint8List bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Impossible de décoder l\'image');
    }

    // Appliquer l'inversion si nécessaire (camera obscura effect)
    if (invert) {
      image = img.flip(image, direction: img.FlipDirection.both);
    }

    // Appliquer le filtre
    image = _applyFilter(image, filter);

    // Appliquer le flou de mouvement si nécessaire
    if (motionBlur > 0.5) {
      image = _applyMotionBlur(image, motionBlur);
    }

    // Sauvegarder l'image traitée
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String fileName = 'processed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String outputPath = '${appDir.path}/$fileName';
    final File outputFile = File(outputPath);

    await outputFile.writeAsBytes(img.encodeJpg(image, quality: 90));

    return outputPath;
  }

  img.Image _applyFilter(img.Image image, FilterType filter) {
    switch (filter) {
      case FilterType.monochrome:
        return _applyMonochromeFilter(image);
      case FilterType.sepia:
        return _applySepiaFilter(image);
      case FilterType.glassPlate:
        return _applyGlassPlateFilter(image);
      case FilterType.none:
        return image;
    }
  }

  img.Image _applyMonochromeFilter(img.Image image) {
    // Convertir en noir et blanc avec du grain
    img.Image grayscale = img.grayscale(image);

    // Ajouter du grain
    final random = math.Random();
    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        if (random.nextDouble() < 0.1) {
          final pixel = grayscale.getPixel(x, y);
          final noise = (random.nextDouble() * 30 - 15).toInt();
          final r = (pixel.r.toInt() + noise).clamp(0, 255);
          final g = (pixel.g.toInt() + noise).clamp(0, 255);
          final b = (pixel.b.toInt() + noise).clamp(0, 255);
          grayscale.setPixelRgba(x, y, r, g, b, pixel.a.toInt());
        }
      }
    }

    // Augmenter le contraste
    return img.adjustColor(grayscale, contrast: 1.3);
  }

  img.Image _applySepiaFilter(img.Image image) {
    // Appliquer un effet sépia
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // Formule sépia
        final tr = (0.393 * r + 0.769 * g + 0.189 * b).round().clamp(0, 255);
        final tg = (0.349 * r + 0.686 * g + 0.168 * b).round().clamp(0, 255);
        final tb = (0.272 * r + 0.534 * g + 0.131 * b).round().clamp(0, 255);

        image.setPixelRgba(x, y, tr, tg, tb, pixel.a.toInt());
      }
    }

    return image;
  }

  img.Image _applyGlassPlateFilter(img.Image image) {
    // Effet plaque de verre : contraste élevé + vignettage + imperfections
    img.Image processed = img.adjustColor(image, contrast: 1.5);
    processed = img.grayscale(processed);

    // Ajouter un vignettage
    final centerX = processed.width / 2;
    final centerY = processed.height / 2;
    final maxDistance = math.sqrt(centerX * centerX + centerY * centerY);

    for (int y = 0; y < processed.height; y++) {
      for (int x = 0; x < processed.width; x++) {
        final distance = math.sqrt(
          math.pow(x - centerX, 2) + math.pow(y - centerY, 2)
        );
        final vignette = 1.0 - (distance / maxDistance) * 0.7;

        final pixel = processed.getPixel(x, y);
        final r = (pixel.r.toInt() * vignette).round().clamp(0, 255);
        final g = (pixel.g.toInt() * vignette).round().clamp(0, 255);
        final b = (pixel.b.toInt() * vignette).round().clamp(0, 255);

        processed.setPixelRgba(x, y, r, g, b, pixel.a.toInt());
      }
    }

    // Ajouter quelques imperfections aléatoires (poussières)
    final random = math.Random();
    for (int i = 0; i < 20; i++) {
      final x = random.nextInt(processed.width);
      final y = random.nextInt(processed.height);
      final radius = random.nextInt(3) + 1;

      img.fillCircle(processed, x: x, y: y, radius: radius,
        color: img.ColorRgb8(50, 50, 50));
    }

    return processed;
  }

  img.Image _applyMotionBlur(img.Image image, double intensity) {
    // Appliquer un flou directionnel simple
    final blurAmount = (intensity * 3).round().clamp(1, 5);
    return img.gaussianBlur(image, radius: blurAmount);
  }

  Future<Uint8List> createThumbnail(String imagePath) async {
    final File imageFile = File(imagePath);
    final Uint8List bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Impossible de créer la miniature');
    }

    // Redimensionner pour la miniature
    final thumbnail = img.copyResize(image, width: 150);

    return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 70));
  }
}