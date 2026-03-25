import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
      1, // Notification ID
      'Energy levels dropping!',
      'Current mode: $currentMode. Your energy will hit the red zone in $minutesToCrash minutes. Suggestion: Consume 15g of sustained carbs (e.g., Nuts or Protein Bar) now.',
      details,
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
      2, // Notification ID
      'Time to refuel?',
      'It\'s been $minutesSinceLastMeal minutes since your last meal. Consider a snack to maintain energy levels.',
      details,
    );
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
    // Handle notification tap - could navigate to specific screen
    // This would be connected to the app's navigation
  }
}

/// Color class for notification (Android)
class Color {
  final int value;
  const Color(this.value);
}
