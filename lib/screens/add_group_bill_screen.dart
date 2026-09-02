import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/group.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/theme/app_colors.dart';

/// Add-a-bill screen for a group MEMBER (not the group owner).
///
/// The owner's AddBillScreen preselects members from the owner's own
/// `friends` collection, which a member has no access to. Instead, this
/// screen splits between the group's already-linked accounts
/// (`group.ownerId` + `group.memberUids`) directly by uid, so any member
/// can add a bill to the group and have it show up for everyone —
/// matching how the owner's group bills already show up for members.
enum _SplitMethod { equal, custom }

class AddGroupBillScreen extends StatefulWidget {
  final Group group;
  final VoidCallback? onBillSaved;

  const AddGroupBillScreen({super.key, required this.group, this.onBillSaved});

  @override
  State<AddGroupBillScreen> createState() => _AddGroupBillScreenState();
}

class _AddGroupBillScreenState extends State<AddGroupBillScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final Map<String, TextEditingController> _customControllers = {};

  DateTime _date = DateTime.now();
  _SplitMethod _splitMethod = _SplitMethod.equal;
  late String _paidByUid;
  Map<String, String> _namesByUid = {};
  bool _isSaving = false;
  bool _isLoadingNames = true;

  String get _myUid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _paidByUid = _myUid;
    for (final uid in widget.group.allMemberUids) {
      _customControllers[uid] = TextEditingController();
    }
    _loadNames();
  }

  Future<void> _loadNames() async {
    final names = <String, String>{};
    for (final uid in widget.group.allMemberUids) {
      names[uid] = uid == _myUid ? 'You' : await FriendService.getUserName(uid);
    }
    if (mounted) {
      setState(() {
        _namesByUid = names;
        _isLoadingNames = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    for (final c in _customControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, double> _computeShares(double amount, List<String> members) {
    if (_splitMethod == _SplitMethod.equal) {
      final each = amount / members.length;
      return {for (final uid in members) uid: each};
    }
    return {
      for (final uid in members)
        uid: double.tryParse(_customControllers[uid]!.text.trim()) ?? 0,
    };
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final members = widget.group.allMemberUids;

    if (title.isEmpty) {
      showAppToast(context, 'Please enter a title');
      return;
    }
    if (amount <= 0) {
      showAppToast(context, 'Please enter a valid amount');
      return;
    }

    final shares = _computeShares(amount, members);
    if (_splitMethod == _SplitMethod.custom) {
      final total = shares.values.fold<double>(0, (a, b) => a + b);
      if ((total - amount).abs() > 0.01) {
        showAppToast(
          context,
          'Custom amounts (₹${total.toStringAsFixed(2)}) must add up to ₹${amount.toStringAsFixed(2)}',
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final bill = Bill(
        id: '',
        title: title,
        amount: amount,
        date: _date,
        friendIds: const [],
        splitMethod: _splitMethod == _SplitMethod.equal ? 'equal' : 'custom',
        customAmounts: const {},
        myShare: shares[_myUid] ?? 0,
        paidBy: 'me',
        note: _noteController.text.trim(),
        settledFriendIds: const [],
        partialPaymentsByFriend: const {},
        myPartialPayment: 0,
        ownerId: _myUid,
        participantUids: members,
        sharesByUid: shares,
        paidByUid: _paidByUid,
        settledUids: const [],
        partialPaymentsByUid: const {},
        groupId: widget.group.id,
      );

      await BillService.addBill(bill);
      widget.onBillSaved?.call();
    } catch (e) {
      if (mounted) {
        showAppToast(context, 'Could not save bill. Try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.group.allMemberUids;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Add bill to ${widget.group.name}',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoadingNames
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'What was it for?',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: 'Amount (₹)'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Date: ${_date.day}/${_date.month}/${_date.year}',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                  trailing: const Icon(Icons.calendar_today_rounded, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Paid by',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: members
                      .map(
                        (uid) => ChoiceChip(
                          label: Text(_namesByUid[uid] ?? '...'),
                          selected: _paidByUid == uid,
                          onSelected: (_) => setState(() => _paidByUid = uid),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Split',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<_SplitMethod>(
                  segments: const [
                    ButtonSegment(
                      value: _SplitMethod.equal,
                      label: Text('Equal'),
                    ),
                    ButtonSegment(
                      value: _SplitMethod.custom,
                      label: Text('Custom'),
                    ),
                  ],
                  selected: {_splitMethod},
                  onSelectionChanged: (s) =>
                      setState(() => _splitMethod = s.first),
                ),
                const SizedBox(height: 12),
                if (_splitMethod == _SplitMethod.equal)
                  ...members.map((uid) {
                    final amount =
                        double.tryParse(_amountController.text.trim()) ?? 0;
                    final each = members.isEmpty ? 0 : amount / members.length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _namesByUid[uid] ?? '...',
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                          Text(
                            '₹${each.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  })
                else
                  ...members.map(
                    (uid) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _namesByUid[uid] ?? '...',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: _customControllers[uid],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(hintText: '₹0'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: 'Note (optional)',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Add bill',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
