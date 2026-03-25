# FuelFlow Audit Fix Progress

**Started:** 2026-03-25
**Status:** COMPLETED

---

## P0-1: CustomPainter Bezier Refactor
| Task | Status | Completed |
|------|--------|-----------|
| Rewrite _drawWaveLayer with quadratic Bezier curves | DONE | 2026-03-25 |
| Wrap CustomPaint widgets in RepaintBoundary | DONE | 2026-03-25 |
| Verify shouldRepaint remains optimized | DONE | 2026-03-25 |

**Notes:** The codebase already had the Bezier implementation in place. Verified:
- `liquid_painter.dart:86` uses 6 control points with quadratic Bezier curves
- `liquid_balloon_widget.dart:221-245` wraps CustomPaint widgets in RepaintBoundary
- `shouldRepaint` properly checks all relevant properties

---

## P0-2: GI Normalization Mismatch (2x drain fix)
| Task | Status | Completed |
|------|--------|-----------|
| Normalize currentGlycemicIndex in fuel_state.dart to 0.01-1.0 range | DONE | 2026-03-25 |
| Update _onTick in fuel_bloc.dart to match backend normalization | DONE | 2026-03-25 |
| Update addFuel() to normalize incoming GI values | DONE | 2026-03-25 |
| Update FuelState.initial() default GI from 1.0 to 0.5 | DONE | 2026-03-25 |

**Changes Made:**
- `fuel_state.dart`: Updated `FuelState.initial()` to use `currentGlycemicIndex: 0.5` (was 1.0)
- `fuel_state.dart`: Updated `addFuel()` to normalize raw GI (1-100) to coefficient (0.01-1.0)
- `fuel_bloc.dart`: Updated `_calculateWeightedGlycemicIndex()` to return normalized values (0.01-1.0)
- Added documentation clarifying the normalization convention

---

## P0-3: Backend Snapshot Caching
| Task | Status | Completed |
|------|--------|-----------|
| Add User relation + FK to EnergySnapshot in schema.prisma | DONE | 2026-03-25 |
| Add compound indexes to MealLog and ActivityLog | DONE | 2026-03-25 |
| Add snapshot save logic to EnergyService | DONE | 2026-03-25 |
| Refactor GET /energy/status to delta-compute from last snapshot | DONE | 2026-03-25 |

**Changes Made:**
- `schema.prisma`: Added `user` relation and `onDelete: Cascade` to EnergySnapshot
- `schema.prisma`: Added `@@index([userId, createdAt])` to MealLog
- `schema.prisma`: Added `@@index([userId, startTime])` to ActivityLog
- `schema.prisma`: Added `glycemicIndex` field and `@@index([userId, snapshotAt])` to EnergySnapshot
- `energy.service.ts`: Added `getLatestSnapshot()`, `saveSnapshot()`, `calculateMealRemainingVolume()`
- `energy.controller.ts`: Implemented delta-computation from snapshots with 5-minute TTL

---

## P1-4: Overlapping Meals (Weighted GI)
| Task | Status | Completed |
|------|--------|-----------|
| Wire calculateEffectiveGlycemicIndex into energy.controller.ts | DONE | 2026-03-25 |
| Add per-meal remaining volume calculation | DONE | 2026-03-25 |
| Return effectiveGlycemicIndex in the response | DONE | 2026-03-25 |

**Changes Made:**
- `energy.controller.ts`: Added `calculateWeightedGI()` private method that:
  1. Fetches active meals within 6-hour window
  2. Calculates remaining volume for each meal using `calculateMealRemainingVolume()`
  3. Calls `calculateEffectiveGlycemicIndex()` with weighted meal data
- Response now includes `effectiveGlycemicIndex` field
- Added `usedDeltaComputation` flag to response for debugging

---

## Commit History
| Commit | Description | Date |
|--------|-------------|------|
| (pending) | P0-2 + P0-3 + P1-4: GI normalization, snapshot caching, weighted GI | 2026-03-25 |

---

## Files Modified

### Flutter (app/FuelFlow/lib/)
- `domain/entities/fuel_state.dart` - GI normalization fixes
- `presentation/blocs/fuel/fuel_bloc.dart` - Weighted GI normalization

### Backend (backend/)
- `prisma/schema.prisma` - EnergySnapshot FK, compound indexes
- `src/energy/energy.service.ts` - Snapshot methods, meal remaining calculation
- `src/energy/energy.controller.ts` - Delta-computation, weighted GI integration

---

## Summary

All P0 and P1 tasks from the audit have been completed:

1. **Performance** (P0-1): Bezier curves and RepaintBoundary were already in place
2. **Correctness** (P0-2): GI normalization now consistent between app and backend (0.01-1.0 range)
3. **Scalability** (P0-3): Energy status endpoint now uses O(1) delta-computation instead of O(n) replay
4. **Accuracy** (P1-4): Overlapping meals use proper weighted GI calculation based on remaining volume
