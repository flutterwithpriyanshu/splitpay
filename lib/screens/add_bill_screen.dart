import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/theme/app_colors.dart';

enum SplitMethod { equal, custom }

class AddBillScreen extends StatefulWidget {
  final VoidCallback? onBillSaved;

  const AddBillScreen({super.key, this.onBillSaved});

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _newFriendController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  SplitMethod _splitMethod = SplitMethod.equal;
  List<Friend> _liveFriends = [];
  final Set<String> _selectedFriendIds = {};
  String? _paidByFriendId; // null = "You"
  final Map<String, TextEditingController> _customAmountControllers = {};

  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _newFriendController.dispose();
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

  double _computeShareForFriend(
    String friendId,
    double totalAmount,
    Map<String, double> customAmounts,
  ) {
    if (_splitMethod == SplitMethod.custom) {
      return customAmounts[friendId] ?? 0;
    }
    return totalAmount / (_selectedFriendIds.length + 1);
  }

  void _showAddFriendSheet() {
    _newFriendController.clear();
    final phoneController = TextEditingController();
    bool isChecking = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add Friend',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _newFriendController,
                      decoration: InputDecoration(
                        hintText: 'Friend\'s name',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'Phone number',
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: IconButton(
                            onPressed: () async {
                              try {
                                final granted =
                                    await FlutterContacts.requestPermission(
                                      readonly: true,
                                    );
                                if (!granted) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Contacts permission is required to pick a contact',
                                        ),
                                      ),
                                    );
                                  }
                                  return;
                                }

                                final contact =
                                    await FlutterContacts.openExternalPick();
                                if (contact == null) return;

                                final fullContact =
                                    await FlutterContacts.getContact(
                                      contact.id,
                                    );
                                if (fullContact == null) return;

                                final pickedName = fullContact.displayName;
                                final pickedPhone =
                                    fullContact.phones.isNotEmpty
                                    ? fullContact.phones.first.number
                                    : '';

                                setSheetState(() {
                                  _newFriendController.text = pickedName;
                                  phoneController.text = pickedPhone;
                                });
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Could not open contacts: $e',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: Icon(
                              Icons.contact_page_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Only phone numbers registered on SplitPay can be added as friends.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isChecking
                          ? null
                          : () async {
                              final name = _newFriendController.text.trim();
                              final phone = phoneController.text.trim();

                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a name'),
                                  ),
                                );
                                return;
                              }
                              if (phone.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Phone number is required'),
                                  ),
                                );
                                return;
                              }

                              setSheetState(() => isChecking = true);

                              final linkedUid =
                                  await FriendService.findUserByPhone(phone);

                              if (linkedUid == null) {
                                setSheetState(() => isChecking = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "This number hasn't signed up for SplitPay — friend not added",
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }

                              final newFriend = await FriendService.addFriend(
                                name,
                                phoneNumber: phone,
                              );

                              setState(() => _toggleFriend(newFriend.id));

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${newFriend.name} is on SplitPay! Accounts linked.',
                                    ),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: isChecking
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Add',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveBill() async {
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

    if (_splitMethod == SplitMethod.custom) {
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

    final myUid = FirebaseAuth.instance.currentUser!.uid;

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
      sharesByUid[friend.linkedUid!] = _computeShareForFriend(
        friend.id,
        amount,
        customAmounts,
      );
    }

    String? paidByUid;
    if (_paidByFriendId != null) {
      final payer = _liveFriends.firstWhere(
        (f) => f.id == _paidByFriendId,
        orElse: () => Friend(id: '', name: '', avatarUrl: ''),
      );
      if (payer.isLinked) paidByUid = payer.linkedUid;
    }

    final bill = Bill(
      id: '',
      title: title,
      amount: amount,
      date: _selectedDate,
      friendIds: _selectedFriendIds.toList(),
      splitMethod: _splitMethod == SplitMethod.equal ? 'equal' : 'custom',
      customAmounts: customAmounts,
      myShare: myShare,
      paidBy: _paidByFriendId ?? 'me',
      note: _noteController.text.trim(),
      settledFriendIds: [],
      partialPaymentsByFriend: {},
      myPartialPayment: 0,
      ownerId: myUid,
      participantUids: participantUids,
      sharesByUid: sharesByUid,
      paidByUid: paidByUid,
      settledUids: [],
      partialPaymentsByUid: {},
    );

    try {
      await BillService.addBill(bill);

      for (final friend in linkedFriends) {
        await FriendService.ensureReciprocalFriend(friend.linkedUid!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError('Failed to save bill: $e');
      return;
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    _showSuccessAndReset();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccessAndReset() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: AppColors.success,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Bill Saved!',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your bill has been added successfully',
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
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      Navigator.of(context).pop();
      _resetForm();
      widget.onBillSaved?.call();
    });
  }

  void _resetForm() {
    setState(() {
      _titleController.clear();
      _amountController.clear();
      _noteController.clear();
      _selectedDate = DateTime.now();
      _splitMethod = SplitMethod.equal;
      _selectedFriendIds.clear();
      _paidByFriendId = null;
      for (final c in _customAmountControllers.values) {
        c.dispose();
      }
      _customAmountControllers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              'Add Bill',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

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
            _field(
              controller: _titleController,
              hint: 'e.g. Dinner at Cafe Noir',
            ),
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _label('Split With'),
                TextButton.icon(
                  onPressed: _showAddFriendSheet,
                  icon: Icon(
                    Icons.add_circle_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Add Friend',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<Friend>>(
              stream: FriendService.streamFriends(),
              builder: (context, snapshot) {
                if (snapshot.hasData) _liveFriends = snapshot.data!;

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                if (_liveFriends.isEmpty) {
                  return Text(
                    'No friends yet — tap "Add Friend" above',
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
                            if (friend.isLinked) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: selected
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ],
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
                Expanded(
                  child: _splitMethodChip('Equal Split', SplitMethod.equal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _splitMethodChip('Custom Split', SplitMethod.custom),
                ),
              ],
            ),

            if (_splitMethod == SplitMethod.custom &&
                _selectedFriendIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              ..._selectedFriendIds.map((id) {
                final friend = _liveFriends.firstWhere((f) => f.id == id);
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
                onPressed: _isSaving ? null : _saveBill,
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
                        'Save Bill',
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

  Widget _splitMethodChip(String label, SplitMethod method) {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _paidByFriendId,
          isExpanded: true,
          hint: Text('You', style: GoogleFonts.inter(fontSize: 14)),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('You', style: GoogleFonts.inter(fontSize: 14)),
            ),
            ..._liveFriends
                .where((f) => _selectedFriendIds.contains(f.id))
                .map(
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
