import 'package:flutter/material.dart';
import 'package:splitpay/core/app_currency.dart';
import 'package:splitpay/core/app_date_format.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/group.dart';
import 'package:splitpay/screens/edit_bill/widgets/edit_bill_parts.dart';
import 'package:splitpay/screens/edit_bill/widgets/edit_bill_category_card.dart';
import 'package:splitpay/core/custom_category_store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/services/group_service.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

/// Edit a GROUP bill that is split by uid (added via AddGroupBillScreen).
/// Members are fixed to the bill's participants. Same save rules as
/// AddGroupBillScreen: custom shares must add up to the total.
class EditGroupBillView extends StatefulWidget {
  const EditGroupBillView({super.key, required this.bill});
  final Bill bill;

  @override
  State<EditGroupBillView> createState() => _EditGroupBillViewState();
}

class _EditGroupBillViewState extends State<EditGroupBillView> {
  late final TextEditingController _title;
  late final TextEditingController _amount;
  final Map<String, TextEditingController> _custom = {};
  late DateTime _date;
  late bool _isCustom;
  late String _paidByUid;
  Group? _group;
  Map<String, String> _names = {};
  bool _loading = true;
  bool _saving = false;
  String? _categoryId;

  String get _myUid => FirebaseAuth.instance.currentUser!.uid;
  List<String> get _members => widget.bill.participantUids;

  @override
  void initState() {
    super.initState();
    final b = widget.bill;
    _title = TextEditingController(text: b.title);
    _amount = TextEditingController(text: b.amount.toString());
    _date = b.date;
    _isCustom = b.splitMethod == 'custom';
    _paidByUid = b.paidByUid ?? b.ownerId;
    for (final uid in _members) {
      final v = b.sharesByUid[uid];
      _custom[uid] = TextEditingController(text: v == null ? '' : v.toString());
    }
    _load();
    _initCategory();
  }

  Future<void> _initCategory() async {
    await CustomCategoryStore.instance.load(_myUid);
    if (!mounted) return;
    setState(
      () => _categoryId = CustomCategoryStore.instance.categoryIdForBill(
        widget.bill.id,
      ),
    );
  }

  Future<void> _load() async {
    try {
      final g = await GroupService.streamGroup(widget.bill.groupId!).first;
      final names = <String, String>{};
      for (final uid in _members) {
        names[uid] = uid == _myUid ? 'You' : await FriendService.getUserName(uid);
      }
      if (!mounted) return;
      setState(() {
        _group = g;
        _names = names;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    for (final c in _custom.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _amountValue => double.tryParse(_amount.text.trim()) ?? 0;

  double _customOf(String uid) => double.tryParse(_custom[uid]!.text.trim()) ?? 0;

  double get _customSum => _members.fold<double>(0, (a, u) => a + _customOf(u));

  double _shareOf(String uid) =>
      _isCustom ? _customOf(uid) : _amountValue / _members.length;

  void _quickAdd(double v) {
    final next = _amountValue + v;
    _amount.text = next == next.roundToDouble()
        ? next.toInt().toString()
        : next.toString();
    setState(() {});
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _title.text.trim();
    final amount = _amountValue;
    if (title.isEmpty) {
      showAppToast(context, 'Please enter a title');
      return;
    }
    if (amount <= 0) {
      showAppToast(context, 'Please enter a valid amount');
      return;
    }
    final shares = {for (final u in _members) u: _shareOf(u)};
    if (_isCustom && (_customSum - amount).abs() > 0.01) {
      showAppToast(
        context,
        'Custom amounts (${AppCurrency.symbol}${_customSum.toStringAsFixed(2)}) '
        'must add up to ${AppCurrency.symbol}${amount.toStringAsFixed(2)}',
      );
      return;
    }

    setState(() => _saving = true);
    final b = widget.bill;
    final updated = Bill(
      id: b.id,
      title: title,
      amount: amount,
      date: _date,
      friendIds: b.friendIds,
      splitMethod: _isCustom ? 'custom' : 'equal',
      customAmounts: b.customAmounts,
      myShare: shares[_myUid] ?? 0,
      paidBy: b.paidBy,
      note: b.note,
      settledFriendIds: b.settledFriendIds,
      partialPaymentsByFriend: b.partialPaymentsByFriend,
      myPartialPayment: b.myPartialPayment,
      ownerId: b.ownerId,
      participantUids: b.participantUids,
      sharesByUid: shares,
      paidByUid: _paidByUid,
      settledUids: b.settledUids,
      partialPaymentsByUid: b.partialPaymentsByUid,
      groupId: b.groupId,
    );
    try {
      await BillService.updateBill(b.id, updated);
      await CustomCategoryStore.instance.setBillCategory(b.id, _categoryId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppToast(context, 'Failed to update bill: $e');
    }
  }

  Future<void> _delete() async {
    if (!await confirmDeleteBill(context)) return;
    try {
      await BillService.deleteBill(widget.bill.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, 'Failed to delete bill: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.bill;
    if (b.ownerId != _myUid) {
      return const EditBillLocked(
        message: 'Only the person who added this bill can edit it.',
      );
    }
    final settled = b.settledUids.isNotEmpty ||
        b.partialPaymentsByUid.isNotEmpty ||
        b.myPartialPayment > 0;
    if (settled) {
      return const EditBillLocked(
        message: 'It already has settled activity with one or more members.',
      );
    }
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final amount = _amountValue;
    String pct(double v) =>
        amount > 0 ? '${(v / amount * 100).toStringAsFixed(1)}% share' : '-- share';
    final groupName = _group?.name;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const EditBillTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  if (groupName != null)
                    EditBillBanner(
                      'Editing recalculates balances in $groupName for all '
                      '${_members.length} members.',
                    ),
                  EditBillHeaderCard(
                    titleController: _title,
                    billId: b.id,
                    groupName: groupName,
                    onChanged: () => setState(() {}),
                  ),
                  EditBillAmountCard(
                    controller: _amount,
                    onChanged: () => setState(() {}),
                    onQuickAdd: _quickAdd,
                  ),
                  EditBillCategoryCard(
                    selectedId: _categoryId,
                    onSelected: (id) => setState(() => _categoryId = id),
                    groupId: b.groupId,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: EditBillDateTile(
                          text: formatDate(_date),
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: EditBillPaidByTile(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _members.contains(_paidByUid)
                                  ? _paidByUid
                                  : null,
                              items: _members
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(
                                        _names[u] ?? 'Someone',
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.labelMd.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _paidByUid = v);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  EditBillCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Split with',
                          style: AppText.headlineSm.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${_members.length} members of the group',
                          style: AppText.bodySm.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _members
                                .map(
                                  (u) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: EditBillPickAvatar(
                                      name: _names[u] ?? '',
                                      url: '',
                                      selected: true,
                                      onTap: () {},
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  EditBillSegment(
                    custom: _isCustom,
                    onChanged: (c) => setState(() => _isCustom = c),
                  ),
                  if (_isCustom) EditBillBalanceBar(left: amount - _customSum),
                  EditBillCard(
                    child: Column(
                      children: _members.map((u) {
                        final isMe = u == _myUid;
                        return EditBillPersonRow(
                          name: _names[u] ?? 'Someone',
                          avatarUrl: '',
                          badge: u == _paidByUid ? 'Payer' : null,
                          subtitle: pct(_shareOf(u)),
                          controller: _isCustom ? _custom[u] : null,
                          fixedAmount: _shareOf(u),
                          onChanged: () => setState(() {}),
                          key: ValueKey('${isMe ? 'me' : 'm'}_$u'),
                        );
                      }).toList(),
                    ),
                  ),
                  EditBillBottomBar(
                    billId: b.id,
                    saving: _saving,
                    onSave: _save,
                    onDelete: _delete,
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
