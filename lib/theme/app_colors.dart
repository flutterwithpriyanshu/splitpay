import 'package:flutter/material.dart';
import 'package:splitpay/main.dart'; // for themeModeNotifier
import 'dart:ui' as ui;

class AppColors {
  static bool get _isDark {
    if (themeModeNotifier.value == ThemeMode.dark) return true;
    if (themeModeNotifier.value == ThemeMode.light) return false;
    return ui.PlatformDispatcher.instance.platformBrightness == Brightness.dark;
  }

  // Brand colors — stay the same in both modes
  static Color get primary => const Color(0xFF6C63FF);
  static Color get secondary => const Color(0xFF8B7CFF);
  static Color get success => const Color(0xFF22C55E);
  static Color get error => const Color(0xFFEF4444);
  static Color get warning => const Color(0xFFF59E0B);

  // These flip based on mode
  static Color get background =>
      _isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD);
  static Color get surface =>
      _isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
  static Color get textPrimary =>
      _isDark ? const Color(0xFFF3F4F6) : const Color(0xFF1F2937);
  static Color get textSecondary =>
      _isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  static Color get divider =>
      _isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB);
}
