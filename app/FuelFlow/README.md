# FuelFlow App (Flutter)

Flutter client for FuelFlow.

## Includes

- Auth and onboarding
- Dashboard + energy state
- Meal capture/history
- Activity tracking
- Favorites, analytics, and settings
- Push notification handling (FCM)

## Local run

```bash
cd app/FuelFlow
flutter pub get
flutter run
```

Make sure app API config points to your backend host.

## Firebase files

Real Firebase config is intentionally not committed.

Add your own:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- valid values in `lib/firebase_options.dart`

Recommended setup command:

```bash
flutterfire configure
```

## Checks

```bash
flutter analyze --no-fatal-infos
flutter test
```

## Build release APK

```bash
flutter build apk --release
```

Output:

- `build/app/outputs/flutter-apk/app-release.apk`
