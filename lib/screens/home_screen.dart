import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/screens/friend_details_screen.dart';
import 'package:splitpay/screens/edit_bill_screen.dart';
import 'package:splitpay/widgets/local_avatar.dart';
import 'package:splitpay/screens/settings_screen.dart';
import 'package:splitpay/screens/add_bill_screen.dart';
import 'package:splitpay/services/group_service.dart';
import 'package:splitpay/model/group.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Sign-out just fired — main.dart's StreamBuilder is about to swap
      // this whole screen out. Bail before touching a null uid.
      return const Scaffold(body: SizedBox.shrink());
    }
    final myUid = user.uid;
    final userName = user.displayName ?? 'there';

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddBillScreen(
                onBillSaved: () => Navigator.of(context).pop(),
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Friend>>(
          stream: FriendService.streamFriends(),
          builder: (context, friendSnapshot) {
            final friends = friendSnapshot.data ?? [];
            final friendsLoading =
                friendSnapshot.connectionState == ConnectionState.waiting;

            final friendNameById = {for (final f in friends) f.id: f.name};
            final nameByLinkedUid = {
              for (final f in friends)
                if (f.isLinked) f.linkedUid!: f.name,
            };
            final friendById = {for (final f in friends) f.id: f};

            return StreamBuilder<List<Bill>>(
              stream: BillService.streamBills(),
              builder: (context, ownSnapshot) {
                final ownBills = ownSnapshot.data ?? [];
                final ownLoading =
                    ownSnapshot.connectionState == ConnectionState.waiting;

                return StreamBuilder<List<Bill>>(
                  stream: BillService.streamSharedBills(),
                  builder: (context, sharedSnapshot) {
                    final sharedBills = sharedSnapshot.data ?? [];
                    final sharedLoading =
                        sharedSnapshot.connectionState ==
                        ConnectionState.waiting;

                    return StreamBuilder<List<Group>>(
                      stream: GroupService.streamSharedGroups(),
                      builder: (context, sharedGroupSnapshot) {
                        final List<Group> sharedGroupsForNames =
                            sharedGroupSnapshot.data ?? <Group>[];
                        final Map<String, String> groupNameById = {
                          for (final g in sharedGroupsForNames) g.id: g.name,
                        };

                    final billsLoading = ownLoading || sharedLoading;

                    double youOwe = 0;
                    double youGet = 0;

                    for (final bill in ownBills) {
                      if (bill.paidBy == 'me') {
                        for (final fid in bill.friendIds) {
                          final f = friendById[fid];
                          final remaining = (f != null && f.isLinked)
                              ? bill.remainingForUid(f.linkedUid!)
                              : bill.remainingForFriend(fid);
                          youGet += remaining;
                        }
                      } else {
                        youOwe += bill.remainingMyShare;
                      }
                    }

                    for (final bill in sharedBills) {
                      final balance = bill.balanceForUid(myUid);
                      if (balance > 0) {
                        youGet += balance;
                      } else if (balance < 0) {
                        youOwe += balance.abs();
                      }
                    }

                    final allActivity = [
                      ...ownBills.map(
                        (b) => _ActivityItem(bill: b, isOwn: true),
                      ),
                      ...sharedBills.map(
                        (b) => _ActivityItem(bill: b, isOwn: false),
                      ),
                    ]..sort((a, b) => b.bill.date.compareTo(a.bill.date));

                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        children: [
                          _buildHeader(userName, myUid),
                          const SizedBox(height: 20),
                          _buildBalanceCard(youOwe, youGet),
                          const SizedBox(height: 24),
                          _buildRecentFriends(friends, friendsLoading),
                          const SizedBox(height: 24),
                          _buildRecentActivityHeader(),
                          const SizedBox(height: 12),
                          if (billsLoading)
                            _billsSkeleton()
                          else if (allActivity.isEmpty)
                            _buildEmptyBills()
                          else
                            ..._buildBillCards(
                              allActivity,
                              friendNameById,
                              nameByLinkedUid,
                              friendById,
                              myUid,
                              groupNameById,
                            ),
                        ],
                      ),
                    );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ---------- Header ----------
  Widget _buildHeader(String userName, String myUid) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $userName 👋',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Welcome Back',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
          },
          child: LocalAvatar(localKey: myUid, isProfile: true, radius: 24),
        ),
      ],
    );
  }

  // ---------- Balance Card ----------
  Widget _buildBalanceCard(double youOwe, double youGet) {
    final total = youGet - youOwe;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${total < 0 ? '-' : ''}₹${total.abs().toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildBalanceStat(
                  label: 'You Owe',
                  amount: '₹${youOwe.toStringAsFixed(0)}',
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withOpacity(0.2),
              ),
              Expanded(
                child: _buildBalanceStat(
                  label: 'You Get',
                  amount: '₹${youGet.toStringAsFixed(0)}',
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceStat({
    required String label,
    required String amount,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              Text(
                amount,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Recent Friends ----------
  Widget _buildRecentFriends(List<Friend> friends, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Friends',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 84,
          child: isLoading
              ? _friendsSkeletonRow()
              : friends.isEmpty
              ? _buildEmptyFriends()
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: friends.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FriendDetailsScreen(friend: friend),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          LocalAvatar(
                            localKey: friend.id,
                            isProfile: false,
                            fallbackUrl: friend.avatarUrl,
                            radius: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            friend.name,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyFriends() {
    return Center(
      child: Text(
        'No friends yet — add one from Add Bill',
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _friendsSkeletonRow() {
    return Row(
      children: List.generate(
        4,
        (i) => Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 40,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Recent Activity ----------
  Widget _buildRecentActivityHeader() {
    return Text(
      'Recent Activity',
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  List<Widget> _buildBillCards(
    List<_ActivityItem> items,
    Map<String, String> friendNameById,
    Map<String, String> nameByLinkedUid,
    Map<String, Friend> friendById,
    String myUid,
    Map<String, String> groupNameById,
  ) {
    return items.map((item) {
      final bill = item.bill;

      String subtitle;
      bool isSettled;
      double displayAmount;

      if (item.isOwn) {
        final names = bill.friendIds
            .map((id) => friendNameById[id] ?? 'Unknown')
            .join(', ');
        subtitle = names.isEmpty ? 'No friends' : 'with $names';
        isSettled =
            bill.friendIds.isNotEmpty &&
            bill.friendIds.every((fid) {
              final f = friendById[fid];
              return (f != null && f.isLinked)
                  ? bill.settledUids.contains(f.linkedUid)
                  : bill.isSettledFor(fid);
            });
        displayAmount = bill.amount;
      } else {
        final creatorName = nameByLinkedUid[bill.ownerId] ?? 'Someone';
        final groupName = bill.groupId != null
            ? groupNameById[bill.groupId]
            : null;
        subtitle = groupName != null
            ? 'Shared by $creatorName · $groupName'
            : 'Shared by $creatorName';
        isSettled = bill.settledUids.contains(myUid);
        displayAmount = bill.sharesByUid[myUid] ?? 0;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: item.isOwn
            ? Dismissible(
                key: ValueKey(bill.id),
                background: _swipeBackground(
                  alignment: Alignment.centerLeft,
                  color: AppColors.error,
                  icon: Icons.delete_rounded,
                ),
                secondaryBackground: _swipeBackground(
                  alignment: Alignment.centerRight,
                  color: AppColors.primary,
                  icon: Icons.edit_rounded,
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    await BillService.deleteBill(bill.id);
                    return true;
                  } else {
                    if (bill.settledFriendIds.isNotEmpty ||
                        bill.settledUids.isNotEmpty ||
                        bill.partialPaymentsByFriend.isNotEmpty ||
                        bill.partialPaymentsByUid.isNotEmpty ||
                        bill.myPartialPayment > 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'This bill has settled activity and can no longer be edited',
                          ),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditBillScreen(bill: bill),
                        ),
                      );
                    }
                    return false;
                  }
                },
                child: _billCard(
                  title: bill.title,
                  subtitle: subtitle,
                  amount: displayAmount,
                  isSettled: isSettled,
                ),
              )
            : _billCard(
                title: bill.title,
                subtitle: subtitle,
                amount: displayAmount,
                isSettled: isSettled,
              ),
      );
    }).toList();
  }

  Widget _billCard({
    required String title,
    required String subtitle,
    required double amount,
    required bool isSettled,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF6C63FF),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isSettled ? AppColors.success : AppColors.warning)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isSettled ? 'Settled' : 'Pending',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSettled ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _swipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildEmptyBills() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 56,
            color: AppColors.textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No bills yet',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add your first bill to get started',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _billsSkeleton() {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityItem {
  final Bill bill;
  final bool isOwn;

  _ActivityItem({required this.bill, required this.isOwn});
}
