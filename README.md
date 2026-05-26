# Cosmic Match ✨

**Cosmic Match** is a production-ready Flutter astrology dating & compatibility app (Tinder + Co-Star style) with Firebase backend, Riverpod state management, AI chat, Google Play subscriptions, and AdMob.

## Project location

```
/Users/ankitapanda/Projects/cosmic_match
```

## Features

- Authentication (Email, Google Sign-In, forgot password, persistent session)
- User profile with birth chart data (Firestore)
- Home dashboard (daily horoscope, love energy, premium banner)
- Full compatibility engine (scores, charts, red flags, soulmate %, twin flame)
- AI astrology chat (OpenAI streaming + mock fallback)
- Premium subscriptions (Google Play Billing)
- AdMob (banner, interstitial, rewarded — non-spammy)
- Shareable social compatibility cards
- Daily horoscope + local notification reminders
- FCM push notifications
- Settings (theme, legal, delete account, logout)
- Viral extras (twin flame, celebrity match, best signs, cosmic energy)

## Tech stack

| Layer | Technology |
|--------|------------|
| UI | Flutter 3, Material 3, animations |
| State | Riverpod |
| Local | Hive |
| Backend | Firebase Auth, Firestore, Storage, Analytics, Crashlytics, FCM |
| AI | OpenAI API |
| Astrology | AstrologyAPI.com (optional mock) |
| Payments | in_app_purchase |
| Ads | google_mobile_ads |

## Folder structure

```
lib/
├── main.dart / bootstrap.dart / app.dart
├── core/          # theme, router, widgets, utils, config
├── data/          # models, repositories, services
├── features/      # splash, auth, home, compatibility, ai_chat, premium, etc.
├── providers/     # Riverpod providers
└── firebase_options.dart
firebase/           # Firestore & Storage rules
android/            # Play Store ready Gradle config
```

## Quick start

### 1. Prerequisites

- Flutter SDK (stable 3.41+)
- Android Studio / Xcode
- Firebase project
- (Optional) OpenAI API key
- (Optional) AstrologyAPI credentials

### 2. Install dependencies

```bash
cd /Users/ankitapanda/Projects/cosmic_match
flutter pub get
```

### 3. Environment variables

```bash
cp .env.example .env
```

Edit `.env` with your keys:

| Variable | Description |
|----------|-------------|
| `OPENAI_API_KEY` | OpenAI key for AI chat (mock if empty) |
| `ASTROLOGY_API_USER_ID` | astrologyapi.com user ID |
| `ASTROLOGY_API_KEY` | astrologyapi.com key |
| `IAP_MONTHLY_ID` / `IAP_YEARLY_ID` | Play Console subscription IDs |
| AdMob IDs | Replace test IDs for production |

Copy `.env` to project root. For release, prefer `--dart-define` or CI secrets instead of bundling `.env`.

### 4. Firebase setup

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login and configure
firebase login
flutterfire configure
```

This generates `lib/firebase_options.dart` and `android/app/google-services.json`.

Enable in Firebase Console:

- Authentication (Email/Password, Google)
- Cloud Firestore
- Storage
- Cloud Messaging
- Crashlytics
- Analytics

Deploy security rules:

```bash
firebase deploy --only firestore:rules,storage
```

### 5. Google Sign-In (Android)

1. Add SHA-1/SHA-256 fingerprints in Firebase Console
2. Download updated `google-services.json`
3. Enable Google provider in Firebase Auth

### 6. Google Play Billing

1. Create app in [Google Play Console](https://play.google.com/console)
2. Create subscriptions: `cosmic_match_premium_monthly`, `cosmic_match_premium_yearly`
3. Match IDs in `.env`
4. Upload signed AAB to internal testing before IAP works

### 7. AdMob

1. Create AdMob app linked to Play package `com.cosmicmatch.cosmic_match`
2. Create ad units (banner, interstitial, rewarded, native)
3. Update `.env` and `AndroidManifest.xml` `APPLICATION_ID`

### 8. Run the app

```bash
flutter run
```

## Play Store deployment

### Signing

Create `android/key.properties`:

```properties
storePassword=***
keyPassword=***
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

Update `android/app/build.gradle.kts` to use release signing (see [Flutter deploy docs](https://docs.flutter.dev/deployment/android)).

### Build release AAB

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Store listing checklist

- [ ] Privacy policy URL (host `legal/privacy` content)
- [ ] Terms URL
- [ ] App icon 512×512
- [ ] Feature graphic & screenshots
- [ ] Content rating questionnaire
- [ ] Data safety form (Firebase, OpenAI, Ads declared)
- [ ] Target API level compliance

## API integration examples

### AstrologyAPI (when keys set)

Basic auth match making endpoint is used in `lib/data/services/astrology_service.dart`.

### OpenAI streaming

Configured in `lib/data/services/openai_service.dart` with `gpt-4o-mini` model.

## Firestore collections

| Collection | Path |
|------------|------|
| users | `users/{uid}` |
| compatibility reports | `users/{uid}/compatibility_reports/{id}` |
| AI chats | `users/{uid}/ai_chats/{id}/messages/{id}` |
| subscriptions | `subscriptions/{uid}` |
| daily horoscopes | `daily_horoscopes/{sign_date}` (read-only cache) |

## Free vs Premium limits

| Feature | Free | Premium |
|---------|------|---------|
| Compatibility checks | 3/day | Unlimited |
| AI messages | 10/day | Unlimited |
| Ads | Yes | No |
| Full reports | Basic | Full |

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Firebase init error | Run `flutterfire configure` |
| Google Sign-In fails | Add SHA fingerprints |
| IAP unavailable | Use licensed test account + internal track |
| Ads not loading | Use test IDs in debug; check AdMob linking |
| OpenAI errors | App uses mock responses when key missing |

## License

Proprietary — Cosmic Match. Configure for your organization before publishing.
