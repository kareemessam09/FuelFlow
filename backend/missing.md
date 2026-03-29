# Missing Features - FuelFlow Backend

Features that should be added for a complete production-ready application.

---


## 📱 Push Notifications

### Notification System
- [ ] **Energy Alert Notifications** - Send push when energy hits 30% threshold
- [ ] **Scheduled Notifications** - Remind users to log meals at regular intervals
- [ ] **Notification Preferences** - Let users configure notification settings
- [ ] **Notification History** - Track sent notifications per user
- [ ] **Batch Notification Service** - Background job to send scheduled alerts

### Implementation
- [ ] **Firebase Admin SDK Integration** - Server-side FCM message sending
- [ ] **Alert Queue System** - Queue alerts based on `alertTime` calculation
- [ ] **Notification Templates** - Configurable message templates

---

## 📊 Analytics & Insights

### User Statistics
- [ ] **Weekly/Monthly Energy Reports** - Aggregate energy patterns over time
- [ ] **Meal Statistics** - Average meals per day, common foods, eating patterns
- [ ] **Activity Statistics** - Time spent in each activity mode per week/month
- [ ] **Goal Progress Tracking** - Track progress toward target goal (bulking/cutting)

### Data Export
- [ ] **Export User Data** - GDPR-compliant data export (JSON/CSV)
- [ ] **Meal History Export** - Download meal logs
- [ ] **Activity History Export** - Download activity logs

---

## 🍽️ Meal Management

### Enhanced Features
- [ ] **Meal Favorites** - Save frequently eaten meals for quick logging
- [ ] **Meal Templates** - Create reusable meal templates
- [ ] **Meal Editing** - Update meal after creation (adjust portion size)
- [ ] **Barcode Scanning** - Integrate with food database API
- [ ] **Nutritional Details** - Calories, macros, micronutrients (beyond GI)
- [ ] **Meal Categories** - Breakfast, lunch, dinner, snack tags

### Food Database
- [ ] **Food Search API** - Search from nutritional database
- [ ] **Custom Foods** - Let users create and save custom food items
- [ ] **Food History** - Quick access to recently logged foods

---

## 🏃 Activity Management

### Enhanced Features
- [ ] **Custom Activity Types** - Let users create custom activities with custom multipliers
- [ ] **Activity Goals** - Set daily/weekly activity targets
- [ ] **Activity Reminders** - Remind to switch activities after X minutes
- [ ] **Auto-Detection** - Integration with wearables/health APIs
- [ ] **Sleep Tracking** - Dedicated sleep mode with different calculations


## 👤 User Management

### Profile Features
- [ ] **Profile Picture Upload** - User avatar support
- [ ] **User Preferences** - Theme, units (metric/imperial), timezone
- [ ] **Onboarding Flow** - Guided setup for new users

---


## 📅 Scheduling & Background Jobs

### Job System
- [ ] **Job Queue (Bull/Agenda)** - Process background tasks
- [ ] **Scheduled Energy Snapshots** - Periodic snapshot updates
- [ ] **Stale Data Cleanup** - Remove old snapshots/logs
- [ ] **Daily Summary Generation** - Pre-compute daily reports

---
