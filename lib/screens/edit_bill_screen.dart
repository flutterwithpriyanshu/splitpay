import 'dart:async';

import 'package:flutter/material.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/core/app_date_format.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/screens/edit_bill/widgets/form_components.dart';
import 'package:splitpay/screens/edit_bill/edit_group_bill_view.dart';
import 'package:splitpay/screens/edit_bill/widgets/edit_bill_parts.dart';
import 'package:splitpay/screens/edit_bill/widgets/edit_bill_category_card.dart';
import 'package:splitpay/core/custom_category_store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitpay/theme/app_text.dart';

class EditBillScreen extends StatefulWidget {
  final Bill bill;

  const EditBillScreen({super.key, required this.bill});

  @override
  State<EditBillScreen> createState() => _EditBillScreenState();
}

class _EditBillScreenState extends State<EditBillScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late DateTime _selectedDate;
  late String _splitMethod; // 'equal' or 'custom'
  List<Friend> _liveFriends = [];
  late Set<String> _selectedFriendIds;
  String? _paidByFriendId; // null = "You"
  final Map<String, TextEditingController> _customAmountControllers = {};

  StreamSubscription<List<Friend>>? _friendsSub;
  String? _categoryId;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _friendsSub = FriendService.streamFriends().listen((list) {
      if (mounted) setState(() => _liveFriends = list);
    });
    _initCategory();
    final bill = widget.bill;
    _titleController = TextEditingController(text: bill.title);
    _amountController = TextEditingController(text: bill.amount.toString());
    _noteController = TextEditingController(text: bill.note);
    _selectedDate = bill.date;
    _splitMethod = bill.splitMethod;
    _selectedFriendIds = Set<String>.from(bill.friendIds);
    _paidByFriendId = bill.paidBy == 'me' ? null : bill.paidBy;

    for (final id in _selectedFriendIds) {
      final amount = bill.customAmounts[id];
      _customAmountControllers[id] = TextEditingController(
        text: amount != null ? amount.toString() : '',
      );
    }
  }

  @override
  void dispose() {
    _friendsSub?.cancel();
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    for (final c in _customAmountControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _toggleFriend(String id) {
    setState(() {
      if (_selectedFriendIds.contains(id)) {
        _selectedFriendIds.remove(id);
        _customAmountControllers.remove(id)?.dispose();
      } else {
        _selectedFriendIds.add(id);
        _customAmountControllers[id] = TextEditingController();
      }
    });
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;

    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();

    if (title.isEmpty) {
      _showError('Please enter a bill title');
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }
    if (_selectedFriendIds.isEmpty) {
      _showError('Please select at least one friend');
      return;
    }

    final customAmounts = <String, double>{};
    double myShare;

    if (_splitMethod == 'custom') {
      double friendsSum = 0;
      for (final id in _selectedFriendIds) {
        final val = double.tryParse(_customAmountControllers[id]?.text ?? '');
        if (val == null) {
          _showError('Please enter custom amounts for all friends');
          return;
        }
        customAmounts[id] = val;
        friendsSum += val;
      }
      if (friendsSum > amount) {
        _showError('Custom amounts exceed the total bill amount');
        return;
      }
      myShare = amount - friendsSum;
    } else {
      myShare = amount / (_selectedFriendIds.length + 1);
    }

    setState(() => _isSaving = true);

    final myUid = widget.bill.ownerId;

    final linkedFriends = _selectedFriendIds
        .map(
          (id) => _liveFriends.firstWhere(
            (f) => f.id == id,
            orElse: () => Friend(id: id, name: '', avatarUrl: ''),
          ),
        )
        .where((f) => f.isLinked)
        .toList();

    final participantUids = <String>[
      myUid,
      ...linkedFriends.map((f) => f.linkedUid!),
    ];

    final sharesByUid = <String, double>{myUid: myShare};
    for (final friend in linkedFriends) {
      sharesByUid[friend.linkedUid!] = _splitMethod == 'custom'
          ? (customAmounts[friend.id] ?? 0)
          : amount / (_selectedFriendIds.length + 1);
    }

    String? paidByUid;
    if (_paidByFriendId != null) {
      final payer = _liveFriends.firstWhere(
        (f) => f.id == _paidByFriendId,
        orElse: () => Friend(id: '', name: '', avatarUrl: ''),
      );
      if (payer.isLinked) paidByUid = payer.linkedUid;
    }

    final updatedBill = Bill(
      id: widget.bill.id,
      title: title,
      amount: amount,
      date: _selectedDate,
      friendIds: _selectedFriendIds.toList(),
      splitMethod: _splitMethod,
      customAmounts: customAmounts,
      myShare: myShare,
      paidBy: _paidByFriendId ?? 'me',
      note: _noteController.text.trim(),
      settledFriendIds: widget.bill.settledFriendIds,
      partialPaymentsByFriend: widget.bill.partialPaymentsByFriend,
      myPartialPayment: widget.bill.myPartialPayment,
      ownerId: widget.bill.ownerId,
      participantUids: participantUids,
      sharesByUid: sharesByUid,
      paidByUid: paidByUid,
      settledUids: widget.bill.settledUids,
      partialPaymentsByUid: widget.bill.partialPaymentsByUid,
    );

    try {
      await BillService.updateBill(widget.bill.id, updatedBill);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError('Failed to update bill: $e');
      return;
    }

    await CustomCategoryStore.instance.setBillCategory(
      widget.bill.id,
      _categoryId,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _showError(String message) {
    showAppToast(context, message);
  }

  Future<void> _initCategory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await CustomCategoryStore.instance.load(uid);
    if (!mounted) return;
    setState(
      () => _categoryId = CustomCategoryStore.instance.categoryIdForBill(
        widget.bill.id,
      ),
    );
  }

  void _quickAdd(double v) {
    final cur = double.tryParse(_amountController.text.trim()) ?? 0;
    final next = cur + v;
    _amountController.text = next == next.roundToDouble()
        ? next.toInt().toString()
        : next.toString();
    setState(() {});
  }

  Future<void> _deleteBill() async {
    if (!await confirmDeleteBill(context)) return;
    try {
      await BillService.deleteBill(widget.bill.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to delete bill: $e');
    }
  }

  double get _amountValue => double.tryParse(_amountController.text.trim()) ?? 0;

  double get _friendsSum => _selectedFriendIds.fold<double>(
    0,
    (a, id) =>
        a + (double.tryParse(_customAmountControllers[id]?.text ?? '') ?? 0),
  );

  Friend _friendById(String id) => _liveFriends.firstWhere(
    (f) => f.id == id,
    orElse: () => Friend(id: id, name: 'Unknown', avatarUrl: ''),
  );

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    // Group bill added by a member: split by uid, not by friend.
    if (bill.groupId != null && bill.friendIds.isEmpty) {
      return EditGroupBillView(bill: bill);
    }

    // Bills with settled activity can't be edited.
    final hasSettledActivity =
        bill.settledFriendIds.isNotEmpty ||
        bill.settledUids.isNotEmpty ||
        bill.partialPaymentsByFriend.isNotEmpty ||
        bill.partialPaymentsByUid.isNotEmpty ||
        bill.myPartialPayment > 0;

    if (hasSettledActivity) {
      return const EditBillLocked(
        message: 'It already has settled activity with one or more friends.',
      );
    }

    final amount = _amountValue;
    final custom = _splitMethod == 'custom';
    final n = _selectedFriendIds.length + 1;
    final myShare = custom ? amount - _friendsSum : (n > 0 ? amount / n : 0.0);
    String pct(double v) =>
        amount > 0 ? '${(v / amount * 100).toStringAsFixed(1)}% share' : '-- share';

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
                  EditBillHeaderCard(
                    titleController: _titleController,
                    billId: bill.id,
                    onChanged: () => setState(() {}),
                  ),
                  EditBillAmountCard(
                    controller: _amountController,
                    onChanged: () => setState(() {}),
                    onQuickAdd: _quickAdd,
                  ),
                  EditBillCategoryCard(
                    selectedId: _categoryId,
                    onSelected: (id) => setState(() => _categoryId = id),
                    groupId: bill.groupId,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: EditBillDateTile(
                          text: formatDate(_selectedDate),
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: EditBillPaidByTile(
                          child: AddBillPaidByDropdown(
                            value: _selectedFriendIds.contains(_paidByFriendId)
                                ? _paidByFriendId
                                : null,
                            friends: _liveFriends,
                            selectedFriendIds: _selectedFriendIds,
                            onChanged: (v) =>
                                setState(() => _paidByFriendId = v),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      return EditBillCard(
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
                              '${_selectedFriendIds.length + 1} people selected',
                              style: AppText.bodySm.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_liveFriends.isEmpty)
                              Text(
                                'No friends available',
                                style: AppText.bodyMd.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              )
                            else
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _liveFriends
                                      .map(
                                        (f) => Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: EditBillPickAvatar(
                                            name: f.name,
                                            url: f.avatarUrl,
                                            selected: _selectedFriendIds
                                                .contains(f.id),
                                            onTap: () => _toggleFriend(f.id),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  EditBillSegment(
                    custom: custom,
                    onChanged: (c) =>
                        setState(() => _splitMethod = c ? 'custom' : 'equal'),
                  ),
                  if (custom)
                    EditBillBalanceBar(
                      left: _friendsSum > amount ? amount - _friendsSum : 0,
                    ),
                  EditBillCard(
                    child: Column(
                      children: [
                        EditBillPersonRow(
                          name: 'You',
                          avatarUrl: '',
                          badge: 'Payer',
                          subtitle: pct(myShare),
                          fixedAmount: myShare < 0 ? 0 : myShare,
                        ),
                        ..._selectedFriendIds.map((id) {
                          final f = _friendById(id);
                          _customAmountControllers.putIfAbsent(
                            id,
                            () => TextEditingController(),
                          );
                          final share = custom
                              ? (double.tryParse(
                                      _customAmountControllers[id]!.text,
                                    ) ??
                                    0)
                              : (n > 0 ? amount / n : 0.0);
                          return EditBillPersonRow(
                            name: f.name,
                            avatarUrl: f.avatarUrl,
                            subtitle: pct(share),
                            controller: custom
                                ? _customAmountControllers[id]
                                : null,
                            fixedAmount: share,
                            onChanged: () => setState(() {}),
                          );
                        }),
                        const SizedBox(height: 4),
                        AddBillLabel('Note (optional)'),
                        const SizedBox(height: 8),
                        AddBillField(
                          controller: _noteController,
                          hint: 'Add a note...',
                        ),
                      ],
                    ),
                  ),
                  EditBillBottomBar(
                    billId: bill.id,
                    saving: _isSaving,
                    onSave: _saveChanges,
                    onDelete: _deleteBill,
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
