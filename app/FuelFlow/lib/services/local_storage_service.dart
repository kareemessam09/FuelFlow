import 'package:hive/hive.dart';
import '../data/datasources/local/activity_adapter.dart';
import '../data/datasources/local/fuel_state_adapter.dart';
import '../data/datasources/local/meal_adapter.dart';
import '../data/datasources/local/user_adapter.dart';
import '../domain/entities/entities.dart';

/// LocalStorageService - Manages all local persistence using Hive
///
/// Responsibilities:
/// - Save/load FuelState for app state restoration
/// - Save/load User profile and preferences
/// - Persist MealLog history for analytics
/// - Persist ActivityLog history for analytics
class LocalStorageService {
  // Singleton pattern
  LocalStorageService._();
  static final LocalStorageService instance = LocalStorageService._();
  factory LocalStorageService() => instance;

  // Box names
  static const String _fuelStateBox = 'fuelState';
  static const String _userBox = 'user';
  static const String _mealsBox = 'meals';
  static const String _activitiesBox = 'activities';

  // Keys
  static const String _currentStateKey = 'currentState';
  static const String _currentUserKey = 'currentUser';

  // --- FuelState Operations ---

  /// Save the current fuel state
  Future<void> saveFuelState(FuelState state) async {
    final box = Hive.box(_fuelStateBox);
    await box.put(_currentStateKey, FuelStateAdapter.fromEntity(state));
  }

  /// Load the last saved fuel state
  FuelState? loadFuelState() {
    final box = Hive.box(_fuelStateBox);
    final adapter = box.get(_currentStateKey) as FuelStateAdapter?;
    return adapter?.toEntity();
  }

  /// Clear fuel state (for reset/logout)
  Future<void> clearFuelState() async {
    final box = Hive.box(_fuelStateBox);
    await box.delete(_currentStateKey);
  }

  // --- User Profile Operations ---

  /// Save user profile and preferences
  Future<void> saveUser(User user) async {
    final box = Hive.box(_userBox);
    await box.put(_currentUserKey, UserAdapter.fromEntity(user));
  }

  /// Load user profile
  User? loadUser() {
    final box = Hive.box(_userBox);
    final adapter = box.get(_currentUserKey) as UserAdapter?;
    return adapter?.toEntity();
  }

  /// Clear user data (for logout)
  Future<void> clearUser() async {
    final box = Hive.box(_userBox);
    await box.delete(_currentUserKey);
  }

  // --- MealLog Operations ---

  /// Add a meal to history
  Future<void> addMealLog(MealLog meal) async {
    final box = Hive.box(_mealsBox);
    final adapter = MealLogAdapter.fromEntity(meal);
    await box.add(adapter);
  }

  /// Get all meal logs
  List<MealLog> getAllMealLogs() {
    final box = Hive.box(_mealsBox);
    return box.values
        .cast<MealLogAdapter>()
        .map((adapter) => adapter.toEntity())
        .toList();
  }

  /// Get recent meal logs (last N days)
  List<MealLog> getRecentMealLogs({int days = 7}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final box = Hive.box(_mealsBox);
    return box.values
        .cast<MealLogAdapter>()
        .map((adapter) => adapter.toEntity())
        .where((meal) => meal.createdAt.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get meal logs for a specific date range
  List<MealLog> getMealLogsByDateRange({
    required DateTime start,
    required DateTime end,
  }) {
    final box = Hive.box(_mealsBox);
    return box.values
        .cast<MealLogAdapter>()
        .map((adapter) => adapter.toEntity())
        .where((meal) =>
            meal.createdAt.isAfter(start) && meal.createdAt.isBefore(end))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Clear all meal logs
  Future<void> clearMealLogs() async {
    final box = Hive.box(_mealsBox);
    await box.clear();
  }

  // --- ActivityLog Operations ---

  /// Add an activity to history
  Future<void> addActivityLog(ActivityLog activity) async {
    final box = Hive.box(_activitiesBox);
    final adapter = ActivityLogAdapter.fromEntity(activity);
    await box.add(adapter);
  }

  /// Get all activity logs
  List<ActivityLog> getAllActivityLogs() {
    final box = Hive.box(_activitiesBox);
    return box.values
        .cast<ActivityLogAdapter>()
        .map((adapter) => adapter.toEntity())
        .toList();
  }

  /// Get recent activity logs (last N days)
  List<ActivityLog> getRecentActivityLogs({int days = 7}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final box = Hive.box(_activitiesBox);
    return box.values
        .cast<ActivityLogAdapter>()
        .map((adapter) => adapter.toEntity())
        .where((activity) => activity.startTime.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// Get activity logs for a specific date range
  List<ActivityLog> getActivityLogsByDateRange({
    required DateTime start,
    required DateTime end,
  }) {
    final box = Hive.box(_activitiesBox);
    return box.values
        .cast<ActivityLogAdapter>()
        .map((adapter) => adapter.toEntity())
        .where((activity) =>
            activity.startTime.isAfter(start) &&
            activity.startTime.isBefore(end))
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// Clear all activity logs
  Future<void> clearActivityLogs() async {
    final box = Hive.box(_activitiesBox);
    await box.clear();
  }

  // --- Batch Operations ---

  /// Clear all data (for app reset)
  Future<void> clearAllData() async {
    await clearFuelState();
    await clearUser();
    await clearMealLogs();
    await clearActivityLogs();
  }

  /// Get total storage size (approximate, in bytes)
  int getStorageSize() {
    int totalSize = 0;
    totalSize += Hive.box(_fuelStateBox).length;
    totalSize += Hive.box(_userBox).length;
    totalSize += Hive.box(_mealsBox).length;
    totalSize += Hive.box(_activitiesBox).length;
    return totalSize;
  }

  /// Compact all boxes to optimize storage
  Future<void> compactStorage() async {
    await Hive.box(_fuelStateBox).compact();
    await Hive.box(_userBox).compact();
    await Hive.box(_mealsBox).compact();
    await Hive.box(_activitiesBox).compact();
  }
}
