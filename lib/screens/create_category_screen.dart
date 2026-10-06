import 'package:flutter/material.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/core/custom_category.dart';
import 'package:splitpay/core/custom_category_store.dart';
import 'package:splitpay/model/group.dart';
import 'package:splitpay/screens/create_category/widgets/category_accent_picker.dart';
import 'package:splitpay/screens/create_category/widgets/category_icon_picker.dart';
import 'package:splitpay/screens/create_category/widgets/category_preview_card.dart';
import 'package:splitpay/screens/create_category/widgets/category_rules_card.dart';
import 'package:splitpay/services/group_service.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/app_ui.dart';

/// New custom category. Saved in a local file on this device only
/// (see CustomCategoryStore). Pops with the created [BillCategoryOption].
class CreateCategoryScreen extends StatefulWidget {
  const CreateCategoryScreen({super.key, this.initialGroupId});
  final String? initialGroupId;

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  static const _maxName = 30;

  final _name = TextEditingController();
  final _cap = TextEditingController(text: '5000');

  int _tone = 0;
  String? _emoji = '🏷️';
  String? _iconKey;
  String _split = 'equal';
  String? _groupId;
  bool _capEnabled = false;
  List<Group> _groups = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _groupId = widget.initialGroupId;
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final own = await GroupService.streamGroups().first;
      final shared = await GroupService.streamSharedGroups().first;
      if (mounted) setState(() => _groups = [...own, ...shared]);
    } catch (_) {}
  }

  @override
  void dispose() {
    _name.dispose();
    _cap.dispose();
    super.dispose();
  }

  Group? get _group {
    for (final g in _groups) {
      if (g.id == _groupId) return g;
    }
    return null;
  }

  String get _splitLabel => switch (_split) {
    'shares' => 'By Shares',
    'percentage' => 'Percentage',
    _ => 'Split Equally',
  };

  void _reset() {
    setState(() {
      _name.clear();
      _cap.text = '5000';
      _tone = 0;
      _emoji = '🏷️';
      _iconKey = null;
      _split = 'equal';
      _groupId = widget.initialGroupId;
      _capEnabled = false;
    });
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showAppToast(context, 'Enter a category name');
      return;
    }
    final store = CustomCategoryStore.instance;
    if (store.all.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
      showAppToast(context, 'Category "$name" already exists');
      return;
    }
    final cap = double.tryParse(_cap.text.trim()) ?? 0;
    if (_capEnabled && cap <= 0) {
      showAppToast(context, 'Enter a valid monthly cap');
      return;
    }
    setState(() => _saving = true);
    final g = _group;
    final cat = BillCategoryOption(
      id: 'c_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      colorValue: categoryTones[_tone].color.toARGB32(),
      emoji: _emoji,
      iconKey: _emoji == null ? _iconKey : null,
      defaultSplit: _split,
      groupId: g?.id,
      groupName: g?.name,
      capEnabled: _capEnabled,
      capAmount: _capEnabled ? cap : 0,
      custom: true,
    );
    await store.addCategory(cat);
    if (!mounted) return;
    showAppToast(context, 'Category "$name" created', isError: false);
    Navigator.of(context).pop(cat);
  }

  Widget _section(Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final tone = categoryTones[_tone];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded, color: AppColors.textPrimary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'New Category',
                      textAlign: TextAlign.center,
                      style: AppText.headlineSm.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _reset,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'Reset',
                        style: AppText.labelMd.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Create a custom category for tailored group expenses',
              style: AppText.bodySm.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  _section(
                    CategoryPreviewCard(
                      name: _name.text,
                      color: tone.color,
                      emoji: _emoji,
                      iconKey: _iconKey,
                      splitLabel: _splitLabel,
                      groupName: _group?.name,
                    ),
                  ),
                  _section(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Category Name ',
                              style: AppText.headlineSm.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '*',
                              style: AppText.headlineSm.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_name.text.length} / $_maxName',
                              style: AppText.labelMd.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _name,
                          maxLength: _maxName,
                          onChanged: (_) => setState(() {}),
                          style: AppText.labelLg.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: AppColors.primaryTint,
                            hintText: 'e.g. Badminton & Turf',
                            suffixIcon: _name.text.isEmpty
                                ? null
                                : IconButton(
                                    icon: Icon(
                                      Icons.cancel_outlined,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () =>
                                        setState(() => _name.clear()),
                                  ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.control,
                              ),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _section(
                    CategoryAccentPicker(
                      selected: _tone,
                      onChanged: (i) => setState(() => _tone = i),
                    ),
                  ),
                  _section(
                    CategoryIconPicker(
                      emoji: _emoji,
                      iconKey: _iconKey,
                      accent: tone.color,
                      onEmoji: (e) => setState(() {
                        _emoji = e;
                        _iconKey = null;
                      }),
                      onIcon: (k) => setState(() {
                        _iconKey = k;
                        _emoji = null;
                      }),
                    ),
                  ),
                  _section(
                    CategoryRulesCard(
                      split: _split,
                      onSplit: (v) => setState(() => _split = v),
                      groups: _groups,
                      groupId: _groupId,
                      onGroup: (v) => setState(() => _groupId = v),
                      capEnabled: _capEnabled,
                      onCapEnabled: (v) => setState(() => _capEnabled = v),
                      capController: _cap,
                    ),
                  ),
                  GradientButton(
                    label: 'Create Category',
                    icon: Icons.arrow_forward_rounded,
                    loading: _saving,
                    onPressed: _saving ? null : _create,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_outlined, size: 14, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(
                        'Saved on this device only',
                        style: AppText.bodySm.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
