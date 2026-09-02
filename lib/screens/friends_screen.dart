import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide Group;
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/services/local_image_service.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/widgets/local_avatar.dart';
import 'package:splitpay/screens/friend_details_screen.dart';
import 'package:splitpay/core/phone_utils.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/model/group.dart';
import 'package:splitpay/services/group_service.dart';
import 'package:splitpay/screens/group_details_screen.dart';
import 'package:splitpay/screens/shared_group_details_screen.dart';

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
                labelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Groups'),
                  Tab(text: 'Friends'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [_GroupsTab(), _FriendsTab()],
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
    Uint8List? pendingContactPhoto;

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
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (pendingContactPhoto != null) ...[
                    Center(
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage: MemoryImage(pendingContactPhoto!),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(hintText: 'Name'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: 'Phone number',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          onPressed: () async {
                            try {
                              // read only — readWrite also asks for
                              // WRITE_CONTACTS and can come back denied
                              // even after the user taps Allow.
                              var status = await FlutterContacts.permissions
                                  .request(PermissionType.read);
                              if (status != PermissionStatus.granted) {
                                status = await FlutterContacts.permissions
                                    .request(PermissionType.read);
                              }
                              if (status != PermissionStatus.granted) {
                                if (sheetContext.mounted) {
                                  showAppToast(
                                    sheetContext,
                                    'Contacts permission is required to pick a contact',
                                  );
                                }
                                return;
                              }

                              final picked = await FlutterContacts.native
                                  .showPicker(
                                    properties: {
                                      ContactProperty.phone,
                                      ContactProperty.photoFullRes,
                                    },
                                  );
                              if (picked == null || picked.id == null) return;

                              final fullContact = await FlutterContacts.get(
                                picked.id!,
                                properties: ContactProperties.all,
                              );
                              if (fullContact == null) return;

                              final pickedName = fullContact.displayName ?? '';
                              final pickedPhone = fullContact.phones.isNotEmpty
                                  ? normalizePhone(
                                      fullContact.phones.first.number,
                                    )
                                  : '';
                              final pickedPhoto = fullContact.photo?.fullSize;

                              setSheetState(() {
                                nameController.text = pickedName;
                                phoneController.text = pickedPhone;
                                pendingContactPhoto = pickedPhoto;
                              });
                            } catch (e) {
                              if (sheetContext.mounted) {
                                showAppToast(
                                  sheetContext,
                                  'Could not open contacts: $e',
                                );
                              }
                            }
                          },
                          icon: Icon(
                            Icons.contact_page_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Only phone numbers registered on SplitPay can be added as friends.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isChecking
                          ? null
                          : () async {
                              final name = nameController.text.trim();
                              final phone = normalizePhone(
                                phoneController.text.trim(),
                              );

                              if (name.isEmpty || phone.isEmpty) {
                                showAppToast(
                                  sheetContext,
                                  'Name and phone are required',
                                );
                                return;
                              }

                              setSheetState(() => isChecking = true);

                              final linkedUid =
                                  await FriendService.findUserByPhone(phone);

                              if (linkedUid == null) {
                                setSheetState(() => isChecking = false);
                                if (sheetContext.mounted) {
                                  showAppToast(
                                    sheetContext,
                                    "This number hasn't signed up for SplitPay — friend not added",
                                  );
                                }
                                return;
                              }

                              final newFriend = await FriendService.addFriend(
                                name,
                                phoneNumber: phone,
                              );

                              if (pendingContactPhoto != null) {
                                await LocalImageService.saveFriendImage(
                                  newFriend.id,
                                  pendingContactPhoto!,
                                );
                              }

                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isChecking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Add',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
    List<Friend> liveFriends = [];
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
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(hintText: 'Group name'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Add members',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: StreamBuilder<List<Friend>>(
                      stream: FriendService.streamFriends(),
                      builder: (context, snapshot) {
                        final friends = snapshot.data ?? [];
                        liveFriends = friends;
                        if (friends.isEmpty) {
                          return Text(
                            'Add a friend first from the Friends tab.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: friends.length,
                          itemBuilder: (context, index) {
                            final friend = friends[index];
                            final isSelected = selectedIds.contains(friend.id);
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
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a group name'),
                                  ),
                                );
                                return;
                              }
                              if (selectedIds.length < 2) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Select at least 2 friends for a group',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setSheetState(() => isSaving = true);
                              try {
                                final selectedMembers = liveFriends
                                    .where(
                                      (f) => selectedIds.contains(f.id),
                                    )
                                    .toList();
                                await GroupService.createGroup(
                                  name,
                                  selectedMembers,
                                );
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              } catch (e) {
                                if (sheetContext.mounted) {
                                  setSheetState(() => isSaving = false);
                                  ScaffoldMessenger.of(
                                    sheetContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not create group. Try again.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Create',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
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
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
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
  }
}

/// Groups tab — real, persisted groups (see Group model / GroupService).
/// Create a group with 2+ friends, then add bills straight into it from
/// its details screen; those bills auto-split across the group's members.
class _GroupsTab extends StatelessWidget {
  const _GroupsTab();

  /// Same fix as GroupDetailsScreen._remainingForBill: a friend is tracked
  /// either via `friendIds`/`remainingForFriend` (non-linked) OR via
  /// `participantUids`/`remainingForUid` (linked) — never both. The old
  /// code summed both lists unconditionally, double-counting every linked
  /// friend's share (participantUids also always includes your own uid,
  /// so your own share leaked into the group's "due" total too).
  double _remainingForBill(Bill bill, Map<String, Friend> friendById) {
    double total = 0;
    for (final id in bill.friendIds) {
      final friend = friendById[id];
      if (friend != null && friend.isLinked) {
        total += bill.remainingForUid(friend.linkedUid!);
      } else {
        total += bill.remainingForFriend(id);
      }
    }
    return total;
  }

  /// Net signed balance for a bill: positive = you're owed, negative = you owe.
  double _netForBill(Bill bill, Map<String, Friend> friendById) {
    if (bill.paidBy == 'me') {
      return _remainingForBill(bill, friendById);
    }
    return -bill.remainingMyShare;
  }

  static const _kCardColors = [
    Color(0xFFFFB37B),
    Color(0xFF7ED0A6),
    Color(0xFF8FB8F6),
    Color(0xFFC7A6F2),
    Color(0xFFF29AB0),
  ];

  Color _colorFor(String seed) =>
      _kCardColors[seed.hashCode.abs() % _kCardColors.length];

  IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('flat') || n.contains('home') || n.contains('rent')) {
      return Icons.home_rounded;
    }
    if (n.contains('trip') || n.contains('travel')) {
      return Icons.flight_takeoff_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Friend>>(
      stream: FriendService.streamFriends(),
      builder: (context, friendSnapshot) {
        final friends = friendSnapshot.data ?? [];
        final friendById = {for (final f in friends) f.id: f};

        return StreamBuilder<List<Group>>(
          stream: GroupService.streamGroups(),
          builder: (context, groupSnapshot) {
            if (groupSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final ownGroups = groupSnapshot.data ?? [];

            // Groups someone else created that you're a linked member of —
            // show up immediately, no bill needed first.
            return StreamBuilder<List<Group>>(
              stream: GroupService.streamSharedGroups(),
              builder: (context, sharedGroupSnapshot) {
                final sharedGroups = sharedGroupSnapshot.data ?? [];
                final groups = [...ownGroups, ...sharedGroups]
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                if (groups.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'No groups yet. Tap the group icon above to create one.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return StreamBuilder<List<Bill>>(
                  stream: BillService.streamBills(),
                  builder: (context, billSnapshot) {
                    final allBills = billSnapshot.data ?? [];

                    // Per-group net + overall net, for own groups only (the
                    // only ones we have bill data for here).
                    final netByGroupId = <String, double>{};
                    double overallNet = 0;
                    for (final group in ownGroups) {
                      final groupBills = allBills
                          .where((b) => b.groupId == group.id)
                          .toList();
                      double net = 0;
                      for (final bill in groupBills) {
                        net += _netForBill(bill, friendById);
                      }
                      netByGroupId[group.id] = net;
                      overallNet += net;
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: groups.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _OverallLine(net: overallNet),
                          );
                        }
                        final group = groups[index - 1];
                        final isOwn = group.ownerId ==
                            FirebaseAuth.instance.currentUser!.uid;

                        final groupBills = isOwn
                            ? allBills
                                  .where((b) => b.groupId == group.id)
                                  .toList()
                            : <Bill>[];

                        final net = netByGroupId[group.id] ?? 0;
                        final isSettled = net.abs() <= 0.009;
                        final color = _colorFor(group.id);

                        String subtitle;
                        Color subtitleColor;
                        if (!isOwn) {
                          subtitle = '';
                          subtitleColor = AppColors.textSecondary;
                        } else if (groupBills.isEmpty) {
                          subtitle = 'No bills yet';
                          subtitleColor = AppColors.textSecondary;
                        } else if (isSettled) {
                          subtitle = 'Settled up';
                          subtitleColor = AppColors.textSecondary;
                        } else if (net > 0) {
                          subtitle = 'you are owed ₹${net.toStringAsFixed(2)}';
                          subtitleColor = AppColors.success;
                        } else {
                          subtitle = 'you owe ₹${(-net).toStringAsFixed(2)}';
                          subtitleColor = AppColors.warning;
                        }

                        return GestureDetector(
                          onTap: () {
                            if (isOwn) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      GroupDetailsScreen(group: group),
                                ),
                              );
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SharedGroupDetailsScreen(
                                    group: group,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    _iconFor(group.name),
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        group.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      if (isOwn)
                                        Text(
                                          subtitle,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: subtitleColor,
                                          ),
                                        )
                                      else
                                        FutureBuilder<String>(
                                          future: FriendService.getUserName(
                                            group.ownerId,
                                          ),
                                          builder: (context, ownerSnap) {
                                            final ownerName =
                                                ownerSnap.data ?? '...';
                                            return Text(
                                              'Shared by $ownerName',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color:
                                                    AppColors.textSecondary,
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                                if (!isOwn)
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textSecondary,
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
      },
    );
  }
}

class _OverallLine extends StatelessWidget {
  final double net;

  const _OverallLine({required this.net});

  @override
  Widget build(BuildContext context) {
    final isSettled = net.abs() <= 0.009;
    final String label;
    final Color color;
    if (isSettled) {
      label = 'Overall, you are settled up';
      color = AppColors.textSecondary;
    } else if (net > 0) {
      label = 'Overall, you are owed ₹${net.toStringAsFixed(2)}';
      color = AppColors.success;
    } else {
      label = 'Overall, you owe ₹${(-net).toStringAsFixed(2)}';
      color = AppColors.warning;
    }

    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}
