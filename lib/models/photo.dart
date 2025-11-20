import 'package:equatable/equatable.dart';

enum FilterType { none, monochrome, sepia, glassPlate, cyanotype, daguerreotype }
enum PhotoStatus { negative, developed }

class Photo extends Equatable {
  final int? id;
  final String path;
  final FilterType filter;
  final double? motionBlur;
  final bool isPortrait;
  final PhotoStatus status;
  final DateTime timestamp;

  Photo({
    this.id,
    required this.path,
    this.filter = FilterType.none,
    this.motionBlur,
    this.isPortrait = false,
    this.status = PhotoStatus.negative,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Photo copyWith({
    int? id,
    String? path,
    FilterType? filter,
    double? motionBlur,
    bool? isPortrait,
    PhotoStatus? status,
    DateTime? timestamp,
  }) {
    return Photo(
      id: id ?? this.id,
      path: path ?? this.path,
      filter: filter ?? this.filter,
      motionBlur: motionBlur ?? this.motionBlur,
      isPortrait: isPortrait ?? this.isPortrait,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'filter': filter.index,
      'motion_blur': motionBlur,
      'is_portrait': isPortrait ? 1 : 0,
      'status': status.index,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'],
      path: map['path'],
      filter: FilterType.values[map['filter']],
      motionBlur: map['motion_blur'],
      isPortrait: map['is_portrait'] == 1,
      status: PhotoStatus.values[map['status']],
      timestamp: map['timestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : null,
    );
  }

  @override
  List<Object?> get props => [id, path, filter, motionBlur, isPortrait, status, timestamp];
}