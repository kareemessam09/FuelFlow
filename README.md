# FuelFlow

FuelFlow is a full-stack mobile product for tracking energy state from meals + activity.

It includes:

- `app/FuelFlow` — Flutter mobile client
- `backend` — NestJS API (Prisma + PostgreSQL)

The app supports onboarding, auth, meal capture/manual logging, activity toggling, analytics, favorites, goals, push notifications, and production-oriented security defaults.

## Theme palette

The UI is built around this required palette:

- `#B21235` (primary red)
- `#FFF66B` (accent yellow)
- `#FF5672` (secondary pink)
- `#149BCC` (cyan)
- `#0985B2` (teal)

## Repository structure

```text
FuelFlow/
├─ app/FuelFlow/                 # Flutter app
│  ├─ lib/                       # app code
│  ├─ android/                   # Android project
│  ├─ ios/                       # iOS project
│  └─ test/                      # Flutter tests
├─ backend/                      # NestJS API
│  ├─ src/                       # modules/services/controllers
│  ├─ prisma/                    # schema + migrations
│  └─ test/                      # backend tests
└─ .github/workflows/ci.yml      # CI + APK release workflow
```

## Local setup

### Prerequisites

- Flutter stable (Dart `3.10.x`)
- Node.js `20+`
- PostgreSQL `14+`
- Optional: Firebase project (push notifications)
- Optional: Gemini API key (image meal analysis)

### Backend boot

```bash
cd backend
npm install
cp .env.example .env
npx prisma migrate dev
npm run start:dev
```

API base: `http://localhost:3000/api`

Health check: `GET http://localhost:3000/api/health`

### App boot

```bash
cd app/FuelFlow
flutter pub get
flutter run
```

Make sure app API config points to your backend host/IP (especially on a real device).

## Core product flows

- Register/login (email-password + Google auth backend support)
- Forgot/reset password (generic secure response + SMTP delivery when configured)
- Onboarding (first-run gated)
- Energy dashboard (live state, thresholds, timers)
- Meals:
  - AI Snap (image upload + Gemini analysis)
  - Manual meal logging
- Activity:
  - mode switching (resting/studying/coding/gym)
  - live energy decay effect
- Favorites/templates/custom foods
- Analytics and goal progress
- Notifications:
  - local + FCM handling
  - FCM token sync to backend

## CI/CD

Workflow file: `.github/workflows/ci.yml`

### CI checks

On push/PR:

- Backend: install, build, tests
- Flutter: `flutter pub get`, analyze, tests

### APK release automation

On tag push matching `v*` (example `v1.0.1`):

- Build release APK
- Create/update GitHub Release
- Upload:
  - `app/FuelFlow/build/app/outputs/flutter-apk/app-release.apk`

To publish a release:

```bash
git tag v1.0.2
git push origin v1.0.2
```

## Security and secrets

- Firebase config files are intentionally ignored:
  - `app/FuelFlow/android/app/google-services.json`
  - `app/FuelFlow/google-services.json`
  - `app/FuelFlow/ios/Runner/GoogleService-Info.plist`
- `firebase_options.dart` should not contain real production keys in shared/public repos.
- If a key was ever committed, rotate it in Firebase/Google Cloud.
- Backend protections include:
  - rate limiting (throttler)
  - strict validation
  - CORS allowlist in production
  - safer forgot-password behavior (no account enumeration)

## Production readiness checklist

- [ ] Configure strong `JWT_SECRET`
- [ ] Configure `DATABASE_URL`
- [ ] Set production `CORS_ORIGINS`
- [ ] Configure SMTP credentials for reset emails
- [ ] Add private Firebase config per environment
- [ ] Protect default branch with required checks
- [ ] Monitor `/api/health` and errors
- [ ] Keep rollback path for previous backend + app release

## Detailed docs

- Backend details and endpoint overview: `backend/README.md`
- App architecture, integration, and release build notes: `app/FuelFlow/README.md`
