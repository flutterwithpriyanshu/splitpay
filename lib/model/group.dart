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

  Group({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.memberFriendIds,
    this.memberUids = const [],
    required this.createdAt,
  });

  factory Group.fromFirestore(String id, Map<String, dynamic> data) {
    return Group(
      id: id,
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      memberFriendIds: List<String>.from(data['memberFriendIds'] ?? []),
      memberUids: List<String>.from(data['memberUids'] ?? []),
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ownerId': ownerId,
      'memberFriendIds': memberFriendIds,
      'memberUids': memberUids,
      'createdAt': createdAt,
    };
  }
}
