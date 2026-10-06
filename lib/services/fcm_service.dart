import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:splitpay/core/app_navigator.dart';
import 'package:splitpay/services/local_notification_service.dart';
import 'package:splitpay/screens/group_settle_up/group_settle_up_screen.dart';
import 'package:splitpay/services/group_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
    LocalNotificationService.onNotificationTap = _openPaymentLink;
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
      final upiUri = message.data['upiUri'];
      _localPlugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: notification.title ?? '',
        body: notification.body ?? '',
        payload: upiUri is String ? upiUri : null,
        notificationDetails: const NotificationDetails(
          android: _channel,
          iOS: DarwinNotificationDetails(),
        ),
      );
    });

    // Background tap + terminated-app tap.
    FirebaseMessaging.onMessageOpenedApp.listen(_openFromMessage);
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _openFromMessage(initial);
  }

  static Future<void> _openPaymentLink(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'upi' || uri.host != 'pay') {
      debugPrint('Ignoring invalid UPI link notification payload.');
      return;
    }
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) debugPrint('No app could open the UPI payment link.');
    } catch (error, stackTrace) {
      debugPrint('Could not open UPI payment link: $error\n$stackTrace');
    }
  }

  /// Push taps open a UPI link or the associated group settle-up screen.
  static Future<void> _openFromMessage(RemoteMessage message) async {
    final upiUri = message.data['upiUri'];
    if (upiUri is String && upiUri.isNotEmpty) {
      await _openPaymentLink(upiUri);
      return;
    }
    final groupId = message.data['groupId'];
    if (groupId is! String || groupId.isEmpty) return;
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      final group = await GroupService.streamGroup(groupId).first;
      // Cold start: navigator may not be mounted yet.
      for (var i = 0; i < 10 && appNavigatorKey.currentState == null; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      appNavigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => GroupSettleUpScreen(group: group)),
      );
    } catch (e) {
      debugPrint('Open settle up from push failed: $e');
    }
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
