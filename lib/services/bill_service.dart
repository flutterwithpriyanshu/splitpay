import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/services/local_notification_service.dart';

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

  static Future<void> addBill(Bill bill) async {
    await _db.collection('bills').add(bill.toFirestore(_uid));
    await LocalNotificationService.billAdded(bill.title, bill.amount);
  }

  static Future<void> updateBill(String billId, Bill bill) async {
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
    await LocalNotificationService.billEdited(bill.title);
  }

  static Future<void> deleteBill(String billId) async {
    final doc = await _db.collection('bills').doc(billId).get();
    final title = doc.data()?['title'] ?? 'Bill';
    await _db.collection('bills').doc(billId).delete();
    await LocalNotificationService.billDeleted(title);
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
        if (bill.paidBy != friendId)
          continue; // only bills where this friend paid
        final owed = bill.remainingMyShare;
        if (owed <= 0.009) continue;
        final pay = owed < remainingToApply ? owed : remainingToApply;
        final newPaid = bill.myPartialPayment + pay;
        remainingToApply -= pay;

        final update = <String, dynamic>{'myPartialPayment': newPaid};
        if (bill.myShare - newPaid <= 0.009) {
          final settledFriendIds = List<String>.from(bill.settledFriendIds);
          if (!settledFriendIds.contains(friendId))
            settledFriendIds.add(friendId);
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
          if (!settledFriendIds.contains(friendId))
            settledFriendIds.add(friendId);
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

    final friendDoc = await _db.collection('friends').doc(friendId).get();
    final friendName = friendDoc.data()?['name'];
    await LocalNotificationService.settledUp(
      friendName: friendName,
      amount: amount,
    );
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
    await LocalNotificationService.settledUp();
  }
}
