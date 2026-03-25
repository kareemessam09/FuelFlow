# FuelFlow Flutter App - Development Progress

## Project Overview
**FuelFlow** is a proactive energy and metabolism management app that visualizes energy levels as a "Stomach Balloon" and predicts energy crashes using a decay algorithm.

---

## Architecture Summary

### Tech Stack
- **State Management**: BLoC (flutter_bloc)
- **Navigation**: go_router (fluid single-page feel)
- **UI**: Custom widgets with CustomPainter for liquid animations
- **Theme**: Futuristic neon dark theme

### Directory Structure
```
lib/
├── core/
│   ├── constants/       # App colors, constants
│   └── theme/           # App theme configuration
├── data/
│   ├── repositories/    # API repositories (Fuel, Meal)
│   └── datasources/     # Local and remote data sources
├── domain/
│   └── entities/        # Core business entities
├── presentation/
│   ├── blocs/           # BLoC state management
│   │   ├── fuel/        # Core fuel state bloc
│   │   └── meal/        # Meal capture bloc
│   ├── screens/         # App screens
│   │   └── dashboard/   # Main dashboard
│   └── widgets/         # Reusable widgets
│       ├── balloon/     # Liquid balloon widget
│       ├── common/      # Buttons, cards, timer
│       └── overlays/    # Bottom sheets, dialogs
├── router/              # go_router configuration
└── services/            # Notification service
```

---

## Completed Tasks

### Phase 1: Project Setup ✅
- [x] Updated pubspec.yaml with all dependencies
- [x] Created feature-first directory structure
- [x] Set up asset directories

### Phase 2: Core Theme & Constants ✅
- [x] Created `AppColors` with neon color palette
  - Fuel colors: Green (>60%), Yellow (30-60%), Red (<30%)
  - Activity mode colors
  - Glow effects
- [x] Created `AppConstants` with decay algorithm constants
- [x] Created `AppTheme` with futuristic dark theme
  - SpaceGrotesk for UI text
  - RobotoMono for numbers/timers

### Phase 3: Domain Entities & BLoC ✅
- [x] Created domain entities:
  - `FuelState` - Core energy state with decay logic
  - `ActivityMode` - User activity modes with multipliers
  - `MealLog` - Logged meals with AI analysis
  - `User` - User profile and preferences
- [x] Created `FuelBloc` with:
  - Local decay timer (updates every second)
  - Activity mode switching
  - Meal addition (additive, capped at 100%)
  - Server sync support
  - Critical threshold detection
- [x] Created `MealCaptureBloc` for Snap & Fuel feature

### Phase 4: Custom UI Components ✅
- [x] Created `LiquidBalloonWidget` with `CustomPainter`
  - Multi-layer wave animation
  - Dynamic color based on fill percentage
  - Neon glow effects
  - Bubble animations
  - Pulse animation for critical state
- [x] Created common widgets:
  - `NeonButton` - Glowing action buttons
  - `NeonIconButton` - Circular icon buttons
  - `GlassCard` - Glass-morphism cards
  - `CrashTimerWidget` - Time to crash display

### Phase 5: Screens & Overlays ✅
- [x] Created `DashboardScreen`
  - Central balloon visualization
  - Time to crash display
  - Activity mode indicator
  - Quick action buttons
  - Critical alert handling
- [x] Created `ActivitySelectorSheet`
  - All 5 activity modes
  - Multiplier display
  - Smooth selection UI

### Phase 6: Navigation & Repositories ✅
- [x] Set up `go_router` with fluid navigation
  - Dashboard as anchor
  - Overlay-style sub-routes
  - Custom transitions
- [x] Created `FuelRepository` for API integration
- [x] Created `MealRepository` for meal logging

### Phase 7: Services ✅
- [x] Created `NotificationService`
  - Critical energy alerts
  - Refuel reminders
  - iOS/Android support

### Phase 8: Main App ✅
- [x] Wired up `main.dart`
  - BLoC providers
  - Router configuration
  - App lifecycle handling
  - System notification integration

---

## Pending Tasks

### Backend Integration
- [ ] Connect FuelBloc to FuelRepository for actual API calls
- [ ] Connect MealCaptureBloc to MealRepository
- [ ] Implement image upload for Gemini AI analysis
- [ ] Add authentication/user management

### Camera Feature
- [ ] Implement actual camera capture using `camera` package
- [ ] Gallery image selection
- [ ] Image preview and confirmation UI

### Additional Screens
- [ ] Stats/History screen
- [ ] Settings screen
- [ ] Onboarding flow

### Polish
- [ ] Add loading states and error handling
- [ ] Implement offline support with Hive
- [ ] Add unit and widget tests
- [ ] Performance optimization

---

## Key Implementation Details

### Decay Formula
```
V_remaining = V_start - (R_base × G_index × M_activity × Δt)
```
Where:
- `R_base` = 0.5 (base metabolic rate)
- `G_index` = Glycemic index coefficient (from AI analysis)
- `M_activity` = Activity multiplier (1.0 - 5.0)
- `Δt` = Time elapsed in minutes

### Activity Multipliers
| Mode | Multiplier |
|------|------------|
| Resting | 1.0x |
| Coding | 1.3x |
| Studying | 1.6x |
| Gym (Strength) | 3.5x |
| Gym (Cardio) | 5.0x |

### Fuel Level Thresholds
- **Optimal** (Green): >60%
- **Warning** (Yellow): 30-60%
- **Critical** (Red): <30%
- Notification triggers at exactly 30%

---

## How to Run

```bash
cd app/FuelFlow
flutter pub get
flutter run
```

**Note**: Fonts (SpaceGrotesk, RobotoMono) need to be added to `assets/fonts/` or use google_fonts package fallback.

---

## Last Updated
March 25, 2026
