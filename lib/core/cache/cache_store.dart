import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A cached JSON payload plus when it was written.
class CachedEntry {
  CachedEntry({required this.value, required this.cachedAt});

  final dynamic value;
  final DateTime cachedAt;
}

/// Generic disk-backed cache for read-only, offline-first data. Built on
/// `shared_preferences` (already a dependency), storing one raw-JSON blob
/// per key with a timestamp alongside it.
///
/// This deliberately caches the *raw* response JSON, not a parsed model —
/// repositories call [write] with whatever `data` the backend's envelope
/// gave them, before parsing, and re-run the same `fromJson` factory on
/// [read] later. That avoids needing a `toJson()` on every model just to
/// support caching.
///
/// This is a plain, unencrypted local cache for UI resilience (so a
/// screen isn't empty when offline), not secure storage — don't cache
/// anything here that isn't already shown on-screen while online.
class CacheStore {
  CacheStore._();
  static final CacheStore instance = CacheStore._();

  static const _prefix = 'skillpath_cache_v1:';

  Future<void> write(String key, dynamic json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$key',
      jsonEncode({
        'data': json,
        'cachedAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  Future<CachedEntry?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return CachedEntry(
        value: decoded['data'],
        cachedAt:
            DateTime.tryParse(decoded['cachedAt'] as String? ?? '') ??
            DateTime.now(),
      );
    } catch (_) {
      // Corrupt/old-format entry — treat as if there were none.
      return null;
    }
  }

  Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }

  /// Wipes every entry this store owns — called on sign-out so cached
  /// screens don't leak one account's data to the next on a shared device.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
