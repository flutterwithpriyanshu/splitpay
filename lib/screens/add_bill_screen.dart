import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide Group;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/services/local_image_service.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/widgets/local_avatar.dart';
import 'package:splitpay/core/phone_utils.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/model/group.dart';
import 'package:splitpay/screens/add_bill/widgets/form_components.dart';

enum SplitMethod { equal, custom }

class AddBillScreen extends StatefulWidget {
  final VoidCallback? onBillSaved;

  /// When set, this bill is created inside this group: the group's
  /// members are preselected and the saved bill is tagged with the
  /// group's id so it shows up in the group's bill list.
  final Group? group;

  const AddBillScreen({super.key, this.onBillSaved, this.group});

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
  void initState() {
    super.initState();
    if (widget.group != null) {
      _selectedFriendIds.addAll(widget.group!.memberFriendIds);
      for (final id in widget.group!.memberFriendIds) {
        _customAmountControllers[id] = TextEditingController();
      }
    }
  }

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
    Uint8List? pendingContactPhoto;

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
                    if (pendingContactPhoto != null) ...[
                      Center(
                        child: CircleAvatar(
                          radius: 32,
                          backgroundImage: MemoryImage(pendingContactPhoto!),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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
                                // Only reading a contact here — request
                                // read, not readWrite. readWrite also asks
                                // for WRITE_CONTACTS, and on some devices
                                // that half of the combined prompt gets
                                // denied even after the user taps Allow,
                                // which made this show "permission required"
                                // even though contacts access was granted.
                                var status = await FlutterContacts.permissions
                                    .request(PermissionType.read);
                                if (status != PermissionStatus.granted) {
                                  // Ask once more directly — some OEM
                                  // dialogs report the first check as
                                  // denied right after the user taps Allow.
                                  status = await FlutterContacts.permissions
                                      .request(PermissionType.read);
                                }
                                if (status != PermissionStatus.granted) {
                                  if (context.mounted) {
                                    showAppToast(
                                      context,
                                      'Contacts permission is required to pick a contact',
                                    );
                                  }
                                  return;
                                }

                                final picked = await FlutterContacts.native
                                    .showPicker(
                                      properties: {
                                        ContactProperty.phone,
                                        ContactProperty.photoFullRes,
                                      },
                                    );
                                if (picked == null || picked.id == null) return;

                                final fullContact = await FlutterContacts.get(
                                  picked.id!,
                                  properties: ContactProperties.all,
                                );
                                if (fullContact == null) return;

                                final pickedName =
                                    fullContact.displayName ?? '';
                                final pickedPhone =
                                    fullContact.phones.isNotEmpty
                                    ? normalizePhone(
                                        fullContact.phones.first.number,
                                      )
                                    : '';
                                final pickedPhoto = fullContact.photo?.fullSize;

                                setSheetState(() {
                                  _newFriendController.text = pickedName;
                                  phoneController.text = pickedPhone;
                                  pendingContactPhoto = pickedPhoto;
                                });
                              } catch (e) {
                                if (context.mounted) {
                                  showAppToast(
                                    context,
                                    'Could not open contacts: $e',
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
                              final phone = normalizePhone(
                                phoneController.text.trim(),
                              );

                              if (name.isEmpty) {
                                showAppToast(context, 'Please enter a name');
                                return;
                              }
                              if (phone.isEmpty) {
                                showAppToast(
                                  context,
                                  'Phone number is required',
                                );
                                return;
                              }

                              setSheetState(() => isChecking = true);

                              final linkedUid =
                                  await FriendService.findUserByPhone(phone);

                              if (linkedUid == null) {
                                setSheetState(() => isChecking = false);
                                if (context.mounted) {
                                  showAppToast(
                                    context,
                                    "This number hasn't signed up for SplitPay — friend not added",
                                  );
                                }
                                return;
                              }

                              final newFriend = await FriendService.addFriend(
                                name,
                                phoneNumber: phone,
                              );

                              // Save the contact's photo locally, if we got one.
                              if (pendingContactPhoto != null) {
                                await LocalImageService.saveFriendImage(
                                  newFriend.id,
                                  pendingContactPhoto!,
                                );
                              }

                              setState(() => _toggleFriend(newFriend.id));

                              if (context.mounted) {
                                Navigator.pop(context);
                                showAppToast(
                                  context,
                                  '${newFriend.name} is on SplitPay! Accounts linked.',
                                  isError: false,
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
      groupId: widget.group?.id,
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
    showAppToast(context, message);
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
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Bill',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            if (widget.group != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: Text(
                  'Adding to "${widget.group!.name}"',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            AddBillLabel('Bill Amount'),
            const SizedBox(height: 8),
            AddBillField(
              controller: _amountController,
              hint: '₹0.00',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),

            AddBillLabel('Bill Title'),
            const SizedBox(height: 8),
            AddBillField(
              controller: _titleController,
              hint: 'e.g. Dinner at Cafe Noir',
            ),
            const SizedBox(height: 16),

            AddBillLabel('Date'),
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
                AddBillLabel('Split With'),
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

                // Inside a group, only show that group's members — plus
                // anyone just added via "Add Friend" for this one bill
                // (already in _selectedFriendIds but not a group member),
                // so their chip doesn't vanish right after adding them.
                final visibleFriends = widget.group != null
                    ? _liveFriends
                          .where(
                            (f) =>
                                widget.group!.memberFriendIds.contains(f.id) ||
                                _selectedFriendIds.contains(f.id),
                          )
                          .toList()
                    : _liveFriends;

                if (visibleFriends.isEmpty) {
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
                  children: visibleFriends.map((friend) {
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
                            LocalAvatar(
                              localKey: friend.id,
                              isProfile: false,
                              fallbackUrl: friend.avatarUrl,
                              radius: 10,
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

            AddBillLabel('Split Method'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AddBillSplitChip(
                    label: 'Equal Split',
                    selected: _splitMethod == SplitMethod.equal,
                    onTap: () =>
                        setState(() => _splitMethod = SplitMethod.equal),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AddBillSplitChip(
                    label: 'Custom Split',
                    selected: _splitMethod == SplitMethod.custom,
                    onTap: () =>
                        setState(() => _splitMethod = SplitMethod.custom),
                  ),
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
                        child: AddBillField(
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

            AddBillLabel('Paid By'),
            const SizedBox(height: 8),
            AddBillPaidByDropdown(
              value: _paidByFriendId,
              friends: _liveFriends,
              selectedFriendIds: _selectedFriendIds,
              onChanged: (value) => setState(() => _paidByFriendId = value),
            ),
            const SizedBox(height: 20),

            AddBillLabel('Note (optional)'),
            const SizedBox(height: 8),
            AddBillField(controller: _noteController, hint: 'Add a note...'),
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
}
