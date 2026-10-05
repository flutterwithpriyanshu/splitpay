import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/core/phone_country_flag.dart';
import 'package:splitpay/screens/auth/auth_screen_components.dart';
import 'package:splitpay/screens/auth/security_check_screen.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/app_logo.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _countryCodeController = TextEditingController(text: '+91');
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _otpFocus = FocusNode();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isLoading = false;
  bool _codeSent = false;
  String? _verificationId;
  int? _resendToken;

  bool _securityOverlayOpen = false;

  // Bumped on each Send OTP and on cancel. Stale Firebase callbacks
  // (from a cancelled attempt) check it and do nothing.
  int _attempt = 0;

  // OTP cooldown. Static so it survives logout -> AuthScreen rebuild, which
  // otherwise resets the timer and lets a user spam Send OTP.
  static DateTime? _cooldownUntil;
  static bool _cooldownTooMany = false;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    if (_cooldownUntil != null) _runCooldownTimer();
  }

  void _startCooldown(int seconds, {bool tooMany = false}) {
    _cooldownTooMany = tooMany;
    _cooldownUntil = DateTime.now().add(Duration(seconds: seconds));
    _runCooldownTimer();
  }

  void _runCooldownTimer() {
    _cooldownTimer?.cancel();
    _tickCooldown();
    if (_cooldownUntil == null) return;
    _cooldownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tickCooldown(),
    );
  }

  String _formatCooldown(int seconds) {
    final m = seconds ~/ 60;
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  void _tickCooldown() {
    final until = _cooldownUntil;
    final left = until == null
        ? 0
        : (until.difference(DateTime.now()).inMilliseconds / 1000).ceil();
    if (left <= 0) {
      _cooldownTimer?.cancel();
      _cooldownTimer = null;
      _cooldownUntil = null;
      _cooldownTooMany = false;
      if (mounted && _cooldownSeconds != 0) {
        setState(() => _cooldownSeconds = 0);
      }
      return;
    }
    if (mounted) setState(() => _cooldownSeconds = left);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _countryCodeController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _showError(String message) => showAppToast(context, message);

  void _showSecurityOverlay() {
    if (_securityOverlayOpen) return;
    _securityOverlayOpen = true;
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) =>
            SecurityCheckScreen(onCancel: _cancelSecurity),
      ),
    );
  }

  void _hideSecurityOverlay() {
    if (!_securityOverlayOpen) return;
    _securityOverlayOpen = false;
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  /// User closed the security page (X, back, retry).
  void _cancelSecurity() {
    _attempt++;
    _hideSecurityOverlay();
    if (mounted) setState(() => _isLoading = false);
  }

  void _changeNumber() {
    if (_isLoading) return;
    setState(() {
      _codeSent = false;
      _otpController.clear();
      _verificationId = null;
      _resendToken = null;
    });
  }

  Future<void> _sendOtp() async {
    if (_cooldownSeconds > 0) {
      _showError(
        'Wait ${_formatCooldown(_cooldownSeconds)} before requesting another OTP',
      );
      return;
    }
    final countryCodeDigits = _countryCodeController.text.replaceAll(
      RegExp(r'\D'),
      '',
    );
    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final totalDigits = countryCodeDigits.length + phoneDigits.length;
    if (countryCodeDigits.isEmpty ||
        countryCodeDigits.length > 3 ||
        countryCodeDigits.startsWith('0') ||
        phoneDigits.isEmpty ||
        totalDigits < 8 ||
        totalDigits > 15) {
      _showError('Enter a valid country code and phone number');
      return;
    }
    final phone = '+$countryCodeDigits$phoneDigits';
    final attempt = ++_attempt;
    setState(() => _isLoading = true);
    _showSecurityOverlay();
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (attempt != _attempt) return;
          _hideSecurityOverlay();
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (attempt != _attempt) return;
          _hideSecurityOverlay();
          // 17010 = too-many-requests: Firebase abuse throttle on this
          // device or number. Back off longer, don't keep hammering it.
          final tooMany =
              e.code == 'too-many-requests' ||
              (e.message ?? '').contains('unusual activity');
          _startCooldown(tooMany ? 300 : 30, tooMany: tooMany);
          if (mounted) {
            setState(() => _isLoading = false);
            _showError(
              tooMany
                  ? 'Too many attempts from this device. Please wait, or '
                        'continue with Google.'
                  : (e.message ?? 'Verification failed'),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (attempt != _attempt) return;
          _hideSecurityOverlay();
          _startCooldown(60);
          if (mounted) {
            setState(() {
              _isLoading = false;
              _codeSent = true;
              _verificationId = verificationId;
              _resendToken = resendToken;
            });
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (attempt != _attempt) return;
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (attempt != _attempt) return;
      _hideSecurityOverlay();
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Could not send OTP: $e');
      }
    }
  }

  void _resendOtp() {
    _otpController.clear();
    _sendOtp();
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty || _verificationId == null) {
      _showError('Enter the OTP sent to your phone');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      // main.dart's root StreamBuilder routes to CompleteProfileScreen or MainShell.
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Invalid OTP');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
    } on GoogleSignInException catch (e) {
      _showError('Google sign-in failed: ${e.description ?? e.code.name}');
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Google sign-in failed');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------- UI

  String get _prettyPhone {
    final cc = _countryCodeController.text.replaceAll(RegExp(r'\D'), '');
    final d = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final spaced = d.length == 10
        ? '${d.substring(0, 5)} ${d.substring(5)}'
        : d;
    return '+$cc $spaced';
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.palette.isDark;
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: Colors.transparent),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: dark
                ? null
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFEDE9FF), Color(0xFFF5F6FB)],
                  ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _topBar(),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    child: Column(
                      children: [
                        AuthTabs(step: _codeSent ? 2 : 0),
                        const SizedBox(height: 20),
                        _hero(),
                        const SizedBox(height: 20),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppRadius.card,
                              ),
                              border: Border.all(
                                color: AppColors.divider.withValues(alpha: 0.7),
                              ),
                              boxShadow: AppShadows.card,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: _codeSent
                                  ? KeyedSubtree(
                                      key: const ValueKey('otp'),
                                      child: _otpCard(),
                                    )
                                  : KeyedSubtree(
                                      key: const ValueKey('phone'),
                                      child: _phoneCard(),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _terms(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: _codeSent
                  ? IconButton(
                      onPressed: _isLoading ? null : _changeNumber,
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppLogo(size: 30),
                  const SizedBox(width: 8),
                  Text(
                    'SplitPay',
                    style: AppText.headlineSm.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    return Column(
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.30),
                      AppColors.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              const AppLogo(size: 64),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _codeSent ? 'Verify OTP' : 'Welcome back',
            key: ValueKey(_codeSent),
            textAlign: TextAlign.center,
            style: AppText.headlineLg.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _codeSent
                ? "We've sent an authorization code via SMS"
                : 'Login or sign up with your phone number to manage shared tabs',
            textAlign: TextAlign.center,
            style: AppText.bodyLg.copyWith(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ---- Phone state ----

  Widget _phoneCard() {
    final canSend = !_isLoading && _cooldownSeconds == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'MOBILE NUMBER',
            style: AppText.labelSm.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
        ),
        Row(
          children: [
            _countryChip(),
            const SizedBox(width: 8),
            Expanded(child: _phoneField()),
          ],
        ),
        const SizedBox(height: 16),
        AuthButton(
          label: _cooldownSeconds > 0
              ? 'Resend OTP in ${_formatCooldown(_cooldownSeconds)}'
              : 'Send OTP',
          icon: Icons.arrow_forward_rounded,
          loading: _isLoading,
          onTap: canSend ? _sendOtp : null,
        ),
        if (_cooldownSeconds > 0) ...[
          const SizedBox(height: 12),
          CooldownNotice(
            tooMany: _cooldownTooMany,
            timeLeft: _formatCooldown(_cooldownSeconds),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.divider, height: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: AppText.labelSm.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.divider, height: 1)),
          ],
        ),
        const SizedBox(height: 16),
        Material(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.control),
            onTap: _isLoading ? null : _signInWithGoogle,
            child: SizedBox(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CustomPaint(painter: GoogleGPainter()),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: AppText.labelLg.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt_rounded, size: 16, color: AppColors.success),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Instant zero-friction UPI auto-sync enabled',
                style: AppText.bodySm.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _countryChip() {
    return Container(
      height: 64,
      padding: const EdgeInsets.only(left: 12, right: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([
              _countryCodeController,
              _phoneController,
            ]),
            builder: (context, _) {
              final flag = phoneCountryFlag(
                countryCode: _countryCodeController.text,
                phoneNumber: _phoneController.text,
              );
              return flag == null
                  ? Icon(
                      Icons.public_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    )
                  : Text(flag, style: const TextStyle(fontSize: 18));
            },
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 40,
            child: TextField(
              controller: _countryCodeController,
              keyboardType: TextInputType.phone,
              maxLength: 4,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
              ],
              style: AppText.labelLg
                  .copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  )
                  .tabular,
              decoration: const InputDecoration(
                counterText: '',
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _phoneField() {
    return Container(
      height: 64,
      padding: const EdgeInsets.only(left: 12, right: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 15,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppText.headlineSm
                  .copyWith(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  )
                  .tabular,
              decoration: InputDecoration(
                counterText: '',
                hintText: '12345 67890',
                hintStyle: AppText.headlineSm
                    .copyWith(
                      fontSize: 16,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                    )
                    .tabular,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _phoneController,
            builder: (_, v, _) => v.text.isEmpty
                ? const SizedBox(width: 12)
                : IconButton(
                    onPressed: _phoneController.clear,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: Icon(
                      Icons.cancel_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ---- OTP state ----

  Widget _otpCard() {
    final resendReady = _cooldownSeconds == 0 && !_isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: Row(
            children: [
              Icon(
                Icons.smartphone_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _prettyPhone,
                  style: AppText.labelMd
                      .copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      )
                      .tabular,
                ),
              ),
              TextButton(
                onPressed: _isLoading ? null : _changeNumber,
                child: Text(
                  'Change',
                  style: AppText.labelMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _otpBoxes(),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_cooldownSeconds > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Resend in ',
                        style: AppText.labelSm.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _formatCooldown(_cooldownSeconds),
                        style: AppText.labelSm
                            .copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w800,
                            )
                            .tabular,
                      ),
                    ],
                  ),
                )
              else
                const SizedBox.shrink(),
              GestureDetector(
                onTap: resendReady ? _resendOtp : null,
                child: Text(
                  'Resend via SMS',
                  style: AppText.labelSm.copyWith(
                    fontSize: 12,
                    color: resendReady
                        ? AppColors.primary
                        : AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AuthButton(
          label: 'Verify & Continue',
          icon: Icons.check_circle_outline_rounded,
          loading: _isLoading,
          onTap: _isLoading ? null : _verifyOtp,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sms_outlined, size: 16, color: AppColors.success),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Listening for incoming OTP automatically…',
                style: AppText.bodySm.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 6 display boxes over one invisible TextField that owns focus + input.
  Widget _otpBoxes() {
    return ListenableBuilder(
      listenable: Listenable.merge([_otpController, _otpFocus]),
      builder: (context, _) {
        final text = _otpController.text;
        final focused = _otpFocus.hasFocus;
        return Stack(
          children: [
            Row(
              children: List.generate(6, (i) {
                final filled = i < text.length;
                final active = focused && i == text.length.clamp(0, 5);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primaryTint
                            : AppColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: active
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: filled
                          ? Text(
                              text[i],
                              style: AppText.headlineMd
                                  .copyWith(color: AppColors.textPrimary)
                                  .tabular,
                            )
                          : Text(
                              '_',
                              style: AppText.headlineMd.copyWith(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.textSecondary.withValues(
                                        alpha: 0.4,
                                      ),
                              ),
                            ),
                    ),
                  ),
                );
              }),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _otpController,
                  focusNode: _otpFocus,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  enableInteractiveSelection: false,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _terms() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: AppText.bodySm.copyWith(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
          children: [
            const TextSpan(text: 'By continuing you agree to our '),
            TextSpan(
              text: 'Terms of Service',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
