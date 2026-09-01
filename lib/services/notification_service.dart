import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Handles push-notification setup: permission, token save, token refresh.
/// Call [init] once, right after a user is signed in (has a users/{uid} doc).
class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _db = FirebaseFirestore.instance;

  static Future<void> init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(user.uid, token);
    }

    // Token can rotate (reinstall, restore, etc.) — keep it fresh.
    _messaging.onTokenRefresh.listen((newToken) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) _saveToken(uid, newToken);
    });
  }

  static Future<void> _saveToken(String uid, String token) async {
    await _db.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  /// Call on logout so this device stops getting notifications for
  /// an account it's no longer signed into.
  static Future<void> clearToken() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await _messaging.getToken();
    if (user == null || token == null) return;
    await _db.collection('users').doc(user.uid).set({
      'fcmTokens': FieldValue.arrayRemove([token]),
    }, SetOptions(merge: true));
  }
}
