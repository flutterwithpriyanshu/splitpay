import 'package:flutter/material.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

/// Light/dark [ThemeData] built from DESIGN.md tokens.
/// Uses [AppPalette] directly (not [AppColors]) so each theme is correct
/// regardless of the current mode when the static field is first built.
abstract final class AppTheme {
  static final ThemeData light = _build(AppPalette.light);
  static final ThemeData dark = _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    final isDark = p.isDark;
    final text = AppText.textTheme(p.textPrimary, p.textSecondary);
    final onSurfaceTint = Color.alphaBlend(
      p.success.withValues(alpha: 0.14),
      p.surface,
    );
    final dangerTint = Color.alphaBlend(
      p.danger.withValues(alpha: 0.14),
      p.surface,
    );

    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: isDark ? const Color(0xFF170065) : Colors.white,
      primaryContainer: p.primaryContainer,
      onPrimaryContainer: p.onPrimaryContainer,
      secondary: p.success,
      onSecondary: isDark ? const Color(0xFF002113) : Colors.white,
      secondaryContainer: onSurfaceTint,
      onSecondaryContainer: p.success,
      tertiary: p.danger,
      onTertiary: Colors.white,
      tertiaryContainer: dangerTint,
      onTertiaryContainer: p.danger,
      error: p.danger,
      onError: Colors.white,
      errorContainer: dangerTint,
      onErrorContainer: p.danger,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      surfaceTint: Colors.transparent, // no M3 tint overlay
      surfaceContainerLowest: p.surface,
      surfaceContainerLow: p.background,
      surfaceContainer: p.surfaceRaised,
      surfaceContainerHigh: p.surfaceRaised,
      surfaceContainerHighest: p.surfaceRaised,
      outline: p.textSecondary,
      outlineVariant: p.divider,
      shadow: Colors.black,
      scrim: const Color(0xFF0F1226),
      inverseSurface: p.textPrimary,
      onInverseSurface: p.background,
      inversePrimary: AppPalette.dark.primary,
    );

    RoundedRectangleBorder rr(double r) =>
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));

    OutlineInputBorder inputBorder(Color c, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
      borderSide: BorderSide(color: c, width: w),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      textTheme: text,
      primaryTextTheme: text,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppText.headlineSm.copyWith(color: p.textPrimary),
        iconTheme: IconThemeData(color: p.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: p.divider.withValues(alpha: 0.7)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(64, 56),
          shape: rr(AppRadius.control),
          textStyle: AppText.labelLg,
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(64, 56),
          shape: rr(AppRadius.control),
          textStyle: AppText.labelLg,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: p.surfaceRaised,
          foregroundColor: p.textPrimary,
          minimumSize: const Size(64, 56),
          side: BorderSide.none,
          shape: rr(AppRadius.control),
          textStyle: AppText.labelLg,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          shape: rr(AppRadius.control),
          textStyle: AppText.labelMd,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        hintStyle: AppText.bodyLg.copyWith(color: p.textSecondary),
        labelStyle: AppText.bodyMd.copyWith(color: p.textSecondary),
        border: inputBorder(Colors.transparent, 1),
        enabledBorder: inputBorder(Colors.transparent, 1),
        disabledBorder: inputBorder(Colors.transparent, 1),
        focusedBorder: inputBorder(p.primary, 1.5),
        errorBorder: inputBorder(p.danger, 1),
        focusedErrorBorder: inputBorder(p.danger, 1.5),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
        sizeConstraints: const BoxConstraints.tightFor(width: 60, height: 60),
        iconSize: 28,
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: p.surfaceRaised,
        selectedColor: p.tint(p.primary),
        labelStyle: AppText.labelMd.copyWith(color: p.textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: rr(6),
        side: BorderSide(color: p.textSecondary, width: 1.5),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        fillColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? p.primary : Colors.transparent,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(rr(AppRadius.inner)),
          side: const WidgetStatePropertyAll(BorderSide.none),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) =>
                s.contains(WidgetState.selected) ? p.surface : p.surfaceRaised,
          ),
          foregroundColor: WidgetStatePropertyAll(p.textPrimary),
          textStyle: WidgetStatePropertyAll(AppText.labelMd),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: const Color(0xFF0F1226).withValues(alpha: 0.60),
        showDragHandle: true,
        dragHandleColor: p.divider,
        dragHandleSize: const Size(40, 4),
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: rr(AppRadius.card),
        titleTextStyle: AppText.headlineSm.copyWith(color: p.textPrimary),
        contentTextStyle: AppText.bodyMd.copyWith(color: p.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: AppText.bodyMd.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: rr(AppRadius.control),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          side: BorderSide(color: p.divider),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.textPrimary,
      ),
    );
  }
}
