import 'package:flutter/material.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/screens/add_bill/widgets/add_bill_info_tile.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/widgets/local_avatar.dart';

/// "Paid by" tile + popup. value null = You.
class AddBillPaidByTile extends StatelessWidget {
  const AddBillPaidByTile({
    super.key,
    required this.value,
    required this.friends,
    required this.selectedIds,
    required this.onChanged,
  });

  final String? value;
  final List<Friend> friends;
  final Set<String> selectedIds;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final payer = value == null
        ? null
        : friends.where((f) => f.id == value).firstOrNull;
    return PopupMenuButton<String>(
      tooltip: '',
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      onSelected: (v) => onChanged(v.isEmpty ? null : v),
      itemBuilder: (_) => [
        const PopupMenuItem(value: '', child: Text('You')),
        for (final f in friends.where((f) => selectedIds.contains(f.id)))
          PopupMenuItem(value: f.id, child: Text(f.name)),
      ],
      child: AddBillInfoTile(
        label: 'Paid by',
        value: payer?.name ?? 'You',
        leading: payer == null
            ? CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.success,
                child: const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              )
            : LocalAvatar(
                localKey: payer.id,
                isProfile: false,
                fallbackUrl: payer.avatarUrl.isEmpty ? null : payer.avatarUrl,
                radius: 14,
              ),
      ),
    );
  }
}
