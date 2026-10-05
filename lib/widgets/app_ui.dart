import 'package:flutter/material.dart';
import 'package:splitpay/core/app_currency.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

/// Level 1 card: surface, 24 radius, 20 padding, hairline border, soft shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Primary CTA: 56 tall, gradient, 16 radius, press = scale 0.98.
/// Gradient is reserved for settle-up / payment / main actions only.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool loading;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: const Duration(milliseconds: 90),
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            height: 56,
            width: widget.expand ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            foregroundDecoration: _down
                ? BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  )
                : null,
            child: Row(
              mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else ...[
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: AppText.labelLg.copyWith(color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// UPI quick pay: 56 tall, success fill, white text, bolt glyph.
class UpiPayButton extends StatelessWidget {
  const UpiPayButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.bolt_rounded, size: 22),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),
    );
  }
}

/// Ledger status pill: "+ ₹XX.XX" (get), "- ₹XX.XX" (owe), "Settled".
/// Pass a signed amount: positive = you get, negative = you owe.
class AmountPill extends StatelessWidget {
  const AmountPill({
    super.key,
    required this.amount,
    this.settledLabel = 'Settled',
  });

  final double amount;
  final String settledLabel;

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color bg;
    final String text;
    if (amount > 0.005) {
      fg = AppColors.success;
      bg = fg.withValues(alpha: 0.12);
      text = '+ ${AppCurrency.symbol}${amount.toStringAsFixed(2)}';
    } else if (amount < -0.005) {
      fg = AppColors.error;
      bg = fg.withValues(alpha: 0.12);
      text = '- ${AppCurrency.symbol}${amount.abs().toStringAsFixed(2)}';
    } else {
      fg = AppColors.textSecondary;
      bg = const Color(0xFF6B7194).withValues(alpha: 0.10);
      text = settledLabel;
    }
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(text, style: AppText.labelMd.copyWith(color: fg).tabular),
    );
  }
}

/// 60px gradient circle FAB with white "+" (use for new bill).
class AppFab extends StatelessWidget {
  const AppFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add_rounded,
  });

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: AppShadows.fab,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class DockItem {
  const DockItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// Floating pill nav: 64 tall, max 420 wide, active = primary + 4px dot.
class FloatingDock extends StatelessWidget {
  const FloatingDock({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<DockItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.palette.isDark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            height: AppSpacing.dockHeight,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF151826).withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF262B45)
                    : const Color(0xFFE3E6F2).withValues(alpha: 0.80),
              ),
              boxShadow: AppShadows.dock,
            ),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(child: _item(i)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int i) {
    final selected = i == currentIndex;
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(i),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(items[i].icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(items[i].label, style: AppText.labelSm.copyWith(color: color)),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.primary : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Settle-up / split bottom sheet. 32px top radius + drag handle come from
/// the theme; this adds keyboard-safe padding and scroll control.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.md,
      ),
      child: builder(ctx),
    ),
  );
}
