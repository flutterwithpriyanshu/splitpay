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
          (snap) =>
              snap.docs
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
          (snap) =>
              snap.docs
                  .map((doc) => Group.fromFirestore(doc.id, doc.data()))
                  .where((g) => g.ownerId != _uid)
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  /// Single group doc, live. GroupDetailsScreen (the one screen used by
  /// owner AND every member) subscribes to this instead of carrying
  /// around a static Group snapshot from the moment it was opened — so
  /// member count / settle date / name stay correct in real time no
  /// matter who changes what.
  static Stream<Group> streamGroup(String groupId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .snapshots()
        .map((doc) => Group.fromFirestore(doc.id, doc.data() ?? {}));
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
    final memberFriendIdsByUid = {
      for (final friend in members)
        if (friend.isLinked) friend.linkedUid!: friend.id,
    };
    final data = {
      'name': name,
      'ownerId': _uid,
      'memberFriendIds': memberFriendIds,
      'memberUids': memberUids,
      'memberFriendIdsByUid': memberFriendIdsByUid,
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
  static Future<void> updateSettleUpDay(
    String groupId,
    int? settleUpDay,
  ) async {
    await _assertOwner(groupId);
    await _db.collection('groups').doc(groupId).update({
      'settleUpDay': settleUpDay,
      'lastSettleReminderMonth': FieldValue.delete(),
    });
  }

  /// Throws unless the signed-in user owns the group. Members can read a
  /// group but never change who is in it.
  static Future<void> _assertOwner(String groupId) async {
    final doc = await _db.collection('groups').doc(groupId).get();
    if (doc.data()?['ownerId'] != _uid) {
      throw StateError('Only the group owner can change members');
    }
  }

  /// Bundles every field the Edit Group Settings screen can touch into one
  /// write — name, members, group type, and the simplify-debts toggle.
  static Future<void> updateSettings(
    String groupId, {
    required String name,
    required List<Friend> members,
    required String groupType,
    required bool simplifyDebts,
  }) async {
    await _assertOwner(groupId);
    final memberFriendIds = members.map((f) => f.id).toList();
    final memberUids = members
        .where((f) => f.isLinked)
        .map((f) => f.linkedUid!)
        .toList();
    final memberFriendIdsByUid = {
      for (final friend in members)
        if (friend.isLinked) friend.linkedUid!: friend.id,
    };
    await _db.collection('groups').doc(groupId).update({
      'name': name,
      'memberFriendIds': memberFriendIds,
      'memberUids': memberUids,
      'memberFriendIdsByUid': memberFriendIdsByUid,
      'groupType': groupType,
      'simplifyDebts': simplifyDebts,
    });
  }

  static Future<void> updateMembers(
    String groupId,
    List<Friend> members,
  ) async {
    await _assertOwner(groupId);
    final memberFriendIds = members.map((f) => f.id).toList();
    final memberUids = members
        .where((f) => f.isLinked)
        .map((f) => f.linkedUid!)
        .toList();
    final memberFriendIdsByUid = {
      for (final friend in members)
        if (friend.isLinked) friend.linkedUid!: friend.id,
    };
    await _db.collection('groups').doc(groupId).update({
      'memberFriendIds': memberFriendIds,
      'memberUids': memberUids,
      'memberFriendIdsByUid': memberFriendIdsByUid,
    });
  }

  static Future<void> leaveGroup(String groupId) async {
    final groupRef = _db.collection('groups').doc(groupId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(groupRef);
      final data = snapshot.data();
      if (data == null) throw StateError('Group not found');
      if (data['ownerId'] == _uid) {
        throw StateError('The group owner cannot leave the group');
      }

      final memberUids = List<String>.from(data['memberUids'] ?? []);
      if (!memberUids.remove(_uid)) {
        throw StateError('You are not a member of this group');
      }

      final memberFriendIds = List<String>.from(data['memberFriendIds'] ?? []);
      final memberFriendIdsByUid = Map<String, String>.from(
        data['memberFriendIdsByUid'] ?? {},
      );
      final friendId = memberFriendIdsByUid.remove(_uid);
      if (friendId != null) memberFriendIds.remove(friendId);

      transaction.update(groupRef, {
        'memberUids': memberUids,
        'memberFriendIds': memberFriendIds,
        'memberFriendIdsByUid': memberFriendIdsByUid,
      });
    });
  }

  static Future<void> deleteGroup(String groupId) async {
    await _assertOwner(groupId);
    final billsSnap = await _db
        .collection('bills')
        .where('groupId', isEqualTo: groupId)
        .where('ownerId', isEqualTo: _uid)
        .get();

    final batch = _db.batch();
    for (final doc in billsSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db.collection('groups').doc(groupId));
    await batch.commit();
  }
}
