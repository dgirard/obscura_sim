import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/photo.dart';
import '../../services/database_service.dart';
import '../../services/image_processing_service.dart';
import '../../services/logger_service.dart';

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

class LoadMorePhotos extends GalleryEvent {
  final PhotoStatus status;

  const LoadMorePhotos(this.status);

  @override
  List<Object?> get props => [status];
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
  final bool hasMoreNegatives;
  final bool hasMoreDeveloped;
  final bool isLoadingMore;

  const GalleryLoaded({
    required this.negatives,
    required this.developed,
    this.hasMoreNegatives = false,
    this.hasMoreDeveloped = false,
    this.isLoadingMore = false,
  });

  GalleryLoaded copyWith({
    List<Photo>? negatives,
    List<Photo>? developed,
    bool? hasMoreNegatives,
    bool? hasMoreDeveloped,
    bool? isLoadingMore,
  }) {
    return GalleryLoaded(
      negatives: negatives ?? this.negatives,
      developed: developed ?? this.developed,
      hasMoreNegatives: hasMoreNegatives ?? this.hasMoreNegatives,
      hasMoreDeveloped: hasMoreDeveloped ?? this.hasMoreDeveloped,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [negatives, developed, hasMoreNegatives, hasMoreDeveloped, isLoadingMore];
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

  static const int _pageSize = 20;

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
    on<LoadMorePhotos>(_onLoadMorePhotos);
  }

  Future<void> _onLoadPhotos(
    LoadPhotos event,
    Emitter<GalleryState> emit,
  ) async {
    emit(GalleryLoading());
    try {
      // Charger la première page de chaque type
      final negatives = await _databaseService.getPhotosPaginated(
        limit: _pageSize,
        offset: 0,
        status: PhotoStatus.negative,
      );
      final developed = await _databaseService.getPhotosPaginated(
        limit: _pageSize,
        offset: 0,
        status: PhotoStatus.developed,
      );

      // Vérifier s'il y a plus de photos
      final totalNegatives = await _databaseService.getPhotosCount(status: PhotoStatus.negative);
      final totalDeveloped = await _databaseService.getPhotosCount(status: PhotoStatus.developed);

      emit(GalleryLoaded(
        negatives: negatives,
        developed: developed,
        hasMoreNegatives: negatives.length < totalNegatives,
        hasMoreDeveloped: developed.length < totalDeveloped,
      ));
    } catch (e) {
      emit(GalleryError('Erreur de chargement: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMorePhotos(
    LoadMorePhotos event,
    Emitter<GalleryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! GalleryLoaded || currentState.isLoadingMore) return;

    final isNegative = event.status == PhotoStatus.negative;
    final hasMore = isNegative ? currentState.hasMoreNegatives : currentState.hasMoreDeveloped;
    if (!hasMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final currentList = isNegative ? currentState.negatives : currentState.developed;
      final newPhotos = await _databaseService.getPhotosPaginated(
        limit: _pageSize,
        offset: currentList.length,
        status: event.status,
      );

      final total = await _databaseService.getPhotosCount(status: event.status);
      final updatedList = [...currentList, ...newPhotos];

      if (isNegative) {
        emit(currentState.copyWith(
          negatives: updatedList,
          hasMoreNegatives: updatedList.length < total,
          isLoadingMore: false,
        ));
      } else {
        emit(currentState.copyWith(
          developed: updatedList,
          hasMoreDeveloped: updatedList.length < total,
          isLoadingMore: false,
        ));
      }
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
      AppLogger.error('Erreur de pagination', e);
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

      // Créer la miniature (TODO: stocker dans la BDD via Photo.thumbnail)
      await _imageService.createThumbnail(processedPath);

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
        AppLogger.warning('Échec de la sauvegarde dans la galerie publique: $e');
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
          AppLogger.warning('Échec de la suppression dans MediaStore: $e');
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