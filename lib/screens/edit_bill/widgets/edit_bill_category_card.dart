import 'package:flutter/material.dart';
import 'package:splitpay/core/custom_category.dart';
import 'package:splitpay/core/custom_category_store.dart';
import 'package:splitpay/screens/create_category_screen.dart';
import 'package:splitpay/screens/edit_bill/widgets/edit_bill_parts.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

/// Category chips + "Create category" link. Custom chips: long press
/// to delete. Selection is kept by the parent and saved locally.
class EditBillCategoryCard extends StatelessWidget {
  const EditBillCategoryCard({
    super.key,
    required this.selectedId,
    required this.onSelected,
    this.groupId,
  });
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final String? groupId;

  Future<void> _create(BuildContext context) async {
    final res = await Navigator.of(context).push<BillCategoryOption>(
      MaterialPageRoute(
        builder: (_) => CreateCategoryScreen(initialGroupId: groupId),
      ),
    );
    if (res != null) onSelected(res.id);
  }

  Future<void> _delete(BuildContext context, BillCategoryOption c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${c.name}"?'),
        content: const Text('Removes this category from this device.'),
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
    if (ok != true) return;
    await CustomCategoryStore.instance.deleteCategory(c.id);
    if (selectedId == c.id) onSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CustomCategoryStore.instance,
      builder: (context, _) {
        final cats = CustomCategoryStore.instance.all;
        return EditBillCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Category',
                    style: AppText.labelLg.copyWith(color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => _create(context),
                    child: Row(
                      children: [
                        Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 2),
                        Text(
                          'Create category',
                          style: AppText.labelMd.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final c in cats)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _Chip(
                          cat: c,
                          selected: c.id == selectedId,
                          onTap: () =>
                              onSelected(c.id == selectedId ? null : c.id),
                          onLongPress: c.custom ? () => _delete(context, c) : null,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.cat,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });
  final BillCategoryOption cat;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.textPrimary;
    final Widget glyph = cat.emoji != null
        ? Text(cat.emoji!, style: const TextStyle(fontSize: 16))
        : Icon(cat.icon ?? Icons.category_rounded, size: 18, color: selected ? Colors.white : cat.color);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.primaryTint,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            glyph,
            const SizedBox(width: 6),
            Text(cat.name, style: AppText.labelMd.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}
