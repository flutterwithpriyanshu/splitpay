import 'package:flutter/material.dart';
import 'package:splitpay/core/friend_balance.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/screens/add_bill/widgets/add_friend_sheet.dart';
import 'package:splitpay/screens/select_friends/widgets/add_friend_banner.dart';
import 'package:splitpay/screens/select_friends/widgets/friend_pick_row.dart';
import 'package:splitpay/screens/select_friends/widgets/friend_search_field.dart';
import 'package:splitpay/screens/select_friends/widgets/friend_section_header.dart';
import 'package:splitpay/screens/select_friends/widgets/select_friends_bar.dart';
import 'package:splitpay/screens/select_friends/widgets/selected_friends_card.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/app_ui.dart';

/// Full friend picker (Add Bill / Edit Bill "See all").
/// Pops `Set<String>` of picked friend ids on Confirm, null on back.
class SelectFriendsScreen extends StatefulWidget {
  const SelectFriendsScreen({
    super.key,
    required this.friends,
    required this.initialSelected,
    this.allowAddNew = true,
  });

  final List<Friend> friends;
  final Set<String> initialSelected;

  /// false inside a group: members are fixed.
  final bool allowAddNew;

  @override
  State<SelectFriendsScreen> createState() => _SelectFriendsScreenState();
}

class _SelectFriendsScreenState extends State<SelectFriendsScreen> {
  final _search = TextEditingController();
  late final Set<String> _selected = {...widget.initialSelected};
  final List<Friend> _added = [];
  late final _bills = BillService.streamBills();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Friend> get _all => [
    ...widget.friends,
    ..._added.where((a) => !widget.friends.any((f) => f.id == a.id)),
  ];

  void _toggle(String id) => setState(() {
    if (!_selected.remove(id)) _selected.add(id);
  });

  bool _match(Friend f) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return f.name.toLowerCase().contains(q) ||
        (f.phoneNumber ?? '').contains(q);
  }

  void _selectAll(List<Friend> all, bool allOn) => setState(() {
    if (allOn) {
      _selected.removeAll(all.map((f) => f.id));
    } else {
      _selected.addAll(all.map((f) => f.id));
    }
  });

  Widget _section(
    List<Friend> list,
    List<Bill> bills, {
    required String title,
    required String trailing,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FriendSectionHeader(title: title, trailing: trailing, icon: icon),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            children: [
              for (final f in list)
                FriendPickRow(
                  friend: f,
                  selected: _selected.contains(f.id),
                  balance: friendBalance(bills, f),
                  onTap: () => _toggle(f.id),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = _all;
    final allOn = all.isNotEmpty && all.every((f) => _selected.contains(f.id));
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: SelectFriendsBar(
        count: _selected.length,
        onConfirm: () => Navigator.of(context).pop(_selected),
      ),
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Bill>>(
          stream: _bills,
          builder: (context, snap) {
            final bills = snap.data ?? const <Bill>[];
            final recentIds = recentFriendIds(bills, all);
            final recent = [
              for (final id in recentIds) all.firstWhere((f) => f.id == id),
            ].where(_match).toList();
            final rest = all
                .where((f) => !recentIds.contains(f.id) && _match(f))
                .toList()
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );
            final picked = all.where((f) => _selected.contains(f.id)).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Friends',
                              style: AppText.headlineMd.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Choose people to split this bill with',
                              style: AppText.bodySm.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (all.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => _selectAll(all, allOn),
                          icon: Icon(
                            Icons.done_all_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            allOn
                                ? 'Deselect All'
                                : 'Select All (${all.length})',
                            style: AppText.labelMd.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      FriendSearchField(
                        controller: _search,
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      SelectedFriendsCard(
                        selected: picked,
                        total: all.length,
                        onRemove: _toggle,
                        onClear: () => setState(_selected.clear),
                      ),
                      if (widget.allowAddNew) ...[
                        const SizedBox(height: 16),
                        AddFriendBanner(
                          onTap: () => showAddFriendSheet(
                            context,
                            onAdded: (f) => setState(() {
                              _added.add(f);
                              _selected.add(f.id);
                            }),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (recent.isNotEmpty)
                        _section(
                          recent,
                          bills,
                          title: 'RECENT BILL ADDED',
                          icon: Icons.groups_rounded,
                          trailing:
                              '${recent.where((f) => _selected.contains(f.id)).length} of ${recent.length} added',
                        ),
                      if (rest.isNotEmpty)
                        _section(
                          rest,
                          bills,
                          title: 'ALL FRIENDS (A-Z)',
                          trailing: '${rest.length} contacts',
                        ),
                      if (recent.isEmpty && rest.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Center(
                            child: Text(
                              'No friends found',
                              style: AppText.bodyMd.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
