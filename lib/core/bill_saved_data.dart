import 'package:flutter/widgets.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/services/friend_service.dart';

/// One person (not "You") in the saved-bill split list.
class BillSavedRow {
  const BillSavedRow({
    required this.name,
    required this.subtitle,
    required this.amount,
    this.friendId,
    this.avatarUrl,
    this.linkedUid,
  });

  final String name;
  final String subtitle;
  final double amount;

  /// Local friend doc id (avatar lookup). Null for group members.
  final String? friendId;
  final String? avatarUrl;

  /// App user id. Null = not on SplitPay (no push possible).
  final String? linkedUid;
}

/// Everything `BillSavedScreen` shows. Built right after save.
class BillSavedData {
  const BillSavedData({
    required this.title,
    required this.amount,
    required this.date,
    required this.paidByMe,
    required this.paidByName,
    required this.rows,
    this.isUpdate = false,
    this.categoryLabel,
    this.categoryIcon,
  });

  final String title;
  final double amount;
  final DateTime date;
  final bool paidByMe;
  final String paidByName;
  final List<BillSavedRow> rows;
  final bool isUpdate;

  /// Picked on Add Bill. Null = derive from title.
  final String? categoryLabel;
  final IconData? categoryIcon;

  int get people => rows.length + 1;

  static String _subtitle(bool custom, int people, String customLabel) =>
      custom ? customLabel : 'Equal 1/$people share';

  /// Friend flow (Add Bill / Edit Bill). [shares] = friendId -> share.
  factory BillSavedData.fromFriends({
    required String title,
    required double amount,
    required DateTime date,
    required List<Friend> friends,
    required Map<String, double> shares,
    required bool custom,
    Friend? paidByFriend,
    bool isUpdate = false,
    String? categoryLabel,
    IconData? categoryIcon,
  }) {
    final people = friends.length + 1;
    return BillSavedData(
      title: title,
      amount: amount,
      date: date,
      paidByMe: paidByFriend == null,
      paidByName: paidByFriend?.name ?? 'You',
      isUpdate: isUpdate,
      categoryLabel: categoryLabel,
      categoryIcon: categoryIcon,
      rows: [
        for (final f in friends)
          BillSavedRow(
            name: f.name,
            subtitle: _subtitle(custom, people, 'Custom split'),
            amount: shares[f.id] ?? 0,
            friendId: f.id,
            avatarUrl: f.avatarUrl,
            linkedUid: f.linkedUid,
          ),
      ],
    );
  }

  /// Group flow. [shares] = uid -> share.
  static Future<BillSavedData> forGroup({
    required String title,
    required double amount,
    required DateTime date,
    required String myUid,
    required String paidByUid,
    required List<String> members,
    required Map<String, double> shares,
    required bool custom,
  }) async {
    final others = members.where((u) => u != myUid).toList();
    final names = await Future.wait(others.map(FriendService.getUserName));
    final people = members.length;
    final payerIdx = others.indexOf(paidByUid);
    final payerName = paidByUid == myUid
        ? 'You'
        : (payerIdx >= 0 ? names[payerIdx] : 'Someone');
    return BillSavedData(
      title: title,
      amount: amount,
      date: date,
      paidByMe: paidByUid == myUid,
      paidByName: payerName,
      rows: [
        for (var i = 0; i < others.length; i++)
          BillSavedRow(
            name: names[i],
            subtitle: _subtitle(custom, people, 'Custom share'),
            amount: shares[others[i]] ?? 0,
            linkedUid: others[i],
          ),
      ],
    );
  }
}
