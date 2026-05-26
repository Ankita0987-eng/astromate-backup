# Requirements Document

## Introduction

This feature replaces all mock/stub data in the Cosmic Match Flutter app with real production API integrations. The three integrations are:

1. **Google Places Autocomplete (New API)** — location search using the Places API v1, returning lat/lng for use in astrology calculations.
2. **AstrologyAPI** (https://www.astrologyapi.com/) — Kundli generation, compatibility/Ashtakoot matchmaking, daily horoscope, and planetary positions using real birth data including coordinates.
3. **OpenAI streaming chat** — GPT-4o-mini streaming responses for the AI astrology chat feature.

All integrations must be production-ready: secure `.env` key handling, Riverpod state management, Hive caching, graceful error handling, and no breaking changes to the existing UI.

---

## Glossary

- **AstrologyAPI**: The third-party REST API at `https://json.astrologyapi.com/v1` providing Kundli, horoscope, compatibility, and planetary data.
- **AstrologyService**: The Dart service class (`lib/data/services/astrology_service.dart`) that wraps AstrologyAPI calls.
- **OpenAiService**: The Dart service class (`lib/data/services/openai_service.dart`) that wraps OpenAI streaming chat.
- **GooglePlacesService**: The Dart service class (`lib/data/services/google_places_service.dart`) that wraps the Google Places API v1.
- **LocalStorageService**: The Hive-backed service (`lib/data/services/local_storage_service.dart`) used for caching API responses.
- **EnvConfig**: The environment configuration class (`lib/core/config/env_config.dart`) that reads API keys from `.env`.
- **PersonInput**: The data model representing a person's birth details including name, date, time, and coordinates.
- **CompatibilityReport**: The data model representing the result of an Ashtakoot/matchmaking API call.
- **DailyHoroscope**: The data model representing a zodiac sign's daily horoscope data.
- **Riverpod**: The state management library used throughout the app (`flutter_riverpod`).
- **Hive**: The local key-value storage library used for caching (`hive_flutter`).
- **Ashtakoot**: The Vedic astrology compatibility scoring system with a maximum of 36 points, used by AstrologyAPI's `match_making_report` endpoint.
- **Kundli**: A Vedic birth chart generated from birth date, time, and location coordinates.
- **Timezone offset**: The UTC offset in hours (e.g., `5.5` for IST) required by AstrologyAPI for all birth data inputs.
- **Mock fallback**: The existing deterministic mock logic that runs when API keys are absent or a call fails.

---

## Requirements

### Requirement 1: Secure API Key Management

**User Story:** As a developer, I want all API keys loaded from `.env` at startup, so that secrets are never hardcoded in source files and can be rotated without a code change.

#### Acceptance Criteria

1. THE `EnvConfig` SHALL read `OPENAI_API_KEY`, `ASTROLOGY_API_USER_ID`, `ASTROLOGY_API_KEY`, `ASTROLOGY_API_BASE_URL`, and `GOOGLE_PLACES_API_KEY` from the bundled `.env` asset file at app startup.
2. WHEN a key is absent from `.env` or set to a placeholder value, THE `EnvConfig` SHALL return an empty string for that key and emit a `debugPrint` warning in debug mode for both the absent and placeholder cases.
3. THE `.env` file SHALL be listed in `.gitignore` so that real keys are never committed to version control.
4. THE `.env.example` file SHALL contain placeholder values for all required keys so that new developers know which keys to configure.
5. WHEN `EnvConfig.hasAstrologyApi` is evaluated, THE `EnvConfig` SHALL return `true` only when both `ASTROLOGY_API_USER_ID` and `ASTROLOGY_API_KEY` are non-empty, not placeholder strings, and each is at least 8 characters long (basic format validation).
6. WHEN `EnvConfig.hasOpenAi` is evaluated, THE `EnvConfig` SHALL return `true` only when `OPENAI_API_KEY` is non-empty, does not start with `sk-your`, and is at least 20 characters long (basic format validation).

---

### Requirement 2: Google Places Autocomplete Integration

**User Story:** As a user entering birth location details, I want to search for and select a city using autocomplete, so that the app captures accurate latitude and longitude for astrology calculations.

#### Acceptance Criteria

1. WHEN the user types at least 1 character in a birth location field, THE `GooglePlacesService` SHALL call the Places API v1 `autocomplete` endpoint and return a list of `PlaceSuggestion` objects within 500ms of the debounce period. THE system SHALL wait for the 1-character threshold before triggering any autocomplete call.
2. WHEN the user selects a suggestion, THE `GooglePlacesService` SHALL call the Places API v1 place details endpoint and return a `PlaceDetails` object containing `latitude`, `longitude`, `city`, and `country`.
3. WHEN the Places API returns a non-200 HTTP status, THE `GooglePlacesService` SHALL throw a typed `PlacesApiException` with the status code and response body included in the message.
4. WHEN `GOOGLE_PLACES_API_KEY` is empty or a placeholder, THE `GooglePlacesService` SHALL return an empty list for autocomplete and throw a `PlacesApiException` for place details without making any network call.
5. THE `GooglePlacesAutocomplete` widget SHALL display a loading indicator while suggestions are being fetched and an error message when the provider is in an error state.
6. WHEN a location is selected, THE `GooglePlacesAutocomplete` widget SHALL invoke `onLocationSelected` with the display name and the full `PlaceDetails` object including coordinates.
7. THE `PlacesAutocompleteNotifier` SHALL debounce search calls by 300ms and cancel any in-flight search when a new query arrives.
8. WHEN the user clears the location field, THE `PlacesAutocompleteNotifier` SHALL reset to an empty data state.

---

### Requirement 3: AstrologyAPI — Timezone Resolution

**User Story:** As a developer integrating AstrologyAPI, I want birth location coordinates automatically converted to a UTC timezone offset, so that all API calls include accurate `tzone` values without requiring manual user input.

#### Acceptance Criteria

1. WHEN `PersonInput` contains non-null `birthLocationLatitude` and `birthLocationLongitude`, THE `AstrologyService` SHALL compute the UTC timezone offset in hours using the device's timezone or a coordinate-based lookup and include it as both `p_tzone` and `s_tzone` in API requests (both persons receive the same computed offset when coordinates are present for both).
2. WHEN `PersonInput` does not contain coordinates, THE `AstrologyService` SHALL default `tzone` to `0.0` (UTC) and log a debug warning.
3. THE timezone offset SHALL be a `double` value (e.g., `5.5` for IST, `-5.0` for EST) as required by AstrologyAPI.

---

### Requirement 4: AstrologyAPI — Compatibility / Ashtakoot Matchmaking

**User Story:** As a user, I want my compatibility report generated from real Vedic astrology data, so that the scores and insights reflect genuine astrological analysis rather than mock calculations.

#### Acceptance Criteria

1. WHEN `EnvConfig.hasAstrologyApi` is `true` and `generateCompatibility` is called, THE `AstrologyService` SHALL POST to `{ASTROLOGY_API_BASE_URL}/match_making_report` with Basic Auth credentials and birth data for both persons including `lat`, `lon`, and `tzone` fields.
2. WHEN the API returns HTTP 200, THE `AstrologyService` SHALL parse `total_score` (0–36 Ashtakoot points), scale it to a 0–100 percentage, and populate all score fields of `CompatibilityReport` using the API response data.
3. WHEN the API response includes a `report` field, THE `AstrologyService` SHALL use it as the `summary` field of `CompatibilityReport`; otherwise it SHALL generate a summary from the score.
4. WHEN the API returns a non-200 status or a network error occurs, THE `AstrologyService` SHALL log the error and fall back to the existing mock report generation without surfacing a crash to the user.
5. WHEN `EnvConfig.hasAstrologyApi` is `false`, THE `AstrologyService` SHALL use mock report generation directly without attempting any network call.
6. THE `AstrologyService` SHALL cache the `CompatibilityReport` result in Hive using a key derived from both persons' birth dates and names, with a TTL of 24 hours, so that repeated calls for the same pair do not trigger redundant API requests.

---

### Requirement 5: AstrologyAPI — Daily Horoscope

**User Story:** As a user, I want my daily horoscope fetched from a real astrology data source, so that the love, career, and mood insights are based on actual planetary positions rather than static mock text.

#### Acceptance Criteria

1. WHEN `getDailyHoroscope` is called with a zodiac sign and `EnvConfig.hasAstrologyApi` is `true`, THE `AstrologyService` SHALL POST to `{ASTROLOGY_API_BASE_URL}/sun_sign_prediction/daily/{zodiacSign}` with Basic Auth and return a populated `DailyHoroscope` object.
2. WHEN the API response contains `bot_response` or `prediction` fields, THE `AstrologyService` SHALL map them to the `loveHoroscope`, `careerHoroscope`, and `moodInsight` fields of `DailyHoroscope`. WHEN the API returns HTTP 200 but the response lacks both `bot_response` and `prediction` fields, THE `AstrologyService` SHALL fall back to mock horoscope generation to ensure users always receive horoscope content.
3. WHEN the API returns a non-200 status or a network error occurs, THE `AstrologyService` SHALL fall back to the existing mock horoscope generation.
4. THE `AstrologyService` SHALL cache the daily horoscope in Hive using a key of `horoscope_{sign}_{YYYY-MM-DD}`, expiring at midnight local time, so that the same sign is not fetched more than once per calendar day.
5. WHEN `EnvConfig.hasAstrologyApi` is `false`, THE `AstrologyService` SHALL use mock horoscope generation directly.

---

### Requirement 6: AstrologyAPI — Planetary Positions

**User Story:** As a premium user, I want to see current planetary positions for my birth chart, so that I can understand how today's transits affect my natal chart.

#### Acceptance Criteria

1. WHEN `getPlanetaryPositions` is called with a `PersonInput` and `EnvConfig.hasAstrologyApi` is `true`, THE `AstrologyService` SHALL POST to `{ASTROLOGY_API_BASE_URL}/planets` with Basic Auth and the person's birth data including coordinates and timezone.
2. WHEN the API returns HTTP 200, THE `AstrologyService` SHALL return a `List<PlanetPosition>` where each entry contains `planet` name, `sign`, `degree`, and `isRetrograde` fields.
3. WHEN the API returns a non-200 status or a network error occurs, THE `AstrologyService` SHALL throw a typed `AstrologyApiException` with the status code included.
4. THE `AstrologyService` SHALL cache planetary positions in Hive using a key of `planets_{uid}_{YYYY-MM-DD}` with a 24-hour TTL. WHEN the API call fails with a non-200 response, THE `AstrologyService` SHALL cache the failure result (empty list) alongside the expiry timestamp to prevent repeated failing calls within the TTL window.

---

### Requirement 7: AstrologyAPI — Kundli Generation

**User Story:** As a user, I want my Kundli (Vedic birth chart) generated from my birth details, so that I can view my natal chart data within the app.

#### Acceptance Criteria

1. WHEN `generateKundli` is called with a `PersonInput` and `EnvConfig.hasAstrologyApi` is `true`, THE `AstrologyService` SHALL POST to `{ASTROLOGY_API_BASE_URL}/birth_details` with Basic Auth and the person's birth data including `lat`, `lon`, and `tzone`.
2. WHEN the API returns HTTP 200, THE `AstrologyService` SHALL return a `KundliData` object containing `sunSign`, `moonSign`, `ascendant`, and `nakshatra` fields parsed from the response.
3. WHEN the API returns a non-200 status or a network error occurs, THE `AstrologyService` SHALL throw a typed `AstrologyApiException` with the status code included.
4. THE `AstrologyService` SHALL cache Kundli data in Hive using a key of `kundli_{uid}` with a 7-day TTL, since birth chart data does not change.

---

### Requirement 8: OpenAI Streaming Chat Integration

**User Story:** As a user chatting with the AI astrologer, I want responses streamed token-by-token, so that the conversation feels natural and responsive rather than waiting for a full response.

#### Acceptance Criteria

1. WHEN `EnvConfig.hasOpenAi` is `true` and `streamChat` is called, THE `OpenAiService` SHALL send a POST request to `https://api.openai.com/v1/chat/completions` with `stream: true`, model `gpt-4o-mini`, and the full conversation history.
2. WHEN the API streams a response, THE `OpenAiService` SHALL yield each text delta as a `String` chunk as it arrives, so that the UI can display tokens progressively.
3. WHEN the stream ends with `[DONE]`, THE `OpenAiService` SHALL close the stream without error.
4. WHEN the API returns a non-200 HTTP status, THE `OpenAiService` SHALL log the failure via `debugPrint` and fall back to the mock stream response without surfacing a crash to the user. WHEN the API returns HTTP 200 but other errors occur during streaming (e.g., malformed JSON, stream interruption), THE `OpenAiService` SHALL allow those errors to propagate to the caller.
5. WHEN `EnvConfig.hasOpenAi` is `false`, THE `OpenAiService` SHALL use mock stream generation directly without attempting any network call.
6. THE `OpenAiService` SHALL include a system prompt that identifies the assistant as "Cosmic Match AI", references the user's name, zodiac sign, and relationship status from `UserContext` when available, and instructs the model to give empathetic astrology-focused responses.
7. WHEN the user's message contains relationship-related keywords, THE `OpenAiService` SHALL include relevant astrological context in the system prompt to improve response quality.

---

### Requirement 9: Hive Caching Layer

**User Story:** As a user on a slow or intermittent connection, I want previously fetched astrology data served from cache, so that the app remains usable without repeated API calls.

#### Acceptance Criteria

1. THE `LocalStorageService` SHALL expose `getCached<T>` and `setCached` methods that read and write JSON-serializable data to the Hive `cacheBox` with an associated expiry timestamp.
2. WHEN `getCached` is called and the cached entry exists and has not expired, THE `LocalStorageService` SHALL return the cached value without making a network call.
3. WHEN `getCached` is called and the cached entry is absent or expired, THE `LocalStorageService` SHALL return `null` so the caller proceeds with a fresh API request.
4. WHEN `setCached` is called, THE `LocalStorageService` SHALL store the value alongside an expiry timestamp computed as `DateTime.now().add(ttl)`.
5. THE `AstrologyService` SHALL use `LocalStorageService` to cache compatibility reports for 24 hours, daily horoscopes until midnight, planetary positions for 24 hours, and Kundli data for 7 days.
6. WHEN the app is launched and cached data exists within its TTL, THE `AstrologyService` SHALL return cached data immediately without making any API call.

---

### Requirement 10: Loading and Error States

**User Story:** As a user, I want clear loading indicators and error messages during API calls, so that I always know the app is working and understand what went wrong if something fails.

#### Acceptance Criteria

1. WHEN any API call is in progress, THE relevant screen or widget SHALL display a loading indicator (spinner or shimmer) in place of the content area.
2. WHEN an API call fails and no cached data is available, THE relevant screen or widget SHALL display a user-friendly error message and a retry button.
3. WHEN the `CompatibilityFormScreen` is generating a report, THE `LoadingOverlay` widget SHALL be displayed with the message "Reading the stars..." until the call completes or fails.
4. WHEN the `HoroscopeScreen` is loading horoscope data, THE screen SHALL display a `CircularProgressIndicator` until data is available.
5. WHEN the `AiChatScreen` is streaming a response, THE `_TypingDots` widget SHALL be displayed until the first token arrives, then replaced by the progressively rendered markdown content. IF markdown rendering fails or is delayed after the first token arrives, THEN THE `AiChatScreen` SHALL display the raw text content as a fallback.
6. IF an API call fails with a network error, THEN THE app SHALL display a `SnackBar` with a human-readable message (not a raw exception string) and offer a retry action where applicable.

---

### Requirement 11: Android Release Optimization

**User Story:** As a developer preparing the Android release build, I want the app configured for production so that it runs efficiently and securely on end-user devices.

#### Acceptance Criteria

1. THE `android/app/build.gradle` SHALL have `minifyEnabled true` and `shrinkResources true` set for the `release` build type.
2. THE `android/app/proguard-rules.pro` file SHALL include keep rules for Hive, Firebase, Google Play Services, and any reflection-dependent libraries to prevent class stripping.
3. THE `AndroidManifest.xml` SHALL declare `INTERNET` and `ACCESS_NETWORK_STATE` permissions required for all API integrations.
4. WHERE the `ANDROID_SHA1_FINGERPRINT` environment variable is set and non-empty, THE `GooglePlacesService` SHALL include both `X-Android-Package` and `X-Android-Cert` headers in all Places API requests. WHERE `ANDROID_SHA1_FINGERPRINT` is absent or empty, THE `GooglePlacesService` SHALL include neither header — partial inclusion is not acceptable.
5. THE release build SHALL not include any debug logging of API keys or raw response bodies.
