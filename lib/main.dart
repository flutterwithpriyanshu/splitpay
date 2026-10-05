import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
import 'package:splitpay/core/app_currency.dart';
import 'package:splitpay/services/local_notification_service.dart';
import 'package:splitpay/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('es'),
        Locale('fr'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const SplitPayApp(),
    ),
  );
}

class SplitPayApp extends StatefulWidget {
  const SplitPayApp({super.key});

  @override
  State<SplitPayApp> createState() => _SplitPayAppState();
}

class _SplitPayAppState extends State<SplitPayApp> {
  bool _booting = true;
  bool _seenIntro = false;
  Object? _startupError;
  final Set<String> _justCompletedProfileUids = {};

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '183970765607-e598234ffcbgq4ca0ocfvre4f3ou3e5a.apps.googleusercontent.com',
      );
      await LocalNotificationService.init();
      await FcmService.init();
      await CurrencyPrefs.load();
      _seenIntro = await OnboardingPrefs.hasSeenIntro();
    } catch (error, stackTrace) {
      debugPrint('App startup failed: $error\n$stackTrace');
      _startupError = error;
    }
    if (!mounted) return;
    setState(() {
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
    return ValueListenableBuilder<String>(
      valueListenable: currencySymbolNotifier,
      builder: (context, _, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeModeNotifier,
          builder: (context, mode, _) {
            return MaterialApp(
              title: 'SplitPay',
              debugShowCheckedModeBanner: false,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: mode,
              home: _startupError != null
                  ? _StartupError(error: _startupError!)
                  : _booting
                  ? const SplashScreen()
                  : !_seenIntro
                  ? IntroScreen(onDone: _onIntroDone)
                  : StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.authStateChanges(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SplashScreen();
                        }
                        if (snapshot.hasData) {
                          final user = snapshot.data!;
                          if (_justCompletedProfileUids.contains(user.uid)) {
                            return const MainShell();
                          }

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
      },
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Unable to start the app: $error'),
        ),
      ),
    );
  }
}
