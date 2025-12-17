import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String _cacheBox = 'app_cache';
  static const Duration _defaultTTL = Duration(hours: 1);

  Box? _box;

  Future<void> initialize() async {
    _box = await Hive.openBox(_cacheBox);
  }

  Future<void> set<T>(String key, T value, {Duration? ttl}) async {
    if (_box == null) await initialize();
    
    final expiry = DateTime.now().add(ttl ?? _defaultTTL);
    await _box!.put(key, {
      'value': value,
      'expiry': expiry.toIso8601String(),
    });
  }

  T? get<T>(String key) {
    if (_box == null) return null;
    
    final cached = _box!.get(key);
    if (cached == null) return null;

    final data = cached as Map<String, dynamic>;
    final expiry = DateTime.parse(data['expiry'] as String);
    
    if (DateTime.now().isAfter(expiry)) {
      _box!.delete(key);
      return null;
    }

    return data['value'] as T?;
  }

  Future<void> delete(String key) async {
    if (_box == null) await initialize();
    await _box!.delete(key);
  }

  Future<void> clear() async {
    if (_box == null) await initialize();
    await _box!.clear();
  }

  bool has(String key) {
    if (_box == null) return false;
    final cached = _box!.get(key);
    if (cached == null) return false;
    
    final data = cached as Map<String, dynamic>;
    final expiry = DateTime.parse(data['expiry'] as String);
    return !DateTime.now().isAfter(expiry);
  }

  // Cache keys
  static String userKey(String id) => 'user:$id';
  static String consultationsKey(String userId) => 'consultations:$userId';
  static String statsKey(String userId) => 'stats:$userId';
  static String drugsKey([String? search]) => 'drugs:${search ?? 'all'}';
}

