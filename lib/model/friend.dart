class Friend {
  final String id;
  final String name;
  final String avatarUrl;
  final String? phoneNumber;
  final String? linkedUid;

  Friend({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.phoneNumber,
    this.linkedUid,
  });

  factory Friend.fromFirestore(String id, Map<String, dynamic> data) {
    return Friend(
      id: id,
      name: data['name'] ?? '',
      avatarUrl: data['avatarUrl'] ?? 'https://i.pravatar.cc/150',
      phoneNumber: data['phoneNumber'],
      linkedUid: data['linkedUid'],
    );
  }

  Map<String, dynamic> toFirestore(String ownerId) {
    return {
      'ownerId': ownerId,
      'name': name,
      'avatarUrl': avatarUrl,
      'phoneNumber': phoneNumber,
      'linkedUid': linkedUid,
      'createdAt': DateTime.now(),
    };
  }

  bool get isLinked => linkedUid != null;
}