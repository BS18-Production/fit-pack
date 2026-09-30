import 'dart:ui' show Locale;

import 'package:fit_pack/core/i18n/formatting.dart';
import 'package:fit_pack/features/activity/activity_providers.dart';
import 'package:fit_pack/features/calendar/calendar_logic.dart';
import 'package:fit_pack/features/home/rhythm_state.dart';
import 'package:fit_pack/features/home/streak_calc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ana sayfa şeridi + ay görünümü + ritim kartı (docs/24) — saf mantık.
void main() {
  group('hafta günleri', () {
    test('7 ardışık gün, ay sınırını geçer', () {
      final d = weekDays(DateTime(2026, 9, 28)); // Pzt
      expect(d.first, DateTime(2026, 9, 28));
      expect(d.last, DateTime(2026, 10, 4));
      expect(monthsOf(d), [DateTime(2026, 9, 1), DateTime(2026, 10, 1)]);
    });

    test('yaz saati geçişinde saat kaymaz (hep gece yarısı)', () {
      // Avrupa'da 2026-10-25 saat geri alınır; Duration ile toplasaydık
      // bir gün 23:00'e düşerdi.
      for (final d in weekDays(DateTime(2026, 10, 19))) {
        expect(d.hour, 0, reason: '$d');
      }
      expect(shiftWeek(DateTime(2026, 10, 19), 1), DateTime(2026, 10, 26));
      expect(shiftWeek(DateTime(2026, 10, 26), -1), DateTime(2026, 10, 19));
    });

    test('gelecek gün yalnız bugünden SONRASI (bugünün geç saati değil)', () {
      final now = DateTime(2026, 9, 23, 9);
      expect(isFutureDay(DateTime(2026, 9, 23, 23, 59), now), isFalse);
      expect(isFutureDay(DateTime(2026, 9, 24), now), isTrue);
      expect(isFutureDay(DateTime(2026, 9, 22), now), isFalse);
    });
  });

  group('gün işareti', () {
    test('kayıt yok → işaretsiz (başarısız değil)', () {
      expect(dayMarkOf(null), DayMark.none);
      expect(dayMarkOf(const DayActivity()), DayMark.none);
    });

    test('yalnız beslenme/su → kayıt; antrenman varsa antrenman', () {
      expect(dayMarkOf(const DayActivity(kcal: 1200)), DayMark.record);
      expect(dayMarkOf(const DayActivity(waterMl: 500)), DayMark.record);
      expect(
          dayMarkOf(const DayActivity(kcal: 900, hasWorkout: true)),
          DayMark.workout);
    });
  });

  group('ritim durumu', () {
    RhythmState of(int weeks, int done, int goal, {bool earlier = false}) =>
        rhythmStateOf(WeeklyStreak(
            weeks: weeks,
            thisWeekDone: done,
            weeklyGoal: goal,
            hasEarlierSessions: earlier));

    test('hiç kayıt yok → başlat', () => expect(of(0, 0, 3), RhythmState.empty));
    test('ilk hafta başladı → ilk haftayı tamamla',
        () => expect(of(0, 1, 3), RhythmState.firstWeek));
    test('seri sürüyor, hafta devam (seri SIFIRLANMAZ)',
        () => expect(of(2, 1, 3, earlier: true), RhythmState.ongoing));
    test('seri sürüyor, hedef doldu',
        () => expect(of(3, 3, 3, earlier: true), RhythmState.weekDone));
    test('geçmişte kayıt var ama seri 0 → yeni seri',
        () => expect(of(0, 0, 3, earlier: true), RhythmState.restart));
    test('önceki hafta kaçtı, bu hafta başlandı → yine yeni seri',
        () => expect(of(0, 1, 3, earlier: true), RhythmState.restart));
  });
  group('dile duyarlı büyük harf', () {
    test('Türkçede i → İ, ı → I', () {
      expect(upperForLanguage('pazartesi · 21 nisan', const Locale('tr')),
          'PAZARTESİ · 21 NİSAN');
      expect(upperForLanguage('salı · 22 eylül', const Locale('tr')),
          'SALI · 22 EYLÜL');
    });
    test('İngilizcede olağan büyük harf', () {
      expect(upperForLanguage('wednesday', const Locale('en')), 'WEDNESDAY');
    });
  });
}
