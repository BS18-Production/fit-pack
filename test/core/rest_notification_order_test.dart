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

  setUp(() {
    calls.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (c) async {
      calls.add(c.method);
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
}
