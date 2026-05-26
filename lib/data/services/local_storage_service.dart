import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';

class LocalStorageService {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(AppConstants.settingsBox);
    await Hive.openBox(AppConstants.cacheBox);
    await Hive.openBox(AppConstants.onboardingBox);
  }

  Box get _settings => Hive.box(AppConstants.settingsBox);
  Box get _onboarding => Hive.box(AppConstants.onboardingBox);
  Box get _cache => Hive.box(AppConstants.cacheBox);

  bool get isOnboardingComplete =>
      _onboarding.get(AppConstants.onboardingCompleteKey, defaultValue: false)
          as bool;

  Future<void> setOnboardingComplete(bool value) async {
    await _onboarding.put(AppConstants.onboardingCompleteKey, value);
  }

  String get themeMode =>
      _settings.get(AppConstants.themeModeKey, defaultValue: 'dark') as String;

  Future<void> setThemeMode(String mode) async {
    await _settings.put(AppConstants.themeModeKey, mode);
  }

  /// TTL remaining until local midnight (for daily horoscope / quota caches).
  static Duration untilMidnight() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    return nextMidnight.difference(now);
  }

  /// Persists [value] as JSON with an absolute expiry timestamp.
  Future<void> setCached(String key, dynamic value, Duration ttl) async {
    try {
      final expiresAt = DateTime.now().add(ttl).millisecondsSinceEpoch;
      final envelope = jsonEncode({
        'expiresAt': expiresAt,
        'value': value,
      });
      await _cache.put(key, envelope);
    } catch (e, st) {
      debugPrint('LocalStorageService.setCached($key) failed: $e\n$st');
    }
  }

  /// Returns decoded cache entry or `null` if missing, expired, or invalid.
  T? getCached<T>(String key, T Function(dynamic json) fromJson) {
    try {
      final raw = _cache.get(key);
      if (raw == null) return null;

      final Map<String, dynamic> envelope;
      if (raw is String) {
        envelope = jsonDecode(raw) as Map<String, dynamic>;
      } else if (raw is Map) {
        envelope = Map<String, dynamic>.from(raw);
      } else {
        debugPrint('LocalStorageService.getCached($key): unexpected type ${raw.runtimeType}');
        return null;
      }

      final expiresAt = envelope['expiresAt'];
      if (expiresAt is! int) return null;

      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        _cache.delete(key);
        return null;
      }

      return fromJson(envelope['value']);
    } catch (e, st) {
      debugPrint('LocalStorageService.getCached($key) failed: $e\n$st');
      return null;
    }
  }
}
