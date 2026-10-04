// lib/core/services/notification_service.dart
// Real local notification engine wrapping flutter_local_notifications and timezone.

import 'dart:async';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../models/care_models.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Stream controller for notification tap payloads (deep linking)
  static final StreamController<String> _payloadController = StreamController<String>.broadcast();
  static Stream<String> get payloadStream => _payloadController.stream;

  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();
    try {
      final tzResult = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = tzResult.toString();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Fallback to UTC if timezone lookup fails
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Android Initialization Settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Initialization Settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          _payloadController.add(response.payload!);
        }
      },
    );

    _isInitialized = true;
  }

  /// Request Notification Permissions (Android 13+ and iOS)
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final bool? granted = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    } else if (Platform.isAndroid) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final bool? granted = await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Check if system notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return (await androidImplementation?.areNotificationsEnabled()) ?? false;
    }
    return true;
  }

  /// Schedule an AppReminder entity
  Future<void> scheduleReminder(AppReminder reminder) async {
    if (!reminder.isEnabled) {
      await cancelReminder(reminder.id);
      return;
    }

    final idHash = reminder.id.hashCode & 0x7FFFFFFF;
    final parts = reminder.timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final scheduledDate = _nextInstanceOfTime(hour, minute, reminder.repeatDays);

    final androidDetails = AndroidNotificationDetails(
      'glow_ai_${reminder.type}',
      _channelName(reminder.type),
      channelDescription: _channelDescription(reminder.type),
      importance: reminder.type == 'medicine' ? Importance.max : Importance.high,
      priority: reminder.type == 'medicine' ? Priority.high : Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      idHash,
      reminder.title,
      reminder.body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: reminder.repeatDays.isNotEmpty
          ? DateTimeComponents.dayOfWeekAndTime
          : DateTimeComponents.time,
      payload: '/${reminder.type}?id=${reminder.linkedId ?? ''}',
    );
  }

  /// Schedule a 5-second test notification
  Future<void> scheduleTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'glow_ai_general',
      'General Alerts',
      channelDescription: 'Test notifications for GlowAI',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));

    await _notifications.zonedSchedule(
      99999,
      'GlowAI Test Notification',
      'Your skincare & health alerts are working perfectly!',
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel scheduled notification by string ID
  Future<void> cancelReminder(String id) async {
    final idHash = id.hashCode & 0x7FFFFFFF;
    await _notifications.cancel(idHash);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute, List<int> repeatDays) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (repeatDays.isNotEmpty) {
      while (!repeatDays.contains(scheduledDate.weekday)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
    }

    return scheduledDate;
  }

  String _channelName(String type) {
    switch (type) {
      case 'routine':
        return 'Skincare Routines';
      case 'medicine':
        return 'Medicine & Prescriptions';
      case 'rescan':
        return 'Skin Re-Scan Alerts';
      default:
        return 'General Care Alerts';
    }
  }

  String _channelDescription(String type) {
    switch (type) {
      case 'routine':
        return 'Notifications for AM/PM skincare routines';
      case 'medicine':
        return 'Alerts for prescribed medicines and doses';
      case 'rescan':
        return 'Reminders to re-scan skin for progress tracking';
      default:
        return 'General notifications';
    }
  }
}
