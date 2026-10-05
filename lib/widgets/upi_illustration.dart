part of 'intro_illustrations.dart';


class UpiIllustration extends StatefulWidget {
  const UpiIllustration({super.key});

  static const double width = 340;
  static const double height = 396;

  @override
  State<UpiIllustration> createState() => _UpiIllustrationState();
}

class _UpiIllustrationState extends State<UpiIllustration> {
  int _selected = 1; // PhonePe

  static const _channels = <(String, IconData)>[
    ('GPay', Icons.account_balance_wallet_outlined),
    ('PhonePe', Icons.payments_rounded),
    ('Paytm', Icons.qr_code_2_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: UpiIllustration.width,
      height: UpiIllustration.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [Positioned(left: 12, top: 0, width: 316, child: _card())],
      ),
    );
  }

  Widget _tile(int i) {
    final selected = i == _selected;
    final (label, icon) = _channels[i];
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selected = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 84,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Stack(
            children: [
              if (selected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.primaryTint,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: selected ? Colors.white : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: AppText.labelMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Pill(
                text: 'Instant UPI Settlement',
                icon: Icons.bolt_rounded,
                bg: AppColors.primaryTint,
                fg: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'TOTAL ₹2,100',
                  style: AppText.labelLg
                      .copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _onMint,
                      )
                      .tabular,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Payer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _Avatar('A', AppColors.primary, size: 52),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surfaceRaised,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aarav Sharma',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.headlineSm.copyWith(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 13,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'aarav.sharma@okaxis',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.bodySm.copyWith(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'PAYING',
                      style: AppText.labelSm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '₹2,100',
                      style: AppText.currencyMd.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Channels
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose payment channel',
                      style: AppText.bodySm.copyWith(
                        fontSize: 12.5,
                        color: AppColors.textPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 13,
                          color: AppColors.success,
                        ),
                        Text(
                          'Fastest • Zero Fees',
                          style: AppText.labelSm.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _tile(0),
                    const SizedBox(width: 8),
                    _tile(1),
                    const SizedBox(width: 8),
                    _tile(2),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Reconciled banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.successTint,
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.done_all_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Instant Ledger Reconciled',
                          style: AppText.labelLg.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        'Ref: #UPI-92834019',
                        style: AppText.bodySm.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _Pill(
                  text: 'Paid',
                  bg: AppColors.surface,
                  fg: _onMint,
                  fontSize: 12,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '1-Tap Deep Link',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodySm.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 15,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Direct Bank-to-Bank',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodySm.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
