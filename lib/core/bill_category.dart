import 'package:flutter/material.dart';
import 'package:splitpay/theme/app_colors.dart';

class BillVisual {
  final IconData icon;
  final Color color;
  const BillVisual(this.icon, this.color);

  Color get bg =>
      color.withValues(alpha: AppColors.palette.isDark ? 0.18 : 0.12);
}

/// Picks an icon + tint from the bill title. Cosmetic only.
BillVisual billVisual(String title) {
  final t = title.toLowerCase();
  bool has(List<String> k) => k.any(t.contains);

  if (has(['power', 'electric', 'bescom', 'wifi', 'internet'])) {
    return BillVisual(Icons.bolt_rounded, AppColors.warning);
  }
  if (has(['petrol', 'fuel', 'toll', 'diesel', 'cab', 'uber', 'taxi'])) {
    return BillVisual(Icons.local_gas_station_rounded, AppColors.primary);
  }
  if (has(['rent', 'flat', 'house', 'maintenance'])) {
    return BillVisual(Icons.apartment_rounded, AppColors.primary);
  }
  if (has([
    'dinner',
    'lunch',
    'breakfast',
    'food',
    'pizza',
    'cafe',
    'coffee',
    'restaurant',
    'swiggy',
    'zomato',
  ])) {
    return BillVisual(Icons.restaurant_rounded, AppColors.primary);
  }
  if (has(['trip', 'hotel', 'flight', 'train', 'travel', 'stay'])) {
    return BillVisual(Icons.flight_takeoff_rounded, AppColors.primary);
  }
  if (has(['movie', 'game', 'party'])) {
    return BillVisual(Icons.movie_rounded, AppColors.primary);
  }
  if (has(['grocer', 'mart', 'shop', 'vegetable'])) {
    return BillVisual(Icons.shopping_basket_rounded, AppColors.primary);
  }
  return BillVisual(Icons.receipt_long_rounded, AppColors.primary);
}
