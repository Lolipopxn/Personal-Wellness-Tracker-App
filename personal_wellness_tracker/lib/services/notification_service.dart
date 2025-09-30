import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const int _dailyId = 1001;
  static const String _enabledKey = 'notificationsEnabled';
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    // Initialize time zones and default to Thailand time for consistent "morning"
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));
    } catch (_) {
      // Fallback to device default if available
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      // onDidReceiveNotificationResponse: (resp) { /* handle tap if needed */ },
    );
    // Request permission on Android 13+ (no-op on lower versions)
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

    // Explicitly create the channel (ensures availability before first schedule)
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'daily_morning_channel',
        'Daily Morning',
        description: 'Daily morning reminders',
        importance: Importance.high,
      ),
    );

    // If notifications are disabled, try requesting again (user may have denied previously)
    final enabled = await androidPlugin?.areNotificationsEnabled();
    if (enabled == false) {
      await androidPlugin?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  // Persisted flag
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  // Toggle notifications from the service
  Future<void> setEnabled(bool enabled, {int hour = 8, int minute = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    await init();
    if (enabled) {
      await requestExactAlarmsPermissionIfNeeded();
      await scheduleDailyMorningNotification(hour: hour, minute: minute);
    } else {
      await cancelAll();
    }
  }

  // Apply current pref at startup
  Future<void> applyCurrentPreferenceAndSchedule({int hour = 8, int minute = 0}) async {
    if (await isEnabled()) {
      await init();
      await scheduleDailyMorningNotification(hour: hour, minute: minute);
    } else {
      await cancelAll();
    }
  }

  // Request exact alarm permission (Android 12+). Returns true if granted/available.
  Future<bool> requestExactAlarmsPermissionIfNeeded() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    final canNow = await android.canScheduleExactNotifications();
    if (canNow == true) return true;
    await android.requestExactAlarmsPermission(); // opens system settings
    final recheck = await android.canScheduleExactNotifications();
    return recheck == true;
  }

  Future<void> scheduleDailyMorningNotification({
    int hour = 8,
    int minute = 0,
    bool exact = false, // set true if you want exact and permission is granted
  }) async {
    await init();
    // Cancel any existing daily schedule before setting a new one
    await _plugin.cancel(_dailyId);

    const androidDetails = AndroidNotificationDetails(
      'daily_morning_channel',
      'Daily Morning',
      channelDescription: 'Daily morning reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
      scheduled = tz.TZDateTime(
        tz.local,
        scheduled.year,
        scheduled.month,
        scheduled.day,
        hour,
        minute,
      );
    }

    final useExact = exact &&
        (await _plugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>()
                ?.canScheduleExactNotifications() ==
            true);

    await _plugin.zonedSchedule(
      _dailyId,
      'พร้อมเริ่มวันใหม่แล้วหรือยัง?',
      'อย่าลืมบันทึกสุขภาพของวันนี้',
      scheduled,
      details,
      androidScheduleMode: useExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily at time
      payload: 'daily_morning',
    );
  }

  Future<void> debugStatus() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final enabled = await android?.areNotificationsEnabled();
    final exact = await android?.canScheduleExactNotifications();
    final pendings = await _plugin.pendingNotificationRequests();

    // ignore: avoid_print
    print('[Notif] enabled=$enabled, exact=$exact, pending=${pendings.length}');
    for (final p in pendings) {
      print(
          '[Notif] id=${p.id}, title=${p.title}, body=${p.body}, payload=${p.payload}');
    }
  }

  Future<void> showNowTest() async {
    const android = AndroidNotificationDetails(
      'daily_morning_channel', // ใช้ให้ตรงกับที่สร้าง
      'Daily Morning',
      channelDescription: 'Daily morning reminders',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );
    const details = NotificationDetails(android: android);
    await _plugin.show(
      7777,
      'ทดสอบเด้งทันที',
      'อันนี้ต้องเด้งเลย แม้อยู่หน้าแอป',
      details,
      payload: 'show_now',
    );
  }

  Future<void> showAtTime(DateTime dateTime, {int id = 7778, bool exact = false}) async {
    const android = AndroidNotificationDetails(
      'daily_morning_channel',
      'Daily Morning',
      channelDescription: 'Daily morning reminders',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );
    const details = NotificationDetails(android: android);

    final scheduled = tz.TZDateTime.from(dateTime, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    final finalTime = scheduled.isBefore(now)
        ? scheduled.add(const Duration(days: 1))
        : scheduled;

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final canExact = exact == true && (await androidPlugin?.canScheduleExactNotifications() == true);

    await _plugin.zonedSchedule(
      id, // one-time id
      'แจ้งเตือนตามเวลาที่ตั้ง',
      'เด้งตามที่กำหนดไว้',
      finalTime,
      details,
      androidScheduleMode: canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      // no matchDateTimeComponents => one-time
      payload: 'show_at_time',
    );
  }

  Future<void> cancelDaily() async {
    await _plugin.cancel(_dailyId);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
