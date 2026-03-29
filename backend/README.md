# FuelFlow Backend

Backend API for FuelFlow mobile app, built with NestJS + Prisma.

## What this service does

- User auth (email/password + Google flow support)
- Password management (change / forgot / reset)
- FCM token registration for push notifications
- Meal logging:
  - manual meal create/history
  - image-based meal analysis via Gemini integration
- Activity logging and energy state computation
- Analytics, favorites, goals, user profile/settings APIs

## Tech stack

- NestJS
- Prisma ORM
- PostgreSQL
- JWT auth (Passport)
- Firebase Admin
- Gemini API integration
- class-validator / class-transformer DTO validation

## Project layout

```text
backend/
├─ src/
│  ├─ auth/
│  ├─ users/
│  ├─ meals/
│  ├─ activity/
│  ├─ energy/
│  ├─ analytics/
│  ├─ favorites/
│  ├─ prisma/
│  └─ main.ts
├─ prisma/
│  └─ schema.prisma
└─ test/
```

## Local development

### 1) Install and configure

```bash
cd backend
npm install
cp .env.example .env
```

### 2) Run DB migrations

```bash
npx prisma migrate dev
```

### 3) Start API

```bash
npm run start:dev
```

Base URL: `http://localhost:3000/api`

Health endpoint: `GET /api/health`

## Environment variables

### Required

- `DATABASE_URL`
- `JWT_SECRET`
- `GEMINI_API_KEY`

### Recommended for production

- `NODE_ENV=production`
- `CORS_ORIGINS` (comma-separated domain allowlist)
- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_USER`
- `SMTP_PASS`
- `SMTP_FROM`

## Scripts

```bash
npm run start:dev
npm run build
npm run test -- --passWithNoTests
npm run test:e2e
```

## Security behavior (implemented)

- Global validation pipe for request DTOs
- Global + route-level throttling for auth-sensitive endpoints
- Generic forgot-password response (no user enumeration leak)
- Reset token delivery via SMTP/log flow, not response payload
- Security response headers in bootstrap middleware
- Production CORS allowlist support with strict origin checks

## API groups (high-level)

- `/auth/*` — auth and account security
- `/users/*` — profile and settings
- `/meals/*` — manual + AI meal endpoints
- `/activity/*` — activity mode and logs
- `/energy/*` — current energy state/status
- `/analytics/*` — trends, reports
- `/favorites/*` — saved items/templates

## Operations notes

- Run migrations in deployment step before serving traffic.
- Keep `.env` secrets outside git and rotate keys periodically.
- Monitor `/api/health` plus auth/error rates.
- If Firebase keys were ever exposed, rotate in GCP/Firebase.
