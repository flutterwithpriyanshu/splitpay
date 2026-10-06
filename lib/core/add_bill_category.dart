import 'package:flutter/material.dart';

class AddBillCategory {
  const AddBillCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

/// Built-in chips. Local only, not saved on the bill.
const kAddBillCategories = <AddBillCategory>[
  AddBillCategory('Food', Icons.restaurant_rounded, Color(0xFFF59E0B)),
  AddBillCategory('Rent', Icons.apartment_rounded, Color(0xFF5B3DF5)),
  AddBillCategory('Travel', Icons.flight_takeoff_rounded, Color(0xFF0EA5E9)),
  AddBillCategory('Fuel', Icons.local_gas_station_rounded, Color(0xFFF43F5E)),
  AddBillCategory('Fun', Icons.movie_rounded, Color(0xFF8E5BFF)),
  AddBillCategory('Shopping', Icons.shopping_basket_rounded, Color(0xFF12B981)),
  AddBillCategory('Bills', Icons.bolt_rounded, Color(0xFFF59E0B)),
];
