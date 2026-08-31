import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  static Future<Group> createGroup(
    String name,
    List<String> memberFriendIds,
  ) async {
    final data = {
      'name': name,
      'ownerId': _uid,
      'memberFriendIds': memberFriendIds,
      'createdAt': DateTime.now(),
    };
    final ref = await _db.collection('groups').add(data);
    return Group.fromFirestore(ref.id, data);
  }

  static Future<void> updateMembers(
    String groupId,
    List<String> memberFriendIds,
  ) {
    return _db.collection('groups').doc(groupId).update({
      'memberFriendIds': memberFriendIds,
    });
  }

  static Future<void> deleteGroup(String groupId) {
    return _db.collection('groups').doc(groupId).delete();
  }
}
