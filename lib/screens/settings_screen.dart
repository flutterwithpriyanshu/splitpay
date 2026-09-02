import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitpay/core/static_content.dart';
import 'package:splitpay/theme/theme_notifier.dart';
import 'package:splitpay/screens/auth_screen.dart';
import 'package:splitpay/screens/static_content_screen.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/widgets/edit_profile_screen.dart';
import 'package:splitpay/widgets/local_avatar.dart';
import 'package:splitpay/widgets/manage_friends_screen.dart';
import 'package:splitpay/services/onesignal_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  String _currency = 'INR (₹)';
  String _language = 'English';

  Map<String, dynamic>? _profile;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _darkMode = themeModeNotifier.value == ThemeMode.dark;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingProfile = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      setState(() {
        _profile = doc.data();
        _loadingProfile = false;
      });
    } catch (_) {
      setState(() => _loadingProfile = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Log out?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await OneSignalService.clearId();
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // The auth flow doesn't rely on the root StreamBuilder after the
        // first launch — every screen up to MainShell got here via
        // pushAndRemoveUntil, which already cleared that route out of the
        // stack. So signOut() alone has nothing left to redirect anything.
        // Push AuthScreen directly and wipe the stack under it, so there's
        // no back-button path into the signed-out MainShell.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showCurrencyPicker() {
    _showOptionSheet(
      title: 'Currency',
      options: const ['INR (₹)', 'USD (\$)', 'EUR (€)', 'GBP (£)'],
      current: _currency,
      onSelect: (val) => setState(() => _currency = val),
    );
  }

  void _showLanguagePicker() {
    _showOptionSheet(
      title: 'Language',
      options: const ['English', 'Hindi', 'Spanish', 'French'],
      current: _language,
      onSelect: (val) => setState(() => _language = val),
    );
  }

  void _showOptionSheet({
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...options.map(
                (opt) => ListTile(
                  title: Text(opt, style: GoogleFonts.inter(fontSize: 14)),
                  trailing: opt == current
                      ? Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  onTap: () {
                    onSelect(opt);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?['fullName'] ?? 'User';
    final phone = _profile?['phoneNumber'] ?? '-';
    final upiId = _profile?['upiId'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Text(
                  'Settings',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Profile card
            _loadingProfile
                ? _skeletonBox(height: 90, width: double.infinity, radius: 20)
                : Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        LocalAvatar(
                          localKey:
                              FirebaseAuth.instance.currentUser?.uid ?? '',
                          isProfile: true,
                          radius: 30,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                phone,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              GestureDetector(
                                onTap: () {
                                  final uid =
                                      FirebaseAuth.instance.currentUser?.uid ??
                                          '';
                                  Clipboard.setData(ClipboardData(text: uid));
                                  showAppToast(context, 'UID copied: $uid');
                                },
                                child: Text(
                                  'UID: ${FirebaseAuth.instance.currentUser?.uid ?? '-'}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textSecondary
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 24),

            _sectionTitle('Account'),
            _settingsTile(
              icon: Icons.person_rounded,
              label: 'Edit Profile',
              onTap: () async {
                final updated = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(
                      initialName: name,
                      initialPhone: phone,
                      initialUpi: upiId,
                    ),
                  ),
                );
                if (updated == true) _loadProfile(); // refresh after save
              },
            ),
            _settingsTile(
              icon: Icons.people_alt_rounded,
              label: 'Manage Friends',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ManageFriendsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            _sectionTitle('Preferences'),
            _switchTile(
              icon: Icons.dark_mode_rounded,
              label: 'Dark Mode',
              value: _darkMode,
              onChanged: (val) {
                setState(() => _darkMode = val);
                themeModeNotifier.value = val
                    ? ThemeMode.dark
                    : ThemeMode.light;
              },
            ),
            _settingsTile(
              icon: Icons.currency_exchange_rounded,
              label: 'Currency',
              trailing: _currency,
              onTap: _showCurrencyPicker,
            ),
            _settingsTile(
              icon: Icons.language_rounded,
              label: 'Language',
              trailing: _language,
              onTap: _showLanguagePicker,
            ),

            const SizedBox(height: 20),
            _sectionTitle('Support'),
            _settingsTile(
              icon: Icons.help_center_rounded,
              label: 'Help Center',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const StaticContentScreen(
                      title: 'Help Center',
                      content: helpCenterContent,
                    ),
                  ),
                );
              },
            ),
            _settingsTile(
              icon: Icons.privacy_tip_rounded,
              label: 'Privacy Policy',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const StaticContentScreen(
                      title: 'Privacy Policy',
                      content: privacyPolicyContent,
                    ),
                  ),
                );
              },
            ),
            _settingsTile(
              icon: Icons.description_rounded,
              label: 'Terms & Conditions',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const StaticContentScreen(
                      title: 'Terms & Conditions',
                      content: termsContent,
                    ),
                  ),
                );
              },
            ),
            _settingsTile(
              icon: Icons.star_rounded,
              label: 'Rate App',
              onTap: () async {
                // Replace with your real Play Store URL once published
                final uri = Uri.parse(
                  'https://play.google.com/store/apps/details?id=com.example.splitpay',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else if (context.mounted) {
                  showAppToast(context, 'Could not open store link');
                }
              },
            ),

            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Logout',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    ),
  );

  Widget _settingsTile({
    required IconData icon,
    required String label,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
        ),
        trailing: trailing != null
            ? Text(
                trailing,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              )
            : Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),

          const SizedBox(width: 16),

          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          Transform.scale(
            scale: 0.80,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: AppColors.primary,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade700,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonBox({
    required double height,
    required double width,
    double radius = 8,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
