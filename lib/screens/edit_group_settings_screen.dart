import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/model/group.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/services/group_service.dart';
import 'package:splitpay/theme/app_colors.dart';

const _kGroupTypes = ['Trip', 'Home', 'Couple', 'Apartment', 'Other'];

/// "Edit Group Settings" — rename, manage members, pick a group type, and
/// flip "Simplify group debts" on/off. Only meant to be opened by the
/// group owner (that's who GroupDetailsScreen shows the gear icon to).
class EditGroupSettingsScreen extends StatefulWidget {
  final Group group;

  const EditGroupSettingsScreen({super.key, required this.group});

  @override
  State<EditGroupSettingsScreen> createState() =>
      _EditGroupSettingsScreenState();
}

class _EditGroupSettingsScreenState extends State<EditGroupSettingsScreen> {
  late final TextEditingController _nameController;
  late List<String> _memberFriendIds;
  late String _groupType;
  late bool _simplifyDebts;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _memberFriendIds = [...widget.group.memberFriendIds];
    _groupType = _kGroupTypes.contains(widget.group.groupType)
        ? widget.group.groupType
        : 'Other';
    _simplifyDebts = widget.group.simplifyDebts;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showSimplifyInfo() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          'This setting automatically combines debts to reduce the total '
          'number of repayments between group members.\n\n'
          'For example, if you owe Anna \u20b910 and Anna owes Bob \u20b910, a '
          'group with simplified debts will tell you to pay Bob \u20b910 '
          'directly.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _addPerson(List<Friend> allFriends) async {
    final available = allFriends
        .where((f) => !_memberFriendIds.contains(f.id))
        .toList();
    if (available.isEmpty) {
      showAppToast(context, 'All your friends are already in this group');
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add a person',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: available.length,
                    itemBuilder: (context, index) {
                      final friend = available[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Icon(
                            Icons.person_rounded,
                            color: AppColors.primary.withOpacity(0.4),
                          ),
                        ),
                        title: Text(
                          friend.name,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        onTap: () => Navigator.pop(sheetContext, friend.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) {
      setState(() => _memberFriendIds.add(picked));
    }
  }

  /// True only when every bill tagged to this group has zero outstanding
  /// balance for every participant — i.e. the whole group is settled up.
  Future<bool> _isGroupFullySettled() async {
    final bills = await BillService.streamGroupBills(widget.group.id).first;
    return bills.every(
      (bill) => bill.participantUids.every(
        (uid) => bill.remainingForUid(uid) <= 0.009,
      ),
    );
  }

  Future<void> _deleteGroup() async {
    final settled = await _isGroupFullySettled();
    if (!settled) {
      if (mounted) {
        showAppToast(
          context,
          'Everyone must settle up before the group can be deleted',
        );
      }
      return;
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete group?'),
        content: const Text(
          'Everyone is settled up. This removes the group for all members '
          '— bills already added stay on each friend\'s individual balance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await GroupService.deleteGroup(widget.group.id);
      if (mounted) {
        Navigator.of(context).pop(); // settings screen
        Navigator.of(context).pop(); // group details screen
      }
    } catch (error) {
      if (mounted) showAppToast(context, error.toString());
    }
  }

  Future<void> _save(List<Friend> allFriends) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showAppToast(context, 'Group name can\'t be empty');
      return;
    }
    if (_memberFriendIds.length < 1) {
      showAppToast(context, 'A group needs at least one member');
      return;
    }
    setState(() => _isSaving = true);
    final members = allFriends
        .where((f) => _memberFriendIds.contains(f.id))
        .toList();
    try {
      await GroupService.updateSettings(
        widget.group.id,
        name: name,
        members: members,
        groupType: _groupType,
        simplifyDebts: _simplifyDebts,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) showAppToast(context, error.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Edit Group Settings',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      body: StreamBuilder<List<Friend>>(
        stream: FriendService.streamFriends(),
        builder: (context, snapshot) {
          final allFriends = snapshot.data ?? [];
          final friendById = {for (final f in allFriends) f.id: f};
          final members = _memberFriendIds
              .map((id) => friendById[id])
              .whereType<Friend>()
              .toList();

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(
                  'My group is called...',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Divider(color: AppColors.divider),
                const SizedBox(height: 16),
                Text(
                  'GROUP MEMBERS',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ...members.map(
                  (friend) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Icon(
                            Icons.person_rounded,
                            color: AppColors.primary.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            friend.phoneNumber == null
                                ? friend.name
                                : '${friend.name} (${friend.phoneNumber})',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            if (members.length <= 1) {
                              showAppToast(
                                context,
                                'A group needs at least one member',
                              );
                              return;
                            }
                            setState(() => _memberFriendIds.remove(friend.id));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _addPerson(allFriends),
                  child: Text(
                    '+ Add a person',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Divider(color: AppColors.divider),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'SIMPLIFY GROUP DEBTS?',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Switch(
                      value: _simplifyDebts,
                      activeColor: Colors.white,
                      activeTrackColor: AppColors.primary,
                      onChanged: (value) =>
                          setState(() => _simplifyDebts = value),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.help_outline_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: _showSimplifyInfo,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppColors.divider),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : () => _save(allFriends),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Save changes',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed:
                        widget.group.ownerId ==
                            FirebaseAuth.instance.currentUser?.uid
                        ? _deleteGroup
                        : null,
                    child: Text(
                      'delete group',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}