# Implementation Plan: Cosmic Match API Integration

## Overview

Replace all mock/stub data in the Cosmic Match Flutter app with real production API integrations across Google Places, AstrologyAPI, and OpenAI. Changes are concentrated in the service layer, caching layer, providers, and Android build config. All existing UI screens and routing remain unchanged.

## Tasks

- [ ] 1. Harden EnvConfig key validation
  - [ ] 1.1 Add `_isPlaceholder` helper and update `hasAstrologyApi`, `hasOpenAi`, and `hasGooglePlaces` getters in `lib/core/config/env_config.dart`
    - Implement `_isPlaceholder(String value)` detecting `YOUR_*`, `sk-your*`, `REPLACE_*`, `<*>` patterns
    - Update `hasAstrologyApi`: both `ASTROLOGY_API_USER_ID` and `ASTROLOGY_API_KEY` must be non-empty, non-placeholder, ≥ 8 chars
    - Update `hasOpenAi`: `OPENAI_API_KEY` non-empty, not starting with `sk-your`, ≥ 20 chars
    - Add `hasGooglePlaces` getter: `GOOGLE_PLACES_API_KEY` non-empty, non-placeholder, ≥ 10 chars
    - Emit `debugPrint` warnings for absent and placeholder keys (debug mode only)
    - _Requirements: 1.1, 1.2, 1.5, 1.6_

  - [ ]* 1.2 Write unit tests for `EnvConfig` validation logic
    - Test `_isPlaceholder` with all pattern variants
    - Test `hasAstrologyApi` returns false for short/placeholder keys and true for valid keys
    - Test `hasOpenAi` returns false for `sk-your*` prefix and short keys
    - Test `hasGooglePlaces` boundary conditions
    - _Requirements: 1.5, 1.6_

- [ ] 2. Add generic TTL-aware cache API to `LocalStorageService`
  - [ ] 2.1 Implement `setCached` and `getCached<T>` methods in `lib/data/services/local_storage_service.dart`
    - Add `setCached(String key, dynamic value, Duration ttl)` storing JSON-encoded value with expiry timestamp
    - Add `getCached<T>(String key, T Function(dynamic) fromJson)` returning null on miss or expiry
    - Add `untilMidnight()` static helper returning `Duration` until next local midnight
    - Use `Hive.box(AppConstants.cacheBox)` via existing `_cache` getter
    - _Requirements: 9.1, 9.2, 9.3, 9.4_

  - [ ]* 2.2 Write unit tests for `LocalStorageService` cache methods
    - Test `getCached` returns null for missing key
    - Test `getCached` returns null for expired entry
    - Test `getCached` returns value for valid non-expired entry
    - Test `setCached` stores value with correct expiry
    - Test `untilMidnight` returns a positive duration less than 24 hours
    - _Requirements: 9.2, 9.3, 9.4_

- [ ] 3. Create new data models
  - [ ] 3.1 Create `lib/data/models/kundli_data.dart` with `KundliData` model
    - Implement `KundliData` with `sunSign`, `moonSign`, `ascendant`, `nakshatra` fields
    - Implement `KundliData.fromJson` mapping `sun_sign`, `moon_sign`, `ascendant`, `nakshatra` keys
    - Implement `toJson` for cache serialization
    - _Requirements: 7.2_

  - [ ] 3.2 Create `lib/data/models/planet_position.dart` with `PlanetPosition` model
    - Implement `PlanetPosition` with `planet`, `sign`, `degree`, `isRetrograde` fields
    - Implement `PlanetPosition.fromJson` mapping `name`, `sign`, `normDegree`, `isRetro` keys
    - Handle `isRetro` as both string `'true'` and boolean `true`
    - Implement `toJson` for cache serialization
    - _Requirements: 6.2_

  - [ ]* 3.3 Write unit tests for `KundliData` and `PlanetPosition` models
    - Test `KundliData.fromJson` with full and partial JSON
    - Test `PlanetPosition.fromJson` with `isRetro` as string and boolean
    - Test `toJson` round-trip for both models
    - _Requirements: 6.2, 7.2_

- [ ] 4. Add typed exceptions
  - [ ] 4.1 Define `AstrologyApiException` in `lib/data/services/astrology_service.dart`
    - Add `AstrologyApiException` class implementing `Exception` with `statusCode` and `message` fields
    - Implement `toString()` returning `'AstrologyApiException($statusCode): $message'`
    - _Requirements: 6.3, 7.3_

  - [ ] 4.2 Define `PlacesApiException` in `lib/data/services/google_places_service.dart`
    - Add `PlacesApiException` class implementing `Exception` with nullable `statusCode` and `message` fields
    - Implement `toString()` returning `'PlacesApiException(${statusCode ?? "no-key"}): $message'`
    - _Requirements: 2.3, 2.4_

- [ ] 5. Update `GooglePlacesService` with typed exceptions and `hasGooglePlaces` guard
  - [ ] 5.1 Replace generic exceptions and add key guard in `lib/data/services/google_places_service.dart`
    - Replace all `throw Exception(...)` calls with `throw PlacesApiException(...)`
    - Guard `getAutocompleteSuggestions`: return empty list when `!EnvConfig.hasGooglePlaces`
    - Guard `getPlaceDetails`: throw `PlacesApiException('Google Places API key not configured')` when `!EnvConfig.hasGooglePlaces`
    - Cap autocomplete results at 5 using `.take(5).toList()`
    - Include `X-Android-Package` and `X-Android-Cert` headers only when `EnvConfig.androidSha1Fingerprint.isNotEmpty` (both headers together or neither)
    - _Requirements: 2.3, 2.4, 11.4_

  - [ ]* 5.2 Write unit tests for `GooglePlacesService` exception and guard behavior
    - Test autocomplete returns empty list when key is absent/placeholder
    - Test place details throws `PlacesApiException` when key is absent/placeholder
    - Test non-200 response throws `PlacesApiException` with status code
    - Test Android headers are included only when SHA1 fingerprint is set
    - _Requirements: 2.3, 2.4, 11.4_

- [ ] 6. Implement `AstrologyService` — timezone resolution and constructor update
  - [ ] 6.1 Add `_tzoneFor` helper and inject `LocalStorageService` in `lib/data/services/astrology_service.dart`
    - Add `_tzoneFor(PersonInput p)` using `DateTime.now().timeZoneOffset.inMinutes / 60.0` when coordinates are present
    - Default to `0.0` and emit `debugPrint` warning when coordinates are null
    - Update constructor: `AstrologyService({http.Client? client, LocalStorageService? storage})`
    - Add `_basicAuth` getter encoding `astrologyUserId:astrologyApiKey` as Base64
    - Add `_headers` getter with `Authorization` and `Content-Type`
    - _Requirements: 3.1, 3.2, 3.3_

- [ ] 7. Implement `AstrologyService` — compatibility / Ashtakoot matchmaking
  - [ ] 7.1 Implement `generateCompatibility` with real API call and caching in `lib/data/services/astrology_service.dart`
    - Check cache using key `compat_{nameA}_{dateA}_{nameB}_{dateB}` (normalized, lowercased)
    - When `EnvConfig.hasAstrologyApi` is true and cache miss: POST to `{ASTROLOGY_API_BASE_URL}/match_making_report` with Basic Auth and both persons' `lat`, `lon`, `tzone`
    - Parse `total_score` (0–36), scale to percentage: `(totalScore / 36 * 100).round()`
    - Map `report` field to `summary` if present; otherwise generate summary from score
    - On non-200 or network error: log and fall back to `_generateMockReport()`
    - When `EnvConfig.hasAstrologyApi` is false: call `_generateMockReport()` directly
    - Cache result for 24 hours via `LocalStorageService.setCached`
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

  - [ ]* 7.2 Write unit tests for `generateCompatibility`
    - Test cache hit returns cached report without network call
    - Test API 200 response parses `total_score` and scales correctly
    - Test non-200 response falls back to mock without throwing
    - Test `hasAstrologyApi` false skips network call
    - _Requirements: 4.1, 4.2, 4.4, 4.5, 4.6_

- [ ] 8. Implement `AstrologyService` — daily horoscope
  - [ ] 8.1 Implement `getDailyHoroscope` with real API call and midnight-expiry caching in `lib/data/services/astrology_service.dart`
    - Check cache using key `horoscope_{sign}_{YYYY-MM-DD}`
    - When `EnvConfig.hasAstrologyApi` is true and cache miss: POST to `{ASTROLOGY_API_BASE_URL}/sun_sign_prediction/daily/{sign}` with Basic Auth
    - Map `bot_response` or `prediction` field to `loveHoroscope`, `careerHoroscope`, and `moodInsight`
    - On 200 with missing fields, non-200, or network error: fall back to `_generateMockHoroscope()`
    - When `EnvConfig.hasAstrologyApi` is false: call `_generateMockHoroscope()` directly
    - Cache result using `LocalStorageService.untilMidnight()` as TTL
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

  - [ ]* 8.2 Write unit tests for `getDailyHoroscope`
    - Test cache hit returns cached horoscope without network call
    - Test API 200 with `bot_response` maps to all three horoscope fields
    - Test API 200 with missing fields falls back to mock
    - Test non-200 falls back to mock without throwing
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ] 9. Implement `AstrologyService` — planetary positions
  - [ ] 9.1 Implement `getPlanetaryPositions` with real API call, caching, and failure caching in `lib/data/services/astrology_service.dart`
    - Check cache using key `planets_{uid}_{YYYY-MM-DD}`
    - When `EnvConfig.hasAstrologyApi` is true and cache miss: POST to `{ASTROLOGY_API_BASE_URL}/planets` with Basic Auth and person's birth data including `lat`, `lon`, `tzone`
    - On HTTP 200: parse response array into `List<PlanetPosition>` using `PlanetPosition.fromJson`
    - On non-200: cache empty list with 24-hour TTL (prevent retry storms), then throw `AstrologyApiException(statusCode, body)`
    - On network error: throw `AstrologyApiException(0, error.toString())`
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [ ]* 9.2 Write unit tests for `getPlanetaryPositions`
    - Test cache hit returns cached list without network call
    - Test API 200 parses `List<PlanetPosition>` correctly
    - Test non-200 caches empty list and throws `AstrologyApiException`
    - Test network error throws `AstrologyApiException`
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ] 10. Implement `AstrologyService` — Kundli generation
  - [ ] 10.1 Implement `generateKundli` with real API call and 7-day caching in `lib/data/services/astrology_service.dart`
    - Check cache using key `kundli_{uid}`
    - When `EnvConfig.hasAstrologyApi` is true and cache miss: POST to `{ASTROLOGY_API_BASE_URL}/birth_details` with Basic Auth and person's `lat`, `lon`, `tzone`
    - On HTTP 200: parse response into `KundliData` using `KundliData.fromJson`
    - On non-200 or network error: throw `AstrologyApiException(statusCode, body)`
    - Cache result for 7 days via `LocalStorageService.setCached`
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

  - [ ]* 10.2 Write unit tests for `generateKundli`
    - Test cache hit returns cached `KundliData` without network call
    - Test API 200 parses `KundliData` correctly
    - Test non-200 throws `AstrologyApiException` without caching
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [ ] 11. Checkpoint — AstrologyService complete
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 12. Update `OpenAiService` — enriched system prompt and SSE error propagation
  - [ ] 12.1 Add `_buildSystemPrompt` and fix SSE parse loop in `lib/data/services/openai_service.dart`
    - Implement `_buildSystemPrompt(String userMessage, UserContext? context)` with base identity, user context (name, zodiac sign, relationship status), and relationship keyword detection
    - Detect relationship keywords: `ex`, `partner`, `love`, `compatible`, `relationship`, `date`, `marry`
    - Include zodiac-specific astrological context in prompt when relationship keywords are detected and `context.zodiacSign` is non-null
    - In SSE parse loop: remove any `catch (_) {}` that swallows post-200 errors; only skip lines not prefixed with `data: `
    - On non-200: call `debugPrint` with failure details and `yield*` mock stream (do not throw)
    - On `[DONE]`: return without error
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7_

  - [ ]* 12.2 Write unit tests for `OpenAiService` system prompt and error handling
    - Test `_buildSystemPrompt` includes user name and zodiac sign when context is provided
    - Test `_buildSystemPrompt` includes relationship context when keywords are present
    - Test non-200 response yields mock stream tokens without throwing
    - Test `[DONE]` closes stream cleanly
    - _Requirements: 8.4, 8.6, 8.7_

- [ ] 13. Wire `LocalStorageService` into `astrologyServiceProvider`
  - [ ] 13.1 Update `astrologyServiceProvider` in `lib/providers/app_providers.dart`
    - Change provider to `Provider<AstrologyService>((ref) => AstrologyService(storage: ref.watch(localStorageProvider)))`
    - Verify `localStorageProvider` is already defined and initialized before `astrologyServiceProvider`
    - _Requirements: 9.5, 9.6_

- [ ] 14. Android release configuration
  - [ ] 14.1 Add `ACCESS_NETWORK_STATE` permission to `android/app/src/main/AndroidManifest.xml`
    - Add `<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>` alongside the existing `INTERNET` permission
    - _Requirements: 11.3_

  - [ ] 14.2 Add Hive ProGuard keep rules to `android/app/proguard-rules.pro`
    - Add `-keep class com.hive.** { *; }` and `-keep class io.hive.** { *; }`
    - Add `-keepclassmembers class * extends com.hive.HiveObject { *; }`
    - Preserve existing Firebase and Google Play Services rules
    - Add `-keep class io.flutter.** { *; }` and `-dontwarn io.flutter.**`
    - _Requirements: 11.2_

- [ ] 15. Verify `.env.example` completeness
  - [ ] 15.1 Confirm `.env.example` contains placeholder entries for all five required keys
    - Check for `OPENAI_API_KEY`, `ASTROLOGY_API_USER_ID`, `ASTROLOGY_API_KEY`, `ASTROLOGY_API_BASE_URL`, and `GOOGLE_PLACES_API_KEY`
    - Add any missing keys with clearly identifiable placeholder values (e.g., `YOUR_KEY_HERE`)
    - Confirm `.env` is listed in `.gitignore`
    - _Requirements: 1.3, 1.4_

- [ ] 16. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- The design has no Correctness Properties section, so unit tests are used throughout (no property-based tests)
- All service classes accept an injected `http.Client` for testability — use this in unit tests with a mock client
- No new packages are required; `http`, `hive_flutter`, `flutter_dotenv`, and `flutter_riverpod` are already in `pubspec.yaml`
- Existing UI screens, models, and routing are unchanged — all changes are in the service/provider/config layer
- The `release` build type already has `isMinifyEnabled = true` and `isShrinkResources = true` in `build.gradle.kts` — no changes needed there

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "2.1", "3.1", "3.2", "4.1", "4.2"] },
    { "id": 1, "tasks": ["1.2", "2.2", "3.3", "5.1"] },
    { "id": 2, "tasks": ["5.2", "6.1"] },
    { "id": 3, "tasks": ["7.1", "8.1", "9.1", "10.1"] },
    { "id": 4, "tasks": ["7.2", "8.2", "9.2", "10.2", "12.1"] },
    { "id": 5, "tasks": ["12.2", "13.1"] },
    { "id": 6, "tasks": ["14.1", "14.2", "15.1"] }
  ]
}
```
