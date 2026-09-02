import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/theme/app_colors.dart';

class AddBillSplitChip extends StatelessWidget {
  const AddBillSplitChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class AddBillPaidByDropdown extends StatelessWidget {
  const AddBillPaidByDropdown({
    required this.value,
    required this.friends,
    required this.selectedFriendIds,
    required this.onChanged,
    super.key,
  });

  final String? value;
  final List<Friend> friends;
  final Set<String> selectedFriendIds;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          hint: Text('You', style: GoogleFonts.inter(fontSize: 14)),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('You', style: GoogleFonts.inter(fontSize: 14)),
            ),
            ...friends
                .where((friend) => selectedFriendIds.contains(friend.id))
                .map(
                  (friend) => DropdownMenuItem<String?>(
                    value: friend.id,
                    child: Text(
                      friend.name,
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ),
                ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class AddBillLabel extends StatelessWidget {
  const AddBillLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class AddBillField extends StatelessWidget {
  const AddBillField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.dense = false,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        isDense: dense,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: dense ? 12 : 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
