import 'package:flutter_test/flutter_test.dart';
import 'package:fit_pack/features/home/streak_calc.dart';

/// Haftalık hedef bazlı seri (streak_calc) — dinlenme günü seriyi kırmaz,
/// hafta sınırı kullanıcı tercihine göre.
void main() {
  // Sabit "şimdi": 2026-07-08 Çarşamba (hafta Pzt 2026-07-06 başlar).
  final now = DateTime(2026, 7, 8, 14, 30);

  group('computeWeeklyStreak', () {
    test('hiç seans yok → 0/0', () {
      final s = computeWeeklyStreak(
          sessionDates: const [],
          weeklyGoal: 4,
          now: now,
          weekStart: DateTime.monday);
      expect(s.weeks, 0);
      expect(s.thisWeekDone, 0);
      expect(s.weeklyGoal, 4);
    });

    test('dinlenme günü seriyi KIRMAZ: hafta ortası, hedef henüz dolmadı', () {
      // Geçen hafta (Pzt 6/29..Paz 7/5) 4 antrenman → tamam.
      // Bu hafta yalnız Pzt+Sal (2/4) — Çarşamba dinlenme. Eski gün-bazlı
      // seri burada sıfırlanırdı; haftalık seri 1 kalmalı, ilerleme 2/4.
      final s = computeWeeklyStreak(
        sessionDates: [
          DateTime(2026, 6, 29), DateTime(2026, 6, 30),
          DateTime(2026, 7, 2), DateTime(2026, 7, 4), // geçen hafta 4 gün
          DateTime(2026, 7, 6), DateTime(2026, 7, 7), // bu hafta 2 gün
        ],
        weeklyGoal: 4,
        now: now,
        weekStart: DateTime.monday,
      );
      expect(s.weeks, 1);
      expect(s.thisWeekDone, 2);
      expect(s.thisWeekComplete, false);
    });

    test('bu hafta hedef dolunca seriye dahil olur', () {
      final s = computeWeeklyStreak(
        sessionDates: [
          DateTime(2026, 6, 29), DateTime(2026, 7, 1), // geçen hafta 2/2
          DateTime(2026, 7, 6), DateTime(2026, 7, 8), // bu hafta 2/2
        ],
        weeklyGoal: 2,
        now: now,
        weekStart: DateTime.monday,
      );
      expect(s.weeks, 2);
      expect(s.thisWeekComplete, true);
    });

    test('eksik geçen hafta seriyi kırar', () {
      final s = computeWeeklyStreak(
        sessionDates: [
          // 2 hafta önce 3/3 ama geçen hafta 1/3 → seri sıfır.
          DateTime(2026, 6, 22), DateTime(2026, 6, 24), DateTime(2026, 6, 26),
          DateTime(2026, 7, 1),
          DateTime(2026, 7, 6), // bu hafta 1/3 (devam ediyor)
        ],
        weeklyGoal: 3,
        now: now,
        weekStart: DateTime.monday,
      );
      expect(s.weeks, 0);
      expect(s.thisWeekDone, 1);
    });

    test('aynı güne iki seans tek gün sayılır', () {
      final s = computeWeeklyStreak(
        sessionDates: [
          DateTime(2026, 7, 6, 9), DateTime(2026, 7, 6, 18), // aynı gün
          DateTime(2026, 7, 7),
        ],
        weeklyGoal: 2,
        now: now,
        weekStart: DateTime.monday,
      );
      expect(s.thisWeekDone, 2); // 3 seans ama 2 benzersiz gün
      expect(s.weeks, 1);
    });

    test('hafta başlangıcı Pazar: Pazar seansı YENİ haftaya sayılır', () {
      // 2026-07-05 Pazar, "şimdi" 7/6 Pazartesi. weekStart=Pazar iken hafta
      // 7/5'te başladı → seans BU haftada; weekStart=Pazartesi iken hafta
      // 7/6'da başladı → seans önceki haftada (6/29–7/5) kaldı.
      final sessions = [DateTime(2026, 7, 5)];
      final monday = DateTime(2026, 7, 6, 10);
      final sun = computeWeeklyStreak(
          sessionDates: sessions,
          weeklyGoal: 1,
          now: monday,
          weekStart: DateTime.sunday);
      expect(sun.thisWeekDone, 1);
      expect(sun.weeks, 1); // bu hafta 1/1 tamam → seriye dahil
      final mon = computeWeeklyStreak(
          sessionDates: sessions,
          weeklyGoal: 1,
          now: monday,
          weekStart: DateTime.monday);
      expect(mon.thisWeekDone, 0); // Pazar önceki haftada
      expect(mon.weeks, 1); // o önceki hafta 1/1 tamam
    });

    test('hedef < 1 gelirse 1e sabitlenir (plan kurulmamış)', () {
      final s = computeWeeklyStreak(
        sessionDates: [DateTime(2026, 7, 7)],
        weeklyGoal: 0,
        now: now,
        weekStart: DateTime.monday,
      );
      expect(s.weeklyGoal, 1);
      expect(s.thisWeekComplete, true);
      expect(s.weeks, 1);
    });

    test('uzun seri: 5 ardışık tam hafta + devam eden hafta', () {
      final dates = <DateTime>[];
      // 5 hafta boyunca her Pzt+Perş (hedef 2): 6/1, 6/8, 6/15, 6/22, 6/29
      for (var w = 0; w < 5; w++) {
        final mon = DateTime(2026, 6, 1).add(Duration(days: 7 * w));
        dates.add(mon);
        dates.add(mon.add(const Duration(days: 3)));
      }
      dates.add(DateTime(2026, 7, 6)); // bu hafta 1/2 (devam)
      final s = computeWeeklyStreak(
          sessionDates: dates,
          weeklyGoal: 2,
          now: now,
          weekStart: DateTime.monday);
      expect(s.weeks, 5);
      expect(s.thisWeekDone, 1);
    });
  });
}
