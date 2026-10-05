import 'package:splitpay/core/app_currency.dart';

String _group(String digits) {
  final b = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) b.write(',');
    b.write(digits[i]);
  }
  return b.toString();
}

/// Absolute amount with currency symbol: "₹1,240" or "₹640.50".
/// Whole numbers show no decimals, anything else shows 2.
String formatMoney(double v) {
  final a = v.abs();
  final whole = (a - a.roundToDouble()).abs() < 0.005;
  final fixed = whole ? a.round().toString() : a.toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = _group(parts[0]);
  final dec = parts.length > 1 ? '.${parts[1]}' : '';
  return '${AppCurrency.symbol}$intPart$dec';
}

/// "+₹650" / "-₹320". Zero gets no sign.
String formatSignedMoney(double v) {
  if (v.abs() < 0.005) return formatMoney(0);
  return '${v > 0 ? '+' : '-'}${formatMoney(v)}';
}
