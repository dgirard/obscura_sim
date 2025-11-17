import 'dart:typed_data';
import 'package:equatable/equatable.dart';

enum FilterType {
  none,
  monochrome,
  sepia,
  glassPlate,
}

enum PhotoStatus {
  negative,  // Photo inversée, non développée
  developed, // Photo développée, prête à l'export
}

class Photo extends Equatable {
  final String id;
  final String path;
  final DateTime capturedAt;
  final FilterType filter;
  final PhotoStatus status;
  final double? motionBlur;  // Niveau de flou de mouvement détecté
  final Uint8List? thumbnailData;

  const Photo({
    required this.id,
    required this.path,
    required this.capturedAt,
    required this.filter,
    required this.status,
    this.motionBlur,
    this.thumbnailData,
  });

  Photo copyWith({
    String? id,
    String? path,
    DateTime? capturedAt,
    FilterType? filter,
    PhotoStatus? status,
    double? motionBlur,
    Uint8List? thumbnailData,
  }) {
    return Photo(
      id: id ?? this.id,
      path: path ?? this.path,
      capturedAt: capturedAt ?? this.capturedAt,
      filter: filter ?? this.filter,
      status: status ?? this.status,
      motionBlur: motionBlur ?? this.motionBlur,
      thumbnailData: thumbnailData ?? this.thumbnailData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'capturedAt': capturedAt.toIso8601String(),
      'filter': filter.index,
      'status': status.index,
      'motionBlur': motionBlur,
      'thumbnailData': thumbnailData,
    };
  }

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'],
      path: map['path'],
      capturedAt: DateTime.parse(map['capturedAt']),
      filter: FilterType.values[map['filter']],
      status: PhotoStatus.values[map['status']],
      motionBlur: map['motionBlur'],
      thumbnailData: map['thumbnailData'],
    );
  }

  @override
  List<Object?> get props => [id, path, capturedAt, filter, status, motionBlur];
}