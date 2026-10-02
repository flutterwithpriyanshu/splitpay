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

  /// Returns the amount actually applied to bills (can be less than
  /// [amount] when no matching bill is left for this payer).
  static Future<double> settleGroupPayment({
    required String groupId,
    required String fromUid,
    required String toUid,
    required double amount,
  }) async {
    double remainingToApply = amount;
    final batch = _db.batch();
    var touched = 0;

    final snap = await _db
        .collection('bills')
        .where('groupId', isEqualTo: groupId)
        .where('participantUids', arrayContains: _uid)
        .get();

    // Sort client-side (oldest first) — avoids needing a composite index.
    final docs = snap.docs.toList()
      ..sort((a, b) {
        final da = (a.data()['date'] as Timestamp?)?.toDate() ?? DateTime(0);
        final db = (b.data()['date'] as Timestamp?)?.toDate() ?? DateTime(0);
        return da.compareTo(db);
      });

    for (final doc in docs) {
      if (remainingToApply <= 0.009) break;
      final bill = Bill.fromFirestore(doc.id, doc.data());
      final payerUid = bill.paidByUid ?? bill.ownerId;
      if (payerUid != toUid) continue; // only bills toUid actually paid
      if (!bill.participantUids.contains(fromUid)) continue;

      final owed = bill.remainingForUid(fromUid);
      if (owed <= 0.009) continue;
      final pay = owed < remainingToApply ? owed : remainingToApply;
      remainingToApply -= pay;

      final paymentsMap = Map<String, double>.from(bill.partialPaymentsByUid);
      paymentsMap[fromUid] = (paymentsMap[fromUid] ?? 0) + pay;

      final update = <String, dynamic>{'partialPaymentsByUid': paymentsMap};
      if ((bill.sharesByUid[fromUid] ?? 0) - paymentsMap[fromUid]! <= 0.009) {
        final settledUids = List<String>.from(bill.settledUids);
        if (!settledUids.contains(fromUid)) settledUids.add(fromUid);
        update['settledUids'] = settledUids;
      }
      batch.update(doc.reference, update);
      touched++;
    }

    if (touched == 0) return 0;
    await batch.commit();
    return amount - remainingToApply;
  }

  static Future<void> deleteBill(String billId) async {
    final doc = await _db.collection('bills').doc(billId).get();
    if (!doc.exists || doc.data()?['ownerId'] != _uid) {
      throw StateError('Only the person who added this bill can delete it');
    }
    await _db.collection('bills').doc(billId).delete();
  }

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
  }

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
