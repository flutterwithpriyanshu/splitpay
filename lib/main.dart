import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitpay/firebase/firebase_options.dart';
import 'package:splitpay/theme/theme.dart';

import 'package:splitpay/screens/splash_screen.dart';
import 'package:splitpay/screens/main_shell.dart';

// Global theme notifier — Settings screen flips this directly.
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.light,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }
              if (snapshot.hasData) {
                return const MainShell();
              }
              return const SplashScreen();
            },
          ),
        );
      },
    );
  }
}
