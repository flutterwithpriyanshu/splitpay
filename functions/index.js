import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitpay/model/bill.dart';

class BillService {
  static final _db = FirebaseFirestore.instance;

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static Stream<List<Bill>> streamBills() {
    return _db
        .collection('bills')
        .where('ownerId', isEqualTo: _uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Bill.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  static Stream<List<Bill>> streamBillsForFriend(String friendId) {
    return _db
        .collection('bills')
        .where('ownerId', isEqualTo: _uid)
        .where('friendIds', arrayContains: friendId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Bill.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Bills where you're a linked participant, but someone ELSE created them.
  static Stream<List<Bill>> streamSharedBills() {
    return _db
        .collection('bills')
        .where('participantUids', arrayContains: _uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Bill.fromFirestore(doc.id, doc.data()))
              .where((bill) => bill.ownerId != _uid)
              .toList(),
        );
  }

  /// Bills created by [otherUid] that include you as a participant.
  static Stream<List<Bill>> streamSharedBillsFrom(String otherUid) {
    return _db
        .collection('bills')
        .where('ownerId', isEqualTo: otherUid)
        .where('participantUids', arrayContains: _uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Bill.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// All bills tagged with [groupId] that involve you — no matter who in
  /// the group actually created the bill. Works because a bill's creator
  /// is always included in their own `participantUids`, so "tagged with
  /// this group AND I'm a participant" catches every group bill I'm part
  /// of, whether I'm the group owner or just a member who added it.
  ///
  /// This is what lets ANY member add a bill to the group (not just the
  /// owner) and have it show up for everyone in the group.
  static Stream<List<Bill>> streamGroupBills(String groupId) {
    return _db
        .collection('bills')
        .where('groupId', isEqualTo: groupId)
        .where('participantUids', arrayContains: _uid)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((doc) => Bill.fromFirestore(doc.id, doc.data()))
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date)),
        );
  }

  /// Push notifications for add/edit/delete/settle are handled entirely
  /// server-side — a Cloud Functions trigger on `bills/{billId}` (create,
  /// update, delete) reads `participantUids` off the doc and sends FCM to
  /// every one of them (owner + friend + every group member), using each
  /// user's `fcmToken` saved by FcmService. Nothing to call from here.
  static Future<void> addBill(Bill bill) async {
    await _db.collection('bills').add(bill.toFirestore(_uid));
  }

  static Future<void> updateBill(String billId, Bill bill) async {
    final existing = await _db.collection('bills').doc(billId).get();
    if (!existing.exists || existing.data()?['ownerId'] != _uid) {
      throw StateError('Only the person who added this bill can edit it');
    }
    await _db.collection('bills').doc(billId).update({
      'title': bill.title,
      'amount': bill.amount,
      'date': bill.date,
      'friendIds': bill.friendIds,
      'splitMethod': bill.splitMethod,
      'customAmounts': bill.customAmounts,
      'myShare': bill.myShare,
      'paidBy': bill.paidBy,
      'note': bill.note,
      'participantUids': bill.participantUids,
      'sharesByUid': bill.sharesByUid,
      'paidByUid': bill.paidByUid,
      // settledFriendIds and settledUids intentionally NOT touched here.
    });
  }

  static Future<void> deleteBill(String billId) async {
    final doc = await _db.collection('bills').doc(billId).get();
    if (!doc.exists || doc.data()?['ownerId'] != _uid) {
      throw StateError('Only the person who added this bill can delete it');
    }
    await _db.collection('bills').doc(billId).delete();
  }

  /// Applies a custom payment amount toward your balance with [friendId],
  /// spreading it across their oldest unpaid bills first (both bills you
  /// created, and — if linked — bills they created that include you).
  static Future<void> settlePartialForFriend({
    required String friendId,
    String? linkedUid,
    required bool youOwe,
    required double amount,
  }) async {
    double remainingToApply = amount;
    final batch = _db.batch();

    // ----- Bills YOU created -----
    final ownSnap = await _db
        .collection('bills')
        .where('ownerId', isEqualTo: _uid)
        .where('friendIds', arrayContains: friendId)
        .orderBy('date')
        .get();

    for (final doc in ownSnap.docs) {
      if (remainingToApply <= 0.009) break;
      final bill = Bill.fromFirestore(doc.id, doc.data());

      if (youOwe) {
        if (bill.paidBy != friendId) {
          continue; // only bills where this friend paid
        }
        final owed = bill.remainingMyShare;
        if (owed <= 0.009) continue;
        final pay = owed < remainingToApply ? owed : remainingToApply;
        final newPaid = bill.myPartialPayment + pay;
        remainingToApply -= pay;

        final update = <String, dynamic>{'myPartialPayment': newPaid};
        if (bill.myShare - newPaid <= 0.009) {
          final settledFriendIds = List<String>.from(bill.settledFriendIds);
          if (!settledFriendIds.contains(friendId)) {
            settledFriendIds.add(friendId);
          }
          update['settledFriendIds'] = settledFriendIds;
          if (linkedUid != null) {
            final settledUids = List<String>.from(bill.settledUids);
            if (!settledUids.contains(linkedUid)) settledUids.add(linkedUid);
            update['settledUids'] = settledUids;
          }
        }
        batch.update(doc.reference, update);
      } else {
        if (bill.paidBy != 'me') continue; // only bills where you paid
        final owed = bill.remainingForFriend(friendId);
        if (owed <= 0.009) continue;
        final pay = owed < remainingToApply ? owed : remainingToApply;
        final paymentsMap = Map<String, double>.from(
          bill.partialPaymentsByFriend,
        );
        paymentsMap[friendId] = (paymentsMap[friendId] ?? 0) + pay;
        remainingToApply -= pay;

        final update = <String, dynamic>{
          'partialPaymentsByFriend': paymentsMap,
        };
        if (bill.shareForFriend(friendId) - paymentsMap[friendId]! <= 0.009) {
          final settledFriendIds = List<String>.from(bill.settledFriendIds);
          if (!settledFriendIds.contains(friendId)) {
            settledFriendIds.add(friendId);
          }
          update['settledFriendIds'] = settledFriendIds;
          if (linkedUid != null) {
            final settledUids = List<String>.from(bill.settledUids);
            if (!settledUids.contains(linkedUid)) settledUids.add(linkedUid);
            update['settledUids'] = settledUids;
          }
        }
        batch.update(doc.reference, update);
      }
    }

    // ----- Bills THEY created that include you (linked friends only) -----
    if (linkedUid != null && remainingToApply > 0.009) {
      final sharedSnap = await _db
          .collection('bills')
          .where('ownerId', isEqualTo: linkedUid)
          .where('participantUids', arrayContains: _uid)
          .orderBy('date')
          .get();

      for (final doc in sharedSnap.docs) {
        if (remainingToApply <= 0.009) break;
        final bill = Bill.fromFirestore(doc.id, doc.data());
        final owed = bill.remainingForUid(_uid);
        if (owed <= 0.009) continue;
        final pay = owed < remainingToApply ? owed : remainingToApply;
        final paymentsMap = Map<String, double>.from(bill.partialPaymentsByUid);
        paymentsMap[_uid] = (paymentsMap[_uid] ?? 0) + pay;
        remainingToApply -= pay;

        final update = <String, dynamic>{'partialPaymentsByUid': paymentsMap};
        if ((bill.sharesByUid[_uid] ?? 0) - paymentsMap[_uid]! <= 0.009) {
          final settledUids = List<String>.from(bill.settledUids);
          if (!settledUids.contains(_uid)) settledUids.add(_uid);
          update['settledUids'] = settledUids;
        }
        batch.update(doc.reference, update);
      }
    }

    await batch.commit();
    // Settlement doc writes above trigger the same bills/{billId} Cloud
    // Function used for add/edit/delete, so FCM for settlement goes out
    // from there too — no separate call needed here.
  }

  /// Marks YOUR OWN participation as settled on every bill created by
  /// [otherUid] that includes you. Only touches your own settledUids entry.
  static Future<void> settleSharedBillsFrom(String otherUid) async {
    final snap = await _db
        .collection('bills')
        .where('ownerId', isEqualTo: otherUid)
        .where('participantUids', arrayContains: _uid)
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      final settled = List<String>.from(doc.data()['settledUids'] ?? []);
      if (!settled.contains(_uid)) {
        settled.add(_uid);
        batch.update(doc.reference, {'settledUids': settled});
      }
    }
    await batch.commit();
  }
}