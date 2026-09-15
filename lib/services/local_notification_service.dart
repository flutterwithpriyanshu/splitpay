import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:splitpay/core/app_currency.dart';

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

  static const _settleChannel = AndroidNotificationDetails(
    'settle_up_reminders',
    'Settle up reminders',
    channelDescription: 'Monthly reminder to settle up group balances',
    importance: Importance.high,
    priority: Priority.high,
  );

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    // NOTE: without the `flutter_timezone` plugin we can't ask the OS for
    // the device's IANA zone name, so scheduled times use UTC as the
    // reference clock. Add `flutter_timezone` + `tz.setLocalLocation(...)`
    // for pixel-perfect "10:00 AM local time" scheduling; until then the
    // monthly reminder may land a few hours off from 10:00 AM depending on
    // the device's timezone offset (the day itself is still correct).

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
    );

    // Android 13+ needs the runtime notification permission separately.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static Future<void> _show(String title, String body) async {
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique-ish id
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: _channel,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> billAdded(String title, double amount) =>
      _show('Bill added', '"$title" for ${AppCurrency.symbol}$amount added.');

  static Future<void> billEdited(String title) =>
      _show('Bill updated', '"$title" was updated.');

  static Future<void> billDeleted(String title) =>
      _show('Bill deleted', '"$title" was deleted.');

  static Future<void> settledUp({String? friendName, double? amount}) => _show(
    'Settled up',
    friendName != null
        ? 'You settled up with $friendName${amount != null ? ' (${AppCurrency.symbol}$amount)' : ''}.'
        : 'Settlement recorded.',
  );

  /// Stable per-group notification id so re-scheduling the same group
  /// overwrites its previous reminder instead of stacking duplicates.
  static int _settleReminderId(String groupId) =>
      0x53455454 ^ groupId.hashCode; // 'SETT' prefix, keeps ids app-specific

  /// Finds the next date/time this month (or next month, if this month's
  /// day has already passed) that this device's local clock will hit
  /// [day] at 10:00 AM. Clamps to the last day of the month for groups
  /// created with day 29/30/31 in a shorter month (e.g. Feb).
  static DateTime _nextOccurrence(int day) {
    final now = DateTime.now();

    DateTime candidateFor(int year, int month) {
      final lastDayOfMonth = DateTime(year, month + 1, 0).day;
      final clampedDay = day > lastDayOfMonth ? lastDayOfMonth : day;
      return DateTime(year, month, clampedDay, 10, 0);
    }

    var candidate = candidateFor(now.year, now.month);
    if (!candidate.isAfter(now)) {
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;
      candidate = candidateFor(nextYear, nextMonth);
    }
    return candidate;
  }

  /// Schedules (or reschedules) this device's monthly "settle up" reminder
  /// for a group. Every member calls this locally (from their own app,
  /// whenever the group's `settleUpDay` changes) so each person gets a
  /// reminder phrased around THEIR OWN balance in that group.
  /// Schedules (or reschedules) this device's monthly "settle up" reminder
  /// for a group. Every member calls this locally (from their own app,
  /// whenever the group's `settleUpDay` changes) so each person gets a
  /// reminder phrased around THEIR OWN balance in that group.
  ///
  /// [counterparts]: who THIS user owes / is owed by in the group, so the
  /// notification can name names instead of just a lump-sum total.
  /// Key = other member's display name, value = signed amount from this
  /// user's point of view (positive = they owe you, negative = you owe
  /// them). Pass an empty map to fall back to the old lump-sum wording.
  static Future<void> scheduleMonthlySettleReminder({
    required String groupId,
    required String groupName,
    required int day,
    required double myNetBalance,
    Map<String, double> counterparts = const {},
  }) async {
    await init();

    final String body;
    if (myNetBalance.abs() <= 0.01) {
      body = 'Time to check "$groupName" — looks settled, nice!';
    } else if (counterparts.isNotEmpty) {
      final lines = counterparts.entries
          .where((e) => e.value.abs() > 0.01)
          .map(
            (e) => e.value > 0
                ? '${e.key} owes you ${AppCurrency.symbol}${e.value.toStringAsFixed(2)}'
                : '${e.key}: you owe ${AppCurrency.symbol}${(-e.value).toStringAsFixed(2)}',
          )
          .join(', ');
      body = lines.isEmpty
          ? 'Time to check "$groupName" — looks settled, nice!'
          : 'Settle up in "$groupName": $lines.';
    } else {
      body = myNetBalance > 0
          ? 'You are owed ${AppCurrency.symbol}${myNetBalance.toStringAsFixed(2)} in "$groupName". Time to settle up!'
          : 'You owe ${AppCurrency.symbol}${(-myNetBalance).toStringAsFixed(2)} in "$groupName". Time to settle up!';
    }

    final scheduledDate = tz.TZDateTime.from(_nextOccurrence(day), tz.local);

    await _plugin.zonedSchedule(
      id: _settleReminderId(groupId),
      title: 'Settle up reminder',
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: _settleChannel,
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  static Future<void> cancelSettleReminder(String groupId) =>
      _plugin.cancel(id: _settleReminderId(groupId));
}
