import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// On-device notifications for bill add/edit/delete/settle — no server,
/// no Cloud Functions, works fine on the free (Spark) Firebase plan.
class LocalNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channel = AndroidNotificationDetails(
    'bill_activity',
    'Bill activity',
    channelDescription: 'Notifications for bill add, edit, delete, settle up',
    importance: Importance.high,
    priority: Priority.high,
  );

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Android 13+ needs the runtime notification permission separately.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> _show(String title, String body) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique-ish id
      title,
      body,
      const NotificationDetails(
        android: _channel,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> billAdded(String title, double amount) =>
      _show('Bill added', '"$title" for ₹$amount added.');

  static Future<void> billEdited(String title) =>
      _show('Bill updated', '"$title" was updated.');

  static Future<void> billDeleted(String title) =>
      _show('Bill deleted', '"$title" was deleted.');

  static Future<void> settledUp({String? friendName, double? amount}) =>
      _show(
        'Settled up',
        friendName != null
            ? 'You settled up with $friendName${amount != null ? ' (₹$amount)' : ''}.'
            : 'Settlement recorded.',
      );
}
