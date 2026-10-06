import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/core/bill_saved_data.dart';
import 'package:splitpay/core/upi_share_state.dart';
import 'package:splitpay/screens/bill_saved/widgets/bill_summary_card.dart';
import 'package:splitpay/screens/bill_saved/widgets/saved_hero.dart';
import 'package:splitpay/screens/bill_saved/widgets/saved_secondary_button.dart';
import 'package:splitpay/screens/notifications_screen.dart';
import 'package:splitpay/services/upi_link_service.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/app_ui.dart';

/// Shown after Add Bill / Edit Bill save. Done / back = pop.
/// "Share UPI Link" = notify linked people with their UPI pay link.
class BillSavedScreen extends StatefulWidget {
  const BillSavedScreen({super.key, required this.data});

  final BillSavedData data;

  @override
  State<BillSavedScreen> createState() => _BillSavedScreenState();
}

class _BillSavedScreenState extends State<BillSavedScreen> {
  final _state = ValueNotifier(UpiShareState.idle);

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    if (_state.value != UpiShareState.idle) return;
    final d = widget.data;
    if (!d.paidByMe) {
      showAppToast(context, 'Only the person who paid can share a UPI link');
      return;
    }
    _state.value = UpiShareState.sending;
    try {
      final res = await UpiLinkService.send(
        billTitle: d.title,
        rows: d.rows,
      );
      if (!mounted) return;
      if (res.noUpiId) {
        _state.value = UpiShareState.idle;
        showAppToast(context, 'Add your UPI ID in profile first');
      } else if (res.sent == 0) {
        _state.value = UpiShareState.idle;
        showAppToast(context, 'No linked friends could be notified');
      } else {
        _state.value = UpiShareState.sent;
        final skip = res.skipped > 0 ? ' (${res.skipped} not notified)' : '';
        showAppToast(
          context,
          'UPI link sent to ${res.sent}$skip',
          isError: false,
        );
      }
    } catch (error) {
      if (!mounted) return;
      _state.value = UpiShareState.idle;
      debugPrint('Failed to send UPI link: $error');
      showAppToast(context, 'Could not send UPI link: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.palette.isDark;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: dark
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFFEDE9FF), AppColors.background],
                  stops: const [0, 0.5],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _topBar(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    SavedHero(isUpdate: widget.data.isUpdate),
                    const SizedBox(height: 20),
                    BillSummaryCard(data: widget.data, state: _state),
                    const SizedBox(height: 20),
                    GradientButton(
                      label: 'Done',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 12),
                    _secondaryRow(context),
                    const SizedBox(height: 20),
                    _footer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
    child: Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        Text(
          'SplitPay',
          style: AppText.headlineSm.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ],
    ),
  );

  Widget _secondaryRow(BuildContext context) => Row(
    children: [
      Expanded(
        child: SavedSecondaryButton(
          label: 'View Activity',
          icon: Icons.receipt_long_rounded,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ValueListenableBuilder<UpiShareState>(
          valueListenable: _state,
          builder: (_, s, __) => SavedSecondaryButton(
            label: s == UpiShareState.sent ? 'Link Sent' : 'Share UPI Link',
            icon: s == UpiShareState.sent
                ? Icons.check_rounded
                : Icons.share_rounded,
            accent: true,
            loading: s == UpiShareState.sending,
            onTap: s == UpiShareState.idle ? _share : null,
          ),
        ),
      ),
    ],
  );

  Widget _footer() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.verified_user_outlined, size: 16, color: AppColors.success),
      const SizedBox(width: 6),
      Text(
        'SplitPay Real-time Ledger',
        style: AppText.labelSm.copyWith(color: AppColors.textSecondary),
      ),
    ],
  );
}
