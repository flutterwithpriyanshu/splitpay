import 'package:flutter/material.dart';
import 'package:splitpay/core/app_currency.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/services/reminder_service.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/app_ui.dart';

/// Opens "Remind <name>" sheet: editable message + in-app / WhatsApp / copy.
Future<void> showRemindSheet(
  BuildContext context, {
  required String groupId,
  required String groupName,
  required String debtorUid,
  required String debtorName,
  required double amount,
}) {
  return showAppSheet<void>(
    context,
    builder: (_) => RemindSheet(
      groupId: groupId,
      groupName: groupName,
      debtorUid: debtorUid,
      debtorName: debtorName,
      amount: amount,
    ),
  );
}

class RemindSheet extends StatefulWidget {
  const RemindSheet({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.debtorUid,
    required this.debtorName,
    required this.amount,
  });

  final String groupId;
  final String groupName;
  final String debtorUid;
  final String debtorName;
  final double amount;

  @override
  State<RemindSheet> createState() => _RemindSheetState();
}

class _RemindSheetState extends State<RemindSheet> {
  late final TextEditingController _msg;
  bool _sending = false;

  String get _amountText =>
      '${AppCurrency.symbol}${widget.amount.toStringAsFixed(2)}';

  @override
  void initState() {
    super.initState();
    _msg = TextEditingController(
      text: ReminderService.defaultMessage(
        name: widget.debtorName,
        amount: _amountText,
        groupName: widget.groupName,
      ),
    );
  }

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  Future<void> _inApp() async {
    setState(() => _sending = true);
    try {
      final left = await ReminderService.cooldownLeft(
        groupId: widget.groupId,
        toUid: widget.debtorUid,
      );
      if (left > Duration.zero) {
        if (!mounted) return;
        final h = left.inHours;
        final m = left.inMinutes % 60;
        showAppToast(
          context,
          'Already reminded. Try again in ${h > 0 ? '${h}h ' : ''}${m}m.',
        );
        return;
      }
      await ReminderService.sendInApp(
        groupId: widget.groupId,
        groupName: widget.groupName,
        debtorUid: widget.debtorUid,
        amount: widget.amount,
        message: _msg.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      showAppToast(
        context,
        'Reminder sent to ${widget.debtorName}',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, 'Could not send reminder: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _whatsApp() async {
    final ok = await ReminderService.sendWhatsApp(
      debtorUid: widget.debtorUid,
      message: _msg.text.trim(),
    );
    if (!mounted) return;
    if (!ok) {
      showAppToast(context, 'WhatsApp or phone number not available.');
    }
  }

  Future<void> _copy() async {
    await ReminderService.copy(_msg.text.trim());
    if (!mounted) return;
    showAppToast(context, 'Message copied', isError: false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Remind ${widget.debtorName}', style: AppText.headlineSm),
          const SizedBox(height: 4),
          Text(
            'Owes you $_amountText in ${widget.groupName}',
            style: AppText.bodySm.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _msg,
            minLines: 3,
            maxLines: 5,
            style: AppText.bodyMd,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceRaised,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: 'Send reminder',
            icon: Icons.notifications_active_outlined,
            loading: _sending,
            onPressed: _sending ? null : _inApp,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SecondaryAction(
                  icon: Icons.chat_outlined,
                  label: 'WhatsApp',
                  onTap: _whatsApp,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SecondaryAction(
                  icon: Icons.copy_rounded,
                  label: 'Copy',
                  onTap: _copy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppText.labelMd.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
