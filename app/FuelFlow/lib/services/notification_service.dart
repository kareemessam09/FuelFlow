import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Notification action types for routing
enum NotificationAction {
  openDashboard,
  openMealCapture,
  none,
}

/// NotificationService - Handles local notifications for FuelFlow
/// 
/// Primary use: Alert users when they hit the critical 30% threshold
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  
  /// Callback for handling notification taps (set by main.dart)
  void Function(NotificationAction action)? onNotificationTap;

  /// Notification ID constants
  static const int _criticalAlertId = 1;
  static const int _refuelReminderId = 2;
  static const int _scheduledAlertId = 3;
  
  /// Payload constants for routing
  static const String _payloadDashboard = 'dashboard';
  static const String _payloadMealCapture = 'meal_capture';

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
  }

  /// Request notification permissions (iOS specific)
  Future<bool> requestPermissions() async {
    // Request permissions for iOS
    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    // Android 13+ requires permission
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }

  /// Show a critical energy alert notification
  Future<void> showCriticalEnergyAlert({
    required String currentMode,
    required int minutesToCrash,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'fuel_flow_critical',
      'Critical Energy Alerts',
      channelDescription: 'Notifications when energy levels are critically low',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFFF003C),
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _criticalAlertId,
      'Energy levels dropping!',
      'Current mode: $currentMode. Your energy will hit the red zone in $minutesToCrash minutes. Suggestion: Consume 15g of sustained carbs (e.g., Nuts or Protein Bar) now.',
      details,
      payload: _payloadMealCapture, // Opens meal capture on tap
    );
  }

  /// Show a refuel reminder notification
  Future<void> showRefuelReminder({
    required int minutesSinceLastMeal,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'fuel_flow_reminder',
      'Refuel Reminders',
      channelDescription: 'Gentle reminders to refuel',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      color: Color(0xFFFFEA00),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _refuelReminderId,
      'Time to refuel?',
      'It\'s been $minutesSinceLastMeal minutes since your last meal. Consider a snack to maintain energy levels.',
      details,
      payload: _payloadMealCapture, // Opens meal capture on tap
    );
  }

  /// Schedule an energy alert notification for a specific time
  /// This is used when activity mode changes to schedule alerts based on
  /// the backend's calculated alertTime
  Future<void> scheduleEnergyAlert({
    required DateTime alertTime,
    required String currentMode,
  }) async {
    // Cancel any existing scheduled alert
    await _notifications.cancel(_scheduledAlertId);

    // Don't schedule if alertTime is in the past
    if (alertTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'fuel_flow_critical',
      'Critical Energy Alerts',
      channelDescription: 'Notifications when energy levels are critically low',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFFF003C),
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduledTz = tz.TZDateTime.from(alertTime, tz.local);

    await _notifications.zonedSchedule(
      _scheduledAlertId,
      'Energy alert approaching!',
      'Current mode: $currentMode. Your energy will hit the red zone soon. Consider eating a snack to maintain your levels.',
      scheduledTz,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: _payloadMealCapture, // Opens meal capture on tap
    );
  }

  /// Cancel scheduled energy alert (call when user eats or changes activity)
  Future<void> cancelScheduledAlert() async {
    await _notifications.cancel(_scheduledAlertId);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Cancel a specific notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  void _onNotificationTap(NotificationResponse response) {
    // Parse payload to determine navigation action
    final payload = response.payload;
    NotificationAction action = NotificationAction.openDashboard;
    
    if (payload == _payloadMealCapture) {
      action = NotificationAction.openMealCapture;
    } else if (payload == _payloadDashboard) {
      action = NotificationAction.openDashboard;
    }
    
    // Invoke callback if set
    onNotificationTap?.call(action);
  }
}

