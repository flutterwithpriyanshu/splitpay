import 'package:shared_preferences/shared_preferences.dart';

/// Caches "profile setup finished" locally so re-opening the app can go
/// straight to MainShell without waiting on a Firestore round trip.
/// Keyed by uid so a different account signing in on the same device
/// never wrongly inherits another account's completed state.
class ProfilePrefs {
  static const _key = 'profile_complete_uid';

  static Future<bool> isProfileComplete(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) == uid;
  }

  static Future<void> setProfileComplete(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, uid);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
