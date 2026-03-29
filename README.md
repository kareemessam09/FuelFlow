# 🔥 FuelFlow - Energy Management App

<div align="center">

![FuelFlow Logo](https://img.shields.io/badge/FuelFlow-Energy%20Management-B21235?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-3.x-149BCC?style=for-the-badge&logo=flutter)
![NestJS](https://img.shields.io/badge/NestJS-TypeScript-FF5672?style=for-the-badge&logo=nestjs)
![Status](https://img.shields.io/badge/Status-Production%20Ready-0985B2?style=for-the-badge)

**Track your energy levels, optimize meal timing, and stay in your flow state.**

[Features](#-features) • [Screenshots](#-screenshots) • [Installation](#-installation) • [Architecture](#-architecture) • [API Docs](#-api-documentation)

</div>

---

## 🌟 Features

### Core Features
- 🎈 **Real-Time Energy Tracking**: Visual balloon metaphor that shrinks as energy depletes
- 📸 **AI Meal Analysis**: Gemini AI analyzes food photos for instant nutritional insights
- ⚡ **Activity Modes**: 6 modes from Resting (0.5x) to High-Intensity (3.0x) energy consumption
- ⏰ **Crash Prediction**: Real-time countdown to energy crash with critical alerts
- 📊 **Analytics Dashboard**: Weekly/monthly reports, meal stats, goal tracking
- ⭐ **Favorites Management**: Save meals, templates, and custom foods for quick logging
- 🔔 **Smart Notifications**: Critical energy alerts and meal reminders
- 🎨 **Beautiful UI**: Vibrant 5-color theme with gradients and modern design

### Technical Features
- ✅ **Offline Support**: Hive-based local caching
- ✅ **JWT Authentication**: Secure token-based auth with auto-refresh
- ✅ **Material 3 Design**: Modern, accessible UI components
- ✅ **BLoC Pattern**: Clean state management architecture
- ✅ **Repository Pattern**: Testable data layer
- ✅ **Clean Architecture**: Separation of concerns
- ✅ **Real-time Sync**: Background sync with server

---

## 🎨 Color Theme

The app features a vibrant, energy-inspired color palette:

| Color | Hex | Usage |
|-------|-----|-------|
| 🔴 **Primary Red** | `#B21235` | Critical alerts, primary actions |
| 🟡 **Bright Yellow** | `#FFF66B` | Warnings, energy mid-level |
| 🩷 **Pink/Coral** | `#FF5672` | Secondary actions, highlights |
| 🩵 **Cyan** | `#149BCC` | Success, optimal energy |
| 💙 **Teal** | `#0985B2` | Resting state, subtle accents |

---

## 📱 Screenshots

### Main Screens
```
┌─────────────┬─────────────┬─────────────┬─────────────┐
│  Dashboard  │ Meal Capture│   History   │  Analytics  │
│             │             │             │             │
│   Energy    │   Gemini    │   Today &   │   Weekly    │
│   Balloon   │     AI      │   All Time  │   Reports   │
│             │             │             │             │
└─────────────┴─────────────┴─────────────┴─────────────┘
```

### Additional Screens
```
┌─────────────┬─────────────┬─────────────┬─────────────┐
│  Favorites  │  Settings   │   Profile   │    Auth     │
│             │             │             │             │
│  Meals &    │ Preferences │   Stats &   │   Login &   │
│  Templates  │   & Prefs   │   Actions   │  Register   │
│             │             │             │             │
└─────────────┴─────────────┴─────────────┴─────────────┘
```

---

## 🚀 Installation

### Prerequisites
- **Flutter SDK**: 3.10 or higher
- **Node.js**: 18 or higher
- **PostgreSQL**: 14 or higher
- **Android Studio** or **Xcode**

### Backend Setup

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your database credentials and Gemini API key

# Run database migrations
npx prisma migrate dev

# Generate Prisma client
npx prisma generate

# Start development server
npm run start:dev

# Backend runs on http://localhost:3000
```

### Flutter App Setup

```bash
# Navigate to Flutter app directory
cd app/FuelFlow

# Install dependencies
flutter pub get

# Update API base URL
# Edit lib/core/constants/constants.dart
# Change baseUrl to your backend URL

# Run on emulator/device
flutter run

# Or build APK
flutter build apk --release
```

### Environment Variables

**Backend `.env`:**
```env
DATABASE_URL="postgresql://user:password@localhost:5432/fuelflow"
JWT_SECRET="your-secret-key-here"
GEMINI_API_KEY="your-gemini-api-key"
PORT=3000
```

**Flutter `constants.dart`:**
```dart
static const String baseUrl = 'http://YOUR_IP:3000';
// Use 10.0.2.2 for Android emulator
// Use your machine's IP for physical devices
```

---

## 🛡️ Production Operations Checklist

Before production launch, ensure these are configured:

- Set backend `CORS_ORIGINS` to your real app domains.
- Configure SMTP (`SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM`) for password reset delivery.
- Set strong `JWT_SECRET` and rotate secrets through your deployment platform.
- Enable CI workflow in `.github/workflows/ci.yml` and require passing checks on pull requests.
- Use rolling or blue/green deploy strategy and keep previous release artifact for quick rollback.
- Monitor `/api/health` and set alerts for failed health checks, build failures, and crash spikes.

### Rollback (Minimal Runbook)

1. Re-deploy last known good backend image/revision.
2. Re-point traffic to previous stable app release if needed.
3. Validate `/api/health` and login flow.
4. Announce incident status and start root-cause analysis with logs/metrics.

---

## 🏗️ Architecture

### Flutter App Structure

```
lib/
├── core/
│   ├── constants/          # Colors, API endpoints, configs
│   ├── theme/              # Material 3 theme
│   └── utils/              # Helper functions
├── data/
│   ├── datasources/
│   │   ├── local/          # Hive adapters
│   │   └── remote/         # API client (Dio)
│   ├── models/             # API response models
│   └── repositories/       # Repository implementations
├── domain/
│   ├── entities/           # Core business models
│   └── usecases/           # Business logic
├── presentation/
│   ├── blocs/              # State management (BLoC)
│   ├── screens/            # 8 main screens
│   └── widgets/            # Reusable components
├── router/                 # GoRouter navigation
├── services/               # Auth, notifications, storage
└── main.dart               # App entry point
```

### Backend Structure

```
src/
├── auth/                   # JWT authentication
├── users/                  # User management
├── meals/                  # Meal logging & AI analysis
├── activity/               # Activity tracking
├── energy/                 # Energy calculations
├── analytics/              # Reports & statistics
├── favorites/              # Favorites management
├── custom-foods/           # Custom food library
├── prisma/                 # Database schema & migrations
└── common/                 # Shared utilities
```

---

## 🔌 API Documentation

### Authentication
```
POST /auth/register     - Register new user
POST /auth/login        - Login user
POST /auth/logout       - Logout user
GET  /auth/me           - Get current user
```

### Meals
```
POST /meals/snap        - Analyze food image with AI
POST /meals/manual      - Log meal manually
GET  /meals/my          - Get meal history
GET  /meals/my/today    - Get today's meals
```

### Energy & Activity
```
GET  /energy/state      - Get current energy state
POST /activity/log      - Log activity
GET  /activity/my       - Get activity history
POST /energy/sync       - Sync energy state
```

### Analytics
```
GET  /analytics/weekly-report     - Weekly summary
GET  /analytics/meal-stats        - Meal statistics
GET  /analytics/activity-stats    - Activity breakdown
GET  /analytics/goal-progress     - Goal tracking
```

### Favorites
```
GET    /favorites/meals           - List favorite meals
POST   /favorites/meals           - Add favorite meal
DELETE /favorites/meals/:id       - Remove favorite
GET    /favorites/templates       - List meal templates
POST   /favorites/templates       - Create template
GET    /favorites/foods           - Custom foods library
```

---

## 💾 Database Schema

### Core Tables
- **users**: User accounts and preferences
- **meals**: Meal logs with nutritional info
- **activities**: Activity logs with energy impact
- **energy_states**: Historical energy states
- **favorite_meals**: Saved meals
- **meal_templates**: Reusable meal templates
- **custom_foods**: User's food library
- **custom_activities**: Custom activity definitions

---

## 🧪 Testing

### Run Tests

**Backend:**
```bash
cd backend
npm run test           # Unit tests
npm run test:e2e       # E2E tests
npm run test:cov       # Coverage report
```

**Flutter:**
```bash
cd app/FuelFlow
flutter test                  # Unit tests
flutter test integration_test # Integration tests
```

### Test Coverage Goals
- Unit Tests: 80%+
- Integration Tests: 70%+
- E2E Tests: Key user flows

---

## 📦 Deployment

### Backend Deployment (Heroku)
```bash
cd backend
heroku create fuelflow-api
heroku addons:create heroku-postgresql:hobby-dev
git push heroku main
heroku run npx prisma migrate deploy
```

### Flutter App (Play Store / App Store)
```bash
cd app/FuelFlow

# Android
flutter build appbundle --release
# Upload to Google Play Console

# iOS
flutter build ios --release
# Archive in Xcode and upload to App Store Connect
```

---

## 🛠️ Technologies

### Frontend
- **Flutter**: UI framework
- **flutter_bloc**: State management
- **go_router**: Navigation
- **dio**: HTTP client
- **hive**: Local storage
- **camera**: Camera integration
- **image_picker**: Photo selection
- **flutter_local_notifications**: Push notifications

### Backend
- **NestJS**: Node.js framework
- **Prisma**: ORM
- **PostgreSQL**: Database
- **Passport JWT**: Authentication
- **Google Gemini API**: AI meal analysis
- **class-validator**: Input validation

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Google Gemini API** for AI-powered meal analysis
- **Flutter Team** for the amazing framework
- **NestJS Team** for the robust backend framework
- All open-source contributors whose packages made this possible

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/fuelflow/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/fuelflow/discussions)
- **Email**: support@fuelflow.app

---

## 📊 Project Stats

- **Lines of Code**: ~15,000+
- **Screens**: 8
- **API Endpoints**: 20+
- **Development Time**: 3 days
- **Contributors**: 1
- **Status**: Production Ready ✅

---

<div align="center">

**Made with ❤️ using Flutter & NestJS**

[⬆ Back to Top](#-fuelflow---energy-management-app)

</div>
