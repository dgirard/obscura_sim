import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:obscura_sim/bloc/filter/filter_bloc.dart';
import 'package:obscura_sim/models/photo.dart';
import 'package:obscura_sim/repositories/settings_repository.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FilterType.none);
  });

  setUp(() {
    mockRepository = MockSettingsRepository();
    when(() => mockRepository.selectedFilter).thenReturn(FilterType.none);
    when(() => mockRepository.setSelectedFilter(any())).thenAnswer((_) async {});
  });

  group('FilterBloc', () {
    test('initial state is FilterSelected with saved filter', () {
      when(() => mockRepository.selectedFilter).thenReturn(FilterType.sepia);
      final filterBloc = FilterBloc(repository: mockRepository);

      expect(filterBloc.state, isA<FilterSelected>());
      expect((filterBloc.state as FilterSelected).selectedFilter, FilterType.sepia);

      filterBloc.close();
    });

    test('initial state is FilterSelected with FilterType.none when no saved filter', () {
      final filterBloc = FilterBloc(repository: mockRepository);

      expect(filterBloc.state, isA<FilterSelected>());
      expect((filterBloc.state as FilterSelected).selectedFilter, FilterType.none);

      filterBloc.close();
    });

    blocTest<FilterBloc, FilterState>(
      'emits [FilterSelected(monochrome)] when SelectFilter(monochrome) is added',
      build: () => FilterBloc(repository: mockRepository),
      act: (bloc) => bloc.add(const SelectFilter(FilterType.monochrome)),
      expect: () => [const FilterSelected(FilterType.monochrome)],
      verify: (_) {
        verify(() => mockRepository.setSelectedFilter(FilterType.monochrome)).called(1);
      },
    );

    blocTest<FilterBloc, FilterState>(
      'emits [FilterSelected(sepia)] when SelectFilter(sepia) is added',
      build: () => FilterBloc(repository: mockRepository),
      act: (bloc) => bloc.add(const SelectFilter(FilterType.sepia)),
      expect: () => [const FilterSelected(FilterType.sepia)],
      verify: (_) {
        verify(() => mockRepository.setSelectedFilter(FilterType.sepia)).called(1);
      },
    );

    blocTest<FilterBloc, FilterState>(
      'emits [FilterSelected(glassPlate)] when SelectFilter(glassPlate) is added',
      build: () => FilterBloc(repository: mockRepository),
      act: (bloc) => bloc.add(const SelectFilter(FilterType.glassPlate)),
      expect: () => [const FilterSelected(FilterType.glassPlate)],
    );

    blocTest<FilterBloc, FilterState>(
      'emits [FilterSelected(cyanotype)] when SelectFilter(cyanotype) is added',
      build: () => FilterBloc(repository: mockRepository),
      act: (bloc) => bloc.add(const SelectFilter(FilterType.cyanotype)),
      expect: () => [const FilterSelected(FilterType.cyanotype)],
    );

    blocTest<FilterBloc, FilterState>(
      'emits [FilterSelected(daguerreotype)] when SelectFilter(daguerreotype) is added',
      build: () => FilterBloc(repository: mockRepository),
      act: (bloc) => bloc.add(const SelectFilter(FilterType.daguerreotype)),
      expect: () => [const FilterSelected(FilterType.daguerreotype)],
    );

    blocTest<FilterBloc, FilterState>(
      'can cycle through multiple filters',
      build: () => FilterBloc(repository: mockRepository),
      act: (bloc) {
        bloc.add(const SelectFilter(FilterType.monochrome));
        bloc.add(const SelectFilter(FilterType.sepia));
        bloc.add(const SelectFilter(FilterType.none));
      },
      expect: () => [
        const FilterSelected(FilterType.monochrome),
        const FilterSelected(FilterType.sepia),
        const FilterSelected(FilterType.none),
      ],
    );

    blocTest<FilterBloc, FilterState>(
      'selecting same filter does not emit new state (Equatable)',
      build: () => FilterBloc(repository: mockRepository),
      seed: () => const FilterSelected(FilterType.monochrome),
      act: (bloc) => bloc.add(const SelectFilter(FilterType.monochrome)),
      expect: () => [], // No emission because state is equal
    );

    blocTest<FilterBloc, FilterState>(
      'LoadSavedFilter emits current saved filter',
      setUp: () {
        when(() => mockRepository.selectedFilter).thenReturn(FilterType.cyanotype);
      },
      build: () => FilterBloc(repository: mockRepository),
      seed: () => const FilterSelected(FilterType.none),
      act: (bloc) => bloc.add(LoadSavedFilter()),
      expect: () => [const FilterSelected(FilterType.cyanotype)],
    );
  });

  group('FilterEvent', () {
    test('SelectFilter props are correct', () {
      const event = SelectFilter(FilterType.sepia);
      expect(event.props, [FilterType.sepia]);
    });

    test('SelectFilter equality', () {
      const event1 = SelectFilter(FilterType.sepia);
      const event2 = SelectFilter(FilterType.sepia);
      const event3 = SelectFilter(FilterType.monochrome);

      expect(event1, equals(event2));
      expect(event1, isNot(equals(event3)));
    });

    test('LoadSavedFilter props are empty', () {
      final event = LoadSavedFilter();
      expect(event.props, isEmpty);
    });
  });

  group('FilterState', () {
    test('FilterSelected props are correct', () {
      const state = FilterSelected(FilterType.cyanotype);
      expect(state.props, [FilterType.cyanotype]);
    });

    test('FilterSelected equality', () {
      const state1 = FilterSelected(FilterType.cyanotype);
      const state2 = FilterSelected(FilterType.cyanotype);
      const state3 = FilterSelected(FilterType.daguerreotype);

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });
  });
}
