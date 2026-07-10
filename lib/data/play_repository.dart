import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_play.dart';

/// CXP.15 — local play persistence. This is intentionally the smallest
/// possible durable store: `shared_preferences` (works identically across
/// all six Flutter targets scaffolded so far, including web, without
/// per-platform setup) holding one JSON-encoded list under a single key.
///
/// This is NOT the domain model's `Statistics`-style versioned event
/// layer, and it is explicitly not meant to be — see
/// `docs/architecture/domain-model.md`'s "Versioned, not overwritten"
/// discipline for plays. A real implementation needs play version
/// history, multi-tenant scoping, and sync; this prototype has none of
/// that and should not be mistaken for it. The `PlayRepository`
/// interface exists specifically so a real backend can replace
/// `SharedPreferencesPlayRepository` later without touching UI code.
abstract class PlayRepository {
  Future<List<SavedPlay>> loadAll();
  Future<void> save(SavedPlay play);
  Future<void> delete(String id);
}

class SharedPreferencesPlayRepository implements PlayRepository {
  static const _storageKey = 'cxp.saved_plays.v1';

  @override
  Future<List<SavedPlay>> loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return [for (final entry in decoded) SavedPlay.fromJson(entry as Map<String, dynamic>)];
  }

  @override
  Future<void> save(SavedPlay play) async {
    final preferences = await SharedPreferences.getInstance();
    final plays = await loadAll();
    final withoutExisting = plays.where((p) => p.id != play.id).toList();
    final updated = [...withoutExisting, play];
    await preferences.setString(_storageKey, jsonEncode([for (final p in updated) p.toJson()]));
  }

  @override
  Future<void> delete(String id) async {
    final preferences = await SharedPreferences.getInstance();
    final plays = await loadAll();
    final updated = plays.where((p) => p.id != id).toList();
    await preferences.setString(_storageKey, jsonEncode([for (final p in updated) p.toJson()]));
  }
}
