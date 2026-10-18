import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../feedback/feedback_service.dart' show restCountdownLeadMs;
import '../feedback/rest_sound.dart';

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
  static const idWeeklyReview = 4;

  /// Öğün hatırlatıcıları (docs/26): `idMealBase + öğün × 3 + gün` —
  /// 3 öğün × 3 gün = 20…28. Hepsi her yeniden kurulumda iptal edilir.
  static const idMealBase = 20;
  static const mealReminderSlots = 9;

  /// Geri çağırma — "ara uzadı" antrenman hatırlatıcısı (docs/51):
  /// `idRecallBase + sıra` (bugün + 2 gün, günde 2 = 40…45). Eski günlük sabit saatli
  /// antrenman hatırlatıcısı ([idWorkout]) bu türe dönüştü; her yeniden
  /// kurulumda o da iptal edilir.
  static const idRecallBase = 40;
  static const recallSlots = 6;

  /// Dokununca açılacak ekranı söyleyen yük (payload). Uygulama kökü bunu
  /// dinleyip ilgili rotaya gider.
  static const payloadWeeklyReview = 'weekly_review';
  static const payloadNutrition = 'nutrition';
  static const payloadRecall = 'recall';

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

  /// iOS hatırlatıcıları sıradan; mola bildiriminin ayarları
  /// [scheduleRestDone] içinde (ses + ön planda sessiz sunum).
  static const _iosReminders = DarwinNotificationDetails();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  /// Uygulama AÇIKKEN (ön ya da arka planda) dokunulan bildirimlerin yükü.
  final _taps = StreamController<String>.broadcast();
  Stream<String> get taps => _taps.stream;

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
      onDidReceiveNotificationResponse: (r) {
        final p = r.payload;
        if (p != null && p.isNotEmpty) _taps.add(p);
      },
    );
    _inited = true;
    unawaited(_removeCopiedSounds());
  }

  /// 2026-10-11 sürümü mola seslerini `Library/Sounds/`a kopyalıyordu. iOS
  /// bildirim sesini önce orada arar — kalan kopyalar paketteki (yeniden
  /// üretilmiş) sesleri gölgelerdi. Ses artık yalnız paketten; kopyalar
  /// silinir (yoksa iş yok).
  Future<void> _removeCopiedSounds() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      final dir =
          Directory(p.join((await getLibraryDirectory()).path, 'Sounds'));
      if (!await dir.exists()) return;
      await for (final f in dir.list()) {
        final name = p.basename(f.path);
        if (name.startsWith('rest_') && name.endsWith('.caf')) await f.delete();
      }
    } catch (_) {
      // En iyi çaba: silinemezse paketteki sesle aynı içerik çalar.
    }
  }

  /// Uygulama KAPALIYKEN bir bildirime dokunularak açıldıysa o bildirimin
  /// yükü; aksi halde `null`. Soğuk açılışta akış (`taps`) bunu kaçırır.
  Future<String?> launchPayload() async {
    await init();
    final d = await _plugin.getNotificationAppLaunchDetails();
    if (d == null || !d.didNotificationLaunchApp) return null;
    return d.notificationResponse?.payload;
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

  // Mola bildirimi işlemleri sıralı (docs/45, Codex incelemesi): ses dosyası
  // kopyalanırken gelen "Atla"/öne dönüş iptali, geç biten kurulum
  // tarafından ezilmesin. Her kurulum/iptal nesli artırır; eski nesil
  // kurulum hiçbir şey yazmadan çıkar.
  Future<void> _restOps = Future.value();
  int _restGen = 0;

  Future<void> _restSerial(Future<void> Function() op) =>
      _restOps = _restOps.then((_) => op()).catchError((Object _) {});

  /// Dinlenme bitince tek seferlik bildirim — [at] anında (docs/12 + P-11).
  /// Dakik alarm izni yoksa inexact'e düşer (birkaç dk gecikebilir).
  ///
  /// iOS'ta [sound] seçili mola sesidir (docs/45 §3); `null` = kullanıcı
  /// mola sesini kapattı → sessiz bildirim. Sistem bildirim sesi telefonun
  /// sessiz anahtarına ve Odaklanma'ya uyar — uygulama hatası değil.
  ///
  /// **Son 3 saniye (iOS, docs/45 §3b).** Uygulama arkadayken iOS onu
  /// askıya alır; uygulama içi tık-tık-tık çalamaz. Yeterli süre varsa
  /// bildirim bitişten [restCountdownLeadMs] ÖNCE, tam geri sayım sesiyle
  /// ([earlyTitle]/[earlyBody]) kurulur: 3-2-1 + bitiş arka planda da duyulur.
  /// Süre azsa tam bitişte yalnız bitiş sesi.
  ///
  /// **Hiçbir zaman iki kez çalmaz (Samet, 2026-10-12).** Ses dosyaları
  /// uygulama paketinde (`ios/Runner/Sounds/`) — çalışma anında kopyalama
  /// ve "kopyalanamazsa varsayılan ses" yolu yok. Ön planda sunum her
  /// zaman sessiz (`presentSound: false`): uygulama açıkken sesi yalnız
  /// uygulama içi geri sayım çalar; bildirimin sesi yalnız arka planda.
  Future<void> scheduleRestDone({
    required DateTime at,
    required String title,
    required String body,
    String? earlyTitle,
    String? earlyBody,
    RestSound? sound,
  }) {
    final gen = ++_restGen;
    return _restSerial(() async {
      await init();
      if (gen != _restGen) return; // arada iptal ya da yeni kurulum geldi
      final countdown = restNotifLeadMs(
            left: at.difference(DateTime.now()),
            countdownSound: sound != null &&
                earlyTitle != null &&
                !kIsWeb &&
                defaultTargetPlatform == TargetPlatform.iOS,
          ) >
          0;
      final fireAt = countdown
          ? at.subtract(const Duration(milliseconds: restCountdownLeadMs))
          : at;
      final left = fireAt.difference(DateTime.now());
      if (left <= Duration.zero) return;
      final when = tz.TZDateTime.now(tz.local).add(left);
      final details = NotificationDetails(
        android: _chRest,
        iOS: DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.timeSensitive,
          presentSound: false,
          sound: sound == null
              ? null
              : (countdown
                  ? sound.countdownNotifFileName
                  : sound.endFileName),
        ),
      );
      final shownTitle = countdown ? earlyTitle! : title;
      final shownBody = countdown ? (earlyBody ?? body) : body;
      try {
        await _plugin.zonedSchedule(
            id: idRest,
            title: shownTitle,
            body: shownBody,
            scheduledDate: when,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
      } on PlatformException {
        await _plugin.zonedSchedule(
            id: idRest,
            title: shownTitle,
            body: shownBody,
            scheduledDate: when,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle);
      }
    });
  }

  Future<void> cancelRestDone() {
    _restGen++;
    return _restSerial(() => _plugin.cancel(id: idRest));
  }

  /// iOS: bu uygulamanın bildirim sesi sistem ayarlarında açık mı. Ayarlar
  /// ekranı uyarı göstermek için sorar; Android'de ses servisten gelir → true.
  Future<bool> iosSoundAllowed() async {
    await init();
    final ios = _ios;
    if (ios == null) return true;
    try {
      final o = await ios.checkPermissions();
      return o == null || (o.isEnabled && o.isSoundEnabled);
    } catch (_) {
      return true;
    }
  }

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

  /// Her hafta aynı gün ve saatte tekrar eden bildirim (haftalık
  /// değerlendirme — docs/22 §5). Dakiklik kritik değil → inexact.
  ///
  /// [weekday] `DateTime.weekday` uzayında (1 = Pazartesi … 7 = Pazar).
  Future<void> scheduleWeekly({
    required int id,
    required int weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    final now = tz.TZDateTime.now(tz.local);
    final next = nextWeeklyOccurrence(now, weekday, hour, minute);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime(tz.local, next.year, next.month, next.day,
          next.hour, next.minute),
      notificationDetails: const NotificationDetails(
        android: _chReminders,
        iOS: _iosReminders,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  /// Tek seferlik bildirim [when] anında (öğün hatırlatıcısı — docs/26).
  /// Dakiklik kritik değil → inexact (özel izin istemez).
  Future<void> scheduleOnce({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime(tz.local, when.year, when.month, when.day,
          when.hour, when.minute),
      notificationDetails: const NotificationDetails(
        android: _chReminders,
        iOS: _iosReminders,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id: id);

  /// Hesaba ait veriden üretilen bildirimleri siler (docs/51 §1): öğün ve
  /// geri çağırma metinleri önceki hesabın rutin/öğün adlarını taşır, mola
  /// bildirimi önceki hesabın seansına aittir. Su ve haftalık değerlendirme
  /// cihaz tercihi, metinleri genel — dokunulmaz. Yeniden kurma yeni hesabın
  /// verisiyle (tablo değişimi) kendiliğinden yapılır.
  Future<void> cancelAccountScoped() async {
    await cancelRestDone();
    await cancel(idWorkout);
    for (var i = 0; i < mealReminderSlots; i++) {
      await cancel(idMealBase + i);
    }
    for (var i = 0; i < recallSlots; i++) {
      await cancel(idRecallBase + i);
    }
  }
}

/// Geri sayımlı bildirim için en az bu kadar pay (ms): kurulum + iOS teslim
/// gecikmesi son 3 saniyeyi yemesin.
const restNotifEarlyMarginMs = 1000;

/// Mola bildirimi bitişten kaç ms ÖNCE kurulsun (docs/45 §3b): geri sayım
/// sesi varsa ve yeterli süre kaldıysa [restCountdownLeadMs] (3-2-1 + bitiş),
/// yoksa 0 (tam bitişte, yalnız bitiş sesi).
int restNotifLeadMs({required Duration left, required bool countdownSound}) =>
    countdownSound &&
            left >
                const Duration(
                    milliseconds: restCountdownLeadMs + restNotifEarlyMarginMs)
        ? restCountdownLeadMs
        : 0;

/// [now]'dan SONRAKİ ilk [weekday] günü, [hour]:[minute] anı. Tam o an
/// geçmişse bir sonraki haftaya atılır.
///
/// Gün eklemek için `Duration` değil takvim alanı kullanılır: yaz saati
/// geçişinde 24 saat ≠ 1 gün, `add(Duration(days: n))` saati kaydırırdı.
DateTime nextWeeklyOccurrence(
    DateTime now, int weekday, int hour, int minute) {
  final ileri = (weekday - now.weekday) % 7;
  var d = DateTime(now.year, now.month, now.day + ileri, hour, minute);
  if (!d.isAfter(now)) {
    d = DateTime(d.year, d.month, d.day + 7, hour, minute);
  }
  return d;
}

/// Haftanın KAPANIŞ günü: başlangıçtan bir önceki gün. Pazartesi başlayan
/// haftada Pazar (7), Pazar başlayan haftada Cumartesi (6).
int weekClosingDay(int weekStart) => ((weekStart - 2) % 7) + 1;

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());
