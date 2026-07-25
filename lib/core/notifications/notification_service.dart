import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Yerel bildirimler (docs/16 §5 — B6, P-11).
///
/// Üç kullanım: dinlenme sayacı bitti (tek seferlik, dakik), günlük antrenman
/// hatırlatıcı ve günlük su hatırlatıcı (saatli, tekrar eden, dakiklik şart
/// değil). Metinler çağıran taraftan gelir (o anki locale ile ARB'den) —
/// servis metin üretmez.
class NotificationService {
  static const idRest = 1;
  static const idWorkout = 2;
  static const idWater = 3;

  static const _chRest = AndroidNotificationDetails(
    'rest_timer',
    'Rest timer',
    channelDescription: 'Alerts when the rest between sets is over',
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.workout,
  );
  static const _chReminders = AndroidNotificationDetails(
    'reminders',
    'Daily reminders',
    channelDescription: 'Workout and water reminders',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  /// iOS karşılıkları. Dinlenme bitişi zamana duyarlı — Odaklanma modunda da
  /// görünsün (Android'deki Importance.high dengi); hatırlatıcılar sıradan.
  static const _iosRest = DarwinNotificationDetails(
    interruptionLevel: InterruptionLevel.timeSensitive,
  );
  static const _iosReminders = DarwinNotificationDetails();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    if (_inited) return;
    tzdata.initializeTimeZones();
    try {
      // flutter_timezone sürümüne göre String ya da TimezoneInfo dönebilir.
      final dynamic info = await FlutterTimezone.getLocalTimezone();
      final name = info is String ? info : (info.identifier as String);
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Bölge çözülemedi — UTC ile devam (yalnız hatırlatıcı saatini kaydırır).
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // iOS'ta izin init'te İSTENMEZ — kullanıcı hatırlatıcıyı açtığında
        // requestPermission() sorar (Android akışıyla aynı, uygulama açılır
        // açılmaz izin diyaloğu çıkmasın).
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _inited = true;
  }

  /// Bildirim izni: Android 13+ çalışma zamanı izni, iOS'ta
  /// UNUserNotificationCenter yetkisi. Verilmezse false.
  Future<bool> requestPermission() async {
    await init();
    final android = _android;
    if (android != null) {
      return await android.requestNotificationsPermission() ?? true;
    }
    final ios = _ios;
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return true;
  }

  /// Dinlenme sayacı dakik alarm izni (Android 12+ özel izin). Reddedilse de
  /// bildirim çalışır — sadece dakikliği düşer (inexact fallback).
  Future<void> requestExactAlarmPermission() async {
    await init();
    try {
      await _android?.requestExactAlarmsPermission();
    } catch (_) {/* platform desteklemiyorsa sessiz geç */}
  }

  /// Dinlenme bitince tek seferlik bildirim — [after] sonra (docs/12 + P-11).
  /// Dakik alarm izni yoksa inexact'e düşer (birkaç dk gecikebilir).
  Future<void> scheduleRestDone({
    required Duration after,
    required String title,
    required String body,
  }) async {
    await init();
    final when = tz.TZDateTime.now(tz.local).add(after);
    const details = NotificationDetails(android: _chRest, iOS: _iosRest);
    try {
      await _plugin.zonedSchedule(
          id: idRest,
          title: title,
          body: body,
          scheduledDate: when,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
    } on PlatformException {
      await _plugin.zonedSchedule(
          id: idRest,
          title: title,
          body: body,
          scheduledDate: when,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> cancelRestDone() => _plugin.cancel(id: idRest);

  /// Her gün aynı saatte tekrar eden hatırlatıcı (antrenman/su). Dakiklik
  /// kritik değil → inexact (SCHEDULE_EXACT_ALARM izni istemez).
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await init();
    final now = tz.TZDateTime.now(tz.local);
    var when =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: _chReminders,
        iOS: _iosReminders,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // her gün tekrar
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id: id);
}

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());
