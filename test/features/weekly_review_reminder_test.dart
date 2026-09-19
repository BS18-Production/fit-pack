import 'package:fit_pack/core/notifications/notification_prefs.dart';
import 'package:fit_pack/core/notifications/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Haftalık değerlendirme bildirimi (docs/22 §5, W-11).
///
/// Bildirim eklentisinin kendisi testte çalışmaz; ölçülen şey eklentiye
/// VERİLEN gün ve saat — yanlışsa bildirim yanlış gün gelir ve bunu kimse
/// fark etmez.
void main() {
  group('hafta kapanış günü', () {
    test('Pazartesi başlayan hafta → Pazar kapanır', () {
      expect(weekClosingDay(DateTime.monday), DateTime.sunday);
    });

    test('Pazar başlayan hafta → Cumartesi kapanır', () {
      expect(weekClosingDay(DateTime.sunday), DateTime.saturday);
    });
  });

  group('bir sonraki haftalık an', () {
    // 2026-09-16 Çarşamba.
    final carsamba = DateTime(2026, 9, 16, 10, 0);

    test('aynı haftanın pazarı, 20:00', () {
      final n = nextWeeklyOccurrence(carsamba, DateTime.sunday, 20, 0);
      expect(n, DateTime(2026, 9, 20, 20, 0));
      expect(n.weekday, DateTime.sunday);
    });

    test('pazar 20:00 GEÇTİYSE bir sonraki pazar', () {
      final pazarGece = DateTime(2026, 9, 20, 21, 30);
      final n = nextWeeklyOccurrence(pazarGece, DateTime.sunday, 20, 0);
      expect(n, DateTime(2026, 9, 27, 20, 0));
    });

    test('tam 20:00 anında bir sonraki haftaya atılır (çift bildirim olmaz)',
        () {
      final tamAn = DateTime(2026, 9, 20, 20, 0);
      final n = nextWeeklyOccurrence(tamAn, DateTime.sunday, 20, 0);
      expect(n, DateTime(2026, 9, 27, 20, 0));
    });

    test('pazar sabahı → aynı gün akşam', () {
      final pazarSabah = DateTime(2026, 9, 20, 9, 0);
      final n = nextWeeklyOccurrence(pazarSabah, DateTime.sunday, 20, 0);
      expect(n, DateTime(2026, 9, 20, 20, 0));
    });

    test('ay sonu geçişi', () {
      final n = nextWeeklyOccurrence(
          DateTime(2026, 9, 29, 12), DateTime.sunday, 20, 0);
      expect(n, DateTime(2026, 10, 4, 20, 0));
    });
  });

  group('tercih', () {
    test('varsayılan KAPALI — izin istemeden bildirim kurulmaz', () {
      expect(const NotificationPrefs().weeklyReviewEnabled, isFalse);
    });

    test('açma tercihi kalıcıdır', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(notificationPrefsProvider);
      await Future<void>.delayed(Duration.zero);

      final n = c.read(notificationPrefsProvider.notifier);
      await n.update(
          c.read(notificationPrefsProvider).copyWith(weeklyReviewEnabled: true));

      final p = await SharedPreferences.getInstance();
      expect(p.getBool('notif_weekly_review'), isTrue);

      // Yeni bir kapsayıcı (uygulama yeniden açıldı) aynı değeri okur.
      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      c2.read(notificationPrefsProvider);
      await Future<void>.delayed(Duration.zero);
      expect(c2.read(notificationPrefsProvider).weeklyReviewEnabled, isTrue);
    });

    test('diğer tercihler haftalık ayarı değiştirmez', () {
      final p = const NotificationPrefs(weeklyReviewEnabled: true)
          .copyWith(waterEnabled: true);
      expect(p.weeklyReviewEnabled, isTrue);
    });
  });
}
