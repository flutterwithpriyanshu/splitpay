class Bill {
  final String id;
  final String title;
  final double amount;
  final DateTime date;

  // --- Local (non-linked) friend fields ---
  final List<String> friendIds;
  final String splitMethod;
  final Map<String, double> customAmounts;
  final double myShare;
  final String paidBy;
  final String note;
  final List<String> settledFriendIds;

  // --- Partial payment tracking (local model) ---
  final Map<String, double>
  partialPaymentsByFriend; // friendId -> paid so far (when you're owed)
  final double
  myPartialPayment; // amount you've paid so far (when a friend paid)

  // --- Shared (linked) participant fields ---
  final String ownerId;
  final List<String> participantUids;
  final Map<String, double> sharesByUid;
  final String? paidByUid;
  final List<String> settledUids;
  final Map<String, double>
  partialPaymentsByUid; // uid -> paid so far toward their share

  Bill({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.friendIds,
    required this.splitMethod,
    required this.customAmounts,
    required this.myShare,
    required this.paidBy,
    required this.note,
    required this.settledFriendIds,
    required this.partialPaymentsByFriend,
    required this.myPartialPayment,
    required this.ownerId,
    required this.participantUids,
    required this.sharesByUid,
    this.paidByUid,
    required this.settledUids,
    required this.partialPaymentsByUid,
  });

  factory Bill.fromFirestore(String id, Map<String, dynamic> data) {
    return Bill(
      id: id,
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as dynamic).toDate(),
      friendIds: List<String>.from(data['friendIds'] ?? []),
      splitMethod: data['splitMethod'] ?? 'equal',
      customAmounts: Map<String, double>.from(
        (data['customAmounts'] ?? {}).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
      myShare: (data['myShare'] ?? 0).toDouble(),
      paidBy: data['paidBy'] ?? 'me',
      note: data['note'] ?? '',
      settledFriendIds: List<String>.from(data['settledFriendIds'] ?? []),
      partialPaymentsByFriend: Map<String, double>.from(
        (data['partialPaymentsByFriend'] ?? {}).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
      myPartialPayment: (data['myPartialPayment'] ?? 0).toDouble(),
      ownerId: data['ownerId'] ?? '',
      participantUids: List<String>.from(data['participantUids'] ?? []),
      sharesByUid: Map<String, double>.from(
        (data['sharesByUid'] ?? {}).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
      paidByUid: data['paidByUid'],
      settledUids: List<String>.from(data['settledUids'] ?? []),
      partialPaymentsByUid: Map<String, double>.from(
        (data['partialPaymentsByUid'] ?? {}).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
    );
  }

  Map<String, dynamic> toFirestore(String ownerId) {
    return {
      'ownerId': ownerId,
      'title': title,
      'amount': amount,
      'date': date,
      'friendIds': friendIds,
      'splitMethod': splitMethod,
      'customAmounts': customAmounts,
      'myShare': myShare,
      'paidBy': paidBy,
      'note': note,
      'settledFriendIds': settledFriendIds,
      'partialPaymentsByFriend': partialPaymentsByFriend,
      'myPartialPayment': myPartialPayment,
      'participantUids': participantUids,
      'sharesByUid': sharesByUid,
      'paidByUid': paidByUid,
      'settledUids': settledUids,
      'partialPaymentsByUid': partialPaymentsByUid,
      'createdAt': DateTime.now(),
    };
  }

  double shareForFriend(String friendId) {
    if (splitMethod == 'custom') {
      return customAmounts[friendId] ?? 0;
    }
    final totalParticipants = friendIds.length + 1;
    return amount / totalParticipants;
  }

  /// How much this friend STILL owes on this bill, after partial payments.
  double remainingForFriend(String friendId) {
    final owed =
        shareForFriend(friendId) - (partialPaymentsByFriend[friendId] ?? 0);
    return owed < 0 ? 0 : owed;
  }

  /// How much YOU still owe on this bill (when a friend paid), after partial payments.
  double get remainingMyShare {
    final owed = myShare - myPartialPayment;
    return owed < 0 ? 0 : owed;
  }

  /// How much a linked participant still owes toward their share.
  double remainingForUid(String uid) {
    final owed = (sharesByUid[uid] ?? 0) - (partialPaymentsByUid[uid] ?? 0);
    return owed < 0 ? 0 : owed;
  }

  bool isSettledFor(String friendId) => settledFriendIds.contains(friendId);

  bool get isFullySettled =>
      friendIds.isNotEmpty &&
      friendIds.every((id) => settledFriendIds.contains(id));

  bool isParticipant(String uid) => participantUids.contains(uid);

  double balanceForUid(String uid) {
    if (!isParticipant(uid)) return 0;
    final isPayer = paidByUid == null ? uid == ownerId : paidByUid == uid;

    if (isPayer) {
      double total = 0;
      for (final pUid in participantUids) {
        if (pUid == uid) continue;
        total += remainingForUid(pUid);
      }
      return total;
    } else {
      return -remainingForUid(uid);
    }
  }
}
