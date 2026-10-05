import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:splitpay/core/phone_utils.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Payment reminder to someone who owes you.
/// In-app = Firestore doc `reminders/{groupId}_{from}_{to}` (one per pair,
/// overwritten each send). Cloud Function on that doc sends the FCM push
/// (same pattern as `bills/{billId}` trigger). WhatsApp = wa.me deep link.
class ReminderService {
  static final _db = FirebaseFirestore.instance;
  static const cooldown = Duration(hours: 6);

  static String _docId(String groupId, String fromUid, String toUid) =>
      '${groupId}_${fromUid}_$toUid';

  static String defaultMessage({
    required String name,
    required String amount,
    required String groupName,
  }) =>
      'Hi $name, friendly reminder: you owe me $amount in "$groupName". '
      'Please settle up when you can. Thanks!';

  /// Time left before next in-app reminder allowed. Zero = can send.
  static Future<Duration> cooldownLeft({
    required String groupId,
    required String toUid,
  }) async {
    final me = FirebaseAuth.instance.currentUser!.uid;
    final snap = await _db
        .collection('reminders')
        .doc(_docId(groupId, toUid, me))
        .get();
    final ts = snap.data()?['createdAt'];
    if (ts is! Timestamp) return Duration.zero;
    final left = cooldown - DateTime.now().difference(ts.toDate());
    return left.isNegative ? Duration.zero : left;
  }

  /// Debtor = person who owes me. Doc id keyed debtor->me.
  static Future<void> sendInApp({
    required String groupId,
    required String groupName,
    required String debtorUid,
    required double amount,
    required String message,
  }) async {
    final me = FirebaseAuth.instance.currentUser!.uid;
    final myName =
        (await FriendService.getMyProfile())?['fullName'] ?? 'A friend';
    await _db.collection('reminders').doc(_docId(groupId, debtorUid, me)).set({
      'groupId': groupId,
      'groupName': groupName,
      'fromUid': debtorUid, // owes
      'toUid': me, // is owed
      'toUidName': myName,
      'amount': amount,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Opens WhatsApp chat with prefilled text. Returns false if no number / no app.
  static Future<bool> sendWhatsApp({
    required String debtorUid,
    required String message,
  }) async {
    final phone = normalizePhone(await FriendService.getUserPhone(debtorUid));
    if (phone.isEmpty) return false;
    final uri = Uri.parse(
      'https://wa.me/91$phone?text=${Uri.encodeComponent(message)}',
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<void> copy(String message) =>
      Clipboard.setData(ClipboardData(text: message));
}
