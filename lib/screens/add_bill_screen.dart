import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:splitpay/core/add_bill_category.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/core/bill_saved_data.dart';
import 'package:splitpay/core/money_format.dart';
import 'package:splitpay/core/split_math.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/model/group.dart';
import 'package:splitpay/screens/add_bill/widgets/add_bill_amount_card.dart';
import 'package:splitpay/screens/add_bill/widgets/add_bill_expense_card.dart';
import 'package:splitpay/screens/add_bill/widgets/add_bill_save_bar.dart';
import 'package:splitpay/screens/add_bill/widgets/add_bill_split_mode_card.dart';
import 'package:splitpay/screens/add_bill/widgets/add_bill_split_with_card.dart';
import 'package:splitpay/screens/add_bill/widgets/add_bill_top_bar.dart';
import 'package:splitpay/screens/add_bill/widgets/add_friend_sheet.dart';
import 'package:splitpay/screens/bill_saved_screen.dart';
import 'package:splitpay/screens/select_friends_screen.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/theme/app_colors.dart';

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
  final _myShareController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  SplitMethod _splitMethod = SplitMethod.equal;
  AddBillCategory? _category;
  List<Friend> _liveFriends = [];
  final Set<String> _selectedFriendIds = {};
  String? _paidByFriendId; // null = "You"
  final Map<String, TextEditingController> _customAmountControllers = {};

  bool _isSaving = false;
  bool _loadingSharedGroupMembers = false;

  bool get _isSharedGroupMember =>
      widget.group != null &&
      widget.group!.ownerId != FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    if (_isSharedGroupMember) {
      _loadingSharedGroupMembers = true;
      _loadSharedGroupMembers();
    } else if (widget.group != null) {
      _selectedFriendIds.addAll(widget.group!.memberFriendIds);
      for (final id in widget.group!.memberFriendIds) {
        _customAmountControllers[id] = TextEditingController();
      }
    }
  }

  Future<void> _loadSharedGroupMembers() async {
    final group = widget.group!;
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final members = <Friend>[];
    for (final uid in group.allMemberUids) {
      if (uid == myUid) continue;
      members.add(
        Friend(
          id: uid,
          name: await FriendService.getUserName(uid),
          avatarUrl: 'https://i.pravatar.cc/150?u=$uid',
          linkedUid: uid,
        ),
      );
    }
    if (!mounted) return;
    _liveFriends = members;
    _selectedFriendIds.addAll(members.map((friend) => friend.id));
    for (final friend in members) {
      _customAmountControllers[friend.id] = TextEditingController();
    }
    setState(() => _loadingSharedGroupMembers = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _myShareController.dispose();
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
        if (_paidByFriendId == id) {
          _paidByFriendId = null;
        }
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
      final meText = _myShareController.text.trim();
      if (meText.isEmpty) {
        myShare = amount - friendsSum;
      } else {
        final me = double.tryParse(meText);
        if (me == null) {
          _showError('Please enter a valid share for you');
          return;
        }
        final left = amount - friendsSum - me;
        if (left.abs() > 0.01) {
          _showError(
            left > 0
                ? '${formatMoney(left)} left to assign'
                : '${formatMoney(-left)} over assigned',
          );
          return;
        }
        myShare = me;
      }
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
      friendIds: _isSharedGroupMember ? [] : _selectedFriendIds.toList(),
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
    final savedFriends = _selectedFriendIds
        .map(
          (id) => _liveFriends.firstWhere(
            (f) => f.id == id,
            orElse: () => Friend(id: id, name: '', avatarUrl: ''),
          ),
        )
        .toList();
    final paidFriend = _paidByFriendId == null
        ? null
        : _liveFriends.where((f) => f.id == _paidByFriendId).firstOrNull;
    _showSuccessAndReset(
      BillSavedData.fromFriends(
        title: title,
        amount: amount,
        date: _selectedDate,
        friends: savedFriends,
        shares: {
          for (final f in savedFriends)
            f.id: _computeShareForFriend(f.id, amount, customAmounts),
        },
        custom: _splitMethod == SplitMethod.custom,
        paidByFriend: paidFriend,
        categoryLabel: _category?.label,
        categoryIcon: _category?.icon,
      ),
    );
  }

  void _showError(String message) {
    showAppToast(context, message);
  }

  Future<void> _showSuccessAndReset(BillSavedData data) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BillSavedScreen(data: data)),
    );
    if (!mounted) return;
    _resetForm();
    widget.onBillSaved?.call();
  }

  void _resetForm() {
    setState(() {
      _titleController.clear();
      _amountController.clear();
      _noteController.clear();
      _selectedDate = DateTime.now();
      _splitMethod = SplitMethod.equal;
      _category = null;
      _myShareController.clear();
      _selectedFriendIds.clear();
      _paidByFriendId = null;
      for (final c in _customAmountControllers.values) {
        c.dispose();
      }
      _customAmountControllers.clear();
    });
  }

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  List<Friend> get _selectedFriends => _selectedFriendIds
      .map(
        (id) => _liveFriends.firstWhere(
          (f) => f.id == id,
          orElse: () => Friend(id: id, name: '', avatarUrl: ''),
        ),
      )
      .toList();

  SplitMath get _math => SplitMath.fromControllers(
    amount: _amount,
    ids: _selectedFriendIds,
    controllers: _customAmountControllers,
    me: _myShareController,
  );

  void _addQuick(int n) {
    _amountController.text = plainAmount(_amount + n);
    setState(() {});
  }

  void _splitEvenly() {
    if (_amount <= 0) {
      _showError('Enter bill amount first');
      return;
    }
    final each = (_amount / (_selectedFriendIds.length + 1) * 100)
            .floorToDouble() /
        100;
    for (final id in _selectedFriendIds) {
      _customAmountControllers[id]?.text = plainAmount(each);
    }
    _myShareController.clear();
    setState(() {});
  }

  void _splitRemaining() {
    final math = _math;
    final empties = _selectedFriendIds.where(math.needsShare).toList();
    if (empties.isEmpty || math.remaining <= 0.005) return;
    final divisor = empties.length + (math.meOverride ? 0 : 1);
    final each = (math.remaining / divisor * 100).floorToDouble() / 100;
    for (final id in empties) {
      _customAmountControllers[id]?.text = plainAmount(each);
    }
    setState(() {});
  }

  Future<void> _openSelectFriends() async {
    final picked = await Navigator.of(context).push<Set<String>>(
      MaterialPageRoute(
        builder: (_) => SelectFriendsScreen(
          friends: _visibleFriends(),
          initialSelected: _selectedFriendIds,
          allowAddNew: widget.group == null,
        ),
      ),
    );
    if (picked == null || !mounted) return;
    for (final id in _selectedFriendIds.toList()) {
      if (!picked.contains(id)) _toggleFriend(id);
    }
    for (final id in picked) {
      if (!_selectedFriendIds.contains(id)) _toggleFriend(id);
    }
  }

  List<Friend> _visibleFriends() {
    final group = widget.group;
    if (_isSharedGroupMember) return _liveFriends;
    if (group == null) return _liveFriends;
    return _liveFriends
        .where(
          (f) =>
              group.memberFriendIds.contains(f.id) ||
              _selectedFriendIds.contains(f.id),
        )
        .toList();
  }

  Widget _splitWith() {
    return StreamBuilder<List<Friend>>(
      stream: FriendService.streamFriends(),
      builder: (context, snapshot) {
        if (snapshot.hasData && !_isSharedGroupMember) {
          _liveFriends = snapshot.data!;
          final group = widget.group;
          if (group != null) {
            final activeMemberIds = _liveFriends
                .where(
                  (friend) =>
                      group.memberFriendIds.contains(friend.id) &&
                      (!friend.isLinked ||
                          group.memberUids.contains(friend.linkedUid)),
                )
                .map((friend) => friend.id)
                .toSet();
            _selectedFriendIds.removeWhere(
              (id) =>
                  group.memberFriendIds.contains(id) &&
                  !activeMemberIds.contains(id),
            );
          }
        }

        if (_isSharedGroupMember
            ? _loadingSharedGroupMembers
            : snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        return AddBillSplitWithCard(
          friends: _visibleFriends(),
          selectedIds: _selectedFriendIds,
          onToggle: _toggleFriend,
          emptyText: widget.group != null
              ? 'No members in this group yet.'
              : 'No friends yet. Tap "Add new".',
          onSeeAll: _openSelectFriends,
          // Inside a group, participants are fixed to the group's members.
          onAddNew: widget.group == null
              ? () => showAddFriendSheet(
                  context,
                  onAdded: (f) => _toggleFriend(f.id),
                )
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: AddBillSaveBar(
        saving: _isSaving,
        onSave: _saveBill,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AddBillTopBar(subtitle: widget.group?.name),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  AddBillAmountCard(
                    controller: _amountController,
                    onChanged: () => setState(() {}),
                    onQuickAdd: _addQuick,
                  ),
                  const SizedBox(height: 16),
                  AddBillExpenseCard(
                    titleController: _titleController,
                    noteController: _noteController,
                    category: _category,
                    onCategory: (c) => setState(() => _category = c),
                    date: _selectedDate,
                    onPickDate: _pickDate,
                    paidByFriendId: _paidByFriendId,
                    friends: _liveFriends,
                    selectedIds: _selectedFriendIds,
                    onPaidBy: (v) => setState(() => _paidByFriendId = v),
                  ),
                  const SizedBox(height: 16),
                  _splitWith(),
                  if (_selectedFriendIds.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    AddBillSplitModeCard(
                      method: _splitMethod,
                      onMethod: (m) => setState(() => _splitMethod = m),
                      amount: _amount,
                      friends: _selectedFriends,
                      controllers: _customAmountControllers,
                      meController: _myShareController,
                      onChanged: () => setState(() {}),
                      onSplitEvenly: _splitEvenly,
                      onSplitRemaining: _splitRemaining,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
