import 'package:flutter/material.dart';
import 'package:splitpay/core/money_format.dart';
import 'package:splitpay/core/split_math.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/screens/add_bill/widgets/share_banner.dart';
import 'package:splitpay/screens/add_bill/widgets/share_row.dart';
import 'package:splitpay/screens/add_bill/widgets/split_mode_toggle.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/app_ui.dart';
import 'package:splitpay/widgets/local_avatar.dart';

/// Split mode toggle + per-person share rows (equal = read-only).
class AddBillSplitModeCard extends StatelessWidget {
  const AddBillSplitModeCard({
    super.key,
    required this.method,
    required this.onMethod,
    required this.amount,
    required this.friends,
    required this.controllers,
    required this.meController,
    required this.onChanged,
    required this.onSplitEvenly,
    required this.onSplitRemaining,
  });

  final SplitMethod method;
  final ValueChanged<SplitMethod> onMethod;
  final double amount;
  final List<Friend> friends;
  final Map<String, TextEditingController> controllers;
  final TextEditingController meController;
  final VoidCallback onChanged;
  final VoidCallback onSplitEvenly;
  final VoidCallback onSplitRemaining;

  String _pct(double share) =>
      amount > 0 ? '${(share / amount * 100).toStringAsFixed(1)}% share' : '-';

  @override
  Widget build(BuildContext context) {
    final custom = method == SplitMethod.custom;
    final math = SplitMath.fromControllers(
      amount: amount,
      ids: friends.map((f) => f.id),
      controllers: controllers,
      me: meController,
    );
    final equal = amount > 0 ? amount / (friends.length + 1) : 0.0;
    final showFooter =
        custom && math.unassignedFriends > 0 && math.remaining > 0.005;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Split Mode',
                  style: AppText.headlineSm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SplitModeToggle(value: method, onChanged: onMethod),
            ],
          ),
          const SizedBox(height: 14),
          if (custom && amount > 0 && math.left.abs() > 0.005) ...[
            AddBillShareBanner(left: math.left, onSplitEvenly: onSplitEvenly),
            const SizedBox(height: 12),
          ],
          AddBillShareRow(
            name: 'You',
            subtitle: _pct(custom ? math.meValue : equal),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryTint,
              child: Text(
                'YOU',
                style: AppText.labelSm.copyWith(color: AppColors.primary),
              ),
            ),
            controller: custom ? meController : null,
            value: plainAmount(equal),
            hint: plainAmount(math.meValue),
            onChanged: onChanged,
          ),
          for (final f in friends) ...[
            const SizedBox(height: 10),
            AddBillShareRow(
              name: f.name,
              subtitle: custom && math.needsShare(f.id)
                  ? 'Unassigned'
                  : _pct(custom ? math.friendValue(f.id) : equal),
              leading: LocalAvatar(
                localKey: f.id,
                isProfile: false,
                fallbackUrl: f.avatarUrl.isEmpty ? null : f.avatarUrl,
                radius: 22,
              ),
              controller: custom ? controllers[f.id] : null,
              value: plainAmount(equal),
              needsShare: custom && math.needsShare(f.id),
              onChanged: onChanged,
            ),
          ],
          if (showFooter) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onSplitRemaining,
              icon: Icon(
                Icons.balance_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              label: Text(
                'Split remaining ${formatMoney(math.remaining)} equally',
                style: AppText.labelMd.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
