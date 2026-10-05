import 'package:flutter/material.dart';
import 'package:splitpay/theme/app_colors.dart';

/// Inline styles used inside a notification body.
TextSpan nameSpan(String t) => TextSpan(
  text: t,
  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
);

TextSpan moneySpan(String t, Color c) =>
    TextSpan(text: t, style: TextStyle(fontWeight: FontWeight.w800, color: c));

TextSpan quotedSpan(String t) => TextSpan(
  text: "'$t'",
  style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textPrimary),
);

TextSpan groupSpan(String t) => TextSpan(
  text: t,
  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
);
