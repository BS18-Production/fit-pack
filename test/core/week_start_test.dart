import 'package:flutter_test/flutter_test.dart';
import 'package:fit_pack/core/prefs/week_start_provider.dart';

void main() {
  group('startOfWeek', () {
    // 2026-07-05 = Pazar. Hafta başı Pazartesi → 29 Haziran (Pzt).
    test('Pazartesi başlangıcı: Pazar günü haftanın son günüdür', () {
      final sunday = DateTime(2026, 7, 5, 14, 30); // saat de kırpılmalı
      expect(startOfWeek(sunday, DateTime.monday), DateTime(2026, 6, 29));
    });

    test('Pazartesi başlangıcı: Pazartesi kendisi hafta başıdır', () {
      final monday = DateTime(2026, 6, 29);
      expect(startOfWeek(monday, DateTime.monday), DateTime(2026, 6, 29));
    });

    // Hafta başı Pazar → 5 Temmuz Pazar hafta başıdır.
    test('Pazar başlangıcı: Pazar kendisi hafta başıdır', () {
      final sunday = DateTime(2026, 7, 5);
      expect(startOfWeek(sunday, DateTime.sunday), DateTime(2026, 7, 5));
    });

    test('Pazar başlangıcı: Pazartesi bir önceki Pazar\'a döner', () {
      final monday = DateTime(2026, 6, 29);
      expect(startOfWeek(monday, DateTime.sunday), DateTime(2026, 6, 28));
    });

    test('Pazar başlangıcı: Cumartesi aynı haftanın Pazar\'ına döner', () {
      final saturday = DateTime(2026, 7, 4);
      expect(startOfWeek(saturday, DateTime.sunday), DateTime(2026, 6, 28));
    });

    test('tüm günler için pencere 7 gün ve gün penceresini kapsar', () {
      for (final weekStart in [DateTime.monday, DateTime.sunday]) {
        for (var d = 1; d <= 14; d++) {
          final day = DateTime(2026, 7, d);
          final start = startOfWeek(day, weekStart);
          expect(start.weekday, weekStart);
          expect(start.isAfter(day), isFalse);
          expect(day.difference(start).inDays, lessThan(7));
        }
      }
    });
  });
  test('yaz saatine geçilen hafta kaymaz (DST)', () {
    // Avrupa'da 2026-03-29 Pazar 23 saat sürer. Eski hesap (n × 24 saat)
    // 30 Mart Pzt'nin haftasını 22 Mart 23:00'e düşürüyordu. Türkiye'de yaz
    // saati yok; bu test `TZ=Europe/Berlin flutter test` ile anlamlıdır,
    // diğer saat dilimlerinde de geçmelidir.
    final s = startOfWeek(DateTime(2026, 4, 1, 12), DateTime.monday);
    expect(s, DateTime(2026, 3, 30));
    expect(s.hour, 0);
    final paz = startOfWeek(DateTime(2026, 3, 30, 9), DateTime.sunday);
    expect(paz, DateTime(2026, 3, 29));
  });
}
