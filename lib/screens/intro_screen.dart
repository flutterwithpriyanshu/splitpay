import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:splitpay/core/onboarding_prefs.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/intro_illustrations.dart';

/// 3-step onboarding: Add Bills -> Track Balances -> Settle UPI.
/// Text is hardcoded English for now (same as splash).
class IntroScreen extends StatefulWidget {
  final VoidCallback onDone;

  const IntroScreen({super.key, required this.onDone});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _controller = PageController();
  // ValueNotifier, not setState: pages stay untouched on swipe.
  final ValueNotifier<int> _index = ValueNotifier<int>(0);
  bool _finishing = false;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _IntroPage(
        illustration: const BillIllustration(),
        sheet: _Sheet(
          step: 0,
          icon: Icons.receipt_long_rounded,
          title: 'Split expenses without the awkward math',
          body:
              'Add bills with friends, roommates or trip squads — SplitPay tracks who owes what and settles via UPI instantly.',
          trust: const _TrustPeople(text: 'Used by 140,000+ friend groups'),
          cta: 'Get started',
          ctaIcon: Icons.arrow_forward_rounded,
          onCta: _next,
          onLogin: _finish,
        ),
      ),
      _IntroPage(
        illustration: const BalanceIllustration(),
        sheet: _Sheet(
          step: 1,
          icon: Icons.bar_chart_rounded,
          title: 'Real-time balances that never get tangled',
          body:
              'See exactly who gets what and who pays whom. Our smart algorithm nets off debts so you do fewer transactions.',
          trust: const _TrustShield(text: '100% transparent group ledger'),
          cta: 'Continue: Settle UPI',
          ctaIcon: Icons.arrow_forward_rounded,
          onCta: _next,
          onLogin: _finish,
        ),
      ),
      _IntroPage(
        illustration: const UpiIllustration(),
        sheet: _Sheet(
          step: 2,
          icon: Icons.bolt_rounded,
          title: 'Settle debts instantly via any UPI app',
          body:
              'Pay back friends with Google Pay, PhonePe, or Paytm with pre-filled deep links and live receipt verification in seconds.',
          trust: const _TrustShield(text: 'NPCI Compliant • 256-Bit Encrypted'),
          cta: 'Start splitting now',
          ctaIcon: Icons.rocket_launch_rounded,
          onCta: _next,
          onLogin: _finish,
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    _index.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    _controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    if (_index.value < _pages.length - 1) {
      _goTo(_index.value + 1);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    await OnboardingPrefs.setSeenIntro();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.palette.isDark;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: AppColors.surface,
            ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: dark
                ? null
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE6E0FF),
                      Color(0xFFF1F0FD),
                      Color(0xFFD9F5EC),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                ValueListenableBuilder<int>(
                  valueListenable: _index,
                  builder: (context, i, _) => _StepTabs(index: i, onTap: _goTo),
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (i) => _index.value = i,
                    children: _pages,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _StepTabs extends StatelessWidget {
  const _StepTabs({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final labels = [
      '1. Add Bills',
      index == 1 ? '2. Track Balances' : '2. Balances',
      '3. Settle UPI',
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final active = i == index;
          final done = i < index;
          return Expanded(
            flex: active ? 5 : 4,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : done
                      ? AppColors.primaryTint
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: active ? AppShadows.fab : null,
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (active) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ] else if (done) ...[
                          Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          labels[i],
                          maxLines: 1,
                          style: AppText.labelMd.copyWith(
                            fontWeight: FontWeight.w700,
                            color: active
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.illustration, required this.sheet});

  final Widget illustration;
  final Widget sheet;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Center(
              child: FittedBox(fit: BoxFit.contain, child: illustration),
            ),
          ),
        ),
        sheet,
      ],
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.step,
    required this.icon,
    required this.title,
    required this.body,
    required this.trust,
    required this.cta,
    required this.ctaIcon,
    required this.onCta,
    required this.onLogin,
  });

  final int step;
  final IconData icon;
  final String title;
  final String body;
  final Widget trust;
  final String cta;
  final IconData ctaIcon;
  final VoidCallback onCta;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.palette.isDark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        border: Border.all(
          color: dark ? AppColors.divider : Colors.transparent,
        ),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF5B3DF5).withValues(alpha: 0.10),
                  blurRadius: 32,
                  offset: const Offset(0, -8),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Dots(active: step),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'STEP ${step + 1} OF 3',
                      style: AppText.labelSm.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppText.displayLgMobile.copyWith(
                  fontSize: 28,
                  height: 1.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                body,
                textAlign: TextAlign.center,
                style: AppText.bodyLg.copyWith(
                  fontSize: 15,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              trust,
              const SizedBox(height: 18),
              _CtaButton(label: cta, icon: ctaIcon, onTap: onCta),
              const SizedBox(height: 4),
              InkWell(
                onTap: onLogin,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Log in',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    style: AppText.bodyMd.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.active});

  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final on = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: on ? 36 : 10,
          height: 8,
          decoration: BoxDecoration(
            color: on
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        );
      }),
    );
  }
}

/// Primary CTA with trailing icon. Gradient = main action (DESIGN.md).
class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.control);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: radius,
          boxShadow: AppShadows.fab,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppText.labelLg.copyWith(color: Colors.white),
                ),
                const SizedBox(width: 10),
                Icon(icon, color: Colors.white, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustShield extends StatelessWidget {
  const _TrustShield({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _TrustPill(
      leading: Icon(
        Icons.verified_user_outlined,
        size: 18,
        color: AppColors.success,
      ),
      text: text,
    );
  }
}

class _TrustPeople extends StatelessWidget {
  const _TrustPeople({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    const colors = [Color(0xFF5B3DF5), Color(0xFF9B1239), Color(0xFF0F7A55)];
    return _TrustPill(
      leading: SizedBox(
        width: 22 + 2 * 15.0,
        height: 26,
        child: Stack(
          children: [
            for (var i = 0; i < 3; i++)
              Positioned(
                left: i * 15.0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: colors[i],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surfaceRaised,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
      text: text,
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({required this.leading, required this.text});

  final Widget leading;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.labelMd.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
