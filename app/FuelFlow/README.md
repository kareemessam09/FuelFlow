# FuelFlow Mobile App (Flutter)

A new Flutter project for the **FuelFlow: Proactive Energy & Metabolism Manager**.

## Getting Started

This project is the frontend client for the FuelFlow system. It connects to the Node.js/NestJS backend to track metabolism and predict energy crashes.

---

## API Documentation (Backend Integration Guide)

**Base URL:** `http://localhost:3000/api` (Development)

### Global Concepts

#### Energy State Object
Many endpoints return an `EnergyState` object. This is the core data the Flutter app needs to drive the "Stomach Balloon" UI.
```json
{
  "volumeRemaining": 75.5, // 0-100%
  "status": "OPTIMAL", // "OPTIMAL" (>60%), "WARNING" (30-60%), "CRITICAL" (<30%)
  "etcMinutes": 120, // Estimated minutes until hitting 30% threshold (null if already below)
  "etcZeroMinutes": 180 // Estimated minutes until hitting 0%
}
```

#### Enums
**ActivityModes:** `Resting`, `Coding`, `Studying`, `GymStrength`, `GymCardio`  
**AbsorptionProfiles:** `Fast`, `Balanced`, `Slow`  
**SensitivityLevels:** `Sensitive`, `Normal`, `Low`  
**TargetGoals:** `Maintenance`, `Bulking`, `Cutting`

---

### 1. User Endpoints

#### Create User
- **Method:** `POST /api/users`
- **Body:**
  ```json
  {
    "email": "user@example.com",
    "name": "John Doe", // Optional
    "sensitivityLevel": "Sensitive", // Optional
    "targetGoal": "Maintenance" // Optional
  }
  ```
- **Response:** Returns the created user object including their `id` (UUID) which you must save locally (e.g., using SharedPreferences) for all subsequent API calls.

#### Get User
- **Method:** `GET /api/users/:id`
- **Response:** Returns user profile along with recent `mealLogs` (last 10) and `activityLogs` (last 5).

---

### 2. Meal Logging ("Snap & Fuel")

#### Upload AI Food Image (Core Feature)
- **Method:** `POST /api/meals/snap`
- **Content-Type:** `multipart/form-data`
- **Body payload:**
  - `userId`: String (UUID)
  - `image`: File (jpeg/png/webp, max 10MB)
- **Response (201 Created):**
  ```json
  {
    "id": 1,
    "userId": "uuid...",
    "foodName": "Avocado Toast",
    "fullnessVolume": 45,
    "absorptionRate": 40,
    "absorptionProfile": "Balanced",
    "estimatedSatiety": 180,
    "createdAt": "2026-03-25T10:00:00Z",
    "energyState": {
      "volumeRemaining": 85.5,
      "status": "OPTIMAL",
      "etcMinutes": 150,
      "etcZeroMinutes": 210
    },
    "aiAnalysis": {
      "confidence": 0.95,
      "notes": "Great source of healthy fats!"
    }
  }
  ```

#### Manual Meal Log
- **Method:** `POST /api/meals/manual`
- **Body:**
  ```json
  {
    "userId": "uuid...",
    "foodName": "Protein Shake",
    "fullnessVolume": 30, // 0-100
    "absorptionRate": 25, // 1-100 (Glycemic Index)
    "absorptionProfile": "Fast",
    "estimatedSatiety": 60
  }
  ```

#### Get Today's Meals
- **Method:** `GET /api/meals/user/:userId/today`
- **Response:** Array of meal objects logged since midnight.

---

### 3. Activity Tracking

#### Toggle Activity Mode
Call this when the user switches what they are doing. The backend handles closing the previous activity automatically.
- **Method:** `POST /api/activity/toggle`
- **Body:**
  ```json
  {
    "userId": "uuid...",
    "modeType": "Studying" // Must match ActivityModes enum
  }
  ```
- **Response:** Returns the new activity log, the updated `energyState`, and an `alertTime` (ISO string) when the Flutter app should schedule a local notification.

#### End Activity (Return to Resting)
- **Method:** `POST /api/activity/end/:userId`
- **Response:** Automatically toggles the user back to `Resting` mode.

#### Get Current Status
- **Method:** `GET /api/activity/status/:userId`
- **Response:**
  ```json
  {
    "currentActivity": {
      "id": 5,
      "modeType": "Studying",
      "multiplier": 1.6,
      "startTime": "2026-03-25T14:00:00Z",
      "durationMinutes": 45
    },
    "energyState": { ... },
    "alertTime": "2026-03-25T16:30:00Z" // Use this for scheduling local notifications
  }
  ```

---

### 4. Energy Sync Engine

#### Sync State
**CRITICAL:** The Flutter app should poll this endpoint when waking up from the background to re-sync its local animation timer with the authoritative backend calculation.
- **Method:** `GET /api/energy/:userId/status`
- **Response:**
  ```json
  {
    "userId": "uuid...",
    "timestamp": "2026-03-25T15:00:00Z",
    "energyState": {
      "volumeRemaining": 62.5,
      "status": "OPTIMAL",
      "etcMinutes": 45,
      "etcZeroMinutes": 125
    },
    "currentActivity": { "modeType": "Coding", "multiplier": 1.3 },
    "effectiveGlycemicIndex": 55,
    "alertTime": "2026-03-25T15:45:00Z",
    "recentMealsCount": 2
  }
  ```

#### Get App Constants
Useful for syncing math variables to the Flutter app's local timer without hardcoding them in Dart.
- **Method:** `GET /api/energy/constants`
- **Response:**
  ```json
  {
    "activityMultipliers": {
      "Resting": 1.0,
      "Coding": 1.3,
      "Studying": 1.6,
      "GymStrength": 3.5,
      "GymCardio": 5.0
    },
    "thresholds": {
      "optimal": 60,
      "warning": 30,
      "critical": 0
    },
    "baseMetabolicRate": 0.5
  }
  ```
