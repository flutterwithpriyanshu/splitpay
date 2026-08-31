import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/widgets/local_avatar.dart';
import 'package:splitpay/screens/friend_details_screen.dart';
import 'package:splitpay/core/phone_utils.dart';
import 'package:splitpay/model/group.dart';
import 'package:splitpay/services/group_service.dart';
import 'package:splitpay/screens/group_details_screen.dart';

/// Bottom-nav "Friends" screen. Holds two tabs:
///   - Groups: bills that involve 2+ other people, grouped by who's on them
///     (SplitPay has no separate "group" entity — a group here just means
///     "this set of people appears together on a bill").
///   - Friends: your friend list with live balances (same data as
///     ManageFriendsScreen, shown inline instead of as a separate push).
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Friends',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _tabController.index == 0
                        ? _showCreateGroupSheet(context)
                        : _showAddFriendSheet(context),
                    icon: Icon(
                      _tabController.index == 0
                          ? Icons.group_add_rounded
                          : Icons.person_add_alt_1_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle:
                    GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Groups'),
                  Tab(text: 'Friends'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _GroupsTab(),
                  _FriendsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFriendSheet(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    bool isChecking = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add Friend',
                    style: GoogleFonts.inter(
                        fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(hintText: 'Name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(hintText: 'Phone number'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Only phone numbers registered on SplitPay can be added as friends.',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isChecking
                          ? null
                          : () async {
                              final name = nameController.text.trim();
                              final phone =
                                  normalizePhone(phoneController.text.trim());

                              if (name.isEmpty || phone.isEmpty) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Name and phone are required'),
                                  ),
                                );
                                return;
                              }

                              setSheetState(() => isChecking = true);

                              final linkedUid =
                                  await FriendService.findUserByPhone(phone);

                              if (linkedUid == null) {
                                setSheetState(() => isChecking = false);
                                if (sheetContext.mounted) {
                                  ScaffoldMessenger.of(sheetContext)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "This number hasn't signed up for SplitPay — friend not added",
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }

                              await FriendService.addFriend(
                                name,
                                phoneNumber: phone,
                              );

                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isChecking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text('Add',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateGroupSheet(BuildContext context) {
    final nameController = TextEditingController();
    final Set<String> selectedIds = {};
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Group',
                    style: GoogleFonts.inter(
                        fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(hintText: 'Group name'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Add members',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: StreamBuilder<List<Friend>>(
                      stream: FriendService.streamFriends(),
                      builder: (context, snapshot) {
                        final friends = snapshot.data ?? [];
                        if (friends.isEmpty) {
                          return Text(
                            'Add a friend first from the Friends tab.',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: friends.length,
                          itemBuilder: (context, index) {
                            final friend = friends[index];
                            final isSelected =
                                selectedIds.contains(friend.id);
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (checked) {
                                setSheetState(() {
                                  if (checked == true) {
                                    selectedIds.add(friend.id);
                                  } else {
                                    selectedIds.remove(friend.id);
                                  }
                                });
                              },
                              activeColor: AppColors.primary,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                friend.name,
                                style: GoogleFonts.inter(fontSize: 14),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final name = nameController.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(sheetContext)
                                    .showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Please enter a group name'),
                                  ),
                                );
                                return;
                              }
                              if (selectedIds.length < 2) {
                                ScaffoldMessenger.of(sheetContext)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Select at least 2 friends for a group',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setSheetState(() => isSaving = true);
                              await GroupService.createGroup(
                                name,
                                selectedIds.toList(),
                              );
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text('Create',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Friends tab — same list/balance logic as ManageFriendsScreen, inline.
class _FriendsTab extends StatelessWidget {
  const _FriendsTab();

  double _balanceForFriend(List<Bill> bills, Friend friend) {
    double balance = 0;
    for (final bill in bills) {
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Friend>>(
      stream: FriendService.streamFriends(),
      builder: (context, friendSnapshot) {
        final friends = friendSnapshot.data ?? [];
        final friendsLoading =
            friendSnapshot.connectionState == ConnectionState.waiting;

        if (friendsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (friends.isEmpty) {
          return Center(
            child: Text(
              'No friends added yet',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          );
        }

        return StreamBuilder<List<Bill>>(
          stream: BillService.streamBills(),
          builder: (context, billSnapshot) {
            final bills = billSnapshot.data ?? [];
            final billsLoading =
                billSnapshot.connectionState == ConnectionState.waiting;

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                final balance = _balanceForFriend(bills, friend);

                String balanceText;
                Color balanceColor;

                if (billsLoading) {
                  balanceText = '...';
                  balanceColor = AppColors.textSecondary;
                } else if (balance == 0) {
                  balanceText = 'Settled up';
                  balanceColor = AppColors.textSecondary;
                } else if (balance > 0) {
                  balanceText = 'Owes you ₹${balance.abs().toStringAsFixed(0)}';
                  balanceColor = AppColors.success;
                } else {
                  balanceText = 'You owe ₹${balance.abs().toStringAsFixed(0)}';
                  balanceColor = AppColors.error;
                }

                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FriendDetailsScreen(friend: friend),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        LocalAvatar(
                          localKey: friend.id,
                          isProfile: false,
                          fallbackUrl: friend.avatarUrl,
                          radius: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                friend.name,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                balanceText,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: balanceColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}


/// Groups tab — real, persisted groups (see Group model / GroupService).
/// Create a group with 2+ friends, then add bills straight into it from
/// its details screen; those bills auto-split across the group's members.
class _GroupsTab extends StatelessWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Friend>>(
      stream: FriendService.streamFriends(),
      builder: (context, friendSnapshot) {
        final friends = friendSnapshot.data ?? [];
        final nameById = {for (final f in friends) f.id: f.name};

        return StreamBuilder<List<Group>>(
          stream: GroupService.streamGroups(),
          builder: (context, groupSnapshot) {
            if (groupSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final groups = groupSnapshot.data ?? [];

            if (groups.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'No groups yet. Tap the group icon above to create one.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              );
            }

            return StreamBuilder<List<Bill>>(
              stream: BillService.streamBills(),
              builder: (context, billSnapshot) {
                final allBills = billSnapshot.data ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final memberNames = group.memberFriendIds
                        .map((id) => nameById[id] ?? 'Unknown')
                        .join(', ');

                    final groupBills =
                        allBills.where((b) => b.groupId == group.id).toList();

                    double totalOutstanding = 0;
                    for (final bill in groupBills) {
                      for (final id in bill.friendIds) {
                        totalOutstanding += bill.remainingForFriend(id);
                      }
                      for (final uid in bill.participantUids) {
                        totalOutstanding += bill.remainingForUid(uid);
                      }
                    }

                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GroupDetailsScreen(group: group),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.15),
                              child: Icon(Icons.groups_rounded,
                                  color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    memberNames.isEmpty
                                        ? 'No members'
                                        : memberNames,
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
                                  '${groupBills.length} bill${groupBills.length == 1 ? '' : 's'}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  totalOutstanding == 0
                                      ? 'Settled up'
                                      : '₹${totalOutstanding.toStringAsFixed(0)} due',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: totalOutstanding == 0
                                        ? AppColors.textSecondary
                                        : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
