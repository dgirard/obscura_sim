import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/photo.dart';

// Data transfer object for the isolate
class ProcessingRequest {
  final String imagePath;
  final FilterType filter;
  final double motionBlur;
  final bool invert;
  final int rotateQuarterTurns;
  final String outputPath;

  ProcessingRequest({
    required this.imagePath,
    required this.filter,
    required this.motionBlur,
    required this.invert,
    required this.rotateQuarterTurns,
    required this.outputPath,
  });
}

// Top-level function for the isolate
Future<String> isolatedImageProcessor(ProcessingRequest request) async {
  // Lire l'image
  final File imageFile = File(request.imagePath);
  final Uint8List bytes = await imageFile.readAsBytes();
  img.Image? image = img.decodeImage(bytes);

  if (image == null) {
    throw Exception('Impossible de décoder l\'image');
  }

  // Redimensionner si l'image est trop grande pour éviter les crashs mémoire (OOM)
  // On limite à 2048px sur le bord le plus long, suffisant pour l'affichage et le partage
  if (image.width > 2048 || image.height > 2048) {
    image = img.copyResize(
      image, 
      width: image.width >= image.height ? 2048 : null,
      height: image.height > image.width ? 2048 : null,
      maintainAspect: true
    );
  }

  // Appliquer l'inversion si nécessaire (camera obscura effect)
  if (request.invert) {
    image = img.flip(image, direction: img.FlipDirection.both);
  }

  // Appliquer la rotation si nécessaire (pour portrait)
  if (request.rotateQuarterTurns != 0) {
    final degrees = request.rotateQuarterTurns * 90;
    image = img.copyRotate(image, angle: degrees);
  }

  // Appliquer le filtre
  image = _applyFilter(image, request.filter);

  // Appliquer le flou de mouvement si nécessaire
  if (request.motionBlur > 0.5) {
    image = _applyMotionBlur(image, request.motionBlur);
  }

  // Sauvegarder l'image traitée
  final File outputFile = File(request.outputPath);
  await outputFile.writeAsBytes(img.encodeJpg(image, quality: 90));

  return request.outputPath;
}

img.Image _applyFilter(img.Image image, FilterType filter) {
  switch (filter) {
    case FilterType.monochrome:
      return _applyMonochromeFilter(image);
    case FilterType.sepia:
      return _applySepiaFilter(image);
    case FilterType.glassPlate:
      return _applyGlassPlateFilter(image);
    case FilterType.cyanotype:
      return _applyCyanotypeFilter(image);
    case FilterType.daguerreotype:
      return _applyDaguerreotypeFilter(image);
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

img.Image _applyCyanotypeFilter(img.Image image) {
  // Cyanotype: Bleu de Prusse
  // On passe en niveaux de gris d'abord
  img.Image processed = img.grayscale(image);
  
  // Augmenter le contraste
  processed = img.adjustColor(processed, contrast: 1.2);

  for (int y = 0; y < processed.height; y++) {
    for (int x = 0; x < processed.width; x++) {
      final pixel = processed.getPixel(x, y);
      // Utiliser la valeur de luminance (r=g=b en grayscale)
      final lum = pixel.r.toInt();
      
      // Formule Cyanotype approximative
      // Les noirs restent sombres mais bleutés (0, 50, 100)
      // Les blancs restent blancs/pâles bleus (230, 240, 255)
      
      // Interpolation vers un bleu profond
      final r = (lum * 0.2).round().clamp(0, 255);
      final g = (lum * 0.4).round().clamp(0, 255);
      final b = (lum * 0.9 + 20).round().clamp(0, 255); // Boost le bleu

      processed.setPixelRgba(x, y, r, g, b, pixel.a.toInt());
    }
  }
  return processed;
}

img.Image _applyDaguerreotypeFilter(img.Image image) {
  // Daguerréotype : Très détaillé, métallique, argentique
  
  // Désaturer mais garder un tout petit peu de couleur (tonalité métallique)
  img.Image processed = img.grayscale(image);
  
  // Augmenter la netteté (sharpen) pour simuler le détail fin sur métal
  // Note: package image n'a pas de sharpen simple rapide, on peut simuler avec contraste élevé
  processed = img.adjustColor(processed, contrast: 1.4, brightness: 1.1);

  // Ajouter un vignettage fort (typique des optiques anciennes)
  final centerX = processed.width / 2;
  final centerY = processed.height / 2;
  final maxDistance = math.sqrt(centerX * centerX + centerY * centerY);

  for (int y = 0; y < processed.height; y++) {
    for (int x = 0; x < processed.width; x++) {
      final distance = math.sqrt(
        math.pow(x - centerX, 2) + math.pow(y - centerY, 2)
      );
      // Vignettage plus agressif sur les bords
      final vignette = 1.0 - math.pow(distance / maxDistance, 2) * 0.6;
      
      final pixel = processed.getPixel(x, y);
      
      // Teinte légèrement chaude/métallique (or/argent)
      // r un peu plus haut, b un peu plus bas
      var r = pixel.r.toInt();
      var g = pixel.g.toInt();
      var b = pixel.b.toInt();
      
      // Shift vers le jaune argenté
      r = (r * 1.05).round().clamp(0, 255);
      b = (b * 0.95).round().clamp(0, 255);

      // Appliquer vignette
      r = (r * vignette).round().clamp(0, 255);
      g = (g * vignette).round().clamp(0, 255);
      b = (b * vignette).round().clamp(0, 255);

      processed.setPixelRgba(x, y, r, g, b, pixel.a.toInt());
    }
  }
  
  return processed;
}

img.Image _applyMotionBlur(img.Image image, double intensity) {
  // Appliquer un flou directionnel simple
  final blurAmount = (intensity * 3).round().clamp(1, 5);
  return img.gaussianBlur(image, radius: blurAmount);
}


class ImageProcessingService {

  Future<String> processImage(
    String imagePath,
    FilterType filter,
    double motionBlur,
    {bool invert = false, int rotateQuarterTurns = 0}
  ) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String fileName = 'processed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String outputPath = '${appDir.path}/$fileName';

    final request = ProcessingRequest(
      imagePath: imagePath,
      filter: filter,
      motionBlur: motionBlur,
      invert: invert,
      rotateQuarterTurns: rotateQuarterTurns,
      outputPath: outputPath,
    );

    // Exécuter le traitement dans un isolate séparé pour éviter de bloquer l'UI
    return compute(isolatedImageProcessor, request);
  }

  Future<Uint8List> createThumbnail(String imagePath) async {
    // Thumbnail creation is also heavy, so we can compute it too
    // Or just leave it as is if it's small enough, but better to be safe.
    // For now, keeping it simple but ensuring it's not blocking if possible.
    // Since the original code didn't ask for this change specifically and I want to minimize diffs, 
    // I will just wrap the heavy parts or leave it if it's used in a FutureBuilder anyway.
    // Given the prompt, I'll focus on the main processImage.
    
    final File imageFile = File(imagePath);
    final Uint8List bytes = await imageFile.readAsBytes();
    
    return compute((Uint8List imageBytes) {
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Impossible de créer la miniature');
      }
      // Redimensionner pour la miniature
      final thumbnail = img.copyResize(image, width: 150);
      return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 70));
    }, bytes);
  }

  Future<String> generateFramedImage(String imagePath, String title, String subtitle) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String fileName = 'framed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String outputPath = '${appDir.path}/$fileName';

    final request = FrameRequest(
      imagePath: imagePath,
      title: title,
      subtitle: subtitle,
      outputPath: outputPath,
    );

    return compute(isolatedFrameProcessor, request);
  }
}

class FrameRequest {
  final String imagePath;
  final String title;
  final String subtitle;
  final String outputPath;

  FrameRequest({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.outputPath,
  });
}

Future<String> isolatedFrameProcessor(FrameRequest request) async {
  final File imageFile = File(request.imagePath);
  final Uint8List bytes = await imageFile.readAsBytes();
  img.Image? image = img.decodeImage(bytes);

  if (image == null) throw Exception('Impossible de décoder l\'image');

  // Créer un canvas plus grand (blanc)
  final int borderSize = (image.width * 0.05).round(); // 5% de bordure
  final int bottomSize = (image.width * 0.20).round(); // 20% en bas pour le texte (Polaroid style)
  
  final framedImage = img.Image(
    width: image.width + borderSize * 2,
    height: image.height + borderSize + bottomSize,
  );
  
  // Remplir de blanc
  img.fill(framedImage, color: img.ColorRgb8(255, 255, 255));

  // Dessiner l'image au centre
  img.compositeImage(
    framedImage, 
    image, 
    dstX: borderSize, 
    dstY: borderSize,
  );

  // Ajouter le texte (si possible avec une police simple)
  // Note: 'image' package a des polices bitmap limitées par défaut.
  // On utilise arial_24 ou 48 selon la taille.
  // Pour simplifier, on utilise arial_48 si l'image est grande, sinon 24.
  final font = img.arial24;
  
  final textColor = img.ColorRgb8(50, 50, 50);
  
  // Titre (ex: Date)
  img.drawString(
    framedImage,
    request.title,
    font: font,
    x: borderSize,
    y: image.height + borderSize + (bottomSize ~/ 3),
    color: textColor,
  );

  // Sous-titre (ex: Filtre)
  img.drawString(
    framedImage,
    request.subtitle,
    font: font,
    x: borderSize,
    y: image.height + borderSize + (bottomSize ~/ 3) + 30,
    color: textColor,
  );

  final File outputFile = File(request.outputPath);
  await outputFile.writeAsBytes(img.encodeJpg(framedImage, quality: 95));

  return request.outputPath;
}