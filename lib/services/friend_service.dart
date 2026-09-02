import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/core/phone_utils.dart';

class FriendService {
  static final _db = FirebaseFirestore.instance;

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static Stream<List<Friend>> streamFriends() {
    return _db
        .collection('friends')
        .where('ownerId', isEqualTo: _uid)
        .orderBy('name')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Friend.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Checks if a phone number belongs to a registered SplitPay user.
  /// Returns their user ID if found, otherwise null.
  static Future<String?> findUserByPhone(String phoneNumber) async {
    final snap = await _db
        .collection('users')
        .where('phoneNumber', isEqualTo: normalizePhone(phoneNumber))
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  static Future<bool> isFriendAlreadyAdded({
    required String phoneNumber,
    String? linkedUid,
  }) async {
    final phone = normalizePhone(phoneNumber);
    final byPhone = await _db
        .collection('friends')
        .where('ownerId', isEqualTo: _uid)
        .where('phoneNumber', isEqualTo: phone)
        .limit(1)
        .get();
    if (byPhone.docs.isNotEmpty) return true;

    if (linkedUid == null) return false;
    final byUid = await _db
        .collection('friends')
        .where('ownerId', isEqualTo: _uid)
        .where('linkedUid', isEqualTo: linkedUid)
        .limit(1)
        .get();
    return byUid.docs.isNotEmpty;
  }

  /// Fetches the current signed-in user's own profile data.
  static Future<Map<String, dynamic>?> getMyProfile() async {
    final doc = await _db.collection('users').doc(_uid).get();
    return doc.data();
  }

  /// Full name of any user by uid — used to label things shared by
  /// someone (a bill, a group) who isn't necessarily in your own
  /// friends collection under that uid.
  static Future<String> getUserName(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['fullName'] ?? 'Someone';
  }

  /// Ensures [targetUid]'s friend list contains an entry representing
  /// the CURRENT signed-in user. If one already exists, does nothing.
  static Future<void> ensureReciprocalFriend(String targetUid) async {
    // Don't create a reciprocal friend pointing to yourself.
    if (targetUid == _uid) return;

    final existing = await _db
        .collection('friends')
        .where('ownerId', isEqualTo: targetUid)
        .where('linkedUid', isEqualTo: _uid)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return; // already linked both ways

    final myProfile = await getMyProfile();
    final myName = myProfile?['fullName'] ?? 'SplitPay User';
    final myPhone = myProfile?['phoneNumber'] ?? '';

    await _db.collection('friends').add({
      'ownerId': targetUid,
      'name': myName,
      'avatarUrl':
          'https://i.pravatar.cc/150?u=$myName-${DateTime.now().millisecondsSinceEpoch}',
      'phoneNumber': myPhone,
      'linkedUid': _uid,
      'createdAt': DateTime.now(),
    });
  }

  /// Adds a friend. If a phone number is given, checks whether it
  /// matches a real registered user and links it if so.
  static Future<Friend> addFriend(String name, {String? phoneNumber}) async {
    String? linkedUid;
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      linkedUid = await findUserByPhone(phoneNumber.trim());
    }

    final data = {
      'ownerId': _uid,
      'name': name,
      'avatarUrl':
          'https://i.pravatar.cc/150?u=$name-${DateTime.now().millisecondsSinceEpoch}',
      'phoneNumber': phoneNumber,
      'linkedUid': linkedUid,
      'createdAt': DateTime.now(),
    };
    final ref = await _db.collection('friends').add(data);
    return Friend.fromFirestore(ref.id, data);
  }

  static Future<void> removeFriend(String friendId) {
    return _db.collection('friends').doc(friendId).delete();
  }
}
