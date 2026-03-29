# FuelFlow Backend Implementation Plan
**Target Agent:** Claude (or executing agent)
**Stack:** NestJS, TypeScript, PostgreSQL, Prisma, Gemini 1.5 Flash API
**Status:** COMPLETED

## Global Execution Directives
1. **Autonomous Execution:** Execute all phases sequentially (Phase 0 through Phase 6) without stopping, unless a critical error requires user intervention.
2. **Compaction Tracking:** Update `backend/PROGRESS.md` after EVERY completed step to maintain context and track the current phase.
3. **Version Control:** Create a local Git commit (`git add . && git commit -m "..."`) after completing each major Phase. **DO NOT PUSH** to any remote repository.

---

## Phase 0: Compaction & Git Setup
- [x] Initialize Git repository in the `backend/` directory via `git init`.
- [x] Create `backend/PROGRESS.md` to track completed tasks, current state, and next steps.
- [x] Create `backend/PLAN.md` with full implementation details.

## Phase 1: Project Initialization & Infrastructure (NestJS)
- [x] Generate NestJS application: `npx @nestjs/cli new . --strict --package-manager npm`.
- [x] Install runtime dependencies: `@prisma/client`, `@google/generative-ai`, `multer`, `class-validator`, `class-transformer`.
- [x] Install dev dependencies: `prisma`, `@types/multer`.
- [x] Enable CORS and Global Validation Pipes in `src/main.ts`.
- [x] **Update `PROGRESS.md`**
- [x] **COMMIT:** `chore: initialize nestjs project and install dependencies`

## Phase 2: Database & Prisma Setup
- [x] Initialize Prisma (`npx prisma init`).
- [x] Define the schema in `prisma/schema.prisma` (User, MealLog, ActivityLog, EnergySnapshot).
- [x] Generate Prisma Client (v7.5.0).
- [x] Generate a Prisma Module & Service (`npx nest g module prisma`, `npx nest g service prisma`).
- [x] Implement `PrismaService` extending `PrismaClient` and hook into `onModuleInit`.
- [x] **Update `PROGRESS.md`**
- [x] **COMMIT:** `feat: setup prisma schema, migration, and nestjs prisma service`

## Phase 3: Core Algorithm Engine (The Math)
- [x] Generate Energy Module & Service (`npx nest g module energy`, `npx nest g service energy`).
- [x] Implement `calculateRemainingVolume` (V_remaining formula) and cap fullness at 100%.
- [x] Implement `calculateETC` (Estimated Time to Crash).
- [x] Write Jest unit tests for `EnergyService` (26 tests, all passing).
- [x] **Update `PROGRESS.md`**
- [x] **COMMIT:** `feat: implement core energy decay algorithm and unit tests`

## Phase 4: AI Vision Integration (Snap & Fuel)
- [x] Generate Gemini Module & Service (`npx nest g module gemini`, `npx nest g service gemini`).
- [x] Setup Google Generative AI client using `process.env.GEMINI_API_KEY`.
- [x] Write the system prompt and enforce JSON schema for food analysis.
- [x] Implement graceful degradation when API unavailable.
- [x] **Update `PROGRESS.md`**
- [x] **COMMIT:** `feat: integrate gemini vision api for food analysis`

## Phase 5: API Endpoints (Controllers & DTOs)
- [x] Generate Users Resource (`npx nest g resource users` - REST API).
- [x] Generate Meals Resource (`npx nest g resource meals` - REST API).
  - [x] Implement `POST /meals/snap` using `@UseInterceptors(FileInterceptor('image'))`.
  - [x] Wire up `GeminiService` for analysis and `EnergyService` to calculate new fullness.
  - [x] Save to DB via `PrismaService`.
- [x] Generate Activity Resource (`npx nest g resource activity` - REST API).
- [x] Add `GET /energy/:userId/status` to `EnergyController`.
- [x] Ensure DTOs use `class-validator` decorators.
- [x] **Update `PROGRESS.md`**
- [x] **COMMIT:** `feat: build rest endpoints, dtos, and controllers`

## Phase 6: Polish & Documentation
- [x] Add global exception filter (`AllExceptionsFilter`).
- [x] Add health check endpoint (`GET /api/health`).
- [x] Add API info endpoint (`GET /api`).
- [x] Final update of `PROGRESS.md`.
- [x] **COMMIT:** `chore: final backend polish and validation`

---

## Core Algorithm Reference

### Digestion Decay Formula
```
V_remaining = V_start - (R_base * G_index * M_activity * delta_t)
```

Where:
- `V_start`: Initial fullness percentage (0-100%).
- `R_base`: Base metabolic rate (0.5% per minute baseline).
- `G_index`: Digestion speed coefficient from AI (1-100, normalized to 0.01-1.0).
- `M_activity`: Current user mode multiplier.
- `delta_t`: Time elapsed in minutes since last state change.

### Activity Multipliers
| Mode           | Multiplier | Description                    |
|----------------|------------|--------------------------------|
| Resting        | 1.0x       | Sedentary or light movement    |
| Coding         | 1.3x       | Sustained cognitive load       |
| Studying       | 1.6x       | High-intensity focus/memory    |
| Gym (Strength) | 3.5x       | Anaerobic/weightlifting        |
| Gym (Cardio)   | 5.0x       | Maximum energy burn rate       |

### Energy Thresholds
- **Green (>60%):** Optimal State
- **Yellow (30-60%):** Warning - Refuel soon
- **Red (<30%):** CRITICAL - High risk of energy crash
