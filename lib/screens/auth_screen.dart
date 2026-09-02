import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/services/local_image_service.dart';
import 'package:splitpay/screens/main_shell.dart';
import 'package:splitpay/core/phone_utils.dart';
import 'package:splitpay/core/upi_utils.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:splitpay/screens/complete_profile_screen.dart';
import 'package:splitpay/services/onesignal_service.dart';
import 'package:splitpay/screens/auth/widgets/auth_form.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  File? _pickedProfileImage;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  late final Future<void> _googleSignInInitialization;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _upiController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _googleSignInInitialization = _googleSignIn.initialize();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _upiController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    showAppToast(context, message);
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (picked != null) {
      setState(() => _pickedProfileImage = File(picked.path));
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter email and password');
      return;
    }

    if (!isLogin) {
      if (_nameController.text.trim().isEmpty) {
        _showError('Please enter your full name');
        return;
      }
      if (_phoneController.text.trim().isEmpty) {
        _showError('Please enter your phone number');
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
      if (password.length < 6) {
        _showError('Password must be at least 6 characters');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
              'fullName': _nameController.text.trim(),
              'phoneNumber': normalizePhone(_phoneController.text.trim()),
              'upiId': _upiController.text.trim(),
              'email': email,
              'createdAt': FieldValue.serverTimestamp(),
            });

        // Save the profile photo locally, if the user picked one.
        if (_pickedProfileImage != null) {
          await LocalImageService.saveProfileImage(
            credential.user!.uid,
            await _pickedProfileImage!.readAsBytes(),
          );
        }

        await OneSignalService.saveIdForCurrentUser();
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Something went wrong');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await _googleSignInInitialization;

      final googleUser = await _googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user!.uid);

      final snap = await userDoc.get();

      if (!mounted) return;

      if (!snap.exists) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => CompleteProfileScreen(
              uid: userCred.user!.uid,
              name: userCred.user!.displayName ?? '',
              email: userCred.user!.email ?? '',
            ),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      }
    } on GoogleSignInException catch (e) {
      _showError('Google sign-in failed: ${e.description ?? e.code.name}');
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Google sign-in failed');
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: AuthForm(
            isLogin: isLogin,
            isLoading: _isLoading,
            obscurePassword: _obscurePassword,
            pickedProfileImage: _pickedProfileImage,
            nameController: _nameController,
            phoneController: _phoneController,
            upiController: _upiController,
            emailController: _emailController,
            passwordController: _passwordController,
            onModeChanged: (value) => setState(() => isLogin = value),
            onPickProfileImage: _pickProfileImage,
            onTogglePasswordVisibility: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            onSubmit: _submit,
            onGoogleSignIn: _signInWithGoogle,
          ),
        ),
      ),
    );
  }
}
