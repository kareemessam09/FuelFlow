# 🔍 FuelFlow - Gap Analysis & Missing Features

## 🎯 What's Currently Missing

### 1. **Analytics Screen - Not Wired to BLoC** ❌
**Status**: Screen exists but shows static/mock data

**What's Missing**:
```dart
// analytics_screen.dart needs BlocBuilder integration
// Currently has hardcoded values like:
final weeklyData = [65, 72, 68, 75, 80, 78, 82]; // Mock data
```

**What's Needed**:
- Wrap screen in BlocBuilder<AnalyticsBloc, AnalyticsState>
- Load data on screen init with `context.read<AnalyticsBloc>().add(AnalyticsLoadData('week'))`
- Display real data from backend
- Add refresh functionality

**Files to Update**:
- `lib/presentation/screens/analytics/analytics_screen.dart`

---

### 2. **Favorites Screen - Not Wired to BLoC** ❌
**Status**: Screen exists but shows empty states only

**What's Missing**:
```dart
// favorites_screen.dart needs BlocBuilder integration
// Currently always shows "No favorites yet" even if data exists
```

**What's Needed**:
- Wrap each tab in BlocBuilder<FavoritesBloc, FavoritesState>
- Load favorites on tab switch
- Handle add/delete actions
- Connect to real backend data

**Files to Update**:
- `lib/presentation/screens/favorites/favorites_screen.dart`

---

### 3. **Settings Screen - Not Connected to Backend** ⚠️
**Status**: Screen exists but changes aren't persisted

**What's Missing**:
- No repository for user preferences
- Toggle switches don't save to backend
- Changes lost on app restart

**What's Needed**:
- Create `UsersRepository` with `updatePreferences()` method
- Wire switches to save on change
- Load current preferences on screen init
- Add SettingsBloc for state management

**Files to Create/Update**:
- `lib/data/repositories/users_repository.dart` (NEW)
- `lib/presentation/blocs/settings/settings_bloc.dart` (NEW)
- `lib/presentation/screens/settings/settings_screen.dart` (UPDATE)

---

### 4. **Profile Stats - Static Data** ⚠️
**Status**: Shows hardcoded numbers

**Current Issue**:
```dart
// profile_screen.dart
StatCard(count: '247', label: 'MEALS LOGGED'), // Hardcoded!
StatCard(count: '1,840', label: 'ACTIVITIES'),  // Hardcoded!
```

**What's Needed**:
- Create ProfileBloc or reuse AnalyticsBloc
- Fetch real user stats from `/analytics/user-stats`
- Update stats in real-time

---

### 5. **FuelBloc Sync Issues** ⚠️ (From task.md)
**Known Issues**:

**Issue 1: Time Drift After Sync**
```dart
// Problem: _lastDecayReferenceTime not reset after sync
// Causes volume jump on next decay tick
```

**Issue 2: Resume Sync**
```dart
// Problem: After resume, offline decay applied but no server sync triggered
// Causes desync between app and server
```

**Issue 3: Alert Notification Timing**
```dart
// Problem: Using client-calculated alertTime instead of server's
// Causes notification to fire at wrong time
```

**Fix Required**: Update `lib/presentation/blocs/fuel/fuel_bloc.dart`

---

### 6. **Image Upload for Meals** ⚠️
**Status**: Camera captures but image might not persist

**Current Flow**:
1. User takes photo ✅
2. Gemini analyzes image ✅
3. Meal logged to backend ✅
4. Image saved to device ✅
5. **Image URL uploaded to backend?** ❌

**What's Missing**:
- Image upload to cloud storage (AWS S3, Cloudinary, Firebase Storage)
- Backend endpoint to receive image file
- Image URL stored in meal record

**Backend Addition Needed**:
```typescript
// backend/src/meals/meals.controller.ts
@Post('upload-image')
@UseInterceptors(FileInterceptor('image'))
async uploadImage(@UploadedFile() file: Express.Multer.File) {
  // Upload to S3/Cloudinary
  // Return image URL
}
```

---

### 7. **Offline Mode - Partial Implementation** ⚠️
**Status**: Hive adapters exist but not fully utilized

**What Works**:
- Energy state cached locally ✅
- User data cached ✅
- Meals cached ✅

**What's Missing**:
- Offline meal logging with sync queue ❌
- Offline activity logging ❌
- Conflict resolution on sync ❌
- Sync indicator in UI ❌

**Files to Update**:
- All repositories need offline-first logic
- Add sync queue service
- Add SyncBloc for managing pending operations

---

### 8. **Error Handling UI** ⚠️
**Status**: Basic error messages but no retry UI

**What's Missing**:
- Global error handler
- Snackbar notifications for errors
- Retry buttons on failed API calls (except meals screen - ✅)
- Network connectivity checker

**Example**:
```dart
// Most screens just show error text, no retry
if (state is AnalyticsError) {
  return Center(child: Text(state.message)); // No retry button!
}
```

---

### 9. **Loading States** ⚠️
**Status**: Basic CircularProgressIndicator, no skeletons

**What's Missing**:
- Shimmer loading skeletons
- Animated placeholders
- Progressive loading for lists
- Pull-to-refresh on all data screens (only meals screen has it)

---

### 10. **Testing** ❌
**Status**: 0% test coverage

**What's Missing**:
- Unit tests for BLoCs
- Unit tests for repositories
- Widget tests for screens
- Integration tests for flows
- Mock data factories
- Test utilities

**Estimated Effort**: 2-3 days for 80% coverage

---

### 11. **Performance Optimizations** ⚠️
**What's Missing**:
- Image caching (cached_network_image)
- List virtualization (already using ListView.builder ✅)
- Lazy loading for analytics data
- Debouncing for search inputs
- Memoization for expensive calculations

---

### 12. **Accessibility** ⚠️
**What's Missing**:
- Screen reader labels (Semantics widgets)
- High contrast mode support
- Font scaling support
- Focus management
- Accessibility testing

---

### 13. **Analytics Events** ❌
**What's Missing**:
- Firebase Analytics integration
- Track user actions (meals logged, activities tracked)
- Track screen views
- Track errors and crashes
- User engagement metrics

---

### 14. **Push Notifications** ⚠️
**Status**: Local notifications work, no remote push

**What Works**:
- Critical energy alerts ✅
- Scheduled local notifications ✅

**What's Missing**:
- Firebase Cloud Messaging (FCM)
- Remote notification handling
- Notification settings in backend
- Deep linking from notifications
- Notification history

---

### 15. **Onboarding Flow** ❌
**What's Missing**:
- First-time user tutorial
- Feature introduction
- Permission requests (camera, notifications)
- Goal setting wizard
- Activity calibration

---

### 16. **Search & Filters** ⚠️
**Status**: No search functionality anywhere

**What's Missing**:
- Search meals by name
- Filter meals by date range
- Filter activities by type
- Search in favorites
- Sort options (date, name, energy impact)

---

### 17. **Data Export** ⚠️
**Status**: Backend has endpoint but no UI

**What's Missing**:
- Export button in settings (exists but not wired)
- Download CSV/JSON of all data
- Share data via email/drive
- Privacy-friendly data portability

---

### 18. **Social Features** ❌ (Optional)
**Not Implemented**:
- Share meals with friends
- Meal recommendations
- Community recipes
- Achievements/badges
- Leaderboards

---

### 19. **Biometric Auth** ❌
**What's Missing**:
- Fingerprint login
- Face ID support
- Secure local auth
- Auto-login after biometric verification

---

### 20. **Dark/Light Mode Toggle** ⚠️
**Status**: Settings screen has toggle but doesn't work

**Current Issue**:
```dart
// settings_screen.dart
Switch(value: false, ...) // Always false, not persisted
```

**What's Needed**:
- ThemeBloc or ThemeCubit
- Save preference to local storage
- Apply theme dynamically

---

## 🚨 Critical Issues (Must Fix)

### Priority 1 - Blocking Core Features
1. ❌ **Wire Analytics Screen to BLoC** - Screen unusable without data
2. ❌ **Wire Favorites Screen to BLoC** - Feature completely non-functional
3. ⚠️ **Wire Settings to Backend** - User preferences not saved
4. ⚠️ **Fix FuelBloc Sync Issues** - Causes data inconsistency

### Priority 2 - Important for UX
5. ⚠️ **Add Retry on Errors** - Users stuck on error screens
6. ⚠️ **Profile Real Stats** - Misleading hardcoded data
7. ⚠️ **Image Upload** - Meal photos not persisted to cloud

### Priority 3 - Nice to Have
8. ⚠️ **Shimmer Loading** - Better loading experience
9. ⚠️ **Pull-to-Refresh** - Add to all data screens
10. ⚠️ **Search & Filters** - Improve data discovery

---

## 📊 Completion Breakdown

| Feature Category | Status | Completion | Priority |
|------------------|--------|------------|----------|
| **UI Design** | ✅ | 100% | - |
| **Color Theme** | ✅ | 100% | - |
| **Navigation** | ✅ | 100% | - |
| **Authentication** | ✅ | 100% | - |
| **Energy Tracking** | ⚠️ | 95% | P1 - Fix sync |
| **Meal Capture** | ⚠️ | 90% | P2 - Image upload |
| **Meal History** | ✅ | 100% | - |
| **Analytics Screen** | ❌ | 30% | P1 - Wire to BLoC |
| **Favorites Screen** | ❌ | 30% | P1 - Wire to BLoC |
| **Settings Screen** | ⚠️ | 50% | P1 - Wire to backend |
| **Profile Screen** | ⚠️ | 80% | P2 - Real stats |
| **Error Handling** | ⚠️ | 40% | P2 - Add retry UI |
| **Loading States** | ⚠️ | 50% | P3 - Add shimmers |
| **Offline Mode** | ⚠️ | 30% | P3 - Full offline |
| **Testing** | ❌ | 0% | P3 - Add tests |
| **Analytics Events** | ❌ | 0% | P3 - Firebase |
| **Search/Filter** | ❌ | 0% | P3 - Add search |
| **Onboarding** | ❌ | 0% | P3 - Tutorial |

**Overall App Completion**: **75%** (core features) | **99%** (UI design)

---

## ⚡ Quick Wins (Can Fix in 1-2 hours)

1. **Wire Analytics Screen** (30 min)
   - Add BlocBuilder wrapper
   - Load data on init
   - Display from state

2. **Wire Favorites Screen** (30 min)
   - Add BlocBuilder for each tab
   - Load on tab switch
   - Handle add/delete

3. **Add Retry Buttons** (20 min)
   - Add retry buttons to all error states
   - Reuse pattern from meals_screen.dart

4. **Fix Profile Stats** (20 min)
   - Call analytics API
   - Display real numbers
   - Update on data change

---

## 🎯 Recommended Action Plan

### Week 1: Critical Features (16 hours)
- ✅ Wire Analytics Screen (2h)
- ✅ Wire Favorites Screen (2h)
- ✅ Wire Settings to Backend (4h)
- ✅ Fix FuelBloc Sync Issues (4h)
- ✅ Add Error Retry UI (2h)
- ✅ Fix Profile Stats (2h)

### Week 2: Polish & UX (16 hours)
- Shimmer loading states (4h)
- Image upload to cloud (4h)
- Pull-to-refresh all screens (2h)
- Search & filters (4h)
- Performance optimizations (2h)

### Week 3: Testing & Quality (20 hours)
- Unit tests for BLoCs (8h)
- Widget tests for screens (6h)
- Integration tests (4h)
- Bug fixes (2h)

### Week 4: Optional Features (16 hours)
- Onboarding flow (4h)
- Firebase Analytics (3h)
- Biometric auth (3h)
- Social features (6h)

---

## 💡 Summary

### What's Working Great ✅
- Beautiful UI with vibrant theme
- Complete navigation system
- Authentication flow
- Core energy tracking
- Meal capture with AI
- Backend API infrastructure

### What Needs Immediate Attention ⚠️
- Wire Analytics screen to real data
- Wire Favorites screen to backend
- Connect Settings to backend
- Fix FuelBloc sync issues
- Add error retry mechanisms

### What Can Wait 📅
- Testing
- Analytics events
- Onboarding
- Social features
- Advanced filters

---

**Status**: **75% Functionally Complete** | **99% UI Complete**

The app looks amazing but needs the new screens wired to actually fetch and display data!

**Estimated Time to 95% Complete**: 16-20 hours (Week 1 priorities)
**Estimated Time to Production Ready**: 40-50 hours (Weeks 1-3)

