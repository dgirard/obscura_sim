import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/photo.dart';
import '../../services/database_service.dart';
import '../../services/image_processing_service.dart';

// Events
abstract class GalleryEvent extends Equatable {
  const GalleryEvent();

  @override
  List<Object?> get props => [];
}

class LoadPhotos extends GalleryEvent {}

class AddPhoto extends GalleryEvent {
  final String path;
  final FilterType filter;
  final double motionBlur;
  final bool isPortrait;

  const AddPhoto({
    required this.path,
    required this.filter,
    required this.motionBlur,
    required this.isPortrait,
  });

  @override
  List<Object?> get props => [path, filter, motionBlur, isPortrait];
}

class DevelopPhoto extends GalleryEvent {
  final Photo photo;

  const DevelopPhoto(this.photo);

  @override
  List<Object?> get props => [photo];
}

class DeletePhoto extends GalleryEvent {
  final Photo photo;

  const DeletePhoto(this.photo);

  @override
  List<Object?> get props => [photo];
}

// States
abstract class GalleryState extends Equatable {
  const GalleryState();

  @override
  List<Object?> get props => [];
}

class GalleryInitial extends GalleryState {}

class GalleryLoading extends GalleryState {}

class GalleryLoaded extends GalleryState {
  final List<Photo> negatives; // Photos non développées
  final List<Photo> developed; // Photos développées

  const GalleryLoaded({
    required this.negatives,
    required this.developed,
  });

  @override
  List<Object?> get props => [negatives, developed];
}

class GalleryError extends GalleryState {
  final String message;

  const GalleryError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class GalleryBloc extends Bloc<GalleryEvent, GalleryState> {
  final DatabaseService _databaseService;
  final ImageProcessingService _imageService;

  GalleryBloc({
    required DatabaseService databaseService,
    required ImageProcessingService imageService,
  })  : _databaseService = databaseService,
        _imageService = imageService,
        super(GalleryInitial()) {
    on<LoadPhotos>(_onLoadPhotos);
    on<AddPhoto>(_onAddPhoto);
    on<DevelopPhoto>(_onDevelopPhoto);
    on<DeletePhoto>(_onDeletePhoto);
  }

  Future<void> _onLoadPhotos(
    LoadPhotos event,
    Emitter<GalleryState> emit,
  ) async {
    emit(GalleryLoading());
    try {
      final photos = await _databaseService.getAllPhotos();
      final negatives = photos
          .where((photo) => photo.status == PhotoStatus.negative)
          .toList();
      final developed = photos
          .where((photo) => photo.status == PhotoStatus.developed)
          .toList();

      emit(GalleryLoaded(negatives: negatives, developed: developed));
    } catch (e) {
      emit(GalleryError('Erreur de chargement: ${e.toString()}'));
    }
  }

  Future<void> _onAddPhoto(
    AddPhoto event,
    Emitter<GalleryState> emit,
  ) async {
    try {
      // Créer une photo inversée avec filtre
      // NOTE: On ne demande plus l'inversion physique ici (invert: false)
      // car on veut garder le fichier "droit" pour que les vignettes soient OK
      // et pour la compatibilité Exif. L'inversion visuelle se fera dans l'UI.
      final processedPath = await _imageService.processImage(
        event.path,
        event.filter,
        event.motionBlur,
        invert: false, 
      );

      // Créer la miniature
      final thumbnail = await _imageService.createThumbnail(processedPath);

      final photo = Photo(
        id: DateTime.now().millisecondsSinceEpoch,
        path: processedPath,
        timestamp: DateTime.now(),
        filter: event.filter,
        status: PhotoStatus.negative,
        motionBlur: event.motionBlur,
        isPortrait: event.isPortrait,
      );

      await _databaseService.insertPhoto(photo);
      add(LoadPhotos());
    } catch (e) {
      emit(GalleryError('Erreur d\'ajout: ${e.toString()}'));
    }
  }

  Future<void> _onDevelopPhoto(
    DevelopPhoto event,
    Emitter<GalleryState> emit,
  ) async {
    try {
      // Créer une version développée (réinverser le négatif) avec rotation si nécessaire
      // NOTE: Comme l'image source "Négatif" est maintenant stockée "droite" (non inversée physiquement),
      // on n'a pas besoin de la ré-inverser ici. On garde le pass-through.
      final developedPath = await _imageService.processImage(
        event.photo.path,
        event.photo.filter,
        0, // Pas de flou supplémentaire lors du développement
        invert: false, 
        rotateQuarterTurns: 0, 
      );

      // Sauvegarder dans la galerie publique (MediaStore) pour rendre accessible aux autres apps
      const platform = MethodChannel('com.obscurasim.app/mediastore');
      final String fileName = 'obscura_${event.photo.id}_developed.jpg';

      try {
        await platform.invokeMethod('saveToMediaStore', {
          'filePath': developedPath,
          'displayName': fileName,
        });
      } catch (e) {
        // Si la sauvegarde dans MediaStore échoue, continuer quand même
        // (la photo sera toujours dans l'app)
        print('Avertissement: Échec de la sauvegarde dans la galerie publique: $e');
      }

      final updatedPhoto = event.photo.copyWith(
        status: PhotoStatus.developed,
      );

      await _databaseService.updatePhoto(updatedPhoto);
      add(LoadPhotos());
    } catch (e) {
      emit(GalleryError('Erreur de développement: ${e.toString()}'));
    }
  }

  Future<void> _onDeletePhoto(
    DeletePhoto event,
    Emitter<GalleryState> emit,
  ) async {
    try {
      // Si la photo est développée, la supprimer aussi du MediaStore (galerie publique)
      if (event.photo.status == PhotoStatus.developed) {
        const platform = MethodChannel('com.obscurasim.app/mediastore');
        final String fileName = 'obscura_${event.photo.id}_developed.jpg';

        try {
          await platform.invokeMethod('deleteFromMediaStore', {
            'fileName': fileName,
          });
        } catch (e) {
          // Si la suppression du MediaStore échoue, continuer quand même
          print('Avertissement: Échec de la suppression dans MediaStore: $e');
        }
      }

      if (event.photo.id != null) {
        await _databaseService.deletePhoto(event.photo.id!);
      }

      // Supprimer les fichiers
      final File photoFile = File(event.photo.path);
      if (await photoFile.exists()) {
        await photoFile.delete();
      }

      add(LoadPhotos());
    } catch (e) {
      emit(GalleryError('Erreur de suppression: ${e.toString()}'));
    }
  }
}