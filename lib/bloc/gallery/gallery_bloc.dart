import 'dart:io';
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

  const AddPhoto({
    required this.path,
    required this.filter,
    required this.motionBlur,
  });

  @override
  List<Object?> get props => [path, filter, motionBlur];
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
      final processedPath = await _imageService.processImage(
        event.path,
        event.filter,
        event.motionBlur,
        invert: true, // Image inversée pour le négatif
      );

      // Créer la miniature
      final thumbnail = await _imageService.createThumbnail(processedPath);

      final photo = Photo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        path: processedPath,
        capturedAt: DateTime.now(),
        filter: event.filter,
        status: PhotoStatus.negative,
        motionBlur: event.motionBlur,
        thumbnailData: thumbnail,
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
      // Créer une version développée (non inversée)
      final developedPath = await _imageService.processImage(
        event.photo.path,
        event.photo.filter,
        0, // Pas de flou supplémentaire lors du développement
        invert: false, // Image normale pour la version développée
      );

      // Sauvegarder dans la galerie du téléphone
      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final File developedFile = File(developedPath);
        final String galleryPath = '${externalDir.path}/ObscuraSim';
        await Directory(galleryPath).create(recursive: true);
        final String finalPath = '$galleryPath/${event.photo.id}_developed.jpg';
        await developedFile.copy(finalPath);
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
      await _databaseService.deletePhoto(event.photo.id);

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