import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/photo.dart';
import '../../repositories/settings_repository.dart';

// Events
abstract class FilterEvent extends Equatable {
  const FilterEvent();

  @override
  List<Object?> get props => [];
}

class SelectFilter extends FilterEvent {
  final FilterType filter;

  const SelectFilter(this.filter);

  @override
  List<Object?> get props => [filter];
}

class LoadSavedFilter extends FilterEvent {}

// States
abstract class FilterState extends Equatable {
  const FilterState();

  @override
  List<Object?> get props => [];
}

class FilterSelected extends FilterState {
  final FilterType selectedFilter;

  const FilterSelected(this.selectedFilter);

  @override
  List<Object?> get props => [selectedFilter];
}

// BLoC
class FilterBloc extends Bloc<FilterEvent, FilterState> {
  final SettingsRepository _repository;

  FilterBloc({required SettingsRepository repository})
      : _repository = repository,
        super(FilterSelected(repository.selectedFilter)) {
    on<SelectFilter>(_onSelectFilter);
    on<LoadSavedFilter>(_onLoadSavedFilter);
  }

  Future<void> _onSelectFilter(
    SelectFilter event,
    Emitter<FilterState> emit,
  ) async {
    await _repository.setSelectedFilter(event.filter);
    emit(FilterSelected(event.filter));
  }

  void _onLoadSavedFilter(
    LoadSavedFilter event,
    Emitter<FilterState> emit,
  ) {
    emit(FilterSelected(_repository.selectedFilter));
  }
}