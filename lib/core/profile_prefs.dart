import 'package:shared_preferences/shared_preferences.dart';

class ProfilePrefs {
  static const _key = 'profile_complete_uid';
  static const _upiKeyPrefix = 'saved_upi_';

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

  /// Device-side copy of the user's UPI, used only when Firestore can't be
  /// reached while pre-filling the complete-profile form.
  static Future<String?> getSavedUpi(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_upiKeyPrefix$uid');
  }

  static Future<void> saveUpi(String uid, String upi) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_upiKeyPrefix$uid', upi);
  }
}
