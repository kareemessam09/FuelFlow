# FuelFlow

FuelFlow is a full-stack project:

- `app/FuelFlow`: Flutter mobile app
- `backend`: NestJS API + Prisma/PostgreSQL

The app tracks energy state from meals and activity, with optional AI meal analysis and push notifications.

## Theme colors

The UI follows this palette:

- `#B21235`
- `#FFF66B`
- `#FF5672`
- `#149BCC`
- `#0985B2`

## Quick start

### 1) Start backend

```bash
cd backend
npm install
cp .env.example .env
npx prisma migrate dev
npm run start:dev
```

Backend runs at `http://localhost:3000/api`.

### 2) Start app

```bash
cd app/FuelFlow
flutter pub get
flutter run
```

Set the API base URL in app config to your backend host.

## Release APK

```bash
cd app/FuelFlow
flutter build apk --release
```

Artifact:

- `app/FuelFlow/build/app/outputs/flutter-apk/app-release.apk`

## CI/CD

GitHub Actions does two things:

- Runs backend build/tests and Flutter analyze/tests on PRs and pushes.
- Builds and uploads a release APK when you push a tag like `v1.0.0`.

## Production checklist

- Use strong `JWT_SECRET`.
- Set `CORS_ORIGINS` in backend.
- Configure SMTP (`SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM`) for password resets.
- Add real Firebase files locally (they are intentionally not committed).
- Protect `master` with required CI checks.

## Docs

- Backend setup and API notes: `backend/README.md`
- App setup and mobile notes: `app/FuelFlow/README.md`
