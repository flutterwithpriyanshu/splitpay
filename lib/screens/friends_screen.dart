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
import 'package:splitpay/services/local_notification_service.dart';
import 'package:splitpay/widgets/day_of_month_picker.dart';
import 'package:splitpay/screens/group_details_screen.dart';
import 'package:splitpay/screens/shared_group_details_screen.dart';
import 'package:splitpay/screens/friends/widgets/balance_widgets.dart';

class _RegisteredContact {
  const _RegisteredContact({required this.contact, required this.phone});

  final Contact contact;
  final String phone;
}

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
                children: [
                  const _GroupsTab(),
                  _FriendsTab(onAddFriend: () => _showAddFriendSheet(context)),
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
                          color: AppColors.primary.withValues(alpha: 0.1),
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

                              final contacts = await FlutterContacts.getAll(
                                properties: {
                                  ContactProperty.phone,
                                  ContactProperty.photoFullRes,
                                },
                              );
                              final candidates = contacts
                                  .map((contact) {
                                    final phone = contact.phones.isEmpty
                                        ? ''
                                        : normalizePhone(
                                            contact.phones.first.number,
                                          );
                                    return phone.isEmpty
                                        ? null
                                        : _RegisteredContact(
                                            contact: contact,
                                            phone: phone,
                                          );
                                  })
                                  .whereType<_RegisteredContact>()
                                  .toList();
                              final registered = <_RegisteredContact>[];
                              for (final candidate in candidates) {
                                if (await FriendService.findUserByPhone(
                                      candidate.phone,
                                    ) !=
                                    null) {
                                  registered.add(candidate);
                                }
                              }

                              if (!sheetContext.mounted) return;
                              if (registered.isEmpty) {
                                showAppToast(
                                  sheetContext,
                                  'No contacts with SplitPay accounts found',
                                );
                                return;
                              }

                              final selected =
                                  await showModalBottomSheet<
                                    _RegisteredContact
                                  >(
                                    context: sheetContext,
                                    backgroundColor: AppColors.surface,
                                    builder: (context) => SafeArea(
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: registered.length,
                                        itemBuilder: (context, index) {
                                          final candidate = registered[index];
                                          final photo =
                                              candidate.contact.photo?.fullSize;
                                          return ListTile(
                                            leading: photo == null
                                                ? const CircleAvatar(
                                                    child: Icon(Icons.person),
                                                  )
                                                : CircleAvatar(
                                                    backgroundImage:
                                                        MemoryImage(photo),
                                                  ),
                                            title: Text(
                                              candidate.contact.displayName ??
                                                  candidate.phone,
                                            ),
                                            subtitle: Text(candidate.phone),
                                            onTap: () => Navigator.pop(
                                              context,
                                              candidate,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                              if (selected == null || !sheetContext.mounted) {
                                return;
                              }
                              setSheetState(() {
                                nameController.text =
                                    selected.contact.displayName ?? '';
                                phoneController.text = selected.phone;
                                final photo = selected.contact.photo?.fullSize;
                                pendingContactPhoto =
                                    photo != null && photo.isNotEmpty
                                    ? photo
                                    : null;
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

                              final alreadyAdded =
                                  await FriendService.isFriendAlreadyAdded(
                                    phoneNumber: phone,
                                    linkedUid: linkedUid,
                                  );
                              if (alreadyAdded) {
                                setSheetState(() => isChecking = false);
                                if (sheetContext.mounted) {
                                  showAppToast(
                                    sheetContext,
                                    'Friend already added',
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
    int? settleUpDay;

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
                  Text(
                    'Settle up reminder (optional)',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showModalBottomSheet<int>(
                        context: sheetContext,
                        backgroundColor: AppColors.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (pickerContext) =>
                            DayOfMonthPicker(initialDay: settleUpDay),
                      );
                      if (picked != null) {
                        setSheetState(() => settleUpDay = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16),
                          const SizedBox(width: 10),
                          Text(
                            settleUpDay == null
                                ? 'Every month on... (tap to set)'
                                : 'Remind every month on day $settleUpDay',
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                        ],
                      ),
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
                                showAppToast(
                                  sheetContext,
                                  'Please enter a group name',
                                );
                                return;
                              }
                              if (selectedIds.length < 2) {
                                showAppToast(
                                  sheetContext,
                                  'Select at least 2 friends for a group',
                                );
                                return;
                              }

                              setSheetState(() => isSaving = true);
                              try {
                                final selectedMembers = liveFriends
                                    .where((f) => selectedIds.contains(f.id))
                                    .toList();
                                final createdGroup =
                                    await GroupService.createGroup(
                                      name,
                                      selectedMembers,
                                      settleUpDay: settleUpDay,
                                    );
                                if (settleUpDay != null) {
                                  await LocalNotificationService.scheduleMonthlySettleReminder(
                                    groupId: createdGroup.id,
                                    groupName: createdGroup.name,
                                    day: settleUpDay!,
                                    myNetBalance: 0,
                                  );
                                }
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              } catch (e) {
                                if (sheetContext.mounted) {
                                  setSheetState(() => isSaving = false);
                                  showAppToast(
                                    sheetContext,
                                    'Could not create group. Try again.',
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
  const _FriendsTab({required this.onAddFriend});

  final VoidCallback onAddFriend;

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No friends added yet',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onAddFriend,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Add Friend'),
                ),
              ],
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
class _GroupsTab extends StatefulWidget {
  const _GroupsTab();

  @override
  State<_GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<_GroupsTab> {
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
    final myUid = FirebaseAuth.instance.currentUser!.uid;

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

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final color = _colorFor(group.id);

                    return GestureDetector(
                      onTap: () {
                        final isOwn = group.ownerId == myUid;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => isOwn
                                ? GroupDetailsScreen(group: group)
                                : SharedGroupDetailsScreen(group: group),
                          ),
                        );
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                  FriendsGroupNetListener(
                                    group: group,
                                    myUid: myUid,
                                    friendById: friendById,
                                  ),
                                ],
                              ),
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
