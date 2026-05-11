Perfect combo. Clean white base, warm accent pops — think performance meets precision. Here's your full Claude Code prompt:

---

## Claude Code Prompt: FuelFlow UI/UX

```
You are building FuelFlow — a high-performance metabolic management mobile app. Implement the complete UI/UX across all screens using React Native (Expo) with TypeScript.

---

## DESIGN MANDATE — READ THIS FIRST

**Aesthetic: Clean Clinical Precision with Warm Energy Accents**

This app must NOT look AI-generated or generic. Every screen must feel intentional.

**Palette (CSS/StyleSheet variables — use everywhere consistently):**
- Background: #FAFAFA (off-white, not pure white)
- Surface: #FFFFFF
- Surface Raised: #F4F4F4
- Border: #E8E8E8 (1px, always present — this is what creates the clinical feel)
- Text Primary: #111111
- Text Secondary: #666666
- Text Muted: #AAAAAA
- Accent: #F97316 (orange — primary action color)
- Accent Warm: #DC2626 (red — critical/danger state only)
- Accent Amber: #FBBF24 (amber — warning state only)
- Success: #16A34A (green — optimal state only)

**Typography:**
- Headers + Labels: `DM Sans` (weight 500–700) — clean but characterful
- Numbers, timers, percentages, metrics: `JetBrains Mono` — precise, clinical data feel
- Body text: `DM Sans` weight 400

**Layout rules:**
- Border-radius: 12px for cards, 8px for buttons, 999px for pills/tags
- All cards have 1px solid #E8E8E8 border AND a very subtle shadow: `0 1px 3px rgba(0,0,0,0.06)`
- Generous padding: 20px horizontal screen padding, 16px between cards
- Accent (#F97316) appears ONLY on: primary CTA buttons, active states, the fuel level indicator, and key data points
- Critical state (<30% fuel): swap accent to #DC2626, add a soft red tint (rgba(220,38,38,0.05)) behind the balloon widget
- Warning state (30–60%): accent becomes #FBBF24 amber
- Optimal state (>60%): accent stays #F97316 orange, optionally #16A34A for the balloon fill indicator

**The one thing users will remember:** The Fuel Balloon — a clean SVG ring/arc that fills clockwise like a radial progress indicator. No gradients. The arc color shifts: green (optimal) → amber (warning) → red (critical). The background track is #E8E8E8. Very precise, very satisfying.

---

## PROJECT STRUCTURE

```
/app
  /(auth)
    login.tsx
    register.tsx
    forgot-password.tsx
  /(onboarding)
    sensitivity.tsx       ← Sensitive / Normal / Low
    goal.tsx              ← Maintenance / Bulking / Cutting
    timezone.tsx
    units.tsx             ← Metric / Imperial
  /(tabs)
    index.tsx             ← Dashboard (main hub)
    meals.tsx             ← Meal history + favorites
    analytics.tsx         ← Energy overview + activity breakdown
    profile.tsx           ← Settings + profile
  /meal-log
    camera.tsx            ← Full-screen camera + AI scanning overlay
    confirm.tsx           ← AI result confirmation screen
    manual.tsx            ← Natural language text input
  /medications
    index.tsx             ← Medication list
    add.tsx               ← Add/edit medication
    schedule.tsx          ← Reminders & recurring schedule
  /activity
    goals.tsx             ← Create and track activity goals
/components
  BalloonWidget.tsx       ← Core SVG radial fuel ring
  CrashTimer.tsx          ← JetBrains Mono countdown
  ActivitySelector.tsx    ← Bottom sheet mode switcher
  EnergyInsightsSheet.tsx ← Bottom sheet with stats + tips
  MedIntercept.tsx        ← Pre-meal medication gate dialog
  FuelLogCard.tsx         ← Meal log list item
  MetricCard.tsx          ← Reusable analytics card
  PillBadge.tsx           ← State pills (OPTIMAL / WARNING / CRITICAL)
/constants
  theme.ts                ← All colors, spacing, font sizes as constants
  multipliers.ts
/hooks
  useMetabolicEngine.ts
  useDecaySimulator.ts
/store
  fuelStore.ts            ← Zustand
  medStore.ts
  activityStore.ts
```

---

## CORE ENGINE — useMetabolicEngine.ts

```ts
type ActivityMode = 'resting' | 'coding' | 'studying' | 'gym_strength' | 'gym_cardio'

const MULTIPLIERS: Record<ActivityMode, number> = {
  resting: 1.0,
  coding: 1.3,
  studying: 1.6,
  gym_strength: 3.5,
  gym_cardio: 5.0,
}

// BASE_RATE: 100% → 0% in 4 hours at resting (1.0x)
// Decay tick: every 30 seconds via setInterval
// Thresholds: Optimal >60% | Warning 30–60% | Critical <30%
// Offline-first: read lastFuelLevel + lastTimestamp from MMKV on mount,
//   calculate elapsed decay immediately before first server sync
// Hook exposes: fuelLevel, fuelState, minutesToCritical, activeMode, setMode, addFuel(volume: number)
```

---

## SCREEN SPECS

### 1. Dashboard — app/(tabs)/index.tsx

Top to bottom layout:
```
[Header]
  Left: "FuelFlow" in DM Sans 700, #111
  Right: notification bell icon + avatar circle (32px)

[State Pill]
  Centered pill badge: "● OPTIMAL" / "● WARNING" / "● CRITICAL"
  Colors: green / amber / red text on matching 8% opacity background
  Font: DM Sans 600, 12px, letter-spacing 0.08em

[BalloonWidget — center hero]
  240×240 SVG radial ring
  Track ring: #E8E8E8, stroke-width 12
  Fuel arc: color based on state, stroke-width 12, stroke-linecap round
  Inner content:
    - JetBrains Mono 48px bold: "73%"
    - DM Sans 13px #666: "fuel remaining"
  Tap → opens EnergyInsightsSheet

[CrashTimer]
  Card with 1px border
  Label: "TIME TO CRASH" DM Sans 500 11px #AAA uppercase
  Value: JetBrains Mono 32px #111: "1h 47m"
  When critical: value turns #DC2626

[Activity Mode Card]
  Label: "CURRENT MODE" uppercase 11px muted
  Row: icon + "Coding" DM Sans 600 + "1.3× burn" in accent color
  Right: "CHANGE" text button in accent color
  Tap → opens ActivitySelector bottom sheet

[Action Row]
  Two full-width buttons, side by side:
  [ADD FUEL] — filled, accent #F97316, DM Sans 700, 16px
  [MEDS] — outlined, 1px accent border, accent text
```

### 2. ActivitySelector Bottom Sheet
- Drag handle at top
- Title: "SELECT MODE"
- 5 rows, each with: icon | mode name (DM Sans 600) | multiplier pill ("3.5×") right-aligned
- Active row: left 3px accent border + accent text on multiplier pill
- Modes: Resting 🛋 / Coding 💻 / Studying 📖 / Gym Strength 🏋 / Gym Cardio 🏃

### 3. EnergyInsightsSheet Bottom Sheet
- Stat grid (2×2):
  - Current Mode | Fuel Level
  - Time to Critical | GI Index (last meal)
- Contextual tip card at bottom: light #FFF7ED background, orange left border 3px, italic tip text
- "ADD FUEL" button at very bottom

### 4. Meal Logging — Snap & Fuel

**camera.tsx:**
- Full-screen camera, no chrome
- Bottom overlay (frosted, white 80% opacity):
  - "SNAP & FUEL" label
  - Shutter button: 72px circle, #F97316 fill, white camera icon
  - "Manual Entry" text link below
- While scanning: animated horizontal scan line (#F97316, 2px) traverses the frame top→bottom on loop. Pulsing "ANALYZING..." text in JetBrains Mono below shutter

**confirm.tsx:**
- Header: food name detected (e.g., "Chicken Rice Bowl") DM Sans 700 24px
- Stats row: Fullness% | GI Score | Calories — each in a bordered card
- Macros breakdown: P / C / F as horizontal bar segments (accent color portions)
- Two buttons: [CONFIRM LOG] filled | [RETAKE] outlined
- Editable fullness slider at top (if user wants to adjust AI estimate)

**manual.tsx:**
- Large text input, DM Sans, placeholder: "Describe your meal... (e.g. two eggs and brown toast)"
- "ANALYZE" button below
- Recent suggestions as pill chips below input

### 5. Medication Intercept — MedIntercept.tsx
- Modal dialog, white card, 12px radius, subtle shadow
- Warning icon (amber) at top center
- Title: "Medication Required" DM Sans 700
- Body: "You have medications to take before this meal."
- List of pending meds with checkbox rows — check each off to enable logging
- Disabled [LOG MEAL] button → becomes active (#F97316) when all meds checked
- [SKIP] text button bottom right (secondary, muted color)

### 6. Analytics — app/(tabs)/analytics.tsx
- Time toggle: TODAY / WEEK / MONTH — pill tabs, active has accent fill
- Energy Overview cards (2×2 grid):
  - Avg Energy Level (big % + JetBrains Mono)
  - Time in Optimal (green accent time value)
  - Time in Warning (amber)
  - Time in Critical (red)
- Activity Breakdown: horizontal stacked bar showing time split across modes, each mode labeled below with time in JetBrains Mono
- Activity Goals section: each goal as a card with progress bar (accent fill), e.g. "Coding — 73/120 min"

### 7. Auth Screens
- Clean, lots of white space
- Logo centered top third
- Input fields: 1px #E8E8E8 border, 12px radius, DM Sans, focus state: 1px #F97316 border
- Primary button: full-width, #F97316, DM Sans 700
- Google OAuth: outlined button, Google logo left-aligned, same full width
- "Forgot password?" right-aligned text link in accent

### 8. Onboarding
- Progress indicator: 4 dots at top, filled = accent color
- One choice per screen — large tap targets (full-width option cards with 1px border)
- Selected card: accent border (2px), light accent background (#FFF7ED)
- Each card: icon + label + optional sublabel
- "CONTINUE" button at bottom, disabled until selection made

### 9. Profile & Settings — app/(tabs)/profile.tsx
- Avatar circle 72px + name + email header
- Grouped settings list (like iOS Settings):
  - Section headers: uppercase 11px DM Sans muted
  - Rows: label left, value/toggle right, 1px bottom border between rows
  - Toggles: accent color when on
- Sections: Notifications | Preferences | Activity | Account

---

## COMPONENT IMPLEMENTATION DETAILS

### BalloonWidget.tsx
```tsx
// SVG radial progress ring
// Props: fuelLevel (0-100), size (default 240)
// Calculate: strokeDasharray = circumference, strokeDashoffset based on fuelLevel
// Arc color: fuelLevel > 60 → #16A34A | 30-60 → #FBBF24 | <30 → #DC2626
// Animate strokeDashoffset change with react-native-reanimated (duration 800ms, easing.out)
// When critical: add Animated pulsing glow (opacity 0.3→1→0.3, 1.5s loop) behind the ring
// Center text updates with animated number roll (reanimated)
```

### CrashTimer.tsx
```tsx
// Displays minutesToCritical from useMetabolicEngine
// Format: "Xh Ym" if >60min, "Xm" if <60min, "CRITICAL" if <5min
// Font: JetBrains Mono
// Color: #111 normally, #DC2626 when critical
// Add subtle animated blinking on the colon separator when <15 minutes remaining
```

---

## NAVIGATION

Use Expo Router file-based routing.
Tab bar: 4 tabs — Dashboard (home icon) | Meals (fork icon) | Analytics (chart icon) | Profile (person icon)
Tab bar style: white background, 1px top border #E8E8E8, active tab icon in #F97316, inactive in #AAA. No labels. Clean.

---

## STATE MANAGEMENT

Zustand stores for:
- fuelStore: fuelLevel, activeMode, lastMealTimestamp, addFuel(), setMode()
- medStore: medications[], pendingMeds[], logMedication()
- activityStore: goals[], activeGoals, logActivity()

Use MMKV for offline persistence (expo-community-flipper or @legendapp/state with MMKV adapter).

---

## PACKAGES TO INSTALL
```
expo, expo-router, expo-camera, react-native-reanimated,
react-native-gesture-handler, react-native-safe-area-context,
zustand, react-native-mmkv, @gorhom/bottom-sheet,
expo-notifications, expo-font, @expo-google-fonts/dm-sans,
@expo-google-fonts/jetbrains-mono
```

---

## QUALITY RULES
- No purple gradients, no Inter font, no generic card shadows
- Every empty state has a purposeful illustration or icon — never just text alone
- All loading states use skeleton screens (grey animated shimmer on #F4F4F4 bg), never spinners
- All transitions: 200–300ms, ease-out. Never jarring.
- Haptic feedback on: ADD FUEL confirm, medication check-off, activity mode change
- The app should feel fast. Optimistic UI updates everywhere — update store first, sync server second.
```

---

Paste this directly into Claude Code. It gives it the full picture: design system, component logic, screen-by-screen specs, and the exact technical stack — precise enough that it won't make generic decisions, but open enough that it can execute intelligently.