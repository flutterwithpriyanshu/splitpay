import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Cross-device push via OneSignal — free tier, no Blaze plan need.
/// Handles SDK init, player-id save to Firestore, and sending pushes
/// to other users when a bill is added/edited/deleted/settled.
class OneSignalService {

  static const String _appId = 'app id';
  static const String _restApiKey =
      'key';

  static final _db = FirebaseFirestore.instance;

  static Future<void> init() async {
    OneSignal.initialize(_appId);
    await OneSignal.Notifications.requestPermission(true);

    final id = await OneSignal.User.pushSubscription.id;
    if (id != null && id.isNotEmpty) await _saveId(id);

    OneSignal.User.pushSubscription.addObserver((state) {
      final newId = state.current.id;
      if (newId != null && newId.isNotEmpty) _saveId(newId);
      // ignore: avoid_print
      print(
        'OneSignal subscription state -> id=${state.current.id}, optedIn=${state.current.optedIn}',
      );
    });

    // Player id may already exist at boot (from above) but user was null
    // then — re-save once login completes, since the observer above only
    // fires on player-id CHANGE, not on auth-state change.
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) return;
      final currentId = await OneSignal.User.pushSubscription.id;
      if (currentId != null && currentId.isNotEmpty) await _saveId(currentId);
    });
  }

  static Future<void> _saveId(String playerId) async {
    if (playerId.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).set({
      'oneSignalId': playerId,
    }, SetOptions(merge: true));
  }

  /// Call on logout so this device stops getting pushes for an
  /// account it's no longer signed into.
  static Future<void> clearId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).update({
      'oneSignalId': FieldValue.delete(),
    });
  }

  /// Sends a push to every uid in [uids] (skips [excludeUid], usually
  /// the current user) that has a saved OneSignal player id.
  static Future<void> notifyUids({
    required List<String> uids,
    required String excludeUid,
    required String title,
    required String body,
  }) async {
    final targets = uids.where((u) => u != excludeUid).toSet();
    if (targets.isEmpty) return;

    final playerIds = <String>[];
    for (final uid in targets) {
      final snap = await _db.collection('users').doc(uid).get();
      if (!snap.exists) {
        // ignore: avoid_print
        print('OneSignal: no users/$uid doc — friend link broken');
        continue;
      }
      final id = snap.data()?['oneSignalId'];
      if (id == null) {
        // ignore: avoid_print
        print(
          'OneSignal: users/$uid has no oneSignalId — never opened app / no push perm',
        );
        continue;
      }
      playerIds.add(id);
    }
    if (playerIds.isEmpty) {
      // ignore: avoid_print
      print('OneSignal: no valid playerIds for targets=$targets — skip send');
      return;
    }

    final resp = await http.post(
      Uri.parse('https://api.onesignal.com/notifications'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Key $_restApiKey',
      },
      body: jsonEncode({
        'app_id': _appId,
        'target_channel': 'push',
        'include_subscription_ids': playerIds,
        'headings': {'en': title},
        'contents': {'en': body},
      }),
    );
    // ignore: avoid_print
    print('OneSignal push -> ${resp.statusCode}: ${resp.body}');
  }
}
