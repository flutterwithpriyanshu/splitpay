import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/core/phone_utils.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/core/upi_utils.dart';
import 'package:splitpay/screens/main_shell.dart';
import 'package:splitpay/services/local_image_service.dart';
import 'package:splitpay/services/onesignal_service.dart';

/// Shown once, right after a brand-new Google sign-in, because Google
/// gives us name + email but never a phone number or UPI ID — and both
/// are mandatory here (phone is how friend-linking finds people, UPI ID
/// is how settlement payments get sent).
class CompleteProfileScreen extends StatefulWidget {
  final String uid;
  final String name;
  final String email;

  const CompleteProfileScreen({
    super.key,
    required this.uid,
    required this.name,
    required this.email,
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
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

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) {
      _showError('Please enter your full name');
      return;
    }
    if (phone.isEmpty) {
      _showError('Please enter your phone number');
      return;
    }
    final normalizedPhone = normalizePhone(phone);
    if (normalizedPhone.length != 10) {
      _showError('Phone number must contain 10 digits');
      return;
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

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'fullName': name,
        'phoneNumber': normalizedPhone,
        'upiId': upi,
        'email': widget.email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (_pickedProfileImage != null) {
        await LocalImageService.saveProfileImage(
          widget.uid,
          await _pickedProfileImage!.readAsBytes(),
        );
      }

      await OneSignalService.saveIdForCurrentUser();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } catch (e) {
      _showError('Something went wrong. Try again.');
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
                'We need your phone number so friends can find and split bills with you, and your UPI ID so you can receive settlement payments.',
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
                'Used to receive settlement payments via UPI.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
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
