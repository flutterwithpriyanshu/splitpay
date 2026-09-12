import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:splitpay/firebase/firebase_options.dart';
import 'package:splitpay/theme/theme.dart';
import 'package:splitpay/theme/theme_notifier.dart';

import 'package:splitpay/screens/splash_screen.dart';
import 'package:splitpay/screens/intro_screen.dart';
import 'package:splitpay/screens/auth_screen.dart';
import 'package:splitpay/screens/main_shell.dart';
import 'package:splitpay/screens/complete_profile_screen.dart';
import 'package:splitpay/core/onboarding_prefs.dart';
import 'package:splitpay/core/profile_prefs.dart';
import 'package:splitpay/services/local_notification_service.dart';
import 'package:splitpay/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleSignIn.instance.initialize(
    serverClientId:
        '183970765607-e598234ffcbgq4ca0ocfvre4f3ou3e5a.apps.googleusercontent.com',
  );
  await LocalNotificationService.init();
  await FcmService.init();
  runApp(const SplitPayApp());
}

class SplitPayApp extends StatefulWidget {
  const SplitPayApp({super.key});

  @override
  State<SplitPayApp> createState() => _SplitPayAppState();
}

class _SplitPayAppState extends State<SplitPayApp> {
  bool _booting = true;
  bool _seenIntro = false;
  final Set<String> _justCompletedProfileUids = {};

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // Keep the splash on screen for a beat while we check whether the
    // intro has ever been shown on this device. This is a plain state
    // flag now (not a Navigator push) so it can never swallow the
    // auth-state StreamBuilder below.
    final results = await Future.wait([
      OnboardingPrefs.hasSeenIntro(),
      Future.delayed(const Duration(milliseconds: 2000)),
    ]);
    if (!mounted) return;
    setState(() {
      _seenIntro = results[0] as bool;
      _booting = false;
    });
  }

  void _onIntroDone() {
    setState(() => _seenIntro = true);
  }

  void _onProfileDone(String uid) {
    setState(() => _justCompletedProfileUids.add(uid));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'SplitPay',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: _booting
              ? const SplashScreen()
              : !_seenIntro
              ? IntroScreen(onDone: _onIntroDone)
              : StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    // Only show the animated splash while Firebase is
                    // still checking for a cached session.
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SplashScreen();
                    }
                    if (snapshot.hasData) {
                      final user = snapshot.data!;
                      if (_justCompletedProfileUids.contains(user.uid)) {
                        return const MainShell();
                      }
                      // Local cache first — instant, no Firestore round
                      // trip, so a returning user never flickers through
                      // complete-profile again after their first launch.
                      return FutureBuilder<bool>(
                        future: ProfilePrefs.isProfileComplete(user.uid),
                        builder: (context, cachedSnap) {
                          if (cachedSnap.connectionState ==
                              ConnectionState.waiting) {
                            return const SplashScreen();
                          }
                          if (cachedSnap.data == true) {
                            return const MainShell();
                          }
                          // authStateChanges fires the moment sign-in succeeds —
                          // before we know whether a users/{uid} doc exists yet.
                          // Check it here too, or brand-new users race straight
                          // past complete-profile into MainShell with nothing saved.
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .get(),
                            builder: (context, profileSnap) {
                              if (profileSnap.connectionState ==
                                  ConnectionState.waiting) {
                                return const SplashScreen();
                              }
                              final profile =
                                  profileSnap.data?.data()
                                      as Map<String, dynamic>?;
                              final hasCompleteProfile =
                                  profileSnap.hasData &&
                                  profileSnap.data!.exists &&
                                  (profile?['fullName'] as String?)
                                          ?.trim()
                                          .isNotEmpty ==
                                      true &&
                                  (profile?['phoneNumber'] as String?)
                                          ?.trim()
                                          .isNotEmpty ==
                                      true &&
                                  (profile?['upiId'] as String?)
                                          ?.trim()
                                          .isNotEmpty ==
                                      true;
                              if (hasCompleteProfile) {
                                // Older accounts that completed their
                                // profile before this local cache existed
                                // — backfill it so next launch is instant.
                                ProfilePrefs.setProfileComplete(user.uid);
                                return const MainShell();
                              }
                              return CompleteProfileScreen(
                                uid: user.uid,
                                name: user.displayName ?? '',
                                email: user.email ?? '',
                                phone: user.phoneNumber,
                                onDone: () => _onProfileDone(user.uid),
                              );
                            },
                          );
                        },
                      );
                    }
                    // Signed out (including right after logout) — go
                    // straight to sign-in.
                    return const AuthScreen();
                  },
                ),
        );
      },
    );
  }
}
