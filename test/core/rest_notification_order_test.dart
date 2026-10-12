import 'package:fit_pack/core/feedback/rest_sound.dart';
import 'package:fit_pack/core/notifications/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

/// docs/45 (Codex incelemesi): mola bildirimi kurulumu ile iptali sıralı.
/// Kurulum beklerken gelen "Atla"/öne dönüş iptali, geç biten kurulumla
/// ezilmemeli — bildirim geri gelmemeli.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <String>[];
  final args = <Map<Object?, Object?>>[];

  setUp(() {
    calls.clear();
    args.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (c) async {
      calls.add(c.method);
      if (c.method == 'zonedSchedule') args.add(c.arguments as Map);
      return c.method == 'initialize' ? true : null;
    });
    m.setMockMethodCallHandler(const MethodChannel('flutter_timezone'),
        (c) async => 'Europe/Istanbul');
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  List<String> restCalls() =>
      calls.where((c) => c == 'zonedSchedule' || c == 'cancel').toList();

  test('kurulumdan hemen sonra iptal: bildirim kalmaz', () async {
    final s = NotificationService();
    final at = DateTime.now().add(const Duration(minutes: 1));
    final a = s.scheduleRestDone(at: at, title: 't', body: 'b');
    final b = s.cancelRestDone();
    await Future.wait([a, b]);
    expect(restCalls(), ['cancel'], reason: 'eski nesil kurulum yazmaz');
  });

  test('art arda iki kurulum: yalnız sonuncusu yazılır', () async {
    final s = NotificationService();
    final now = DateTime.now();
    final a = s.scheduleRestDone(
        at: now.add(const Duration(seconds: 60)), title: 't', body: 'b');
    final b = s.scheduleRestDone(
        at: now.add(const Duration(seconds: 75)), title: 't', body: 'b');
    await Future.wait([a, b]);
    expect(restCalls(), ['zonedSchedule']);
  });

  test('geçmiş bitiş anı kurulmaz', () async {
    final s = NotificationService();
    await s.scheduleRestDone(
        at: DateTime.now().subtract(const Duration(seconds: 1)),
        title: 't',
        body: 'b');
    expect(restCalls(), isEmpty);
  });

  test('son 3 saniye: süre yeterliyse bildirim 3 sn önce (geri sayım sesi)', () {
    expect(restNotifLeadMs(left: const Duration(seconds: 90), countdownSound: true),
        3000);
    // Kurulum + teslim payı yoksa tam bitişte (3-2-1 yarım kalmasın).
    expect(restNotifLeadMs(left: const Duration(milliseconds: 3800), countdownSound: true),
        0);
    // Ses kapalı / Android (ses servisten) → tam bitişte.
    expect(restNotifLeadMs(left: const Duration(seconds: 90), countdownSound: false),
        0);
  });

  group('iOS: bildirim hiçbir zaman ön planda çalmaz (çift ses yok)', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      FlutterLocalNotificationsPlatform.instance =
          IOSFlutterLocalNotificationsPlugin();
    });

    Map<Object?, Object?> ios() =>
        args.single['platformSpecifics'] as Map<Object?, Object?>;

    test('geri sayımlı: 3 sn önce, paketteki geri sayım sesi', () async {
      final at = DateTime.now().add(const Duration(seconds: 60));
      await NotificationService().scheduleRestDone(
          at: at,
          title: 'bitti',
          body: 'b',
          earlyTitle: '3 sn',
          sound: RestSound.boxingBell);
      expect(ios()['presentSound'], isFalse);
      expect(ios()['sound'], 'rest_boxing_bell_countdown.caf');
      expect(args.single['title'], '3 sn');
    });

    test('süre az: bitişte, bitiş sesi', () async {
      await NotificationService().scheduleRestDone(
          at: DateTime.now().add(const Duration(milliseconds: 3500)),
          title: 'bitti',
          body: 'b',
          earlyTitle: '3 sn',
          sound: RestSound.boxingBell);
      expect(ios()['presentSound'], isFalse);
      expect(ios()['sound'], 'rest_boxing_bell_end.caf');
      expect(args.single['title'], 'bitti');
    });

    test('ses kapalı: sessiz', () async {
      await NotificationService().scheduleRestDone(
          at: DateTime.now().add(const Duration(seconds: 60)),
          title: 'bitti',
          body: 'b');
      expect(ios()['presentSound'], isFalse);
      expect(ios()['sound'], isNull);
    });
  });
}
