import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/core/phone_utils.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/core/upi_utils.dart';
import 'package:splitpay/core/profile_prefs.dart';
import 'package:splitpay/services/local_image_service.dart';
import 'package:splitpay/services/fcm_service.dart';

/// Shown once, right after a brand-new sign-in, to collect whatever the
/// auth provider didn't already give us. Google gives name + email but
/// never phone/UPI. Phone-OTP sign-in already gives a verified phone
/// number, so that field is hidden in that case — only UPI (and name,
/// pre-filled empty) is asked for.
class CompleteProfileScreen extends StatefulWidget {
  final String uid;
  final String name;
  final String email;

  /// Verified phone number from Firebase Auth (phone sign-in). Null when
  /// the user signed in with Google — in that case we still ask for phone.
  final String? phone;

  /// Called after profile is saved. Root app flips its own state to move
  /// to MainShell — this screen never navigates the app Navigator itself,
  /// so the root auth StreamBuilder stays alive.
  final VoidCallback onDone;

  const CompleteProfileScreen({
    super.key,
    required this.uid,
    required this.name,
    required this.email,
    required this.onDone,
    this.phone,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _phoneController = TextEditingController();
  final _upiController = TextEditingController();
  late final TextEditingController _nameController;
  File? _pickedProfileImage;
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  bool _hasExistingProfile = false;
  bool _upiPrefilled = false;

  /// Normalized phone already saved on THIS uid's doc ('' = none yet).
  String _savedOwnPhone = '';

  bool get _phoneAlreadyVerified =>
      widget.phone != null && widget.phone!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _loadExistingProfile().then((_) => _checkVerifiedPhoneDuplicate());
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _upiController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    showAppToast(context, message);
  }

  /// Fills the form from a saved profile map. [overwrite] true = own doc
  /// (saved values win). false = borrowed from another account of the same
  /// verified person (only fills empty fields).
  void _applySavedProfile(Map<String, dynamic> profile,
      {required bool overwrite}) {
    final savedName = (profile['fullName'] as String?)?.trim() ?? '';
    final savedPhone = (profile['phoneNumber'] as String?)?.trim() ?? '';
    final savedUpi = (profile['upiId'] as String?)?.trim() ?? '';

    if (savedName.isNotEmpty &&
        (overwrite || _nameController.text.trim().isEmpty)) {
      _nameController.text = savedName;
    }
    if (!_phoneAlreadyVerified &&
        savedPhone.isNotEmpty &&
        (overwrite || _phoneController.text.trim().isEmpty)) {
      _phoneController.text = savedPhone;
    }
    if (savedUpi.isNotEmpty &&
        (overwrite || _upiController.text.trim().isEmpty)) {
      _upiController.text = savedUpi;
      _upiPrefilled = true;
    }
  }

  /// Same person can land on a new uid. Match only on the Google email,
  /// which is verified. Phone is NOT used here: a typed phone is
  /// unverified, and a duplicate phone is blocked instead (see below).
  Future<Map<String, dynamic>?> _findProfileFromOtherAccount(
    CollectionReference<Map<String, dynamic>> users,
  ) async {
    try {
      final email = widget.email.trim();
      if (email.isEmpty) return null;
      final snap = await users.where('email', isEqualTo: email).limit(5).get();
      for (final d in snap.docs) {
        if (d.id == widget.uid) continue;
        final upi = (d.data()['upiId'] as String?)?.trim();
        if (upi != null && upi.isNotEmpty) return d.data();
      }
    } catch (_) {
      // Rules or network blocked the lookup. User types UPI instead.
    }
    return null;
  }

  /// Login method of the OTHER account that already owns this phone
  /// number: 'phone', 'google' or 'unknown' (old doc without the field).
  /// Null = nobody else owns it. Fails open (null) on error so a rules or
  /// network problem never locks a user out of signup.
  Future<String?> _otherAccountMethodForPhone(String normalizedPhone) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: normalizedPhone)
          .limit(5)
          .get();
      for (final d in snap.docs) {
        if (d.id == widget.uid) continue;
        final m = (d.data()['signInMethod'] as String?)?.trim();
        return (m == 'phone' || m == 'google') ? m : 'unknown';
      }
    } catch (_) {}
    return null;
  }

  /// Method of the login being used right now, from Firebase Auth.
  String get _currentSignInMethod {
    final ids = FirebaseAuth.instance.currentUser?.providerData
            .map((p) => p.providerId)
            .toSet() ??
        <String>{};
    if (ids.contains('phone')) return 'phone';
    if (ids.contains('google.com')) return 'google';
    return _phoneAlreadyVerified ? 'phone' : 'google';
  }

  /// Phone OTP login whose number already sits on another account
  /// (e.g. user signed up with Google and typed this number earlier).
  Future<void> _checkVerifiedPhoneDuplicate() async {
    if (!mounted || !_phoneAlreadyVerified) return;
    final verified = normalizePhone(widget.phone!);
    if (verified == _savedOwnPhone) return;
    final method = await _otherAccountMethodForPhone(verified);
    if (method != null && mounted) {
      await _showDuplicatePhoneDialog(verifiedPhone: true, method: method);
    }
  }

  Future<void> _showDuplicatePhoneDialog({
    required bool verifiedPhone,
    required String method,
  }) async {
    final String hint;
    switch (method) {
      case 'google':
        hint = 'Log in with Google instead.';
        break;
      case 'phone':
        hint = 'Log in with this number using OTP instead.';
        break;
      default:
        hint = 'Log in with the method you used first.';
    }
    final goBack = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Number already in use'),
        content: Text('This number already belongs to an existing account. $hint'),
        actions: [
          if (!verifiedPhone)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Change number'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Back to login'),
          ),
        ],
      ),
    );
    if (goBack == true) await _backToLogin();
  }

  /// Drops the empty half-made account (only when no profile doc exists,
  /// so no data is lost) and returns to the sign-in screen. The root
  /// StreamBuilder in main.dart swaps to AuthScreen on signOut.
  Future<void> _backToLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    try {
      if (user != null && user.uid == widget.uid && !_hasExistingProfile) {
        await user.delete();
      }
    } catch (_) {
      // Needs recent login or already gone. signOut below still runs.
    }
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await ProfilePrefs.clear();
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _loadExistingProfile() async {
    final users = FirebaseFirestore.instance.collection('users');
    try {
      final doc = await users.doc(widget.uid).get();
      if (!mounted) return;

      final profile = doc.data();
      if (profile != null) {
        _hasExistingProfile = true;
        _savedOwnPhone =
            normalizePhone((profile['phoneNumber'] as String?) ?? '');
        _applySavedProfile(profile, overwrite: true);
      }

      if (_upiController.text.trim().isEmpty) {
        final other = await _findProfileFromOtherAccount(users);
        if (!mounted) return;
        if (other != null) _applySavedProfile(other, overwrite: false);
      }
    } catch (e) {
      // Offline or Firestore error: use last UPI cached on this device.
      final cached = await ProfilePrefs.getSavedUpi(widget.uid);
      if (!mounted) return;
      if (cached != null && _upiController.text.trim().isEmpty) {
        _upiController.text = cached;
        _upiPrefilled = true;
      }
      _showError('Could not load your saved profile: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _submit() async {
    if (_isLoadingProfile) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Please enter your full name');
      return;
    }

    String normalizedPhone;
    if (_phoneAlreadyVerified) {
      normalizedPhone = normalizePhone(widget.phone!);
    } else {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        _showError('Please enter your phone number');
        return;
      }
      normalizedPhone = normalizePhone(phone);
      if (normalizedPhone.length != 10) {
        _showError('Phone number must contain 10 digits');
        return;
      }
      if (normalizedPhone != _savedOwnPhone) {
        setState(() => _isLoading = true);
        final method = await _otherAccountMethodForPhone(normalizedPhone);
        if (mounted) setState(() => _isLoading = false);
        if (method != null) {
          if (mounted) {
            await _showDuplicatePhoneDialog(
              verifiedPhone: false,
              method: method,
            );
          }
          return;
        }
      }
    }

    final upi = _upiController.text.trim();
    if (upi.isEmpty) {
      _showError('Please enter your UPI ID');
      return;
    }
    if (!isValidUpiFormat(upi)) {
      _showError('Enter a valid UPI ID, e.g. name@bank');
      return;
    }

    setState(() => _isLoading = true);

    var profileSaved = false;
    try {
      final profileData = <String, dynamic>{
        'fullName': name,
        'phoneNumber': normalizedPhone,
        'upiId': upi,
      };
      // Phone-OTP users have no email. Never store a blank one.
      final email = widget.email.trim();
      if (email.isNotEmpty) profileData['email'] = email;
      if (!_hasExistingProfile) {
        profileData['createdAt'] = FieldValue.serverTimestamp();
        // First login method. Used to tell the user which login to use
        // when the same phone shows up on another account.
        profileData['signInMethod'] = _currentSignInMethod;
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .set(profileData, SetOptions(merge: true));
      profileSaved = true;
      await ProfilePrefs.saveUpi(widget.uid, upi);

      if (_pickedProfileImage != null) {
        await LocalImageService.saveProfileImage(
          widget.uid,
          await _pickedProfileImage!.readAsBytes(),
        );
      }

      await FcmService.saveTokenForCurrentUser();

      await ProfilePrefs.setProfileComplete(widget.uid);

      if (!mounted) return;
      widget.onDone();
    } catch (e) {
      _showError(
        profileSaved
            ? 'Your profile was saved, but setup could not be completed: $e'
            : 'Could not save your profile to Firestore: $e',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                'One more thing',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _phoneAlreadyVerified
                    ? 'We need your UPI ID so you can receive settlement payments.'
                    : 'We need your phone number so friends can find and split bills with you, and your UPI ID so you can receive settlement payments.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Full Name',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: GoogleFonts.inter(fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Your full name',
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickProfileImage,
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.surface,
                  backgroundImage: _pickedProfileImage == null
                      ? null
                      : FileImage(_pickedProfileImage!),
                  child: _pickedProfileImage == null
                      ? const Icon(Icons.add_a_photo_rounded)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Profile picture (optional)',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              if (!_phoneAlreadyVerified) ...[
                Text(
                  'Phone Number',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.inter(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: '(555) 000-0000',
                    filled: true,
                    fillColor: AppColors.surface,
                    suffixIcon: _phoneIsValid
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'UPI ID',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _upiController,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.inter(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'yourname@bank',
                  filled: true,
                  fillColor: AppColors.surface,
                  suffixIcon: _upiIsValid
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _upiPrefilled
                    ? 'Filled from your saved profile. Edit it to change.'
                    : 'Used to receive settlement payments via UPI.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading || _isLoadingProfile ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading || _isLoadingProfile
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Continue',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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

  bool get _phoneIsValid => normalizePhone(_phoneController.text).length == 10;

  bool get _upiIsValid => isValidUpiFormat(_upiController.text);

  Future<void> _pickProfileImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (picked != null && mounted) {
      setState(() => _pickedProfileImage = File(picked.path));
    }
  }
}