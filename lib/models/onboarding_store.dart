import 'package:shared_preferences/shared_preferences.dart';

abstract final class OnboardingStore {
  static const completedKey = 'onboarding_complete_v1';

  static Future<bool> hasCompleted() async {
    try {
      return await SharedPreferencesAsync().getBool(completedKey) ?? false;
    } catch (_) {
      try {
        return (await SharedPreferences.getInstance()).getBool(completedKey) ??
            false;
      } catch (_) {
        return false;
      }
    }
  }

  static Future<void> markCompleted() async {
    try {
      await SharedPreferencesAsync().setBool(completedKey, true);
    } catch (_) {
      await (await SharedPreferences.getInstance()).setBool(completedKey, true);
    }
  }
}
