import 'package:flutter/material.dart';
import 'package:splitpay/core/icon_catalog.dart';

/// Accent tones for the category picker.
class CategoryTone {
  final String name;
  final Color color;
  const CategoryTone(this.name, this.color);
}

const List<CategoryTone> categoryTones = [
  CategoryTone('Electric Indigo', Color(0xFF5B3DF5)),
  CategoryTone('Emerald', Color(0xFF006C49)),
  CategoryTone('Crimson', Color(0xFFC1123E)),
  CategoryTone('Royal Blue', Color(0xFF4212DE)),
  CategoryTone('Forest', Color(0xFF1B7F4C)),
  CategoryTone('Ruby', Color(0xFFBA1A1A)),
  CategoryTone('Slate', Color(0xFF474556)),
];

/// One category shown as a chip. Built-in or user made.
class BillCategoryOption {
  final String id;
  final String name;
  final int colorValue;

  /// Emoji text, or null when an icon is used.
  final String? emoji;

  /// Key into [categoryIcons], or null when emoji is used.
  final String? iconKey;

  /// 'equal' | 'shares' | 'percentage'
  final String defaultSplit;
  final String? groupId;
  final String? groupName;
  final bool capEnabled;
  final double capAmount;
  final bool custom;

  const BillCategoryOption({
    required this.id,
    required this.name,
    required this.colorValue,
    this.emoji,
    this.iconKey,
    this.defaultSplit = 'equal',
    this.groupId,
    this.groupName,
    this.capEnabled = false,
    this.capAmount = 0,
    this.custom = false,
  });

  Color get color => Color(colorValue);

  IconData? get icon => categoryIconByKey(iconKey);

  String get splitLabel => switch (defaultSplit) {
    'shares' => 'By Shares',
    'percentage' => 'Percentage',
    _ => 'Split Equally',
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': colorValue,
    if (emoji != null) 'emoji': emoji,
    if (iconKey != null) 'icon': iconKey,
    'split': defaultSplit,
    if (groupId != null) 'gid': groupId,
    if (groupName != null) 'gn': groupName,
    'cap': capEnabled,
    'capAmt': capAmount,
  };

  factory BillCategoryOption.fromJson(Map<String, dynamic> j) =>
      BillCategoryOption(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        colorValue: (j['color'] as num?)?.toInt() ?? 0xFF5B3DF5,
        emoji: j['emoji'] as String?,
        iconKey: j['icon'] as String?,
        defaultSplit: j['split'] as String? ?? 'equal',
        groupId: j['gid'] as String?,
        groupName: j['gn'] as String?,
        capEnabled: j['cap'] as bool? ?? false,
        capAmount: (j['capAmt'] as num?)?.toDouble() ?? 0,
        custom: true,
      );
}

/// Built-in chips (always shown first).
const List<BillCategoryOption> builtInCategories = [
  BillCategoryOption(id: 'food', name: 'Food', colorValue: 0xFFE8890C, emoji: '🍔'),
  BillCategoryOption(id: 'rent', name: 'Rent', colorValue: 0xFF5B3DF5, emoji: '🏠'),
  BillCategoryOption(id: 'travel', name: 'Travel', colorValue: 0xFF0B7BD1, emoji: '✈️'),
  BillCategoryOption(id: 'fuel', name: 'Fuel', colorValue: 0xFFC1123E, emoji: '⛽'),
];
