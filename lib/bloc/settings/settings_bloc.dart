import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../repositories/settings_repository.dart';

// Events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object> get props => [];
}

class LoadSettings extends SettingsEvent {}

class ToggleInvertedViewfinder extends SettingsEvent {
  final bool isEnabled;
  const ToggleInvertedViewfinder(this.isEnabled);
  @override
  List<Object> get props => [isEnabled];
}

class SetImageQuality extends SettingsEvent {
  final ResolutionPreset quality;
  const SetImageQuality(this.quality);
  @override
  List<Object> get props => [quality];
}

class CompleteOnboarding extends SettingsEvent {}

// State
class SettingsState extends Equatable {
  final bool isInvertedViewfinder;
  final ResolutionPreset imageQuality;
  final bool isOnboardingCompleted;

  const SettingsState({
    required this.isInvertedViewfinder,
    required this.imageQuality,
    required this.isOnboardingCompleted,
  });

  SettingsState copyWith({
    bool? isInvertedViewfinder,
    ResolutionPreset? imageQuality,
    bool? isOnboardingCompleted,
  }) {
    return SettingsState(
      isInvertedViewfinder: isInvertedViewfinder ?? this.isInvertedViewfinder,
      imageQuality: imageQuality ?? this.imageQuality,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
    );
  }

  @override
  List<Object> get props => [isInvertedViewfinder, imageQuality, isOnboardingCompleted];
}

// Bloc
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _repository;

  SettingsBloc({required SettingsRepository repository})
      : _repository = repository,
        super(SettingsState(
          isInvertedViewfinder: repository.isInvertedViewfinderEnabled,
          imageQuality: repository.imageQuality,
          isOnboardingCompleted: repository.isOnboardingCompleted,
        )) {
    on<LoadSettings>((event, emit) {
      emit(SettingsState(
        isInvertedViewfinder: _repository.isInvertedViewfinderEnabled,
        imageQuality: _repository.imageQuality,
        isOnboardingCompleted: _repository.isOnboardingCompleted,
      ));
    });

    on<ToggleInvertedViewfinder>((event, emit) async {
      await _repository.setInvertedViewfinder(event.isEnabled);
      emit(state.copyWith(isInvertedViewfinder: event.isEnabled));
    });

    on<SetImageQuality>((event, emit) async {
      await _repository.setImageQuality(event.quality);
      emit(state.copyWith(imageQuality: event.quality));
    });

    on<CompleteOnboarding>((event, emit) async {
      await _repository.setOnboardingCompleted();
      emit(state.copyWith(isOnboardingCompleted: true));
    });
  }
}
