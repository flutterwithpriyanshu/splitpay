import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitpay/model/transaction.dart';

class TransactionService {
  static final _db = FirebaseFirestore.instance;

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static Stream<List<WalletTransaction>> streamTransactions() {
    return _db
        .collection('transactions')
        .where('ownerId', isEqualTo: _uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => WalletTransaction.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Adds a transaction to YOUR OWN wallet.
  static Future<void> addTransaction({
    required String personName,
    required double amount,
    required TransactionType type,
    String? note,
  }) async {
    final tx = WalletTransaction(
      id: '',
      personName: personName,
      amount: amount,
      date: DateTime.now(),
      type: type,
      isCompleted: true,
      note: note,
    );
    await _db.collection('transactions').add(tx.toFirestore(_uid));
  }

  /// Adds a MIRRORED transaction into a linked friend's wallet.
  /// ownerId = the friend (so it shows on THEIR wallet),
  /// initiatedBy = you (so security rules allow this write).
  static Future<void> addTransactionForUid({
    required String targetUid,
    required String personName,
    required double amount,
    required TransactionType type,
    String? note,
  }) async {
    final tx = WalletTransaction(
      id: '',
      personName: personName,
      amount: amount,
      date: DateTime.now(),
      type: type,
      isCompleted: true,
      note: note,
    );
    await _db
        .collection('transactions')
        .add(tx.toFirestore(targetUid, initiatedBy: _uid));
  }
}
