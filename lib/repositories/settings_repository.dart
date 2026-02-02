import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import '../models/photo.dart';

class SettingsRepository {
  static const String _keyInvertedViewfinder = 'inverted_viewfinder';
  static const String _keyImageQuality = 'image_quality';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keySelectedFilter = 'selected_filter';

  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  bool get isInvertedViewfinderEnabled => _prefs.getBool(_keyInvertedViewfinder) ?? true;

  Future<void> setInvertedViewfinder(bool value) async {
    await _prefs.setBool(_keyInvertedViewfinder, value);
  }

  ResolutionPreset get imageQuality {
    final String? value = _prefs.getString(_keyImageQuality);
    if (value == 'medium') return ResolutionPreset.medium;
    return ResolutionPreset.high; // Default to high
  }

  Future<void> setImageQuality(ResolutionPreset preset) async {
    String value = 'high';
    if (preset == ResolutionPreset.medium) value = 'medium';
    await _prefs.setString(_keyImageQuality, value);
  }

  bool get isOnboardingCompleted => _prefs.getBool(_keyOnboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted() async {
    await _prefs.setBool(_keyOnboardingCompleted, true);
  }

  /// Récupère le filtre sélectionné (persiste entre les sessions)
  FilterType get selectedFilter {
    final int? index = _prefs.getInt(_keySelectedFilter);
    if (index == null || index < 0 || index >= FilterType.values.length) {
      return FilterType.none;
    }
    return FilterType.values[index];
  }

  /// Sauvegarde le filtre sélectionné
  Future<void> setSelectedFilter(FilterType filter) async {
    await _prefs.setInt(_keySelectedFilter, filter.index);
  }
}
