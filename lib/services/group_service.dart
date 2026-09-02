import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/model/group.dart';

class GroupService {
  static final _db = FirebaseFirestore.instance;

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static Stream<List<Group>> streamGroups() {
    return _db
        .collection('groups')
        .where('ownerId', isEqualTo: _uid)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Group.fromFirestore(doc.id, doc.data()))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  /// Groups created by someone ELSE that you're a linked member of — shows
  /// up the instant the group is created, no bill needed first.
  static Stream<List<Group>> streamSharedGroups() {
    return _db
        .collection('groups')
        .where('memberUids', arrayContains: _uid)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Group.fromFirestore(doc.id, doc.data()))
              .where((g) => g.ownerId != _uid)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  static Future<Group> createGroup(
    String name,
    List<Friend> members, {
    int? settleUpDay,
  }) async {
    final memberFriendIds = members.map((f) => f.id).toList();
    final memberUids = members
        .where((f) => f.isLinked)
        .map((f) => f.linkedUid!)
        .toList();
    final data = {
      'name': name,
      'ownerId': _uid,
      'memberFriendIds': memberFriendIds,
      'memberUids': memberUids,
      'createdAt': Timestamp.now(),
      'settleUpDay': settleUpDay,
    };
    final ref = await _db.collection('groups').add(data);
    return Group.fromFirestore(ref.id, data);
  }

  /// Sets/changes/clears (pass null) the monthly settle-up reminder date
  /// for a group. Any member can read it; only shown as editable to the
  /// owner in the UI, but it lives on the group doc so every member's app
  /// can independently schedule their own local reminder from it.
  static Future<void> updateSettleUpDay(String groupId, int? settleUpDay) {
    return _db.collection('groups').doc(groupId).update({
      'settleUpDay': settleUpDay,
    });
  }

  static Future<void> updateMembers(
    String groupId,
    List<Friend> members,
  ) {
    final memberFriendIds = members.map((f) => f.id).toList();
    final memberUids = members
        .where((f) => f.isLinked)
        .map((f) => f.linkedUid!)
        .toList();
    return _db.collection('groups').doc(groupId).update({
      'memberFriendIds': memberFriendIds,
      'memberUids': memberUids,
    });
  }

  static Future<void> deleteGroup(String groupId) {
    return _db.collection('groups').doc(groupId).delete();
  }
}
