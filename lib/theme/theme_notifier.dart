import 'package:flutter/material.dart';

// Global theme notifier — Settings screen flips this directly.
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.light,
);
