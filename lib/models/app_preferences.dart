import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  const AppPreferences({
    this.showTemplateGuides = true,
    this.autoRotatePreview = true,
    this.confirmBeforeClear = true,
  });

  final bool showTemplateGuides;
  final bool autoRotatePreview;
  final bool confirmBeforeClear;

  AppPreferences copyWith({
    bool? showTemplateGuides,
    bool? autoRotatePreview,
    bool? confirmBeforeClear,
  }) {
    return AppPreferences(
      showTemplateGuides: showTemplateGuides ?? this.showTemplateGuides,
      autoRotatePreview: autoRotatePreview ?? this.autoRotatePreview,
      confirmBeforeClear: confirmBeforeClear ?? this.confirmBeforeClear,
    );
  }
}

abstract final class AppPreferencesStore {
  static const _showTemplateGuidesKey = 'show_template_guides';
  static const _autoRotatePreviewKey = 'auto_rotate_preview';
  static const _confirmBeforeClearKey = 'confirm_before_clear';

  static final SharedPreferencesAsync _storage = SharedPreferencesAsync();

  static Future<AppPreferences> load() async {
    try {
      return AppPreferences(
        showTemplateGuides:
            await _storage.getBool(_showTemplateGuidesKey) ?? true,
        autoRotatePreview:
            await _storage.getBool(_autoRotatePreviewKey) ?? true,
        confirmBeforeClear:
            await _storage.getBool(_confirmBeforeClearKey) ?? true,
      );
    } catch (_) {
      return const AppPreferences();
    }
  }

  static Future<void> save(AppPreferences preferences) async {
    await Future.wait([
      _storage.setBool(_showTemplateGuidesKey, preferences.showTemplateGuides),
      _storage.setBool(_autoRotatePreviewKey, preferences.autoRotatePreview),
      _storage.setBool(_confirmBeforeClearKey, preferences.confirmBeforeClear),
    ]);
  }

  static Future<void> reset() async {
    await Future.wait([
      _storage.remove(_showTemplateGuidesKey),
      _storage.remove(_autoRotatePreviewKey),
      _storage.remove(_confirmBeforeClearKey),
    ]);
  }
}
