class Group {
  final String id;
  final String name;
  final String ownerId;

  /// Friend doc IDs (from the `friends` collection) that belong to this
  /// group. Works for both linked and non-linked friends, same as a Bill's
  /// `friendIds`.
  final List<String> memberFriendIds;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.memberFriendIds,
    required this.createdAt,
  });

  factory Group.fromFirestore(String id, Map<String, dynamic> data) {
    return Group(
      id: id,
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      memberFriendIds: List<String>.from(data['memberFriendIds'] ?? []),
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ownerId': ownerId,
      'memberFriendIds': memberFriendIds,
      'createdAt': createdAt,
    };
  }
}
