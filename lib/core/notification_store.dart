import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:splitpay/core/app_notification.dart';

/// Keeps every notification in a local JSON file
/// (`<documents>/notifications_<uid>.json`), one file per user.
///
/// - New notifications are saved by [sync] as soon as the feed builds them.
/// - Deleted / cleared ids go in a "dismissed" list so they never come back.
/// - Resolved pending rows (paid request, settled group) are dropped.
class NotificationStore extends ChangeNotifier {
  NotificationStore._();
  static final NotificationStore instance = NotificationStore._();

  static const _maxItems = 200;
  static const _maxDismissed = 600;
  static const _keepDays = 90;

  String? _uid;
  File? _file;
  bool _loaded = false;
  bool _loading = false;
  Future<void> _saving = Future<void>.value();

  final Map<String, AppNotification> _items = {};
  final Set<String> _dismissed = <String>{};

  bool get loaded => _loaded;

  Future<void> load(String uid) async {
    if (uid.isEmpty) return;
    if (_uid == uid && (_loaded || _loading)) return;
    _uid = uid;
    _loaded = false;
    _loading = true;
    _items.clear();
    _dismissed.clear();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/notifications_$uid.json');
      _file = f;
      if (await f.exists()) {
        final raw = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        for (final id in (raw['dismissed'] as List? ?? const [])) {
          _dismissed.add(id as String);
        }
        for (final e in (raw['items'] as List? ?? const [])) {
          final n = AppNotification.fromJson(e as Map<String, dynamic>);
          _items[n.id] = n;
        }
      }
    } catch (e) {
      debugPrint('NotificationStore.load failed: $e');
    }
    if (_uid != uid) return; // user switched while loading
    _loading = false;
    _loaded = true;
    notifyListeners();
  }

  /// Saved rows + freshly built rows, newest first, minus dismissed.
  /// Live objects (bill / friend / group) come from [derived].
  List<AppNotification> visible(
    List<AppNotification> derived, {
    required bool ready,
  }) {
    final derivedIds = {for (final n in derived) n.id};
    final map = <String, AppNotification>{
      for (final e in _items.entries)
        if (!_dismissed.contains(e.key) &&
            !(ready && e.value.isPendingAction && !derivedIds.contains(e.key)))
          e.key: e.value,
    };
    for (final n in derived) {
      if (!_dismissed.contains(n.id)) map[n.id] = n;
    }
    return map.values.toList()..sort((a, b) => b.time.compareTo(a.time));
  }

  /// Save new / changed rows. [ready] = every source stream has answered,
  /// so a pending row missing from [derived] really is resolved.
  Future<void> sync(
    List<AppNotification> derived, {
    required bool ready,
  }) async {
    if (!_loaded) return;
    var changed = false;
    final ids = <String>{};
    for (final n in derived) {
      ids.add(n.id);
      if (n.kind == NotifKind.security || _dismissed.contains(n.id)) continue;
      final clean = n.withoutLive();
      final old = _items[n.id];
      if (old == null ||
          jsonEncode(old.toJson()) != jsonEncode(clean.toJson())) {
        _items[n.id] = clean;
        changed = true;
      }
    }
    if (ready) {
      final gone = [
        for (final n in _items.values)
          if (n.isPendingAction && !ids.contains(n.id)) n.id,
      ];
      for (final id in gone) {
        _items.remove(id);
        changed = true;
      }
    }
    final cutoff = DateTime.now().subtract(const Duration(days: _keepDays));
    final old = [
      for (final n in _items.values)
        if (!n.isPendingAction && n.time.isBefore(cutoff)) n.id,
    ];
    for (final id in old) {
      _items.remove(id);
      changed = true;
    }
    if (_items.length > _maxItems) {
      final sorted = _items.values.toList()
        ..sort((a, b) => b.time.compareTo(a.time));
      for (final n in sorted.skip(_maxItems)) {
        _items.remove(n.id);
      }
      changed = true;
    }
    if (changed) {
      _persist();
      notifyListeners();
    }
  }

  Future<void> delete(String id) => clearIds([id]);

  /// Delete one or many. Ids stay dismissed so the feed can't rebuild them.
  Future<void> clearIds(Iterable<String> ids) async {
    for (final id in ids) {
      _items.remove(id);
      _dismissed.add(id);
    }
    while (_dismissed.length > _maxDismissed) {
      _dismissed.remove(_dismissed.first);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() {
    _saving = _saving.then((_) => _write());
    return _saving;
  }

  Future<void> _write() async {
    final f = _file;
    if (f == null) return;
    try {
      final data = jsonEncode({
        'v': 1,
        'dismissed': _dismissed.toList(),
        'items': [for (final n in _items.values) n.toJson()],
      });
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(data, flush: true);
      await tmp.rename(f.path);
    } catch (e) {
      debugPrint('NotificationStore.save failed: $e');
    }
  }
}
