import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/model/group.dart';
import 'package:splitpay/services/group_service.dart';
import 'package:splitpay/services/local_notification_service.dart';
import 'package:splitpay/widgets/day_of_month_picker.dart';
import 'package:splitpay/widgets/local_avatar.dart';
import 'package:splitpay/screens/group_details_screen.dart';
import 'package:splitpay/screens/shared_group_details_screen.dart';
import 'package:splitpay/screens/friends/widgets/balance_widgets.dart';

/// Bottom-nav "Groups" screen. Real, persisted groups (see Group model /
/// GroupService). Create a group with 2+ friends, then add bills straight
/// into it from its details screen; those bills auto-split across the
/// group's members. Split out of FriendsScreen so it's its own tab.
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Groups',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(child: _GroupsTab()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCreateGroupSheet(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.group_add_rounded, color: Colors.white),
      ),
    );
  }

  /// Public + static so other screens (FriendsScreen's multi-select "Add
  /// to Group" flow) can open the exact same sheet, optionally with
  /// friends already checked off.
  static void showCreateGroupSheet(
    BuildContext context, {
    Set<String> preselectedIds = const {},
  }) {
    final nameController = TextEditingController();
    final searchController = TextEditingController();
    final Set<String> selectedIds = {...preselectedIds};
    String searchQuery = '';
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
              child: SingleChildScrollView(
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
                    StreamBuilder<List<Friend>>(
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

                        // Recent 4 = newest createdAt first. Friends with
                        // no createdAt (older docs written before this
                        // field existed) sink to the bottom instead of
                        // crashing the sort.
                        final recentSorted = [...friends]
                          ..sort((a, b) {
                            final ad = a.createdAt;
                            final bd = b.createdAt;
                            if (ad == null && bd == null) return 0;
                            if (ad == null) return 1;
                            if (bd == null) return -1;
                            return bd.compareTo(ad);
                          });
                        final recentFour = recentSorted.take(4).toList();

                        final query = searchQuery.trim().toLowerCase();
                        final filtered = query.isEmpty
                            ? friends
                            : friends
                                  .where(
                                    (f) => f.name.toLowerCase().contains(query),
                                  )
                                  .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (query.isEmpty && recentFour.isNotEmpty) ...[
                              Text(
                                'Recent',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 78,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: recentFour.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 14),
                                  itemBuilder: (context, index) {
                                    final friend = recentFour[index];
                                    final isSelected = selectedIds.contains(
                                      friend.id,
                                    );
                                    return GestureDetector(
                                      onTap: () => setSheetState(() {
                                        isSelected
                                            ? selectedIds.remove(friend.id)
                                            : selectedIds.add(friend.id);
                                      }),
                                      child: Column(
                                        children: [
                                          Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              LocalAvatar(
                                                localKey: friend.id,
                                                isProfile: false,
                                                fallbackUrl: friend.avatarUrl,
                                                radius: 24,
                                              ),
                                              if (isSelected)
                                                Positioned(
                                                  right: -2,
                                                  bottom: -2,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color:
                                                            AppColors.surface,
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.check,
                                                      size: 12,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            width: 56,
                                            child: Text(
                                              friend.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            TextField(
                              controller: searchController,
                              onChanged: (val) =>
                                  setSheetState(() => searchQuery = val),
                              decoration: InputDecoration(
                                hintText: 'Search friends by name',
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: AppColors.background,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 220),
                              child: filtered.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Text(
                                        'No friends match "$searchQuery"',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: filtered.length,
                                      itemBuilder: (context, index) {
                                        final friend = filtered[index];
                                        final isSelected = selectedIds.contains(
                                          friend.id,
                                        );
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
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        );
                      },
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
              ),
            );
          },
        );
      },
    );
  }
}

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
                        'No groups yet. Tap the + button below to create one.',
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
