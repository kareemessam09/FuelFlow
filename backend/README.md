# FuelFlow Backend

This is the NestJS API used by the Flutter app.

## Responsibilities

- Authentication (email/password + Google)
- Password reset flow
- Meals and AI meal analysis
- Activity tracking and energy calculations
- Favorites, analytics, and user settings

## Stack

- NestJS
- Prisma
- PostgreSQL
- JWT auth
- Firebase Admin (push)
- Gemini API (meal analysis)

## Run locally

```bash
cd backend
npm install
cp .env.example .env
npx prisma migrate dev
npm run start:dev
```

Base API URL: `http://localhost:3000/api`

## Important env vars

Required:

- `DATABASE_URL`
- `JWT_SECRET`
- `GEMINI_API_KEY`

Recommended for production:

- `CORS_ORIGINS` (comma-separated allowlist)
- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_USER`
- `SMTP_PASS`
- `SMTP_FROM`

## Useful commands

```bash
npm run build
npm run test -- --passWithNoTests
```

## Security behavior

- Global DTO validation is enabled.
- Auth routes are rate-limited.
- Forgot-password returns a generic response.
- Reset tokens are delivered via email/log flow, not API payload.

## Health check

- `GET /api/health`
