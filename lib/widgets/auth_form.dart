import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/theme/app_colors.dart';

class AuthForm extends StatelessWidget {
  const AuthForm({
    required this.isLogin,
    required this.isLoading,
    required this.obscurePassword,
    required this.pickedProfileImage,
    required this.nameController,
    required this.phoneController,
    required this.upiController,
    required this.emailController,
    required this.passwordController,
    required this.onModeChanged,
    required this.onPickProfileImage,
    required this.onTogglePasswordVisibility,
    required this.onSubmit,
    required this.onGoogleSignIn,
    super.key,
  });

  final bool isLogin;
  final bool isLoading;
  final bool obscurePassword;
  final File? pickedProfileImage;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController upiController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onPickProfileImage;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onSubmit;
  final VoidCallback onGoogleSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLogin ? 'Login to continue' : 'Create an account to get started',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          _modeToggle(),
          const SizedBox(height: 24),
          if (!isLogin) ...[
            _profileImagePicker(),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Add a photo (optional)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _fieldWithLabel(
              'Full Name',
              _field(controller: nameController, hint: 'Enter your full name'),
            ),
            const SizedBox(height: 16),
            _fieldWithLabel(
              'Phone Number',
              _field(
                controller: phoneController,
                hint: '(555) 000-0000',
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(height: 16),
            _fieldWithLabel(
              'UPI ID',
              _field(controller: upiController, hint: 'yourname@bank'),
            ),
            const SizedBox(height: 4),
            Text(
              'Used to receive settlement payments via UPI.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
          ],
          _fieldWithLabel(
            'Email',
            _field(
              controller: emailController,
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          const SizedBox(height: 16),
          _fieldWithLabel(
            'Password',
            _field(
              controller: passwordController,
              hint: 'Enter your password',
              obscureText: obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: onTogglePasswordVisibility,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _submitButton(),
          const SizedBox(height: 16),
          _divider(),
          const SizedBox(height: 16),
          _googleButton(),
          const SizedBox(height: 20),
          _terms(),
        ],
      ),
    );
  }

  Widget _modeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [_tab('Login', true), _tab('Sign Up', false)]),
    );
  }

  Widget _tab(String label, bool tabIsLogin) {
    final selected = isLogin == tabIsLogin;
    return Expanded(
      child: GestureDetector(
        onTap: () => onModeChanged(tabIsLogin),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: onPickProfileImage,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.background,
              backgroundImage: pickedProfileImage == null
                  ? null
                  : FileImage(pickedProfileImage!),
              child: pickedProfileImage == null
                  ? Icon(
                      Icons.person_rounded,
                      size: 40,
                      color: AppColors.textSecondary.withOpacity(0.4),
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldWithLabel(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_label(label), const SizedBox(height: 8), field],
    );
  }

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.inter(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                isLogin ? 'Login' : 'Sign Up',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _divider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: AppColors.textSecondary.withOpacity(0.2)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: AppColors.textSecondary.withOpacity(0.2)),
        ),
      ],
    );
  }

  Widget _googleButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onGoogleSignIn,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
        ),
        icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
        label: Text(
          'Continue with Google',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _terms() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          TextSpan(
            text: 'Terms',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const TextSpan(text: ' and\n'),
          TextSpan(
            text: 'Privacy Policy',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}
