This master specification document outlines the complete feature set for **FuelFlow**, a high-performance metabolic management system designed to prevent energy crashes through proactive modeling and AI.

---

# FuelFlow: Project Master Specification

## 1. Visual Identity & UX (The Swiss-Minimalist Aesthetic)
The application follows a strict **High-Contrast Minimalism** style to distinguish itself from generic AI-generated interfaces.
* **Palette:** Pure Black (`#000000`), Pure White (`#FFFFFF`), and minimal Grey shades for structural borders.
* **Typography:** Space Grotesk for headers and Roboto Mono for data-heavy metrics and timers.
* **Grid System:** Brutalist, 1px/2px solid borders, and sharp 4px radii instead of over-rounded corners.
* **Visual Texture:** The "Stomach Balloon" uses stroke weight and patterns (solid, dotted, slashed) instead of colors to indicate status.

---

## 2. The Core Engine: Metabolic Decay Logic
The system treats the stomach as a dynamic fuel tank where volume decreases based on biological and cognitive load.
* **The Formula:** $V_{remaining} = V_{start} - (R_{base} \times G_{index} \times M_{activity} \times \Delta t)$.
* **Normalization:** $G_{index}$ (Glycemic Index) is standardized between $0.01$ and $1.0$.
* **Base Metabolic Rate ($R_{base}$):** Set at $0.5\%$ per minute.
* **Activity Multipliers ($M_{activity}$):**
    * Resting: $1.0x$
    * Coding: $1.3x$
    * Studying: $1.6x$
    * Gym (Strength): $3.5x$
    * Gym (Cardio): $5.0x$

---

## 3. Multimodal Fuel Logging (Snap & Fuel)
A hybrid input system that utilizes Gemini 1.5 Flash for instant metabolic analysis.
* **Image Analysis:** Users snap a photo; the AI identifies food items, estimates volume, and assigns a $G_{index}$.
* **Natural Language Input:** Users can type descriptions (e.g., "Two eggs and brown toast") which are processed by the same AI pipeline.
* **Weighted GI Average:** If multiple meals are consumed, the system calculates an effective GI based on the remaining volume of overlapping meals.

---

## 4. Contextual Medication Tracking
Medication management is directly linked to the eating cycle to ensure safety and stability.
* **Meal-Relation Logic:** Medications are categorized as "Before" or "After" specific meals (Breakfast, Lunch, Dinner, or Any).
* **Contextual Intercepts:**
    * **Pre-Meal:** If a "Before" med is required, the app blocks the meal log until the medication is confirmed.
    * **Post-Meal:** Automatically schedules a reminder 30 minutes after a meal log is completed.
* **Relational Logs:** Every `MedicationLog` is optionally linked to a specific `MealId` for long-term stability analysis.

---

## 5. Performance & Sync Architecture (Zero-Drift)
Designed for high efficiency and O(1) performance at scale.
* **EnergySnapshots:** The backend saves snapshots after every event (meal/activity) to prevent re-calculating the entire history on every poll.
* **Zero-Drift Sync:** The Flutter client resets its `_lastDecayReferenceTime` after every server sync to prevent "volume jumps".
* **App Resumption:** On resume, the BLoC applies offline decay for instant UI feedback followed by an immediate server reconciliation.

---

## 6. Proactive Safety & Notifications
* **Threshold States:** Optimal ($>60\%$), Warning ($30-60\%$), and Critical ($<30\%$).
* **AlertTime Calculation:** The backend returns a precise `alertTime` for background notifications, predicting exactly when the user will hit the $30\%$ "Crash Zone" based on their current activity.
* **Critical UI:** A pulsing B&W strobe effect or inverted colors when the balloon reaches the Critical state.

---

## 7. Technical Stack
* **Frontend:** Flutter (BLoC state management, Layer-first architecture).
* **Backend:** Node.js/NestJS.
* **Database:** PostgreSQL with Prisma ORM (Compound indexes on `userId` and `createdAt`).
* **AI:** Multimodal Gemini 1.5 Flash.



[Image of the human digestive system]


This configuration supports the unique health needs of kimo, a final-year CS student at Suez Canal University working on the Studyfy graduation project.

How would you like to handle the "Offline-First" sync queue for those moments when you lose connection during a gym session?