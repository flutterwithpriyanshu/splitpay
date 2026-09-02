class Group {
  final String id;
  final String name;
  final String ownerId;

  /// Friend doc IDs (from the `friends` collection) that belong to this
  /// group. Works for both linked and non-linked friends, same as a Bill's
  /// `friendIds`. These ids only resolve to names in the OWNER's own
  /// friends collection.
  final List<String> memberFriendIds;

  /// Firebase Auth uids of members who are linked SplitPay accounts.
  /// Lets a linked member see the group on THEIR OWN device the moment
  /// it's created — mirrors how a Bill's `participantUids` makes it show
  /// up cross-account without needing anything else added to it.
  final List<String> memberUids;
  final DateTime createdAt;

  /// Day of the month (1-31) the group owner picked to settle up on.
  /// Every month, on this date, every member (owner + linked members) gets
  /// a reminder notification showing what THEY owe/are owed in this group.
  /// Null = no recurring settle-up reminder set for this group.
  final int? settleUpDay;

  Group({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.memberFriendIds,
    this.memberUids = const [],
    required this.createdAt,
    this.settleUpDay,
  });

  /// All member uids who can be reminded / who can add bills directly
  /// (owner + every linked member). Local-only (non-linked) friends can't
  /// receive push/local reminders since they don't have a SplitPay account.
  List<String> get allMemberUids => [ownerId, ...memberUids];

  factory Group.fromFirestore(String id, Map<String, dynamic> data) {
    return Group(
      id: id,
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      memberFriendIds: List<String>.from(data['memberFriendIds'] ?? []),
      memberUids: List<String>.from(data['memberUids'] ?? []),
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      settleUpDay: data['settleUpDay'] as int?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ownerId': ownerId,
      'memberFriendIds': memberFriendIds,
      'memberUids': memberUids,
      'createdAt': createdAt,
      'settleUpDay': settleUpDay,
    };
  }
}
