import 'package:flutter/material.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/app_ui.dart';
import 'package:splitpay/widgets/app_logo.dart';

class ProfileSetupTopBar extends StatelessWidget {
  const ProfileSetupTopBar({
    required this.isLoading,
    required this.onBack,
    super.key,
  });

  final bool isLoading;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            IconButton(
              onPressed: isLoading ? null : onBack,
              icon: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
              ),
            ),
            const AppLogo(size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Profile Setup',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.headlineMd.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                'Step 2 of 2',
                style: AppText.labelMd.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileSetupStepBar extends StatelessWidget {
  const ProfileSetupStepBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STEP 2 OF 2',
              style: AppText.labelSm.copyWith(
                color: AppColors.primary.withValues(alpha: 0.45),
              ),
            ),
            Text(
              'Profile Details',
              style: AppText.labelMd.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ],
    );
  }
}

class ProfileSetupHero extends StatelessWidget {
  const ProfileSetupHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chevron_left_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 2),
              Text(
                'Almost ready to split!',
                style: AppText.labelMd.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'One more thing',
          textAlign: TextAlign.center,
          style: AppText.displayLgMobile.copyWith(
            color: AppColors.textPrimary,
            fontSize: 34,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Set up your personal profile to split and settle balances in seconds.',
          textAlign: TextAlign.center,
          style: AppText.bodyLg.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class ProfileSetupAvatar extends StatelessWidget {
  const ProfileSetupAvatar({
    required this.name,
    required this.image,
    required this.onTap,
    super.key,
  });

  final String name;
  final ImageProvider? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: 136,
            height: 136,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 136,
                  height: 136,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.30),
                      width: 3,
                    ),
                    boxShadow: AppShadows.raised,
                  ),
                  child: CircleAvatar(
                    backgroundColor: AppColors.primaryTint,
                    backgroundImage: image,
                    onBackgroundImageError: image == null ? null : (_, _) {},
                    child: image != null
                        ? null
                        : (name.isEmpty
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 56,
                                  color: AppColors.primary,
                                )
                              : Text(
                                  name.characters.first.toUpperCase(),
                                  style: AppText.displayLgMobile.copyWith(
                                    color: AppColors.primary,
                                  ),
                                )),
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 6,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 3),
                    ),
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tap to change profile picture',
          style: AppText.labelMd.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class ProfileDetailsForm extends StatelessWidget {
  const ProfileDetailsForm({
    required this.nameController,
    required this.phoneController,
    required this.upiController,
    required this.nameFocus,
    required this.phoneFocus,
    required this.upiFocus,
    required this.phoneAlreadyVerified,
    required this.phoneIsValid,
    required this.upiIsValid,
    required this.upiPrefilled,
    required this.upiTouched,
    required this.onChanged,
    required this.onApplyHandle,
    super.key,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController upiController;
  final FocusNode nameFocus;
  final FocusNode phoneFocus;
  final FocusNode upiFocus;
  final bool phoneAlreadyVerified;
  final bool phoneIsValid;
  final bool upiIsValid;
  final bool upiPrefilled;
  final bool upiTouched;
  final VoidCallback onChanged;
  final ValueChanged<String> onApplyHandle;

  static const _handles = ['@okhdfcbank', '@oksbi', '@paytm'];

  @override
  Widget build(BuildContext context) {
    final upiText = upiController.text.trim();
    final upiError = upiTouched && upiText.isNotEmpty && !upiIsValid;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _labelRow(
            'Full Name',
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_rounded, size: 16, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  'Public Name',
                  style: AppText.labelMd.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _field(
            controller: nameController,
            focus: nameFocus,
            icon: Icons.badge_outlined,
            hint: 'Your full name',
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 18),
          _labelRow(
            'Phone Number',
            phoneAlreadyVerified
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successTint,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: AppText.labelMd.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    'Required',
                    style: AppText.labelMd.copyWith(color: AppColors.error),
                  ),
          ),
          const SizedBox(height: 8),
          _field(
            controller: phoneController,
            focus: phoneFocus,
            icon: Icons.smartphone_rounded,
            hint: '98765 43210',
            readOnly: phoneAlreadyVerified,
            keyboardType: TextInputType.phone,
            tabular: true,
            prefixText: phoneAlreadyVerified ? null : '+91  ',
            onChanged: (_) => onChanged(),
            trailing: phoneAlreadyVerified
                ? Icon(Icons.lock_rounded, size: 22, color: AppColors.success)
                : (phoneIsValid
                      ? Icon(
                          Icons.check_circle_rounded,
                          size: 22,
                          color: AppColors.success,
                        )
                      : null),
          ),
          const SizedBox(height: 18),
          _labelRow(
            'UPI ID (Virtual Payment Address)',
            Text(
              'Required',
              style: AppText.labelMd.copyWith(color: AppColors.error),
            ),
            expandLabel: true,
          ),
          const SizedBox(height: 8),
          _field(
            controller: upiController,
            focus: upiFocus,
            icon: Icons.account_balance_wallet_outlined,
            hint: 'yourname@bank',
            keyboardType: TextInputType.emailAddress,
            error: upiError,
            autocorrect: false,
            onChanged: (_) => onChanged(),
            trailing: upiText.isEmpty
                ? null
                : (upiError
                      ? GestureDetector(
                          onTap: () {
                            upiController.clear();
                            onChanged();
                          },
                          child: Icon(
                            Icons.cancel_outlined,
                            size: 22,
                            color: AppColors.error,
                          ),
                        )
                      : (upiIsValid
                            ? Icon(
                                Icons.check_circle_rounded,
                                size: 22,
                                color: AppColors.success,
                              )
                            : null)),
          ),
          if (upiError) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Invalid UPI ID format. Must include bank handle (e.g. username@okhdfcbank, mobile@upi)',
                    style: AppText.bodySm.copyWith(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Quick Fix:',
                style: AppText.labelMd.copyWith(color: AppColors.textSecondary),
              ),
              for (final handle in _handles) _handleChip(handle),
            ],
          ),
          const SizedBox(height: 16),
          const _DirectSettlementCard(),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    style: AppText.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      const TextSpan(text: 'Sample: '),
                      TextSpan(
                        text: '9876543210@paytm',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const TextSpan(text: ' or '),
                      TextSpan(
                        text: 'priya@oksbi',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (upiPrefilled) ...[
            const SizedBox(height: 8),
            Text(
              'Filled from your saved profile. Edit it to change.',
              textAlign: TextAlign.center,
              style: AppText.bodySm.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _labelRow(String label, Widget trailing, {bool expandLabel = false}) {
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppText.labelMd.copyWith(
        color: AppColors.textPrimary,
        fontSize: 14,
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (expandLabel) Flexible(child: text) else text,
        const SizedBox(width: 8),
        trailing,
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required FocusNode focus,
    required IconData icon,
    required String hint,
    bool readOnly = false,
    bool error = false,
    bool tabular = false,
    bool autocorrect = true,
    String? prefixText,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    ValueChanged<String>? onChanged,
    Widget? trailing,
  }) {
    final focused = focus.hasFocus && !readOnly;
    final fill = error ? AppColors.dangerTint : AppColors.surfaceRaised;
    final border = error
        ? AppColors.error.withValues(alpha: 0.45)
        : (focused ? AppColors.primary : Colors.transparent);
    var style = AppText.bodyLg.copyWith(
      color: AppColors.textPrimary,
      fontSize: 17,
    );
    if (tabular) style = style.tabular;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: error ? AppColors.error : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focus,
              readOnly: readOnly,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              autocorrect: autocorrect,
              enableSuggestions: autocorrect,
              onChanged: onChanged,
              style: style,
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: hint,
                hintStyle: style.copyWith(color: AppColors.textSecondary),
                prefixText: prefixText,
                prefixStyle: style,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
        ],
      ),
    );
  }

  Widget _handleChip(String handle) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: () => onApplyHandle(handle),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryTint,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          handle,
          style: AppText.labelMd.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _DirectSettlementCard extends StatelessWidget {
  const _DirectSettlementCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.inner),
            ),
            child: Icon(Icons.bolt_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'DIRECT SETTLEMENT',
                        style: AppText.labelSm.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'UPI 2.0',
                        style: AppText.labelSm.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'We need your valid UPI ID so friends can settle balances directly into your bank account with zero platform fees.',
                  style: AppText.bodyMd.copyWith(
                    color: AppColors.textSecondary,
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

class ProfileTrustLine extends StatelessWidget {
  const ProfileTrustLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 22,
            color: AppColors.success,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'SplitPay never asks for your UPI PIN or banking passwords. 100% NPCI compliant.',
              textAlign: TextAlign.center,
              style: AppText.bodyMd.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
