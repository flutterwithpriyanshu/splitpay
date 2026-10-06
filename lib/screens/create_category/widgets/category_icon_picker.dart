import 'package:flutter/material.dart';
import 'package:splitpay/core/custom_category_store.dart';
import 'package:splitpay/core/emoji_catalog.dart';
import 'package:splitpay/core/icon_catalog.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

/// "Fun Emojis" / "Fintech Icons" picker with search + custom emoji.
/// Exactly one of [emoji] / [iconKey] is set.
class CategoryIconPicker extends StatefulWidget {
  const CategoryIconPicker({
    super.key,
    required this.emoji,
    required this.iconKey,
    required this.accent,
    required this.onEmoji,
    required this.onIcon,
  });
  final String? emoji;
  final String? iconKey;
  final Color accent;
  final ValueChanged<String> onEmoji;
  final ValueChanged<String> onIcon;

  @override
  State<CategoryIconPicker> createState() => _CategoryIconPickerState();
}

class _CategoryIconPickerState extends State<CategoryIconPicker> {
  final _search = TextEditingController();
  late bool _emojiTab = widget.iconKey == null;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _addCustom() async {
    final ctrl = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom emoji'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Type or paste any emoji. Use your keyboard emoji key.'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32),
              decoration: const InputDecoration(hintText: '😀'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (value == null || value.isEmpty) return;
    // Must contain a non-ASCII symbol (emoji), max one glyph-ish length.
    final hasEmoji = value.runes.any((r) => r > 0x2000);
    if (!hasEmoji || value.length > 16) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter one emoji')),
      );
      return;
    }
    await CustomCategoryStore.instance.addEmoji(value);
    widget.onEmoji(value);
    if (mounted) setState(() => _emojiTab = true);
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text;
    final custom = CustomCategoryStore.instance.customEmojis;
    final emojis = _emojiTab
        ? [
            if (q.trim().isEmpty) ...custom,
            ...searchEmojis(q).where(
              (e) => q.trim().isNotEmpty || !custom.contains(e),
            ),
          ]
        : const <String>[];
    final icons = _emojiTab ? const <CategoryIcon>[] : searchCategoryIcons(q);
    final count = _emojiTab ? emojis.length : icons.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Select Icon',
              style: AppText.headlineSm.copyWith(color: AppColors.textPrimary),
            ),
            const Spacer(),
            Text(
              '$count ${_emojiTab ? 'emojis' : 'icons'}',
              style: AppText.labelMd.copyWith(color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: Row(
            children: [
              _Tab('Fun Emojis', _emojiTab, () => setState(() => _emojiTab = true)),
              _Tab('Fintech Icons', !_emojiTab, () => setState(() => _emojiTab = false)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 180,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: count == 0
              ? Center(
                  child: Text(
                    'Nothing found. Try Custom.',
                    style: AppText.bodyMd.copyWith(color: AppColors.textSecondary),
                  ),
                )
              : GridView.builder(
                  itemCount: count,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemBuilder: (_, i) {
                    final bool selected;
                    final Widget glyph;
                    final VoidCallback tap;
                    if (_emojiTab) {
                      final e = emojis[i];
                      selected = widget.emoji == e;
                      glyph = Text(e, style: const TextStyle(fontSize: 24));
                      tap = () => widget.onEmoji(e);
                    } else {
                      final ic = icons[i];
                      selected = widget.iconKey == ic.key;
                      glyph = Icon(ic.icon, size: 24, color: widget.accent);
                      tap = () => widget.onIcon(ic.key);
                    }
                    return GestureDetector(
                      onTap: tap,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.surface
                              : AppColors.surface.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? widget.accent : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: glyph,
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                style: AppText.bodyMd.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.primaryTint,
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
                  hintText: _emojiTab
                      ? 'Search emoji (e.g. tacos, fuel, trip)'
                      : 'Search icon (e.g. bank, wifi, gym)',
                  hintStyle: AppText.bodySm.copyWith(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: TextButton.icon(
                onPressed: _addCustom,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primaryTint,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                ),
                icon: Icon(Icons.add_reaction_outlined, size: 18, color: AppColors.primary),
                label: Text(
                  'Custom',
                  style: AppText.labelMd.copyWith(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab(this.label, this.selected, this.onTap);
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
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
  }
}
