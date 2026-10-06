import 'package:flutter/material.dart';
import 'package:splitpay/core/app_currency.dart';
import 'package:splitpay/core/bill_category.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

/// Shared UI pieces for EditBillScreen (friend bill) and
/// EditGroupBillView (group bill). UI only, no logic.

class EditBillTopBar extends StatelessWidget {
  const EditBillTopBar({super.key, this.title = 'Edit Bill'});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.headlineSm.copyWith(color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class EditBillCard extends StatelessWidget {
  const EditBillCard({super.key, required this.child, this.padding = 16});
  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

class EditBillBanner extends StatelessWidget {
  const EditBillBanner(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppText.bodySm.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Group chip + bill id + description field.
class EditBillHeaderCard extends StatelessWidget {
  const EditBillHeaderCard({
    super.key,
    required this.titleController,
    required this.billId,
    this.groupName,
    this.onChanged,
  });
  final TextEditingController titleController;
  final String billId;
  final String? groupName;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final v = billVisual(titleController.text);
    final shortId = billId.length >= 6 ? billId.substring(0, 6) : billId;
    return EditBillCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (groupName != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: AppColors.success),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            groupName!,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.labelMd.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                '#BILL-${shortId.toUpperCase()}',
                style: AppText.labelSm.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: v.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(v.icon, size: 20, color: v.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expense Description',
                        style: AppText.bodySm.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextField(
                        controller: titleController,
                        onChanged: (_) => onChanged?.call(),
                        style: AppText.labelLg.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                          hintText: 'e.g. Dinner',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditBillAmountCard extends StatelessWidget {
  const EditBillAmountCard({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onQuickAdd,
  });
  final TextEditingController controller;
  final VoidCallback onChanged;
  final ValueChanged<double> onQuickAdd;

  @override
  Widget build(BuildContext context) {
    return EditBillCard(
      padding: 20,
      child: Column(
        children: [
          Text(
            'Total Bill Amount',
            style: AppText.bodyMd.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppCurrency.symbol,
                style: AppText.currencyDisplay.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              IntrinsicWidth(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 80, maxWidth: 220),
                  child: TextField(
                    controller: controller,
                    onChanged: (_) => onChanged(),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: AppText.currencyDisplay.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '0',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [100.0, 500.0, 1000.0]
                .map(
                  (v) => ActionChip(
                    onPressed: () => onQuickAdd(v),
                    backgroundColor: AppColors.primaryTint,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    label: Text(
                      '+${AppCurrency.symbol}${v.toInt()}',
                      style: AppText.labelMd.copyWith(color: AppColors.primary),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Date tile (tap to pick).
class EditBillDateTile extends StatelessWidget {
  const EditBillDateTile({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date',
              style: AppText.labelMd.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.labelMd.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Paid-by tile wrapper: label + any child (dropdown).
class EditBillPaidByTile extends StatelessWidget {
  const EditBillPaidByTile({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paid by',
            style: AppText.labelMd.copyWith(color: AppColors.textSecondary),
          ),
          child,
        ],
      ),
    );
  }
}

class EditBillSegment extends StatelessWidget {
  const EditBillSegment({
    super.key,
    required this.custom,
    required this.onChanged,
  });
  final bool custom;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool selected, VoidCallback onTap) => Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.inner),
          ),
          child: Text(
            label,
            style: AppText.labelMd.copyWith(
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          tab('Equal', !custom, () => onChanged(false)),
          tab('Custom', custom, () => onChanged(true)),
        ],
      ),
    );
  }
}

class EditBillBalanceBar extends StatelessWidget {
  const EditBillBalanceBar({super.key, required this.left});

  /// amount - assigned. 0 = balanced, >0 left, <0 over.
  final double left;

  @override
  Widget build(BuildContext context) {
    final ok = left.abs() < 0.01;
    final c = ok ? AppColors.success : AppColors.error;
    final tint = ok ? AppColors.successTint : AppColors.dangerTint;
    final text = ok
        ? '${AppCurrency.symbol}0 left to assign'
        : left > 0
        ? '${AppCurrency.symbol}${left.toStringAsFixed(2)} left to assign'
        : 'Over by ${AppCurrency.symbol}${(-left).toStringAsFixed(2)}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
            size: 20,
            color: c,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppText.labelMd.copyWith(color: c))),
          Text(
            ok ? 'BALANCED' : 'UNBALANCED',
            style: AppText.labelSm.copyWith(color: c),
          ),
        ],
      ),
    );
  }
}

/// One person row: avatar, name, share %, amount (field or text).
class EditBillPersonRow extends StatelessWidget {
  const EditBillPersonRow({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.subtitle,
    this.controller,
    this.fixedAmount,
    this.badge,
    this.onChanged,
  });
  final String name;
  final String avatarUrl;
  final String subtitle;
  final TextEditingController? controller;
  final double? fixedAmount;
  final String? badge;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          EditBillAvatar(name: name, url: avatarUrl, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.labelMd.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          badge!,
                          style: AppText.labelSm.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  subtitle,
                  style: AppText.bodySm.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 104,
            child: controller != null
                ? TextField(
                    controller: controller,
                    onChanged: (_) => onChanged?.call(),
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: AppText.currencyMd.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixText: AppCurrency.symbol,
                      hintText: '0',
                    ),
                  )
                : Text(
                    '${AppCurrency.symbol}${(fixedAmount ?? 0).toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: AppText.currencyMd.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class EditBillAvatar extends StatelessWidget {
  const EditBillAvatar({
    super.key,
    required this.name,
    required this.url,
    this.size = 48,
    this.selected = false,
  });
  final String name;
  final String url;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: AppColors.primaryTint,
          backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
          child: url.isEmpty
              ? Text(
                  initial,
                  style: AppText.labelMd.copyWith(color: AppColors.primary),
                )
              : null,
        ),
        if (selected)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: const Icon(Icons.check, size: 10, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

/// Selectable avatar tile for "Split with" row.
class EditBillPickAvatar extends StatelessWidget {
  const EditBillPickAvatar({
    super.key,
    required this.name,
    required this.url,
    required this.selected,
    required this.onTap,
  });
  final String name;
  final String url;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Opacity(
              opacity: selected ? 1 : 0.45,
              child: EditBillAvatar(
                name: name,
                url: url,
                size: 52,
                selected: selected,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.bodySm.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class EditBillBottomBar extends StatelessWidget {
  const EditBillBottomBar({
    super.key,
    required this.billId,
    required this.saving,
    required this.onSave,
    required this.onDelete,
  });
  final String billId;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final shortId = billId.length >= 6 ? billId.substring(0, 6) : billId;
    return Column(
      children: [
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: saving ? null : onDelete,
          icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
          label: Text.rich(
            TextSpan(
              text: 'Delete this bill ',
              style: AppText.labelMd.copyWith(color: AppColors.error),
              children: [
                TextSpan(
                  text: '(#BILL-${shortId.toUpperCase()})',
                  style: AppText.bodySm.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: TextButton(
                  onPressed: saving ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryTint,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: AppText.labelLg.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: saving ? null : onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Save Changes',
                              style: AppText.labelLg.copyWith(color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt_rounded, size: 14, color: AppColors.success),
            const SizedBox(width: 4),
            Text(
              'Instant sync with group ledger',
              style: AppText.bodySm.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class EditBillLocked extends StatelessWidget {
  const EditBillLocked({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const EditBillTopBar(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 48,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "This bill can't be edited",
                        style: AppText.labelLg.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppText.bodyMd.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirm + delete helper used by both edit views.
Future<bool> confirmDeleteBill(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete this bill?'),
      content: const Text('This removes it for everyone. Cannot undo.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('Delete', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  return ok == true;
}
