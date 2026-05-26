# Design Document

## Overview

This design covers the production API integration for the Cosmic Match Flutter app. The work is additive — all existing UI screens, models, and routing remain unchanged. The changes are concentrated in the service layer, providers, caching layer, and Android build config.

Three external APIs are integrated:
1. **Google Places API v1** — already partially wired; needs typed exceptions, Android restriction headers, and a `PlacesApiException`.
2. **AstrologyAPI** (`https://json.astrologyapi.com/v1`) — needs real HTTP calls for compatibility, horoscope, planetary positions, and Kundli, plus Hive caching and timezone resolution.
3. **OpenAI** (`gpt-4o-mini` streaming) — already partially wired; needs enriched system prompt and correct non-200 fallback behavior.

The `LocalStorageService` gains a generic TTL-aware cache API. `EnvConfig` gains stricter key validation. The Android release build is already configured with `minifyEnabled`/`shrinkResources`; ProGuard rules need Hive keep rules added.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                             │
│  CompatibilityFormScreen  HoroscopeScreen  AiChatScreen     │
│  GooglePlacesAutocomplete widget                            │
└────────────────────┬────────────────────────────────────────┘
                     │ reads/watches Riverpod providers
┌────────────────────▼────────────────────────────────────────┐
│                    Provider Layer                           │
│  astrologyServiceProvider  openAiServiceProvider            │
│  googlePlacesServiceProvider  placesAutocompleteProvider    │
│  localStorageProvider                                       │
└────────────────────┬────────────────────────────────────────┘
                     │ calls
┌────────────────────▼────────────────────────────────────────┐
│                   Service Layer                             │
│  AstrologyService   OpenAiService   GooglePlacesService     │
│  LocalStorageService                                        │
└────────────────────┬────────────────────────────────────────┘
                     │ reads
┌────────────────────▼────────────────────────────────────────┐
│                  Config / Storage                           │
│  EnvConfig (.env)          Hive (cacheBox)                  │
└─────────────────────────────────────────────────────────────┘
```

All service classes accept an injected `http.Client` for testability. No new packages are required — `http`, `hive_flutter`, `flutter_dotenv`, and `flutter_riverpod` are already in `pubspec.yaml`.

---

## Component Design

### 1. EnvConfig (`lib/core/config/env_config.dart`)

**Changes from current state:**
- Add placeholder detection: a value is a placeholder if it matches `YOUR_*`, `your-*`, `REPLACE_*`, `<*>` patterns (case-insensitive) or equals the literal values in `.env.example`.
- `hasAstrologyApi`: require both `ASTROLOGY_API_USER_ID` and `ASTROLOGY_API_KEY` to be non-empty, non-placeholder, and ≥ 8 characters.
- `hasOpenAi`: require `OPENAI_API_KEY` to be non-empty, not start with `sk-your`, and be ≥ 20 characters.
- `hasGooglePlaces`: new getter — `GOOGLE_PLACES_API_KEY` non-empty, non-placeholder, ≥ 10 characters.
- Emit `debugPrint` warnings for absent and placeholder keys (debug mode only).
- When `.env` asset is missing entirely, fall back to `.env.example`, then built-in defaults — existing behavior preserved.

```dart
// Placeholder detection helper (internal)
static bool _isPlaceholder(String value) {
  if (value.isEmpty) return true;
  final lower = value.toLowerCase();
  return lower.startsWith('your_') ||
      lower.startsWith('sk-your') ||
      lower.startsWith('replace_') ||
      (lower.startsWith('<') && lower.endsWith('>'));
}

static bool get hasAstrologyApi {
  final uid = astrologyUserId;
  final key = astrologyApiKey;
  return !_isPlaceholder(uid) && uid.length >= 8 &&
         !_isPlaceholder(key) && key.length >= 8;
}

static bool get hasOpenAi {
  final key = openAiApiKey;
  return !_isPlaceholder(key) && key.length >= 20;
}

static bool get hasGooglePlaces {
  final key = googlePlacesApiKey;
  return !_isPlaceholder(key) && key.length >= 10;
}
```

---

### 2. LocalStorageService (`lib/data/services/local_storage_service.dart`)

**New generic cache API:**

```dart
/// Stores [value] (JSON-encodable) under [key] with expiry at now + [ttl].
Future<void> setCached(String key, dynamic value, Duration ttl) async {
  final expiry = DateTime.now().add(ttl).millisecondsSinceEpoch;
  await _cache.put(key, {'value': jsonEncode(value), 'expiry': expiry});
}

/// Returns the cached value if present and not expired, otherwise null.
T? getCached<T>(String key, T Function(dynamic json) fromJson) {
  final entry = _cache.get(key) as Map?;
  if (entry == null) return null;
  final expiry = entry['expiry'] as int?;
  if (expiry == null || DateTime.now().millisecondsSinceEpoch > expiry) return null;
  return fromJson(jsonDecode(entry['value'] as String));
}
```

The `_cache` getter returns `Hive.box(AppConstants.cacheBox)` — already opened in `init()`.

**Midnight TTL helper** (for daily horoscope):
```dart
static Duration untilMidnight() {
  final now = DateTime.now();
  final midnight = DateTime(now.year, now.month, now.day + 1);
  return midnight.difference(now);
}
```

---

### 3. New Data Models

#### `KundliData` (`lib/data/models/kundli_data.dart`)
```dart
class KundliData {
  final String sunSign;
  final String moonSign;
  final String ascendant;
  final String nakshatra;

  const KundliData({
    required this.sunSign,
    required this.moonSign,
    required this.ascendant,
    required this.nakshatra,
  });

  factory KundliData.fromJson(Map<String, dynamic> json) => KundliData(
    sunSign: json['sun_sign'] as String? ?? '',
    moonSign: json['moon_sign'] as String? ?? '',
    ascendant: json['ascendant'] as String? ?? '',
    nakshatra: json['nakshatra'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'sun_sign': sunSign,
    'moon_sign': moonSign,
    'ascendant': ascendant,
    'nakshatra': nakshatra,
  };
}
```

#### `PlanetPosition` (`lib/data/models/planet_position.dart`)
```dart
class PlanetPosition {
  final String planet;
  final String sign;
  final double degree;
  final bool isRetrograde;

  const PlanetPosition({
    required this.planet,
    required this.sign,
    required this.degree,
    required this.isRetrograde,
  });

  factory PlanetPosition.fromJson(Map<String, dynamic> json) => PlanetPosition(
    planet: json['name'] as String? ?? '',
    sign: json['sign'] as String? ?? '',
    degree: (json['normDegree'] as num?)?.toDouble() ?? 0.0,
    isRetrograde: json['isRetro'] == 'true' || json['isRetro'] == true,
  );

  Map<String, dynamic> toJson() => {
    'name': planet,
    'sign': sign,
    'normDegree': degree,
    'isRetro': isRetrograde,
  };
}
```

#### `AstrologyApiException` (`lib/data/services/astrology_service.dart` — defined inline)
```dart
class AstrologyApiException implements Exception {
  final int statusCode;
  final String message;
  const AstrologyApiException(this.statusCode, this.message);

  @override
  String toString() => 'AstrologyApiException($statusCode): $message';
}
```

#### `PlacesApiException` (`lib/data/services/google_places_service.dart` — defined inline)
```dart
class PlacesApiException implements Exception {
  final int? statusCode;
  final String message;
  const PlacesApiException(this.message, {this.statusCode});

  @override
  String toString() => 'PlacesApiException(${statusCode ?? "no-key"}): $message';
}
```

---

### 4. AstrologyService (`lib/data/services/astrology_service.dart`)

**Timezone resolution** (Requirement 3):
- Use `DateTime.now().timeZoneOffset.inMinutes / 60.0` to get the device's UTC offset as a `double`.
- If `PersonInput.birthLocationLatitude` and `birthLocationLongitude` are non-null, use the device timezone offset (best available without a paid geo-timezone API).
- If coordinates are null, default to `0.0` and emit a `debugPrint` warning.

```dart
double _tzoneFor(PersonInput p) {
  if (p.birthLocationLatitude != null && p.birthLocationLongitude != null) {
    return DateTime.now().timeZoneOffset.inMinutes / 60.0;
  }
  debugPrint('AstrologyService: no coordinates for ${p.name}, defaulting tzone to 0.0');
  return 0.0;
}
```

**Compatibility** (Requirement 4):
- Check cache first using key `compat_${personA.name}_${personA.birthDate.toIso8601String()}_${personB.name}_${personB.birthDate.toIso8601String()}` (normalized, lowercased).
- If cache miss and `EnvConfig.hasAstrologyApi`, POST to `/match_making_report`.
- Parse `total_score` (0–36), scale: `(totalScore / 36 * 100).round()`.
- On non-200 or network error: log and fall back to mock.
- Cache result for 24 hours.

**Daily Horoscope** (Requirement 5):
- Cache key: `horoscope_${sign.toLowerCase()}_${YYYY-MM-DD}`.
- TTL: `LocalStorageService.untilMidnight()`.
- POST to `/sun_sign_prediction/daily/{sign}`.
- Map `bot_response` or `prediction` field to all three horoscope text fields.
- On missing fields or non-200: fall back to mock.

**Planetary Positions** (Requirement 6):
- Cache key: `planets_${uid}_${YYYY-MM-DD}`.
- TTL: 24 hours.
- POST to `/planets`.
- On non-200: cache empty list + expiry (to prevent retry storms), then throw `AstrologyApiException`.
- On network error: throw `AstrologyApiException`.
- Returns `List<PlanetPosition>`.

**Kundli** (Requirement 7):
- Cache key: `kundli_${uid}`.
- TTL: 7 days.
- POST to `/birth_details`.
- On non-200 or network error: throw `AstrologyApiException`.
- Returns `KundliData`.

**Basic Auth helper:**
```dart
String get _basicAuth {
  final credentials = '${EnvConfig.astrologyUserId}:${EnvConfig.astrologyApiKey}';
  return 'Basic ${base64Encode(utf8.encode(credentials))}';
}

Map<String, String> get _headers => {
  'Authorization': _basicAuth,
  'Content-Type': 'application/json',
};
```

**Constructor update** — inject `LocalStorageService`:
```dart
AstrologyService({http.Client? client, LocalStorageService? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? LocalStorageService();
```

The `astrologyServiceProvider` in `app_providers.dart` is updated to pass the `localStorageProvider`:
```dart
final astrologyServiceProvider = Provider<AstrologyService>((ref) {
  return AstrologyService(storage: ref.watch(localStorageProvider));
});
```

---

### 5. GooglePlacesService (`lib/data/services/google_places_service.dart`)

**Changes from current state:**
- Replace generic `Exception` throws with typed `PlacesApiException`.
- Use `EnvConfig.hasGooglePlaces` guard (instead of manual string comparison).
- For autocomplete: return empty list when key is absent/placeholder (no exception).
- For place details: throw `PlacesApiException` when key is absent/placeholder.
- Android restriction headers: already implemented correctly — include both `X-Android-Package` and `X-Android-Cert` only when `EnvConfig.androidSha1Fingerprint.isNotEmpty`.
- Cap suggestions at 5 results.
- Coordinate precision: `PlaceDetails.latitude` and `longitude` are already `double` from JSON — no truncation needed; the API returns full precision.

**Updated `getAutocompleteSuggestions`:**
```dart
Future<List<PlaceSuggestion>> getAutocompleteSuggestions(String query) async {
  if (query.length < 1) return const [];
  if (!EnvConfig.hasGooglePlaces) {
    debugPrint('GooglePlacesService: key absent or placeholder');
    return const [];
  }
  // ... HTTP call ...
  // cap at 5
  return suggestions.take(5).toList();
}
```

**Updated `getPlaceDetails`:**
```dart
Future<PlaceDetails> getPlaceDetails(String placeId) async {
  if (!EnvConfig.hasGooglePlaces) {
    throw const PlacesApiException('Google Places API key not configured');
  }
  // ... HTTP call ...
  if (response.statusCode != 200) {
    throw PlacesApiException(
      'HTTP ${response.statusCode}: ${response.body}',
      statusCode: response.statusCode,
    );
  }
}
```

---

### 6. OpenAiService (`lib/data/services/openai_service.dart`)

**Changes from current state:**
- Enrich system prompt with relationship keywords detection.
- Non-200 response: `debugPrint` + fall back to mock (already done, just ensure `debugPrint` is called).
- Post-200 streaming errors (malformed JSON, stream interruption): propagate to caller — remove the `catch (_) {}` swallowing in the SSE parse loop; only skip lines that are not `data:` prefixed.

**Enriched system prompt:**
```dart
String _buildSystemPrompt(String userMessage, UserContext? context) {
  final base = 'You are Cosmic Match AI, a warm expert astrologer. '
      'Give insightful, empathetic relationship and chart advice. '
      'Use markdown sparingly. Keep responses concise but meaningful.';

  final userCtx = context != null
      ? ' User: ${context.name}, sign: ${context.zodiacSign ?? "unknown"}, '
        'status: ${context.relationshipStatus ?? "unknown"}.'
      : '';

  final lower = userMessage.toLowerCase();
  final isRelationship = lower.contains('ex') ||
      lower.contains('partner') ||
      lower.contains('love') ||
      lower.contains('compatible') ||
      lower.contains('relationship') ||
      lower.contains('date') ||
      lower.contains('marry');

  final astroCtx = isRelationship && context?.zodiacSign != null
      ? ' When discussing relationships, reference the user\'s ${context!.zodiacSign} '
        'traits: emotional depth, communication style, and compatibility patterns.'
      : '';

  return '$base$userCtx$astroCtx';
}
```

**SSE parse loop — propagate post-200 errors:**
```dart
await for (final chunk in response.stream.transform(utf8.decoder)) {
  for (final line in chunk.split('\n')) {
    if (!line.startsWith('data: ')) continue;
    final data = line.substring(6).trim();
    if (data == '[DONE]') return;
    // Let JSON parse errors propagate — do NOT catch here
    final json = jsonDecode(data) as Map<String, dynamic>;
    final delta = json['choices']?[0]?['delta']?['content'];
    if (delta is String && delta.isNotEmpty) yield delta;
  }
}
```

---

### 7. Provider Updates (`lib/providers/app_providers.dart`)

Only `astrologyServiceProvider` changes — inject `LocalStorageService`:

```dart
final astrologyServiceProvider = Provider<AstrologyService>((ref) {
  return AstrologyService(storage: ref.watch(localStorageProvider));
});
```

No other provider changes needed. `googlePlacesServiceProvider` and `openAiServiceProvider` already exist and are correct.

---

### 8. Android Release Configuration

**`android/app/build.gradle.kts`** — already has `isMinifyEnabled = true` and `isShrinkResources = true`. No changes needed.

**`android/app/proguard-rules.pro`** — add Hive keep rules:
```
# Hive
-keep class com.hive.** { *; }
-keep class io.hive.** { *; }
-keepclassmembers class * extends com.hive.HiveObject { *; }

# Flutter / Dart reflection
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Existing rules preserved
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
```

**`android/app/src/main/AndroidManifest.xml`** — add `ACCESS_NETWORK_STATE` permission (currently only `INTERNET` is declared):
```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

**`.env.example`** — already contains all required keys. No changes needed.

**`.gitignore`** — verify `.env` is listed (it already is in standard Flutter `.gitignore`).

---

### 9. New Files Summary

| File | Purpose |
|------|---------|
| `lib/data/models/kundli_data.dart` | `KundliData` model with `fromJson`/`toJson` |
| `lib/data/models/planet_position.dart` | `PlanetPosition` model with `fromJson`/`toJson` |

All other changes are modifications to existing files.

---

## Data Flow: Compatibility Report

```
CompatibilityFormScreen._generate()
  → astrologyServiceProvider.generateCompatibility(personA, personB)
      → LocalStorageService.getCached('compat_...')
          → cache hit: return CompatibilityReport immediately
          → cache miss:
              → EnvConfig.hasAstrologyApi?
                  → true: POST /match_making_report
                      → 200: parse + scale score → CompatibilityReport
                      → non-200 / error: log → _generateMockReport()
                  → false: _generateMockReport()
              → LocalStorageService.setCached(result, 24h)
              → return CompatibilityReport
  → CompatibilityRepository.saveReport() (Firestore)
  → context.push('/compatibility/result', extra: report)
```

## Data Flow: Daily Horoscope

```
HoroscopeScreen (FutureBuilder)
  → astrologyServiceProvider.getDailyHoroscope(sign)
      → LocalStorageService.getCached('horoscope_{sign}_{date}')
          → cache hit: return DailyHoroscope
          → cache miss:
              → EnvConfig.hasAstrologyApi?
                  → true: POST /sun_sign_prediction/daily/{sign}
                      → 200 + fields present: map to DailyHoroscope
                      → 200 + fields absent: _generateMockHoroscope()
                      → non-200 / error: _generateMockHoroscope()
                  → false: _generateMockHoroscope()
              → LocalStorageService.setCached(result, untilMidnight())
              → return DailyHoroscope
```

## Data Flow: OpenAI Streaming

```
AiChatScreen._send(text)
  → openAiServiceProvider.streamChat(history, userMessage, context)
      → EnvConfig.hasOpenAi?
          → false: yield* _mockStream()
          → true:
              → POST /v1/chat/completions (stream: true)
              → statusCode != 200: debugPrint + yield* _mockStream()
              → statusCode == 200:
                  → parse SSE lines
                  → yield delta strings
                  → [DONE]: close stream
                  → parse errors: propagate to caller
  → UI: _streamingBuffer accumulates tokens → MarkdownBody renders
```

---

## Error Handling Strategy

| Scenario | Behavior |
|----------|----------|
| AstrologyAPI non-200 (compatibility/horoscope) | Log + mock fallback, no crash |
| AstrologyAPI non-200 (planets/kundli) | Throw `AstrologyApiException` with status code |
| AstrologyAPI network error (all) | Same as non-200 for each endpoint |
| OpenAI non-200 | `debugPrint` + mock stream fallback |
| OpenAI post-200 stream error | Propagate to caller |
| Places API non-200 | Throw `PlacesApiException` with status code |
| Places API key absent | Empty list (autocomplete) / `PlacesApiException` (details) |
| Cache read error | Return null (treat as cache miss) |
| Cache write error | Log and continue (non-fatal) |

---

## Caching Summary

| Data | Cache Key | TTL |
|------|-----------|-----|
| CompatibilityReport | `compat_{nameA}_{dateA}_{nameB}_{dateB}` | 24 hours |
| DailyHoroscope | `horoscope_{sign}_{YYYY-MM-DD}` | Until midnight |
| PlanetPositions (success) | `planets_{uid}_{YYYY-MM-DD}` | 24 hours |
| PlanetPositions (failure) | `planets_{uid}_{YYYY-MM-DD}` | 24 hours (empty list) |
| KundliData | `kundli_{uid}` | 7 days |

All cache entries are stored as JSON strings with an expiry timestamp in milliseconds since epoch.

---

## Requirements Traceability

| Requirement | Design Section |
|-------------|---------------|
| R1: Secure API Key Management | §1 EnvConfig |
| R2: Google Places Autocomplete | §5 GooglePlacesService |
| R3: Timezone Resolution | §4 AstrologyService — timezone |
| R4: Compatibility / Ashtakoot | §4 AstrologyService — compatibility |
| R5: Daily Horoscope | §4 AstrologyService — horoscope |
| R6: Planetary Positions | §4 AstrologyService — planets |
| R7: Kundli Generation | §4 AstrologyService — kundli |
| R8: OpenAI Streaming Chat | §6 OpenAiService |
| R9: Hive Caching Layer | §2 LocalStorageService |
| R10: Loading and Error States | Existing UI patterns preserved; no new widgets needed |
| R11: Android Release Optimization | §8 Android Release Configuration |
