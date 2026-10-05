import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tabular + lining figures. Required on every ₹ amount, balance and
/// split percentage (DESIGN.md "Numerical Tabular OpenType Enforcement").
extension TabularFigures on TextStyle {
  TextStyle get tabular => copyWith(
    fontFeatures: const [
      FontFeature.tabularFigures(),
      FontFeature.liningFigures(),
    ],
  );
}

/// Plus Jakarta Sans type scale from DESIGN.md.
abstract final class AppText {
  static TextStyle _s(double size, FontWeight w, double lh, double em) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: w,
        height: lh / size,
        letterSpacing: em * size,
      );

  static TextStyle get displayLg => _s(40, FontWeight.w800, 48, -0.03);
  static TextStyle get displayLgMobile => _s(32, FontWeight.w800, 40, -0.025);
  static TextStyle get headlineLg => _s(28, FontWeight.w700, 36, -0.02);
  static TextStyle get headlineMd => _s(22, FontWeight.w700, 30, -0.015);
  static TextStyle get headlineSm => _s(18, FontWeight.w600, 26, -0.01);
  static TextStyle get bodyLg => _s(16, FontWeight.w400, 24, -0.005);
  static TextStyle get bodyMd => _s(14, FontWeight.w400, 20, 0);
  static TextStyle get bodySm => _s(12, FontWeight.w400, 16, 0.01);
  static TextStyle get labelLg => _s(16, FontWeight.w600, 20, 0);
  static TextStyle get labelMd => _s(13, FontWeight.w600, 18, 0.01);
  static TextStyle get labelSm => _s(11, FontWeight.w700, 14, 0.03);

  /// Home net balance, single-screen bill amount.
  static TextStyle get currencyDisplay =>
      _s(36, FontWeight.w800, 44, -0.02).tabular;
  static TextStyle get currencyMd => _s(18, FontWeight.w700, 24, -0.01).tabular;

  static TextTheme textTheme(Color primary, Color secondary) {
    return TextTheme(
          displayLarge: displayLg,
          displayMedium: displayLgMobile,
          displaySmall: headlineLg,
          headlineLarge: headlineLg,
          headlineMedium: headlineMd,
          headlineSmall: headlineSm,
          titleLarge: headlineSm,
          titleMedium: labelLg,
          titleSmall: labelMd,
          bodyLarge: bodyLg,
          bodyMedium: bodyMd,
          bodySmall: bodySm,
          labelLarge: labelLg,
          labelMedium: labelMd,
          labelSmall: labelSm,
        )
        .apply(bodyColor: primary, displayColor: primary)
        .copyWith(bodySmall: bodySm.copyWith(color: secondary));
  }
}
