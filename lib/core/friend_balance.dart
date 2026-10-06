import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/friend.dart';

/// Net 1:1 balance with [friend]: >0 they owe me, <0 I owe them.
/// Group bills are skipped (group screens own those balances).
double friendBalance(List<Bill> bills, Friend friend) {
  double balance = 0;
  for (final bill in bills) {
    if (bill.groupId != null) continue;
    if (friend.isLinked) {
      if (!bill.isParticipant(friend.linkedUid!)) continue;
      balance += bill.balanceForUid(friend.linkedUid!);
    } else {
      if (bill.isSettledFor(friend.id)) continue;
      if (!bill.friendIds.contains(friend.id)) continue;
      if (bill.paidBy == 'me') {
        balance += bill.shareForFriend(friend.id);
      } else if (bill.paidBy == friend.id) {
        balance -= bill.myShare;
      }
    }
  }
  return balance;
}

/// Ids of the friends from the most recent bills, newest first.
/// [bills] must be sorted newest first (`BillService.streamBills` is).
List<String> recentFriendIds(
  List<Bill> bills,
  List<Friend> friends, {
  int limit = 5,
}) {
  final out = <String>[];
  for (final bill in bills) {
    for (final f in friends) {
      if (out.contains(f.id)) continue;
      final inBill = bill.friendIds.contains(f.id) ||
          (f.isLinked && bill.isParticipant(f.linkedUid!));
      if (inBill) out.add(f.id);
      if (out.length >= limit) return out;
    }
  }
  return out;
}
