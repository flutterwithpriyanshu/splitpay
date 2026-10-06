import 'dart:async';

import 'package:flutter/material.dart';
import 'package:splitpay/core/app_navigator.dart';
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
  final Map<String, Future<bool>> _profileCompletionChecks = {};
  final Map<String, Future<DocumentSnapshot<Map<String, dynamic>>>>
  _profileDocumentChecks = {};
  Stream<User?>? _authStateChanges;

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
      _authStateChanges = FirebaseAuth.instance.authStateChanges();
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '183970765607-e598234ffcbgq4ca0ocfvre4f3ou3e5a.apps.googleusercontent.com',
      );
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
    if (_startupError == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_initializeOptionalServices());
      });
    }
  }

  Future<void> _initializeOptionalServices() async {
    try {
      await LocalNotificationService.init();
    } catch (error, stackTrace) {
      debugPrint('Local notifications unavailable: $error\n$stackTrace');
    }

    try {
      await FcmService.init();
    } catch (error, stackTrace) {
      debugPrint('Push notifications unavailable: $error\n$stackTrace');
    }
  }

  Future<bool> _isProfileComplete(String uid) =>
      _profileCompletionChecks.putIfAbsent(
        uid,
        () => ProfilePrefs.isProfileComplete(uid),
      );

  Future<DocumentSnapshot<Map<String, dynamic>>> _loadProfile(String uid) =>
      _profileDocumentChecks.putIfAbsent(
        uid,
        () => FirebaseFirestore.instance.collection('users').doc(uid).get(),
      );

  void _retryProfileLoad(String uid) {
    _profileCompletionChecks.remove(uid);
    _profileDocumentChecks.remove(uid);
    setState(() {});
  }

  void _cacheProfileComplete(String uid) {
    unawaited(
      ProfilePrefs.setProfileComplete(uid).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        debugPrint('Could not cache profile completion: $error\n$stackTrace');
      }),
    );
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
              navigatorKey: appNavigatorKey,
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
                      stream: _authStateChanges,
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
                            future: _isProfileComplete(user.uid),
                            builder: (context, cachedSnap) {
                              if (cachedSnap.connectionState ==
                                  ConnectionState.waiting) {
                                return const SplashScreen();
                              }
                              if (cachedSnap.data == true) {
                                return const MainShell();
                              }

                              return FutureBuilder<
                                DocumentSnapshot<Map<String, dynamic>>
                              >(
                                future: _loadProfile(user.uid),
                                builder: (context, profileSnap) {
                                  if (profileSnap.connectionState ==
                                      ConnectionState.waiting) {
                                    return const SplashScreen();
                                  }
                                  if (profileSnap.hasError) {
                                    return _ProfileLoadError(
                                      error: profileSnap.error!,
                                      onRetry: () =>
                                          _retryProfileLoad(user.uid),
                                    );
                                  }
                                  final profile = profileSnap.data?.data();
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
                                    _cacheProfileComplete(user.uid);
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

class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load your profile. Check your connection.'),
              const SizedBox(height: 12),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
