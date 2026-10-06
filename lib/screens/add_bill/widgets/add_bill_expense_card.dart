import 'package:flutter/material.dart';
import 'package:splitpay/core/add_bill_category.dart';
import 'package:splitpay/core/app_date_format.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/screens/add_bill/widgets/add_bill_info_tile.dart';
import 'package:splitpay/screens/add_bill/widgets/bare_input.dart';
import 'package:splitpay/screens/add_bill/widgets/category_chip_row.dart';
import 'package:splitpay/screens/add_bill/widgets/paid_by_tile.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/app_ui.dart';

/// Title, category, date, paid by, note.
class AddBillExpenseCard extends StatelessWidget {
  const AddBillExpenseCard({
    super.key,
    required this.titleController,
    required this.noteController,
    required this.category,
    required this.onCategory,
    required this.date,
    required this.onPickDate,
    required this.paidByFriendId,
    required this.friends,
    required this.selectedIds,
    required this.onPaidBy,
  });

  final TextEditingController titleController;
  final TextEditingController noteController;
  final AddBillCategory? category;
  final ValueChanged<AddBillCategory?> onCategory;
  final DateTime date;
  final VoidCallback onPickDate;
  final String? paidByFriendId;
  final List<Friend> friends;
  final Set<String> selectedIds;
  final ValueChanged<String?> onPaidBy;

  String get _dateLabel {
    final now = DateTime.now();
    final today =
        now.year == date.year && now.month == date.month && now.day == date.day;
    return today
        ? 'Today, ${date.day} ${monthAbbr(date)}'
        : '${date.day} ${monthAbbr(date)} ${date.year}';
  }

  Widget _boxed(Widget child) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.control),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final hint = AppText.bodyMd.copyWith(color: AppColors.textSecondary);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _boxed(
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(AppRadius.inner),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expense title',
                        style: AppText.bodySm.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextField(
                        controller: titleController,
                        textCapitalization: TextCapitalization.sentences,
                        style: AppText.bodyLg.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: bareInput('e.g. Dinner at Cafe', hintStyle: hint),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AddBillCategoryRow(selected: category, onSelect: onCategory),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AddBillInfoTile(
                  label: 'Date',
                  value: _dateLabel,
                  onTap: onPickDate,
                  leading: Icon(
                    Icons.calendar_today_outlined,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AddBillPaidByTile(
                  value: paidByFriendId,
                  friends: friends,
                  selectedIds: selectedIds,
                  onChanged: onPaidBy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _boxed(
            Row(
              children: [
                Icon(
                  Icons.notes_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: noteController,
                    style: AppText.bodyMd.copyWith(color: AppColors.textPrimary),
                    decoration: bareInput('Add a note (optional)', hintStyle: hint),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
