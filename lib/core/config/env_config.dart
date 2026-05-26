import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration loaded from bundled `.env` / `.env.example` assets.
/// Safe to read before and after [load]; never throws [NotInitializedError].
class EnvConfig {
  EnvConfig._();

  static bool _loadAttempted = false;

  /// Google AdMob test IDs (used when .env is missing or keys are empty).
  static const Map<String, String> _defaults = {
    'OPENAI_API_KEY': '',
    'GROQ_API_KEY': '',
    'ASTROLOGY_API_USER_ID': '',
    'ASTROLOGY_API_KEY': '',
    'ASTROLOGY_API_BASE_URL': 'https://json.astrologyapi.com/v1',
    'ADMOB_APP_ID_ANDROID': 'ca-app-pub-3940256099942544~3347511713',
    'ADMOB_BANNER_ID': 'ca-app-pub-3940256099942544/6300978111',
    'ADMOB_INTERSTITIAL_ID': 'ca-app-pub-3940256099942544/1033173712',
    'ADMOB_REWARDED_ID': 'ca-app-pub-3940256099942544/5224354917',
    'ADMOB_NATIVE_ID': 'ca-app-pub-3940256099942544/2247696110',
    'IAP_MONTHLY_ID': 'cosmic_match_premium_monthly',
    'IAP_YEARLY_ID': 'cosmic_match_premium_yearly',
    'GOOGLE_PLACES_API_KEY': 'your_google_places_api_key',
    'ANDROID_SHA1_FINGERPRINT': '',
  };

  /// Call once at startup (from [bootstrap]) before reading any getters.
  static Future<void> load() async {
    if (_loadAttempted) return;
    _loadAttempted = true;

    const candidates = ['.env', '.env.example'];

    for (final fileName in candidates) {
      try {
        await dotenv.load(fileName: fileName);
        if (kDebugMode) {
          debugPrint('EnvConfig: loaded $fileName');
        }
        return;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('EnvConfig: could not load $fileName ($e)');
        }
      }
    }

    // Ensure dotenv is initialized so dotenv.env never throws.
    dotenv.testLoad(
      fileInput: _defaults.entries
          .map((e) => '${e.key}=${e.value}')
          .join('\n'),
    );
    if (kDebugMode) {
      debugPrint('EnvConfig: using built-in defaults (AdMob test IDs)');
    }
  }

  /// Returns true when [value] matches a known placeholder pattern.
  ///
  /// Patterns (case-insensitive):
  ///   YOUR_*  |  sk-your*  |  REPLACE_*  |  <anything>
  static bool _isPlaceholder(String value) {
    if (value.isEmpty) return true;
    final lower = value.toLowerCase();
    return lower.startsWith('your_') ||
        lower.startsWith('sk-your') ||
        lower.startsWith('replace_') ||
        (lower.startsWith('<') && lower.endsWith('>'));
  }

  static String _get(String key) {
    if (dotenv.isInitialized) {
      final value = dotenv.env[key];
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return _defaults[key] ?? '';
  }

  static String get openAiApiKey => _get('OPENAI_API_KEY');

  static String get groqApiKey => _get('GROQ_API_KEY');

  static String get astrologyUserId => _get('ASTROLOGY_API_USER_ID');

  static String get astrologyApiKey => _get('ASTROLOGY_API_KEY');

  static String get astrologyBaseUrl => _get('ASTROLOGY_API_BASE_URL');

  static bool get hasAstrologyApi {
    final uid = astrologyUserId;
    final key = astrologyApiKey;
    final valid = !_isPlaceholder(uid) && uid.length >= 8 &&
        !_isPlaceholder(key) && key.length >= 8;
    if (kDebugMode && !valid) {
      if (_isPlaceholder(uid) || uid.isEmpty) {
        debugPrint('EnvConfig: ASTROLOGY_API_USER_ID is absent or a placeholder');
      } else if (uid.length < 8) {
        debugPrint('EnvConfig: ASTROLOGY_API_USER_ID is too short (< 8 chars)');
      }
      if (_isPlaceholder(key) || key.isEmpty) {
        debugPrint('EnvConfig: ASTROLOGY_API_KEY is absent or a placeholder');
      } else if (key.length < 8) {
        debugPrint('EnvConfig: ASTROLOGY_API_KEY is too short (< 8 chars)');
      }
    }
    return valid;
  }

  static bool get hasOpenAi {
    final key = openAiApiKey;
    final valid = !_isPlaceholder(key) && key.length >= 20;
    if (kDebugMode && !valid) {
      if (_isPlaceholder(key) || key.isEmpty) {
        debugPrint('EnvConfig: OPENAI_API_KEY is absent or a placeholder');
      } else if (key.length < 20) {
        debugPrint('EnvConfig: OPENAI_API_KEY is too short (< 20 chars)');
      }
    }
    return valid;
  }

  /// Returns true when a Groq API key is configured and valid.
  static bool get hasGroq {
    final key = groqApiKey;
    final valid = !_isPlaceholder(key) && key.length >= 20;
    if (kDebugMode && !valid) {
      debugPrint('EnvConfig: GROQ_API_KEY is absent or a placeholder — AI chat will use mock');
    }
    return valid;
  }

  static bool get hasGooglePlaces {
    final key = googlePlacesApiKey;
    final valid = !_isPlaceholder(key) && key.length >= 10;
    if (kDebugMode && !valid) {
      if (_isPlaceholder(key) || key.isEmpty) {
        debugPrint('EnvConfig: GOOGLE_PLACES_API_KEY is absent or a placeholder');
      } else if (key.length < 10) {
        debugPrint('EnvConfig: GOOGLE_PLACES_API_KEY is too short (< 10 chars)');
      }
    }
    return valid;
  }

  static String get admobAppIdAndroid => _get('ADMOB_APP_ID_ANDROID');

  static String get admobBannerId => _get('ADMOB_BANNER_ID');

  static String get admobInterstitialId => _get('ADMOB_INTERSTITIAL_ID');

  static String get admobRewardedId => _get('ADMOB_REWARDED_ID');

  static String get admobNativeId => _get('ADMOB_NATIVE_ID');

  static String get iapMonthlyId => _get('IAP_MONTHLY_ID');

  static String get iapYearlyId => _get('IAP_YEARLY_ID');

  static String get googlePlacesApiKey => _get('GOOGLE_PLACES_API_KEY');

  static String get androidSha1Fingerprint => _get('ANDROID_SHA1_FINGERPRINT');
}
