import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global currency symbol — every ₹/$/€/£ amount in the app reads this
/// instead of hardcoding a symbol, so flipping it in Settings changes the
/// symbol everywhere at once (same idea as [themeModeNotifier] for theme).
final ValueNotifier<String> currencySymbolNotifier = ValueNotifier('₹');

const kSupportedCurrencies = ['INR (₹)', 'USD (\$)', 'EUR (€)', 'GBP (£)'];

/// Pulls the bare symbol out of a picker label like 'USD (\$)' -> '\$'.
String symbolFromLabel(String label) {
  final match = RegExp(r'\(([^)]+)\)').firstMatch(label);
  return match?.group(1) ?? '₹';
}

/// Convenience getter so call sites can write
/// '${AppCurrency.symbol}${amount}' instead of importing the notifier
/// directly everywhere.
class AppCurrency {
  static String get symbol => currencySymbolNotifier.value;
}

class CurrencyPrefs {
  static const _key = 'currency_label';

  static Future<String> getLabel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? 'INR (₹)';
  }

  static Future<void> setLabel(String label) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, label);
    currencySymbolNotifier.value = symbolFromLabel(label);
  }

  /// Call once at app boot to restore the saved symbol before first paint.
  static Future<void> load() async {
    currencySymbolNotifier.value = symbolFromLabel(await getLabel());
  }
}