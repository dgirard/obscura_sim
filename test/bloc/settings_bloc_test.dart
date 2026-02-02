import 'package:bloc_test/bloc_test.dart';
import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:obscura_sim/bloc/settings/settings_bloc.dart';
import 'package:obscura_sim/repositories/settings_repository.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(ResolutionPreset.medium);
  });

  setUp(() {
    mockRepository = MockSettingsRepository();

    // Default setup
    when(() => mockRepository.isInvertedViewfinderEnabled).thenReturn(true);
    when(() => mockRepository.imageQuality).thenReturn(ResolutionPreset.high);
    when(() => mockRepository.isOnboardingCompleted).thenReturn(false);
    when(() => mockRepository.setInvertedViewfinder(any())).thenAnswer((_) async {});
    when(() => mockRepository.setImageQuality(any())).thenAnswer((_) async {});
    when(() => mockRepository.setOnboardingCompleted()).thenAnswer((_) async {});
  });

  group('SettingsBloc', () {
    test('initial state reflects repository values', () {
      final bloc = SettingsBloc(repository: mockRepository);

      expect(bloc.state.isInvertedViewfinder, true);
      expect(bloc.state.imageQuality, ResolutionPreset.high);
      expect(bloc.state.isOnboardingCompleted, false);

      bloc.close();
    });

    blocTest<SettingsBloc, SettingsState>(
      'emits updated state when LoadSettings is added',
      setUp: () {
        when(() => mockRepository.isInvertedViewfinderEnabled).thenReturn(false);
        when(() => mockRepository.imageQuality).thenReturn(ResolutionPreset.medium);
        when(() => mockRepository.isOnboardingCompleted).thenReturn(true);
      },
      build: () => SettingsBloc(repository: mockRepository),
      act: (bloc) => bloc.add(LoadSettings()),
      expect: () => [
        const SettingsState(
          isInvertedViewfinder: false,
          imageQuality: ResolutionPreset.medium,
          isOnboardingCompleted: true,
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits state with inverted viewfinder enabled when ToggleInvertedViewfinder(true) is added',
      build: () => SettingsBloc(repository: mockRepository),
      seed: () => const SettingsState(
        isInvertedViewfinder: false,
        imageQuality: ResolutionPreset.high,
        isOnboardingCompleted: false,
      ),
      act: (bloc) => bloc.add(const ToggleInvertedViewfinder(true)),
      expect: () => [
        const SettingsState(
          isInvertedViewfinder: true,
          imageQuality: ResolutionPreset.high,
          isOnboardingCompleted: false,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.setInvertedViewfinder(true)).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits state with inverted viewfinder disabled when ToggleInvertedViewfinder(false) is added',
      build: () => SettingsBloc(repository: mockRepository),
      seed: () => const SettingsState(
        isInvertedViewfinder: true,
        imageQuality: ResolutionPreset.high,
        isOnboardingCompleted: false,
      ),
      act: (bloc) => bloc.add(const ToggleInvertedViewfinder(false)),
      expect: () => [
        const SettingsState(
          isInvertedViewfinder: false,
          imageQuality: ResolutionPreset.high,
          isOnboardingCompleted: false,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.setInvertedViewfinder(false)).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits state with new image quality when SetImageQuality is added',
      build: () => SettingsBloc(repository: mockRepository),
      seed: () => const SettingsState(
        isInvertedViewfinder: true,
        imageQuality: ResolutionPreset.high,
        isOnboardingCompleted: false,
      ),
      act: (bloc) => bloc.add(const SetImageQuality(ResolutionPreset.medium)),
      expect: () => [
        const SettingsState(
          isInvertedViewfinder: true,
          imageQuality: ResolutionPreset.medium,
          isOnboardingCompleted: false,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.setImageQuality(ResolutionPreset.medium)).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits state with onboarding completed when CompleteOnboarding is added',
      build: () => SettingsBloc(repository: mockRepository),
      seed: () => const SettingsState(
        isInvertedViewfinder: true,
        imageQuality: ResolutionPreset.high,
        isOnboardingCompleted: false,
      ),
      act: (bloc) => bloc.add(CompleteOnboarding()),
      expect: () => [
        const SettingsState(
          isInvertedViewfinder: true,
          imageQuality: ResolutionPreset.high,
          isOnboardingCompleted: true,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.setOnboardingCompleted()).called(1);
      },
    );
  });

  group('SettingsEvent', () {
    test('ToggleInvertedViewfinder props are correct', () {
      const event = ToggleInvertedViewfinder(true);
      expect(event.props, [true]);
    });

    test('SetImageQuality props are correct', () {
      const event = SetImageQuality(ResolutionPreset.medium);
      expect(event.props, [ResolutionPreset.medium]);
    });

    test('LoadSettings props are empty', () {
      final event = LoadSettings();
      expect(event.props, isEmpty);
    });

    test('CompleteOnboarding props are empty', () {
      final event = CompleteOnboarding();
      expect(event.props, isEmpty);
    });
  });

  group('SettingsState', () {
    test('copyWith works correctly', () {
      const state = SettingsState(
        isInvertedViewfinder: true,
        imageQuality: ResolutionPreset.high,
        isOnboardingCompleted: false,
      );

      final updated = state.copyWith(isInvertedViewfinder: false);
      expect(updated.isInvertedViewfinder, false);
      expect(updated.imageQuality, ResolutionPreset.high);
      expect(updated.isOnboardingCompleted, false);
    });

    test('copyWith with all parameters', () {
      const state = SettingsState(
        isInvertedViewfinder: true,
        imageQuality: ResolutionPreset.high,
        isOnboardingCompleted: false,
      );

      final updated = state.copyWith(
        isInvertedViewfinder: false,
        imageQuality: ResolutionPreset.low,
        isOnboardingCompleted: true,
      );

      expect(updated.isInvertedViewfinder, false);
      expect(updated.imageQuality, ResolutionPreset.low);
      expect(updated.isOnboardingCompleted, true);
    });

    test('props are correct', () {
      const state = SettingsState(
        isInvertedViewfinder: true,
        imageQuality: ResolutionPreset.high,
        isOnboardingCompleted: false,
      );
      expect(state.props, [true, ResolutionPreset.high, false]);
    });

    test('equality', () {
      const state1 = SettingsState(
        isInvertedViewfinder: true,
        imageQuality: ResolutionPreset.high,
        isOnboardingCompleted: false,
      );
      const state2 = SettingsState(
        isInvertedViewfinder: true,
        imageQuality: ResolutionPreset.high,
        isOnboardingCompleted: false,
      );
      const state3 = SettingsState(
        isInvertedViewfinder: false,
        imageQuality: ResolutionPreset.high,
        isOnboardingCompleted: false,
      );

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });
  });
}
