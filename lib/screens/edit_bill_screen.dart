import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/theme/app_colors.dart';

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

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
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
      participantUids: widget.bill.participantUids,
      sharesByUid: widget.bill.sharesByUid,
      paidByUid: widget.bill.paidByUid,
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

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // Bills with settled activity can't be edited.
    final hasSettledActivity =
        widget.bill.settledFriendIds.isNotEmpty ||
        widget.bill.settledUids.isNotEmpty ||
        widget.bill.partialPaymentsByFriend.isNotEmpty ||
        widget.bill.partialPaymentsByUid.isNotEmpty ||
        widget.bill.myPartialPayment > 0;

    if (hasSettledActivity) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Text(
                    'Edit Bill',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
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
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'This bill can\'t be edited',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'It already has settled activity with one or more friends.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Text(
                  'Edit Bill',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _label('Bill Amount'),
            const SizedBox(height: 8),
            _field(
              controller: _amountController,
              hint: '₹0.00',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),

            _label('Bill Title'),
            const SizedBox(height: 8),
            _field(controller: _titleController, hint: 'e.g. Dinner'),
            const SizedBox(height: 16),

            _label('Date'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            _label('Split With'),
            const SizedBox(height: 8),
            StreamBuilder<List<Friend>>(
              stream: FriendService.streamFriends(),
              builder: (context, snapshot) {
                if (snapshot.hasData) _liveFriends = snapshot.data!;
                if (_liveFriends.isEmpty) {
                  return Text(
                    'No friends available',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  );
                }
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _liveFriends.map((friend) {
                    final selected = _selectedFriendIds.contains(friend.id);
                    return GestureDetector(
                      onTap: () => _toggleFriend(friend.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundImage: NetworkImage(friend.avatarUrl),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              friend.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),

            _label('Split Method'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _splitMethodChip('Equal Split', 'equal')),
                const SizedBox(width: 12),
                Expanded(child: _splitMethodChip('Custom Split', 'custom')),
              ],
            ),

            if (_splitMethod == 'custom' && _selectedFriendIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              ..._selectedFriendIds.map((id) {
                final friend = _liveFriends.firstWhere(
                  (f) => f.id == id,
                  orElse: () => Friend(id: id, name: 'Unknown', avatarUrl: ''),
                );
                _customAmountControllers.putIfAbsent(
                  id,
                  () => TextEditingController(),
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          friend.name,
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: _field(
                          controller: _customAmountControllers[id]!,
                          hint: '₹0.00',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 20),

            _label('Paid By'),
            const SizedBox(height: 8),
            _paidByDropdown(),
            const SizedBox(height: 20),

            _label('Note (optional)'),
            const SizedBox(height: 8),
            _field(controller: _noteController, hint: 'Add a note...'),
            const SizedBox(height: 28),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _splitMethodChip(String label, String method) {
    final selected = _splitMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _splitMethod = method),
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

  Widget _paidByDropdown() {
    final availableFriends = _liveFriends
        .where((f) => _selectedFriendIds.contains(f.id))
        .toList();
    final availableIds = availableFriends.map((f) => f.id).toSet();

    final safeValue =
        (_paidByFriendId != null && availableIds.contains(_paidByFriendId))
        ? _paidByFriendId
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: safeValue,
          isExpanded: true,
          hint: Text('You', style: GoogleFonts.inter(fontSize: 14)),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('You', style: GoogleFonts.inter(fontSize: 14)),
            ),
            ...availableFriends.map(
              (f) => DropdownMenuItem<String?>(
                value: f.id,
                child: Text(f.name, style: GoogleFonts.inter(fontSize: 14)),
              ),
            ),
          ],
          onChanged: (val) => setState(() => _paidByFriendId = val),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool dense = false,
  }) {
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
