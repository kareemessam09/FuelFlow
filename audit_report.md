# FuelFlow — Code & Architecture Audit

**Application:** FuelFlow — Proactive Metabolism Tracker  
**Stack:** Flutter (BLoC) + NestJS (Prisma/PostgreSQL/Gemini AI)  
**Auditor:** Code Review — Production-Readiness Assessment  
**Files Reviewed:** 20+ source files across both codebases

---

## Severity Legend

| Tag | Meaning |
|---|---|
| 🔴 **CRITICAL** | Will break at scale or in production |
| 🟡 **MAJOR** | Significant tech-debt or performance risk |
| 🟢 **MINOR** | Best-practice improvement |

---

## 1. Flutter Architectural Integrity

### 1.1 Directory Structure — 🟡 MAJOR: Hybrid, Not Feature-First

Your current structure is **Layer-first** (`presentation/`, `domain/`, [data/](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/.metadata)), not Feature-first. This is fine for a project of this size, but the plan says "Feature-first." You need to pick one and commit.

**Current (Layer-first):**
```
lib/
├── core/
├── data/
│   ├── datasources/
│   └── repositories/
├── domain/entities/
├── presentation/
│   ├── blocs/
│   ├── screens/
│   └── widgets/
```

**Recommendation:** Your current layer-first structure is *correct for this project size*. Feature-first becomes beneficial when you have 8+ features with independent teams. **Don't refactor this — just update documentation to accurately say "Layer-first" instead of "Feature-first."**

---

### 1.2 Widget Strategy — 🟡 MAJOR: Dashboard is Monolithic

[dashboard_screen.dart](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/presentation/screens/dashboard/dashboard_screen.dart) is 347 lines with 8 private helper methods ([_buildTopSection](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/presentation/screens/dashboard/dashboard_screen.dart#120-158), [_buildBalloonSection](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/presentation/screens/dashboard/dashboard_screen.dart#159-170), [_buildBottomSection](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/presentation/screens/dashboard/dashboard_screen.dart#171-186), [_buildActivityIndicator](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/presentation/screens/dashboard/dashboard_screen.dart#187-247), [_buildActionButtons](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/presentation/screens/dashboard/dashboard_screen.dart#248-285), etc.).

**Problem:** These are "widget methods" inside a single class. They can't be tested individually, can't take advantage of Flutter's element tree diffing, and can't be reused.

**Fix — Extract into Atomic Widgets:**

```dart
// BEFORE (monolithic)
class DashboardScreen extends StatelessWidget {
  Widget _buildActivityIndicator(BuildContext ctx, FuelBlocState state) { ... }
  Widget _buildActionButtons(BuildContext ctx, FuelBlocState state) { ... }
}

// AFTER (Atomic Design)
// lib/presentation/widgets/dashboard/activity_indicator.dart
class ActivityIndicator extends StatelessWidget {
  final ActivityMode mode;
  final VoidCallback onTap;
  const ActivityIndicator({required this.mode, required this.onTap});
  // ... build()
}

// lib/presentation/widgets/dashboard/action_bar.dart
class DashboardActionBar extends StatelessWidget {
  final ActivityMode currentMode;
  final VoidCallback onChangeActivity;
  final VoidCallback onAddFuel;
  // ...
}
```

> [!IMPORTANT]
> **Rule of thumb:** If a `_build*` method takes `BuildContext` + state as parameters, it should be a standalone widget. This enables Flutter's [const](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/backend/src/meals/meals.controller.ts#29-30) constructor optimization, `RepaintBoundary`, and independent testing.

---

### 1.3 CustomPainter Performance — 🔴 CRITICAL: Pixel-by-Pixel Loop

In [liquid_painter.dart:85](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/presentation/widgets/balloon/liquid_painter.dart#L85-L102):

```dart
// PROBLEM: iterates EVERY PIXEL across width (x++)
for (double x = 0; x <= width; x++) {    // 280+ iterations PER LAYER
  final primaryWave = math.sin(...);      // 2 sin() calls per pixel
  final secondaryWave = math.sin(...);
  path.lineTo(x, y);                     // 280+ lineTo calls
}
```

With `waveLayers = 3`, this runs **~840 sin() calculations and ~840 path segments per frame at 60fps** = ~50,400 sin() calls per second. This *will* jank on low-end Android devices.

**Fix — Use Quadratic Bézier Curves Instead of Per-Pixel Sin:**

```dart
void _drawWaveLayer(Canvas canvas, Size size, double baseWaterLevel, int layerIndex) {
  final path = Path();
  path.moveTo(0, size.height);

  // Sample only 4-6 control points instead of width+1 points
  const segments = 4;
  final segmentWidth = size.width / segments;

  for (int i = 0; i <= segments; i++) {
    final x = i * segmentWidth;
    final phase = waveAnimation * 2 * math.pi + layerIndex * (math.pi / 3);
    final y = baseWaterLevel +
        math.sin(x / size.width * 2 * math.pi + phase) * waveHeight;

    if (i == 0) {
      path.lineTo(x, y);
    } else {
      // Smooth curve between control points
      final prevX = (i - 1) * segmentWidth;
      final cpX = (prevX + x) / 2;
      path.quadraticBezierTo(cpX, y, x, y);
    }
  }

  path.lineTo(size.width, size.height);
  path.close();
  canvas.drawPath(path, paint);
}
```

**Impact:** Goes from **~840 sin() per frame → ~15**. The GPU rasterizes Bézier curves natively.

**Additional Optimization — wrap in `RepaintBoundary`:**

```dart
// In liquid_balloon_widget.dart, wrap the CustomPaint:
RepaintBoundary(
  child: CustomPaint(
    painter: LiquidPainter(...),
    size: Size(widget.size - 20, widget.size - 20),
  ),
),
```

---

### 1.4 AnimationController Count — 🟡 MAJOR: Four Tickers on One Widget

[liquid_balloon_widget.dart](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/presentation/widgets/balloon/liquid_balloon_widget.dart#L48-L51) creates **4 AnimationControllers** (`_waveController`, `_fillController`, `_bubbleController`, `_pulseController`), each triggering rebuilds independently.

**Problem:** `Listenable.merge([4 listenables])` fires the builder ~4× as often as needed, since any listener change triggers a full rebuild.

**Fix — Merge wave + bubble into one controller:**

```dart
// Wave and bubble can share the same animation cycle
// They both loop infinitely with different speeds.
// Use a single controller and derive the bubble phase as:
_bubblePhase = (_waveAnimation.value * 0.6666) % 1.0;
```

This drops from 4 tickers → 3, reducing unnecessary rebuilds by ~25%.

---

## 2. Backend & API Design

### 2.1 API RESTfulness — 🟢 MINOR: `POST /auth/me` Should Be `GET`

```
POST /auth/me        ← Not RESTful. GET = idempotent read.
POST /activity/toggle ← "toggle" is an RPC verb, not REST.
```

**Fix:**
```
GET  /auth/me              → Read current user (safe, idempotent)
POST /activity/sessions     → Create a new activity session (RESTful noun)
PATCH /activity/sessions/:id → End a session
```

Not a blocker, but a graduation committee will notice this.

---

### 2.2 GET /energy/status — 🔴 CRITICAL: O(n) Per Poll

[energy.controller.ts:42-118](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/backend/src/energy/energy.controller.ts#L42-L118) re-computes the **entire energy history from scratch** on every `/energy/status` call:

```typescript
// EVERY POLL does this:
const recentMeals = await this.prisma.mealLog.findMany({...}); // DB query
const activityLogs = await this.prisma.activityLog.findMany({...}); // DB query
for (const meal of recentMeals) { ... }    // O(n) loop
```

With 30-second polling × 1000 users = **~2000 full replays per minute**.

**Fix — Cache `lastEnergySnapshot` and compute incrementally:**

```typescript
// 1. Add a "lastSnapshot" column to the User model
//    { volumeRemaining, glycemicIndex, snapshotAt }
//
// 2. On /energy/status, only query events AFTER the snapshot
//
// 3. After computing, update the snapshot in the User record
//
// This turns O(n_all_meals) into O(n_new_meals_since_snapshot)
// which is usually 0-2.
```

Alternatively: Use the existing `EnergySnapshot` model in your schema — it already has `volumeRemaining`, `etcMinutes`, and `snapshotAt` but **is never written to**. Wire it up.

---

### 2.3 JWT Placement — 🟢 Correct as Implemented

Your [JwtAuthGuard](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/backend/src/auth/guards/jwt-auth.guard.ts#4-6) sits as a NestJS Guard, which is industry standard:

```
Request → GlobalExceptionFilter → JwtAuthGuard → Controller → Service
```

The `@CurrentUser()` decorator extracts `userId` from the JWT payload. This is textbook correct. No changes needed here.

**Enhancement for a committee wow:** Add refresh tokens. Your current JWT has no expiry handling — if the token expires, the app silently fails. Add a `/auth/refresh` endpoint that takes a refresh token (stored in `httpOnly` cookie or SecureStorage) and returns a new access token.

---

### 2.4 Prisma Schema Scalability — 🟡 MAJOR: Missing Indexes and Partitioning Strategy

```prisma
model MealLog {
  @@index([userId])
  @@index([createdAt])
  // ❌ Missing compound index for the most common query:
  // "get meals for this user in the last 24 hours"
}
```

**Fix — Add compound indexes:**

```prisma
model MealLog {
  @@index([userId, createdAt])  // Covers the 24-hour window query perfectly
}

model ActivityLog {
  @@index([userId, startTime])  // Same pattern
}
```

**Partitioning note:** For a graduation project, compound indexes are sufficient. In production at >1M rows, you'd partition [MealLog](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/domain/entities/meal.dart#44-115) by `createdAt` (monthly range partitions) and `EnergySnapshot` similarly.

---

### 2.5 EnergySnapshot — 🟡 MAJOR: Exists in Schema but Never Populated

The `EnergySnapshot` model has no foreign key to [User](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/domain/entities/user.dart#4-59) and no service writes to it:

```prisma
model EnergySnapshot {
  userId  String    // ❌ No @relation, no FK constraint
}
```

**Fix:**
```prisma
model EnergySnapshot {
  id              Int      @id @default(autoincrement())
  userId          String
  volumeRemaining Float
  etcMinutes      Int?
  snapshotAt      DateTime @default(now())

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId, snapshotAt])
}
```

And add `energySnapshots EnergySnapshot[]` to the [User](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/domain/entities/user.dart#4-59) model.

---

## 3. Core Logic — The Decay Engine

### 3.1 Formula Analysis — 🟢 Correct, With a Caveat

```
V_remaining = V_start − (R_base × G_index × M_activity × Δt)
```

This is a **linear decay** model. It's mathematically sound and simple to reason about. For a graduation project this is the right choice.

**Caveat — the GI normalization is inconsistent:**

| Location | Normalization |
|---|---|
| Backend [energy.service.ts](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/backend/src/energy/energy.service.ts) line 27 | `glycemicIndex / 100` → 0.01–1.0 |
| Flutter [fuel_state.dart](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/domain/entities/fuel_state.dart) line 14 | `currentGlycemicIndex` stored as 1.0 (coefficient, not raw GI) |
| Flutter [fuel_repository.dart](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/data/repositories/fuel_repository.dart) | [(effectiveGI / 100).clamp(0.01, 1.0)](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/services/auth_service.dart#17-20) |
| Flutter [fuel_bloc.dart](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/presentation/blocs/fuel/fuel_bloc.dart) line 103 | Passes `AppConstants.baseMetabolicRate` = `0.5` |

The backend normalizes `GI / 100`. The app sometimes stores GI as a raw coefficient (1.0 default), sometimes as a percentage. When the app calculates locally with `baseRate=0.5` and `GI=1.0`, the decay rate is `0.5 × 1.0 × 1.0 = 0.5% per minute at rest` — which equals the backend's `0.5 × (50/100) × 1.0 = 0.25%`.

> [!CAUTION]
> **This means the app drains energy ~2× faster than the backend on the same meal.** The GI normalization must be identical. Since the backend's formula divides by 100, the local `currentGlycemicIndex` should always be in the 0.01–1.0 range, not 1.0 as the default.

---

### 3.2 Overlapping Meals — 🟡 MAJOR: App Uses Heuristic, Backend Ignores It

**Backend** ([energy.controller.ts:102](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/backend/src/energy/energy.controller.ts#L102)): After each meal, `effectiveGI = meal.absorptionRate`. This **overwrites** the previous meal's GI rather than blending.

**App** ([fuel_bloc.dart:136-173](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/presentation/blocs/fuel/fuel_bloc.dart#L136-L173)): Uses a weighted average with time-based decay weights. This is more correct.

**The proper model — Meal Queue with Per-Meal Decay:**

Each active meal should be tracked as a separate entity with its own remaining volume:

```
Effective_GI = Σ (meal_i.GI × meal_i.remainingVolume) / Σ meal_i.remainingVolume
```

The **backend already has this method** ([calculateEffectiveGlycemicIndex](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/backend/src/energy/energy.service.ts#124-145) in [energy.service.ts:130-144](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/backend/src/energy/energy.service.ts#L130-L144)) — it just isn't called in the controller. Wire it up:

```typescript
// In energy.controller.ts, replace line 102:
// effectiveGI = meal.absorptionRate;  ← overwrites, wrong

// With:
const activeMeals = recentMeals
  .filter(m => /* still within satiety window */)
  .map(m => ({
    glycemicIndex: m.absorptionRate,
    remainingVolume: this.calculateMealRemaining(m, now),
  }));
effectiveGI = this.energyService.calculateEffectiveGlycemicIndex(activeMeals);
```

---

### 3.3 Time-Drift Protection — 🟢 Well Done

The app's `_lastDecayReferenceTime` + `DateTime.now().difference()` pattern is correct. When the app backgrounds and resumes, it recalculates the full elapsed duration. The server sync then reconciles. Good.

---

## 4. Best Practices & "Gotchas"

### 4.1 Technical Debt Inventory

| # | Debt Item | Location | Impact |
|---|---|---|---|
| 1 | [_openMealCapture()](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/presentation/screens/dashboard/dashboard_screen.dart#297-329) hardcodes a mock meal | [dashboard_screen.dart:300](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/presentation/screens/dashboard/dashboard_screen.dart#L300) | Users never actually use the camera flow |
| 2 | [generateBubbles()](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/presentation/widgets/balloon/liquid_painter.dart#251-262) is a top-level function with a private return type | [liquid_painter.dart:252](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/presentation/widgets/balloon/liquid_painter.dart#L252) | Can't be imported or tested |
| 3 | `LocalStorageService` is called statically everywhere | [fuel_bloc.dart:53](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/presentation/blocs/fuel/fuel_bloc.dart#L53) | Cannot be mocked in tests; violates dependency injection |
| 4 | No error handling in [_onInitialize](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/presentation/blocs/meal/meal_capture_bloc.dart#31-43) | [fuel_bloc.dart:46-79](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/presentation/blocs/fuel/fuel_bloc.dart#L46-L79) | If Hive box is corrupted, the app crashes |
| 5 | [auth_repository.dart](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/data/repositories/auth_repository.dart) never validates JWT expiry locally | — | Expired tokens trigger API calls that always 401 |

> [!WARNING]
> **Debt #3 is the most dangerous.** Every BLoC calls `LocalStorageService()` as a constructor (singleton), making unit testing impossible without a real Hive instance. Inject it via constructor parameter, same as you did with [FuelRepository](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/data/repositories/fuel_repository.dart#7-14).

---

### 4.2 Three Features That Will Wow the Committee

#### Feature 1: Predictive "Energy Forecast" Timeline

Using the decay formula + today's activity log, render a **24-hour forecast chart** showing predicted energy levels:

```
100% ┤████████████▓▓▓▓▓▓▓▓░░░░░░░░────
 50% ┤            ↑ Lunch    ↑ Dinner
  0% ┤─────────────────────────────────
     8am  10am  12pm  2pm  4pm  6pm  8pm
```

**Why it wows:** This is rare in health apps. You have all the math already ([simulateEnergyDrain](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/backend/src/energy/energy.service.ts#189-223)); you just need a `CustomPainter` chart widget and a `ForecastBloc` that simulates future segments.

#### Feature 2: Offline-First Sync with Conflict Resolution

You already have Hive persistence. Make it **primary**:

1. All writes go to Hive first (instant UI update)
2. A `SyncQueue` stores pending API calls as `SyncAction` objects
3. When connectivity returns, replay the queue in order
4. On conflict (server volume ≠ local volume), take the server's value (server is authoritative)

```dart
class SyncAction {
  final String endpoint;
  final String method;
  final Map<String, dynamic> body;
  final DateTime createdAt;
}
```

**Why it wows:** Demonstrates CRDT-like thinking and resilience engineering.

#### Feature 3: Background Fetch + Smart Notification Scheduling

Use `workmanager` (Flutter) to run a periodic background task every 15 minutes:

1. Read [FuelState](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/app/FuelFlow/lib/domain/entities/fuel_state.dart#6-167) from Hive
2. Apply offline decay
3. If projected volume will hit 30% within 30 minutes, schedule a local notification:  
   *"You'll crash in 28 minutes. Current mode: Studying (1.6×). Snack suggestion: banana (GI 51, +25%)"*

**Why it wows:** Proactive alerts that fire even when the app is closed. The "snack suggestion" ties into Gemini AI meal analysis.

---

## Summary — Priority Matrix

| Priority | Fix | Effort |
|---|---|---|
| 🔴 P0 | Fix CustomPainter pixel loop → Bézier curves | 1 hour |
| 🔴 P0 | Fix GI normalization mismatch (app 2× faster than backend) | 30 min |
| 🔴 P0 | Cache energy state; stop O(n) replay on every poll | 2 hours |
| 🟡 P1 | Add compound indexes to Prisma schema | 15 min |
| 🟡 P1 | Wire [calculateEffectiveGlycemicIndex](file:///media/kvreem09/0812F39B12F38BC6/Fundmentals/FuelFlow/backend/src/energy/energy.service.ts#124-145) in backend controller | 1 hour |
| 🟡 P1 | Inject `LocalStorageService` via constructor (testability) | 1 hour |
| 🟡 P1 | Extract dashboard helper methods into standalone widgets | 1 hour |
| 🟡 P1 | Merge wave+bubble AnimationControllers | 30 min |
| 🟡 P1 | Wire `EnergySnapshot` model properly | 30 min |
| 🟢 P2 | Fix `POST /auth/me` → `GET` | 15 min |
| 🟢 P2 | Implement Predictive Timeline feature | 1 day |
| 🟢 P2 | Implement Offline-First Sync Queue | 1 day |
| 🟢 P2 | Implement Background Fetch notifications | 1 day |
