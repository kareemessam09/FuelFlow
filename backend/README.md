# FuelFlow Backend API

A proactive energy and metabolism tracking backend built with NestJS, featuring AI-powered food analysis, JWT authentication, and real-time energy calculations with delta-computation optimization.

## Features

### Core Features
- **JWT Authentication** with Email/Password and Google OAuth support
- **AI Food Analysis** using Google Gemini 1.5 Flash Vision API
- **Real-time Energy Tracking** with activity-based metabolic decay algorithm
- **Multi-Activity Mode System** supporting 5 activity types with different burn rates
- **Snap & Fuel** - Upload food photos for instant AI nutritional analysis

### Technical Features
- **RESTful API** with comprehensive DTO validation (class-validator)
- **PostgreSQL Database** with Prisma ORM and optimized indexes
- **Delta-Computation Optimization** - O(1) energy status polling via snapshots
- **Push Notification Support** via Firebase Cloud Messaging (FCM)
- **Health Check Endpoints** for monitoring and load balancers
- **Ownership-based Authorization** - Users can only access their own data

## Project Setup

### Prerequisites

- Node.js 18+ or Bun
- PostgreSQL database (or use Prisma Dev)
- Google Gemini API key

### Installation

```bash
npm install
```

### Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Database
DATABASE_URL="postgresql://postgres:password@localhost:5432/fuelflow"

# JWT Authentication
JWT_SECRET="your-super-secret-jwt-key"

# Google OAuth (optional)
GOOGLE_CLIENT_ID="your-google-client-id"
GOOGLE_CLIENT_SECRET="your-google-client-secret"

# Gemini AI
GEMINI_API_KEY="your-gemini-api-key"

# CORS allowlist (required in production)
CORS_ORIGINS="https://your-app.example.com"

# SMTP for password reset email delivery
SMTP_HOST="smtp.example.com"
SMTP_PORT=587
SMTP_USER="smtp-user"
SMTP_PASS="smtp-password"
SMTP_FROM="FuelFlow <no-reply@your-app.example.com>"
```

### Database Setup

Start Prisma Dev database:

```bash
npx prisma dev start default
```

Run migrations:

```bash
npx prisma migrate dev
```

Generate Prisma Client:

```bash
npx prisma generate
```

## Running the Application

```bash
# Development mode with watch
npm run start:dev

# Production mode
npm run start:prod

# Debug mode
npm run start:debug
```

The API will be available at `http://localhost:3000`

## API Endpoints

All endpoints (except public ones) require a JWT token in the `Authorization` header:

```
Authorization: Bearer <your-jwt-token>
```

### App Controller (`/api`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api` | ❌ | API info and endpoint directory |
| GET | `/api/health` | ❌ | Health check endpoint |

---

### Auth Controller (`/auth`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/auth/register` | ❌ | Register new user with email/password |
| POST | `/auth/login` | ❌ | Login with email/password |
| POST | `/auth/forgot-password` | ❌ | Request password reset email/token |
| POST | `/auth/reset-password` | ❌ | Reset password with email + token |
| POST | `/auth/google` | ❌ | Google OAuth authentication |
| POST | `/auth/fcm-token` | ✅ | Update Firebase Cloud Messaging token |
| POST | `/auth/change-password` | ✅ | Change password using current password |
| POST | `/auth/me` | ✅ | Get authenticated user info |

**Security notes:**
- Auth endpoints are rate-limited.
- `forgot-password` returns a generic message to avoid account enumeration.
- Password reset token is no longer returned by API response; it is delivered via configured SMTP email (or server log fallback when SMTP is not configured).

**Request/Response Examples:**

```bash
# Register
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "securePassword123", "name": "John Doe"}'

# Response
{
  "user": { "id": "uuid", "email": "user@example.com", "name": "John Doe" },
  "accessToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

---

### Meals Controller (`/meals`)

All endpoints require JWT authentication. The `userId` is automatically extracted from the token.

| Method | Path | Description |
|--------|------|-------------|
| POST | `/meals/snap` | Upload food image for AI analysis (multipart/form-data, max 10MB) |
| POST | `/meals/manual` | Create meal manually without AI |
| GET | `/meals/my` | Get all meals for authenticated user |
| GET | `/meals/my/today` | Get today's meals only |
| GET | `/meals/:id` | Get specific meal (own meals only) |
| DELETE | `/meals/:id` | Delete meal (own meals only) |

**Snap & Fuel Example:**

```bash
curl -X POST http://localhost:3000/meals/snap \
  -H "Authorization: Bearer <token>" \
  -F "image=@food.jpg"

# Response includes AI analysis
{
  "id": 1,
  "foodName": "Grilled Chicken Salad",
  "fullnessVolume": 45,
  "absorptionRate": 35,
  "absorptionProfile": "Slow",
  "estimatedSatiety": 180,
  "energyState": {
    "volumeRemaining": 78.5,
    "status": "OPTIMAL",
    "etcMinutes": 142,
    "etcZeroMinutes": 245
  },
  "aiAnalysis": { "confidence": 0.92, "notes": "Fresh vegetables detected" }
}
```

**Manual Meal DTO:**

```typescript
{
  foodName: string           // Required
  fullnessVolume: number     // 0-100, required
  absorptionRate: number     // 1-100 (glycemic index), required
  absorptionProfile?: "Fast" | "Balanced" | "Slow"
  estimatedSatiety: number   // 10-480 minutes, required
  imageUrl?: string
}
```

---

### Activity Controller (`/activity`)

All endpoints require JWT authentication.

| Method | Path | Description |
|--------|------|-------------|
| POST | `/activity/toggle` | Toggle activity mode (closes previous, starts new) |
| GET | `/activity/status` | Get current activity status & energy state |
| GET | `/activity/history` | Get activity history (`?limit=20`) |
| GET | `/activity/summary` | Get today's activity time summary |
| POST | `/activity/end` | End current activity (switches to Resting) |

**Activity Modes & Multipliers:**

| Mode | Multiplier | Description |
|------|-----------|-------------|
| Resting | 1.0x | Baseline energy drain (sleeping, relaxing) |
| Coding | 1.3x | 30% faster drain (mental work, sitting) |
| Studying | 1.6x | 60% faster drain (intense focus, reading) |
| GymStrength | 3.5x | 250% faster drain (weightlifting) |
| GymCardio | 5.0x | 400% faster drain (running, intense cardio) |

**Toggle Activity Example:**

```bash
curl -X POST http://localhost:3000/activity/toggle \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"modeType": "Studying"}'
```

---

### Energy Controller (`/energy`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/energy/status` | ✅ | Get current energy state (optimized with delta-computation) |
| GET | `/energy/constants` | ❌ | Get energy calculation constants (public) |

**Energy Status Response:**

```typescript
{
  userId: string,
  timestamp: string,
  energyState: {
    volumeRemaining: number,  // 0-100, rounded to 2 decimals
    status: "OPTIMAL" | "WARNING" | "CRITICAL",
    etcMinutes: number | null,      // Minutes to 30% threshold
    etcZeroMinutes: number | null   // Minutes to 0%
  },
  currentActivity: { modeType, multiplier, startTime } | null,
  effectiveGlycemicIndex: number,   // Weighted avg of active meals
  alertTime: string | null,          // When 30% threshold reached
  usedDeltaComputation: boolean      // Optimization indicator
}
```

**Energy Status Thresholds:**

| Status | Volume Range | Meaning |
|--------|-------------|---------|
| OPTIMAL | > 60% | Good energy level |
| WARNING | 30-60% | Low energy, consider eating |
| CRITICAL | < 30% | Energy crash imminent |

---

### Users Controller (`/users`)

All endpoints require JWT authentication. Users can only access their own data.

| Method | Path | Description |
|--------|------|-------------|
| POST | `/users` | Create new user |
| GET | `/users` | Get all users (admin) |
| GET | `/users/:id` | Get user profile (own profile only) |
| PATCH | `/users/:id` | Update user profile (own profile only) |
| DELETE | `/users/:id` | Delete user account (own account only) |

**User Preferences:**

```typescript
{
  sensitivityLevel: "Sensitive" | "Normal" | "Low"  // Energy sensitivity
  targetGoal: "Maintenance" | "Bulking" | "Cutting" // Fitness goal
}
```

## Database Schema

### User Model
```prisma
model User {
  id               String   @id @default(uuid())
  email            String   @unique
  name             String?
  password         String?              // Hashed (null for Google-only users)
  googleId         String?  @unique
  authProvider     String   @default("local")
  fcmToken         String?              // Firebase Cloud Messaging token
  lastAlertAt      DateTime?            // Last push notification timestamp
  sensitivityLevel String   @default("Sensitive")
  targetGoal       String   @default("Maintenance")
  createdAt        DateTime @default(now())
  updatedAt        DateTime @updatedAt
  
  mealLogs         MealLog[]
  activityLogs     ActivityLog[]
  energySnapshots  EnergySnapshot[]
}
```

### MealLog Model
```prisma
model MealLog {
  id                Int      @id @default(autoincrement())
  userId            String
  foodName          String
  fullnessVolume    Float    // 0-100%
  absorptionRate    Float    // Glycemic Index 1-100
  absorptionProfile String   @default("Balanced")
  estimatedSatiety  Int      // Minutes at 1.0x multiplier
  imageUrl          String?
  createdAt         DateTime @default(now())
  user              User     @relation(...)
}
```

### ActivityLog Model
```prisma
model ActivityLog {
  id          Int       @id @default(autoincrement())
  userId      String
  modeType    String    // Resting, Coding, Studying, GymStrength, GymCardio
  multiplier  Float     // 1.0, 1.3, 1.6, 3.5, 5.0
  startTime   DateTime  @default(now())
  endTime     DateTime? // Null if currently active
  user        User      @relation(...)
}
```

### EnergySnapshot Model (Delta-Computation Optimization)
```prisma
model EnergySnapshot {
  id              Int      @id @default(autoincrement())
  userId          String
  volumeRemaining Float    // Current volume 0-100
  glycemicIndex   Float    @default(50)
  etcMinutes      Int?
  snapshotAt      DateTime @default(now())
  user            User     @relation(...)
}
```

---

## Energy Calculation Algorithm

### Core Formula

```
V_remaining = V_start - (R_base × G_index × M_activity × Δt)
```

Where:
- **V_remaining**: Energy volume remaining (0-100%)
- **V_start**: Starting energy volume
- **R_base**: Base metabolic drain rate = 0.5% per minute
- **G_index**: Normalized glycemic index (1-100 → 0.01-1.0)
- **M_activity**: Activity multiplier (1.0, 1.3, 1.6, 3.5, 5.0)
- **Δt**: Elapsed time in minutes

### Energy Constants

```typescript
ENERGY_CONSTANTS = {
  R_BASE: 0.5,              // Base drain rate per minute
  MAX_FULLNESS: 100,        // Maximum volume cap
  MIN_FULLNESS: 0,          // Minimum volume floor
  WARNING_THRESHOLD: 60,    // OPTIMAL if > 60%
  CRITICAL_THRESHOLD: 30,   // CRITICAL if < 30%
  ALERT_THRESHOLD: 30       // Alert when reaching 30%
}
```

### Example Calculation

**Scenario:** Current volume 60%, GI 55, Studying (1.6x), 30 minutes elapsed

```
normalizedGI = 55 / 100 = 0.55
drain = 0.5 × 0.55 × 1.6 × 30 = 13.2%
remaining = 60 - 13.2 = 46.8%

Status: WARNING (30 < 46.8 < 60)
drainRate = 0.44% per minute
etcMinutes = ceil((46.8 - 30) / 0.44) = 39 minutes to warning
etcZeroMinutes = ceil(46.8 / 0.44) = 107 minutes to empty
```

### Multi-Meal Weighted GI

When multiple meals are active, effective GI is calculated as weighted average:

```typescript
effectiveGI = (sum of gi × remaining) / (sum of remaining)
```

### Delta-Computation Optimization

To avoid O(n) replay on every energy poll:

1. **After computing full state**, save snapshot: `volumeRemaining`, `effectiveGI`, `etcMinutes`, `snapshotAt`
2. **On next poll (within 5 minutes)**: Get snapshot → query new meals → apply decay → O(1) to O(m)
3. **Stale snapshot (>5 minutes)**: Fall back to full replay and save new snapshot

---

## Gemini AI Integration

### Food Analysis Pipeline

1. User uploads image via `POST /meals/snap`
2. Image converted to base64 and sent to Gemini 1.5 Flash
3. AI analyzes and returns structured JSON
4. Response validated and meal created

### AI Response Structure

```typescript
{
  foodName: string,
  absorptionProfile: "Fast" | "Balanced" | "Slow",
  glycemicIndex: number,      // 1-100
  fullnessVolume: number,     // 0-100
  estimatedSatietyMinutes: number,  // 10-480
  confidence: number,         // 0-1
  notes?: string
}
```

### Glycemic Index Guidelines (AI uses)

| Range | Category | Examples |
|-------|----------|----------|
| 1-55 | Low GI | Whole grains, legumes, nuts |
| 56-69 | Medium GI | Rice, sweet potatoes |
| 70-100 | High GI | White bread, sugary foods |

### Fullness Volume Guidelines (AI uses)

| Volume | Portion Size |
|--------|--------------|
| 10-20% | Small snack |
| 25-40% | Light meal |
| 45-65% | Regular meal |
| 70-85% | Large meal |
| 85-100% | Very large meal |

### Fallback Behavior

If Gemini is unavailable or analysis fails:

```typescript
{
  foodName: "Unknown Food",
  absorptionProfile: "Balanced",
  glycemicIndex: 50,
  fullnessVolume: 40,
  estimatedSatietyMinutes: 120,
  confidence: 0,
  notes: "Could not analyze the image. Using default values."
}
```

---

## Architecture

```
backend/
├── src/
│   ├── auth/              # JWT & Google OAuth authentication
│   │   ├── decorators/    # CurrentUser decorator
│   │   ├── dto/           # RegisterDto, LoginDto, GoogleAuthDto
│   │   ├── guards/        # JwtAuthGuard
│   │   └── strategies/    # JWT strategy (HS256, 7-day expiry)
│   ├── users/             # User CRUD with ownership checks
│   │   └── dto/           # CreateUserDto, UpdateUserDto
│   ├── meals/             # Meal logging & AI snap feature
│   │   └── dto/           # CreateMealManualDto, MealResponseDto
│   ├── activity/          # Activity mode tracking
│   │   └── dto/           # ToggleActivityDto, ActivityResponseDto
│   ├── energy/            # Energy calculation engine
│   │   ├── energy.constants.ts  # Multipliers, thresholds
│   │   └── energy.service.ts    # Core algorithm
│   ├── gemini/            # Google Gemini AI integration
│   │   └── gemini.constants.ts  # AI system prompt
│   ├── prisma/            # Prisma service
│   ├── common/            # Shared utilities
│   └── app.controller.ts  # Health check, API info
├── prisma/
│   └── schema.prisma      # Database schema
└── test/                  # E2E tests
```

---

## Authentication Flow

1. **Registration**: Email/password → bcrypt hash → JWT token (7 days)
2. **Login**: Verify password → JWT token
3. **Google OAuth**: Verify Google ID token → Create/link user → JWT token
4. **Protected Routes**: `Authorization: Bearer <token>` → JwtStrategy validates → `@CurrentUser()` decorator extracts user

### CurrentUser Decorator

```typescript
@Get('status')
@UseGuards(JwtAuthGuard)
getCurrentStatus(@CurrentUser() user: CurrentUserType) {
  // user.userId, user.email, user.name available
}
```

---

## Testing

```bash
# Unit tests
npm run test

# Watch mode
npm run test:watch

# Test coverage
npm run test:cov

# E2E tests
npm run test:e2e
```

---

## Error Handling

The API uses standard HTTP status codes:

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 204 | No Content (successful delete) |
| 400 | Bad Request (validation errors) |
| 401 | Unauthorized (missing/invalid JWT) |
| 403 | Forbidden (accessing other user's resources) |
| 404 | Not Found |
| 409 | Conflict (e.g., email already exists) |
| 413 | Payload Too Large (file upload exceeds 10MB) |
| 422 | Unprocessable Entity |
| 500 | Internal Server Error |

---

## Development Notes

- All endpoints (except `/auth/*`, `/api/health`, `/energy/constants`) require JWT authentication
- Users can only access their own data (ownership enforced at controller level)
- File uploads limited to 10MB, supported formats: jpeg, jpg, png, webp, gif
- JWT tokens expire after 7 days (HS256 algorithm)
- Database uses Prisma ORM with PostgreSQL
- Passwords hashed with bcrypt (10 rounds)
- Delta-computation snapshots valid for 5 minutes

---

## License

This project is part of the FuelFlow application.
