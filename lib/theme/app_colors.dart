import 'package:flutter/material.dart';
import 'package:splitpay/theme/theme_notifier.dart'; // for themeModeNotifier
import 'dart:ui' as ui;

/// Raw design tokens from DESIGN.md ("Electric Modern Fintech").
/// Const, mode-independent: ThemeData reads these directly.
@immutable
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.gradientStart,
    required this.gradientEnd,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.success,
    required this.danger,
    required this.warning,
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
  });

  final Brightness brightness;
  final Color primary;
  final Color gradientStart;
  final Color gradientEnd;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color success;
  final Color danger;
  final Color warning;
  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;

  bool get isDark => brightness == Brightness.dark;

  /// Tint surface: 10% light, 14% dark (DESIGN.md "Tint Surface").
  Color tint(Color c) => c.withValues(alpha: isDark ? 0.14 : 0.10);

  static const light = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFF5B3DF5),
    gradientStart: Color(0xFF5B3DF5),
    gradientEnd: Color(0xFF8E5BFF),
    primaryContainer: Color(0xFFE4DFFF),
    onPrimaryContainer: Color(0xFF170065),
    success: Color(0xFF12B981),
    danger: Color(0xFFF43F5E),
    warning: Color(0xFFF59E0B),
    background: Color(0xFFF5F6FB),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFEEF0F8),
    textPrimary: Color(0xFF0F1226),
    textSecondary: Color(0xFF6B7194),
    divider: Color(0xFFE3E6F2),
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF8B7CFF),
    gradientStart: Color(0xFF6E56FF),
    gradientEnd: Color(0xFFA78BFF),
    primaryContainer: Color(0xFF2B2560),
    onPrimaryContainer: Color(0xFFE0DAFF),
    success: Color(0xFF34D399),
    danger: Color(0xFFFB7185),
    warning: Color(0xFFFBBF24),
    background: Color(0xFF0B0D17),
    surface: Color(0xFF151826),
    surfaceRaised: Color(0xFF1E2235),
    textPrimary: Color(0xFFF3F4FA),
    textSecondary: Color(0xFF9AA0C3),
    divider: Color(0xFF262B45),
  );
}

/// Runtime color access used across screens. Names kept from the old
/// AppColors so every existing screen keeps compiling; values now follow
/// DESIGN.md and flip with light/dark mode.
class AppColors {
  static bool get _isDark {
    if (themeModeNotifier.value == ThemeMode.dark) return true;
    if (themeModeNotifier.value == ThemeMode.light) return false;
    return ui.PlatformDispatcher.instance.platformBrightness == Brightness.dark;
  }

  static AppPalette get palette => _isDark ? AppPalette.dark : AppPalette.light;

  // ---- Existing names (unchanged API) ----
  static Color get primary => palette.primary;
  static Color get secondary => palette.gradientEnd;
  static Color get success => palette.success;
  static Color get error => palette.danger;
  static Color get warning => palette.warning;
  static Color get background => palette.background;
  static Color get surface => palette.surface;
  static Color get textPrimary => palette.textPrimary;
  static Color get textSecondary => palette.textSecondary;
  static Color get divider => palette.divider;

  // ---- New tokens ----
  static Color get surfaceRaised => palette.surfaceRaised;
  static Color get successTint => palette.tint(palette.success);
  static Color get dangerTint => palette.tint(palette.danger);
  static Color get warningTint => palette.tint(palette.warning);
  static Color get primaryTint => palette.tint(palette.primary);

  /// Reserved for FAB, final payment banners, primary settle-up CTA.
  static LinearGradient get primaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [palette.gradientStart, palette.gradientEnd],
  );
}

/// Corner radii (DESIGN.md "Shapes").
abstract final class AppRadius {
  static const double card = 24;
  static const double control = 16; // buttons + text inputs
  static const double inner = 12; // segmented active tab
  static const double sheet = 32;
  static const double pill = 999;
}

/// Spacing (8pt grid, 4px micro gaps).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Floating dock: 64 tall + 20 above safe area.
  static const double dockHeight = 64;
  static const double dockBottomGap = 20;
}

/// Elevation (DESIGN.md "Elevation & Depth"). Dark mode = no shadow.
abstract final class AppShadows {
  static bool get _dark => AppColors.palette.isDark;

  static List<BoxShadow> get card => _dark
      ? const []
      : [
          BoxShadow(
            color: const Color(0xFF5B3DF5).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ];

  static List<BoxShadow> get raised => _dark
      ? const []
      : [
          BoxShadow(
            color: const Color(0xFF5B3DF5).withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ];

  static List<BoxShadow> get dock => [
    BoxShadow(
      color: _dark
          ? Colors.black.withValues(alpha: 0.40)
          : const Color(0xFF0F1226).withValues(alpha: 0.10),
      blurRadius: 36,
      offset: const Offset(0, 16),
    ),
  ];

  static List<BoxShadow> get fab => [
    BoxShadow(
      color: const Color(0xFF5B3DF5).withValues(alpha: 0.35),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];
}
