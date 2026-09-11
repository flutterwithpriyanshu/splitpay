import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Cross-device push via Firebase Cloud Messaging. Needs Blaze plan
/// since send-side runs in a Cloud Function (Admin SDK).
/// Replaces OneSignalService — same job: save token, clear on logout,
/// show foreground notifs. Actual SEND now happens server-side via
/// Firestore trigger on `bills/{billId}`, not from client code.
class FcmService {
  static final _db = FirebaseFirestore.instance;
  static final _messaging = FirebaseMessaging.instance;
  static final _localPlugin = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationDetails(
    'bill_activity',
    'Bill activity',
    channelDescription: 'Notifications for bill add, edit, delete, settle up',
    importance: Importance.high,
    priority: Priority.high,
  );

  static Future<void> init() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) await _saveToken(token);

    _messaging.onTokenRefresh.listen((newToken) => _saveToken(newToken));

    // Token may exist at boot but user was null then — re-save once
    // login completes, same reasoning as old OneSignal flow.
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) return;
      final currentToken = await _messaging.getToken();
      if (currentToken != null && currentToken.isNotEmpty) {
        await _saveToken(currentToken);
      }
    });

    // Foreground messages don't auto-show a system notif on Android —
    // show one manually via existing flutter_local_notifications setup.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _localPlugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: notification.title ?? '',
        body: notification.body ?? '',
        notificationDetails: const NotificationDetails(
          android: _channel,
          iOS: DarwinNotificationDetails(),
        ),
      );
    });
  }

  /// Call right after sign-in / sign-up completes, same spot
  /// OneSignalService.saveIdForCurrentUser() was called.
  static Future<void> saveTokenForCurrentUser() async {
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) await _saveToken(token);
  }

  static Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  /// Call on logout so this device stops getting pushes for an
  /// account it's no longer signed into.
  static Future<void> clearToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).update({
      'fcmToken': FieldValue.delete(),
    });
  }
}
