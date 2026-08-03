enum TransactionType { sent, received }

class WalletTransaction {
  final String id;
  final String personName;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final bool isCompleted;
  final String? note;

  WalletTransaction({
    required this.id,
    required this.personName,
    required this.amount,
    required this.date,
    required this.type,
    required this.isCompleted,
    this.note,
  });

  factory WalletTransaction.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return WalletTransaction(
      id: id,
      personName: data['personName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as dynamic).toDate(),
      type: data['type'] == 'received'
          ? TransactionType.received
          : TransactionType.sent,
      isCompleted: data['isCompleted'] ?? true,
      note: data['note'],
    );
  }

  Map<String, dynamic> toFirestore(String ownerId, {String? initiatedBy}) {
    return {
      'ownerId': ownerId,
      'initiatedBy': initiatedBy ?? ownerId,
      'personName': personName,
      'amount': amount,
      'date': date,
      'type': type == TransactionType.received ? 'received' : 'sent',
      'isCompleted': isCompleted,
      'note': note,
      'createdAt': DateTime.now(),
    };
  }
}
