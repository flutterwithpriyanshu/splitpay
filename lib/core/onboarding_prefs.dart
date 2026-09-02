import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the intro screen has ever been shown on this device.
class OnboardingPrefs {
  static const _key = 'has_seen_intro';

  static Future<bool> hasSeenIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> setSeenIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
