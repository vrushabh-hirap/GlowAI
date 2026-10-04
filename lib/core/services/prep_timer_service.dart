// lib/core/services/prep_timer_service.dart
// 30-minute skin prep timer with persistence across restarts.
// Uses shared_preferences to store the wash timestamp.
// Schedules a local notification at +30 min if permission is granted.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const _kWashTimestampKey = 'glowai_wash_timestamp_ms';
const _kNotifId = 9001;
const _kPrepMinutes = 30;

final _flnPlugin = FlutterLocalNotificationsPlugin();

class PrepTimerService {
  PrepTimerService._();
  static final PrepTimerService instance = PrepTimerService._();

  bool _notifInitialized = false;

  Future<void> _ensureNotifInitialized() async {
    if (_notifInitialized) return;
    tz_data.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _flnPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _notifInitialized = true;
  }

  /// Start the 30-minute prep timer from now.
  /// Returns the end DateTime. Schedules a notification if possible.
  Future<DateTime> startTimer() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kWashTimestampKey, now.millisecondsSinceEpoch);
    await _scheduleNotification(now.add(const Duration(minutes: _kPrepMinutes)));
    return now.add(const Duration(minutes: _kPrepMinutes));
  }

  /// Cancel the timer (remove stored timestamp and cancel notification).
  Future<void> cancelTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kWashTimestampKey);
    await _cancelNotification();
  }

  /// Returns the DateTime when the timer ends, or null if no timer is running.
  Future<DateTime?> timerEndTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kWashTimestampKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms)
        .add(const Duration(minutes: _kPrepMinutes));
  }

  /// Returns remaining duration, or Duration.zero if expired/none.
  Future<Duration> remaining() async {
    final end = await timerEndTime();
    if (end == null) return Duration.zero;
    final rem = end.difference(DateTime.now());
    return rem.isNegative ? Duration.zero : rem;
  }

  /// True if a wash was recorded ≥30 min ago OR timer is finished.
  Future<bool> isReady() async {
    final rem = await remaining();
    return rem == Duration.zero;
  }

  /// True if a timer is currently active (not yet expired).
  Future<TimerState> state() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kWashTimestampKey);
    if (ms == null) return TimerState.none;
    final end = DateTime.fromMillisecondsSinceEpoch(ms)
        .add(const Duration(minutes: _kPrepMinutes));
    if (DateTime.now().isAfter(end)) return TimerState.ready;
    return TimerState.running;
  }

  // ── Notifications ────────────────────────────────────────────────────────

  Future<void> _scheduleNotification(DateTime when) async {
    try {
      await _ensureNotifInitialized();
      // Request permission on Android 13+
      final androidPlugin =
          _flnPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      if (granted == false) return;

      final local = tz.TZDateTime.from(when, tz.local);
      await _flnPlugin.zonedSchedule(
        _kNotifId,
        'Your skin is ready ✨',
        'It\'s been 30 minutes — time for your GlowAI scan!',
        local,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'glowai_scan_ready',
            'Scan Readiness',
            channelDescription: 'Notifies when skin is ready to scan after washing',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Permission denied or notification scheduling failed — degrade gracefully
    }
  }

  Future<void> _cancelNotification() async {
    try {
      await _ensureNotifInitialized();
      await _flnPlugin.cancel(_kNotifId);
    } catch (_) {}
  }
}

enum TimerState { none, running, ready }

final prepTimerStateProvider = FutureProvider<TimerState>((ref) async {
  return PrepTimerService.instance.state();
});
