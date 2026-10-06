import 'dart:math' as m;
import 'package:flutter/widgets.dart';

enum SplitMethod { equal, custom }

/// 400 -> "400", 33.333 -> "33.33".
String plainAmount(double v) {
  final whole = (v - v.roundToDouble()).abs() < 0.005;
  return whole ? v.round().toString() : v.toStringAsFixed(2);
}

/// Custom-split numbers for Add Bill. "You" share = typed value if any,
/// else whatever friends leave (old behavior).
class SplitMath {
  SplitMath({
    required this.amount,
    required this.friendTexts,
    required this.meText,
  });

  factory SplitMath.fromControllers({
    required double amount,
    required Iterable<String> ids,
    required Map<String, TextEditingController> controllers,
    required TextEditingController me,
  }) => SplitMath(
    amount: amount,
    friendTexts: {for (final id in ids) id: controllers[id]?.text ?? ''},
    meText: me.text,
  );

  final double amount;
  final Map<String, String> friendTexts;
  final String meText;

  double friendValue(String id) =>
      double.tryParse(friendTexts[id]?.trim() ?? '') ?? 0;

  bool needsShare(String id) => friendValue(id) <= 0.005;

  double get friendsSum =>
      friendTexts.keys.fold<double>(0, (a, id) => a + friendValue(id));

  bool get meOverride => meText.trim().isNotEmpty;

  double get meValue => meOverride
      ? (double.tryParse(meText.trim()) ?? 0)
      : m.max(0, amount - friendsSum);

  /// >0 left to assign, <0 over assigned, 0 ok.
  double get left => meOverride
      ? amount - friendsSum - meValue
      : m.min(0, amount - friendsSum);

  /// Money not yet given to anyone typed.
  double get remaining => amount - friendsSum - (meOverride ? meValue : 0);

  int get unassignedFriends =>
      friendTexts.keys.where(needsShare).length;
}
