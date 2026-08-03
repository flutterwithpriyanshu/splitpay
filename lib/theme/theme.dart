import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:splitpay/theme/app_colors.dart';

/// The [AppTheme] defines light and dark themes for the app.
///
/// Theme setup for FlexColorScheme package v8.
abstract final class AppTheme {
  // ---- SplitPay brand colors ----

  // The FlexColorScheme defined light mode ThemeData.
  static ThemeData light = FlexThemeData.light(
    // Using SplitPay's custom brand colors instead of a built-in FlexScheme.
    colors: FlexSchemeColor(
      primary: AppColors.primary,
      primaryContainer: AppColors.secondary,
      secondary: AppColors.secondary,
      secondaryContainer: AppColors.warning,
      tertiary: AppColors.success,
      tertiaryContainer: AppColors.success,
      appBarColor: AppColors.background,
      error: AppColors.error,
    ),
    scaffoldBackground: AppColors.background,
    surface: AppColors.surface,
    // Component theme configurations for light mode.
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      tintedDisabledControls: true,
      useM2StyleDividerInM3: true,
      textButtonRadius: 8.0,
      filledButtonRadius: 10.0,
      outlinedButtonRadius: 7.0,
      toggleButtonsRadius: 11.0,
      segmentedButtonRadius: 12.0,
      segmentedButtonBorderWidth: 1.0,
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      fabUseShape: true,
      fabAlwaysCircular: true,
      chipBlendColors: true,
      chipRadius: 12.0,
      popupMenuSchemeColor: SchemeColor.primaryContainer,
      alignedDropdown: true,
      navigationRailUseIndicator: true,
    ),
    // Direct ThemeData properties.
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );

  // The FlexColorScheme defined dark mode ThemeData.
  static ThemeData dark = FlexThemeData.dark(
    colors: FlexSchemeColor(
      primary: AppColors.primary,
      primaryContainer: AppColors.secondary,
      secondary: AppColors.secondary,
      secondaryContainer: AppColors.warning,
      tertiary: AppColors.success,
      tertiaryContainer: AppColors.success,

      error: AppColors.error,
    ),
    // Component theme configurations for dark mode.
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      tintedDisabledControls: true,
      blendOnColors: true,
      useM2StyleDividerInM3: true,
      textButtonRadius: 8.0,
      filledButtonRadius: 10.0,
      outlinedButtonRadius: 7.0,
      toggleButtonsRadius: 11.0,
      segmentedButtonRadius: 12.0,
      segmentedButtonBorderWidth: 1.0,
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      fabUseShape: true,
      fabAlwaysCircular: true,
      chipBlendColors: true,
      chipRadius: 12.0,
      popupMenuSchemeColor: SchemeColor.primaryContainer,
      alignedDropdown: true,
      navigationRailUseIndicator: true,
    ),
    // Direct ThemeData properties.
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );
}
