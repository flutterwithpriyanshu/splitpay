import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:splitpay/firebase/firebase_options.dart';
import 'package:splitpay/theme/theme.dart';
import 'package:splitpay/theme/theme_notifier.dart';

import 'package:splitpay/screens/splash_screen.dart';
import 'package:splitpay/screens/auth_screen.dart';
import 'package:splitpay/screens/main_shell.dart';
import 'package:splitpay/screens/complete_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleSignIn.instance.initialize(
    serverClientId:
        '183970765607-e598234ffcbgq4ca0ocfvre4f3ou3e5a.apps.googleusercontent.com',
  );
  runApp(const SplitPayApp());
}

class SplitPayApp extends StatelessWidget {
  const SplitPayApp({super.key});

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
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              // Only show the animated splash on cold start, while
              // Firebase is still checking for a cached session.
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }
              if (snapshot.hasData) {
                final user = snapshot.data!;
                // authStateChanges fires the moment sign-in succeeds —
                // before we know whether a users/{uid} doc exists yet.
                // Check it here too, or brand-new Google users race
                // straight past complete-profile into MainShell with
                // no phone/UPI saved.
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
                    if (profileSnap.hasData && profileSnap.data!.exists) {
                      return const MainShell();
                    }
                    return CompleteProfileScreen(
                      uid: user.uid,
                      name: user.displayName ?? '',
                      email: user.email ?? '',
                    );
                  },
                );
              }
              // Signed out (including right after logout) — go straight
              // to sign-in, not back through Splash → Intro.
              return const AuthScreen();
            },
          ),
        );
      },
    );
  }
}
