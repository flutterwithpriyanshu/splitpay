import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:splitpay/core/custom_category.dart';

/// Local-only storage (`<documents>/categories_<uid>.json`, one per user):
/// - custom categories the user created
/// - which category each bill uses (billId -> categoryId)
/// - custom emojis the user typed in (shown first in the picker)
/// Nothing is sent to Firestore.
class CustomCategoryStore extends ChangeNotifier {
  CustomCategoryStore._();
  static final CustomCategoryStore instance = CustomCategoryStore._();

  String? _uid;
  File? _file;
  bool _loaded = false;
  Future<void> _saving = Future<void>.value();

  final List<BillCategoryOption> _custom = [];
  final Map<String, String> _byBill = {};
  final List<String> _emojis = [];

  bool get loaded => _loaded;
  List<BillCategoryOption> get custom => List.unmodifiable(_custom);
  List<String> get customEmojis => List.unmodifiable(_emojis);

  /// Built-ins first, then user made.
  List<BillCategoryOption> get all => [...builtInCategories, ..._custom];

  BillCategoryOption? byId(String? id) {
    if (id == null) return null;
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  String? categoryIdForBill(String billId) => _byBill[billId];

  Future<void> load(String uid) async {
    if (uid.isEmpty || (_uid == uid && _loaded)) return;
    _uid = uid;
    _loaded = false;
    _custom.clear();
    _byBill.clear();
    _emojis.clear();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/categories_$uid.json');
      _file = f;
      if (await f.exists()) {
        final raw = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        for (final e in (raw['categories'] as List? ?? const [])) {
          _custom.add(BillCategoryOption.fromJson(e as Map<String, dynamic>));
        }
        (raw['bills'] as Map? ?? const {}).forEach(
          (k, v) => _byBill[k as String] = v as String,
        );
        for (final e in (raw['emojis'] as List? ?? const [])) {
          _emojis.add(e as String);
        }
      }
    } catch (e) {
      debugPrint('CustomCategoryStore.load failed: $e');
    }
    if (_uid != uid) return;
    _loaded = true;
    notifyListeners();
  }

  Future<void> addCategory(BillCategoryOption c) async {
    _custom.add(c);
    notifyListeners();
    await _save();
  }

  Future<void> deleteCategory(String id) async {
    _custom.removeWhere((c) => c.id == id);
    _byBill.removeWhere((_, v) => v == id);
    notifyListeners();
    await _save();
  }

  Future<void> setBillCategory(String billId, String? categoryId) async {
    if (categoryId == null) {
      _byBill.remove(billId);
    } else {
      _byBill[billId] = categoryId;
    }
    notifyListeners();
    await _save();
  }

  Future<void> addEmoji(String emoji) async {
    _emojis.remove(emoji);
    _emojis.insert(0, emoji);
    if (_emojis.length > 40) _emojis.removeRange(40, _emojis.length);
    notifyListeners();
    await _save();
  }

  Future<void> _save() {
    final f = _file;
    if (f == null) return Future<void>.value();
    final data = jsonEncode({
      'categories': _custom.map((c) => c.toJson()).toList(),
      'bills': _byBill,
      'emojis': _emojis,
    });
    // Chain writes so two quick saves never interleave.
    _saving = _saving.then((_) async {
      try {
        await f.writeAsString(data, flush: true);
      } catch (e) {
        debugPrint('CustomCategoryStore.save failed: $e');
      }
    });
    return _saving;
  }
}
