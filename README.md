Here is the complete, professional **FuelFlow** documentation in Markdown format. You can copy and paste this directly into a `README.md` file or send it to an AI agent to set the stage for your development.

---

# FuelFlow: Proactive Energy & Metabolism Manager
**Project Status:** Specification & Architecture Phase  
**Target Platform:** Mobile (iOS/Android)  
**Primary Goal:** Prevent "Energy Crashes" through predictive metabolic modeling and AI-driven visual food logging.

---

## 1. Project Vision
**FuelFlow** is not a standard calorie counter. It is a **Human Fueling System** designed for users who experience sudden fatigue or "crashes" (hypoglycemia symptoms) when they miss a meal. By treating the stomach as a dynamic fuel tank—visualized as a **Stomach Balloon**—the app predicts energy depletion in real-time based on activity levels and food composition.

---

## 2. Technical Stack
* **Frontend:** Flutter (State Management: BLoC or Provider)
* **Backend:** Node.js (Express or NestJS)
* **AI Engine:** Gemini 1.5 Flash API (Image Analysis)
* **Database:** PostgreSQL (with Prisma ORM)
* **Infrastructure:** Redis (Optional: for real-time state caching)

---

## 3. The Core Algorithm: Digestion Decay
The app calculates the **Estimated Time to Crash (ETC)** using a dynamic decay formula. The volume of the "Balloon" ($V$) decreases based on the **Glycemic Index** ($G$) of the food and the **Activity Multiplier** ($M$).

$$V_{remaining} = V_{start} - (R_{base} \cdot G_{index} \cdot M_{activity} \cdot \Delta t)$$

Where:
* $V_{start}$: Initial fullness percentage (0–100%).
* $R_{base}$: Base metabolic rate (constant).
* $G_{index}$: Digestion speed coefficient (Calculated by AI).
* $M_{activity}$: Current user mode multiplier.
* $\Delta t$: Time elapsed since the last state change.

### **Activity Multipliers ($M_{activity}$)**
The user manually toggles their current state to adjust the "Drain" speed:

| Mode | Multiplier | Description |
| :--- | :--- | :--- |
| **Resting** | $1.0x$ | Sedentary or light movement. |
| **Coding** | $1.3x$ | Sustained cognitive load. |
| **Studying** | $1.6x$ | High-intensity focus/memory tasks (high glucose drain). |
| **Gym (Strength)** | $3.5x$ | Anaerobic/weightlifting depletion. |
| **Gym (Cardio)** | $5.0x$ | Maximum energy burn rate. |

---

## 4. Feature Specifications

### **A. Snap & Fuel (AI Visual Logging)**
Users take a photo of their meal. The Node.js backend sends the image to Gemini 1.5 Flash to extract:
* **Absorption Profile:** (Fast, Balanced, or Slow-Release).
* **Glycemic Index:** A value between 1–100.
* **Estimated Satiety:** How many minutes this meal will last at a $1.0x$ burn rate.

### **B. The Stomach Balloon UI**
A custom Flutter widget that visually represents current energy levels:
* **Green (>60%):** Optimal State.
* **Yellow (30–60%):** Warning: Refuel soon.
* **Red (<30%):** **CRITICAL:** High risk of an energy crash.

### **C. Proactive "Safety Buffer" Alerts**
The app does not wait for 0%. It triggers a high-priority notification at the **30% threshold**:
> *"Energy levels dropping. Current mode: [Study]. Your energy will hit the red zone in 20 minutes. Suggestion: Consume 15g of sustained carbs (e.g., Nuts or Protein Bar) now."*

---

## 5. Data Model (Prisma/PostgreSQL)

```prisma
model User {
  id                String         @id @default(uuid())
  sensitivityLevel  String         @default("Sensitive") // High-priority alerts
  targetGoal        String         // Maintenance, Bulking, Cutting
  mealLogs          MealLog[]
  activityLogs      ActivityLog[]
}

model MealLog {
  id              Int      @id @default(autoincrement())
  userId          String
  foodName        String
  fullnessVolume  Float    // Estimated balloon fill %
  absorptionRate  Float    // G_index
  imageUrl        String?
  createdAt       DateTime @default(now())
}

model ActivityLog {
  id          Int       @id @default(autoincrement())
  userId      String
  modeType    String    // Study, Gym, Coding, etc.
  multiplier  Float
  startTime   DateTime  @default(now())
  endTime     DateTime?
}
```

---

## 6. Instructions for AI Agent
When assisting with code generation:
1.  **Architecture:** Keep the **Decay Logic** isolated in a backend service so it can be recalculated on every activity toggle.
2.  **Flutter UI:** Use `CustomPainter` for the Balloon animation to allow for fluid level changes.
3.  **Real-time:** Ensure the Flutter app uses a local timer to update the UI balloon level even when the server isn't being polled.
4.  **Edge Cases:** Handle "Multiple Meals"—if a user eats a snack while the balloon is at 40%, the new $V_{start}$ should be calculated additively but capped at 100%.

---

**Would you like me to generate the first set of Node.js routes to handle the Image-to-AI analysis part?**
