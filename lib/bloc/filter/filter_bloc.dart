import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/photo.dart';

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
  FilterBloc() : super(const FilterSelected(FilterType.none)) {
    on<SelectFilter>((event, emit) {
      emit(FilterSelected(event.filter));
    });
  }
}