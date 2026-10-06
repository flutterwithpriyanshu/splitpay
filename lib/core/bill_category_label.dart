import 'package:flutter/material.dart';
import 'package:splitpay/core/bill_category.dart';

/// Label for the category chip. Derived from `billVisual` icon (same
/// title keywords) so label + icon never disagree.
String billCategoryLabel(String title) {
  final icon = billVisual(title).icon;
  if (icon == Icons.restaurant_rounded) return 'FOOD & DINING';
  if (icon == Icons.bolt_rounded) return 'UTILITIES';
  if (icon == Icons.local_gas_station_rounded) return 'FUEL & TRANSPORT';
  if (icon == Icons.apartment_rounded) return 'HOME & RENT';
  if (icon == Icons.flight_takeoff_rounded) return 'TRAVEL';
  if (icon == Icons.movie_rounded) return 'ENTERTAINMENT';
  if (icon == Icons.shopping_basket_rounded) return 'GROCERIES';
  return 'GENERAL';
}
