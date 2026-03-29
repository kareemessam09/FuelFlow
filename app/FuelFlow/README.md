# FuelFlow App (Flutter)

Mobile client for FuelFlow.

## Main features

- Authentication and onboarding flow
- Home dashboard with live energy state
- Meal logging:
  - AI image meal capture
  - manual input
  - history/today views
- Activity tracking with mode switching
- Favorites/templates/custom entries
- Analytics and goal progress
- Settings/profile updates
- Push notification integration (FCM + local notifications)

## Tech stack

- Flutter (Material 3)
- `flutter_bloc` for state management
- `go_router` for navigation
- `dio` for API integration
- Hive/shared preferences for local persistence
- Firebase Messaging + local notifications

## Directory guide

```text
app/FuelFlow/
├─ lib/
│  ├─ core/              # theme, constants, shared helpers
│  ├─ data/              # datasources, models, repositories
│  ├─ domain/            # entities/use cases
│  ├─ presentation/      # screens, blocs, widgets
│  ├─ router/            # routes
│  ├─ services/          # auth, notifications, local storage
│  └─ main.dart
├─ assets/
├─ android/
├─ ios/
└─ test/
```

## Run locally

```bash
cd app/FuelFlow
flutter pub get
flutter run
```

## Backend integration

Make sure app API base URL points to your backend:

- emulator usually uses `10.0.2.2` for host machine
- physical devices use your machine LAN IP

Backend should be reachable from the device and expose `/api`.

## Firebase setup (required for push)

Firebase config files are intentionally excluded from git.

Provide your own:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- valid `lib/firebase_options.dart` values

Recommended:

```bash
flutterfire configure
```

If Firebase files are missing, the app still runs with core features.
Only Firebase push messaging is disabled.

## Quality checks

```bash
flutter analyze --no-fatal-infos
flutter test
```

## Release build

### APK

```bash
flutter build apk --release
```

Output:

- `build/app/outputs/flutter-apk/app-release.apk`

Smaller APK option (recommended for distribution):

```bash
flutter build apk --release --split-per-abi
```

This produces:

- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

For GitHub Actions release builds, configure repository secret:

- `FIREBASE_ANDROID_GOOGLE_SERVICES_JSON_B64` (base64 of `android/app/google-services.json`)

Without this secret, release CI intentionally fails because push notifications
would not be fully configured in the generated APK.

### AAB (optional for Play Console)

```bash
flutter build appbundle --release
```

## Notes for production

- Keep signing keys and Firebase configs outside repository.
- Ensure backend `CORS_ORIGINS` includes production domains.
- Use release build variants for final testing (not debug).
- Verify notification permission flow on real devices.
