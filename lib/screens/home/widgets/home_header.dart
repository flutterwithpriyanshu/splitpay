import 'dart:async';

import 'package:flutter/material.dart';
import 'package:splitpay/screens/home/widgets/notification_bell.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/app_logo.dart';
import 'package:splitpay/widgets/local_avatar.dart';

/// Greeting from the device clock. Re-checked every 30 s and on app resume,
/// so it flips at 12:00 / 17:00 / 21:00 / 05:00 without a restart.
String greetingForHour(int hour) {
  if (hour >= 5 && hour < 12) return 'Good morning';
  if (hour >= 12 && hour < 17) return 'Good afternoon';
  if (hour >= 17 && hour < 21) return 'Good evening';
  return 'Good night';
}

/// Fixed top bar: logo, "SplitPay / Home", bell, profile avatar.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.myUid,
    required this.onProfileTap,
  });

  final String myUid;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        children: [
          const AppLogo(size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SplitPay',
                  style: AppText.labelMd.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.1,
                  ),
                ),
                Text(
                  'Home',
                  style: AppText.headlineMd.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const NotificationBell(),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  width: 2,
                ),
              ),
              child: LocalAvatar(localKey: myUid, isProfile: true, radius: 18),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Welcome back / Good evening, Name" + show-hide balances toggle.
class HomeGreeting extends StatefulWidget {
  const HomeGreeting({
    super.key,
    required this.userName,
    required this.myUid,
    required this.hidden,
    required this.onToggleHidden,
    required this.onProfileTap,
  });

  /// Auth displayName fallback. Phone-login users have none, so the saved
  /// profile name is loaded from Firestore and wins when present.
  final String userName;
  final String myUid;
  final bool hidden;
  final VoidCallback onToggleHidden;
  final VoidCallback onProfileTap;

  @override
  State<HomeGreeting> createState() => _HomeGreetingState();
}

class _HomeGreetingState extends State<HomeGreeting>
    with WidgetsBindingObserver {
  late String _salutation = greetingForHour(DateTime.now().hour);
  Timer? _timer;
  String? _profileName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
    _loadName();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    final g = greetingForHour(DateTime.now().hour);
    if (g != _salutation && mounted) setState(() => _salutation = g);
  }

  Future<void> _loadName() async {
    try {
      final profile = await FriendService.getMyProfile();
      final name = (profile?['fullName'] as String?)?.trim() ?? '';
      if (name.isNotEmpty && mounted) setState(() => _profileName = name);
    } catch (_) {}
  }

  String get _firstName {
    final full = (_profileName ?? widget.userName).trim();
    if (full.isEmpty) return 'there';
    return full.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: widget.onProfileTap,
          child: SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                  child: LocalAvatar(
                    localKey: widget.myUid,
                    isProfile: true,
                    radius: 29,
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: AppText.bodyMd.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                '$_salutation, $_firstName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.headlineLg.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.onToggleHidden,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.hidden
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}
