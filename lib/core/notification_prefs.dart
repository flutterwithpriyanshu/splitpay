import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';


final ValueNotifier<int> notificationLastSeenNotifier = ValueNotifier<int>(0);

class NotificationPrefs {
  static const _key = 'notif_last_seen_ms_';
  static String? _uid;

  /// Call once per signed-in user. First run on a device marks everything
  /// already there as read, so a new install is not flooded with dots.
  static Future<void> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    var v = prefs.getInt('$_key$uid');
    if (v == null) {
      v = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt('$_key$uid', v);
    }
    _uid = uid;
    notificationLastSeenNotifier.value = v;
  }

  static Future<void> markAllRead() async {
    final uid = _uid;
    if (uid == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    notificationLastSeenNotifier.value = now;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_key$uid', now);
  }
}
