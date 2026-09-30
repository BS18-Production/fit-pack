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
  group('ritim başlığı — haftadan haftaya değişir', () {
    RhythmHeadline h(int weeks, int done, int goal,
            {bool earlier = true, int weekIndex = 0}) =>
        rhythmHeadline(
            WeeklyStreak(
                weeks: weeks,
                thisWeekDone: done,
                weeklyGoal: goal,
                hasEarlierSessions: earlier),
            weekIndex: weekIndex);

    test('kilometre taşları: 1, 2, 3 hafta · 1, 2, 3 ay · yarım yıl · 1 yıl',
        () {
      expect(h(1, 3, 3, earlier: false).line, RhythmLine.week1);
      expect(h(2, 3, 3).line, RhythmLine.week2);
      expect(h(3, 3, 3).line, RhythmLine.week3);
      expect(h(4, 3, 3).line, RhythmLine.month1);
      expect(h(8, 3, 3).line, RhythmLine.month2);
      expect(h(12, 3, 3).line, RhythmLine.month3);
      expect(h(26, 3, 3).line, RhythmLine.halfYear);
      expect(h(52, 3, 3).line, RhythmLine.year1);
    });

    test('sıradan haftalarda art arda iki hafta aynı cümle çıkmaz', () {
      for (var w = 5; w < 60; w++) {
        if ({8, 12, 26, 52}.contains(w) || {8, 12, 26, 52}.contains(w + 1)) {
          continue;
        }
        expect(h(w, 3, 3).line, isNot(h(w + 1, 3, 3).line), reason: '$w');
        expect(h(w, 1, 3).line, isNot(h(w + 1, 1, 3).line), reason: '$w');
      }
    });

    test('hedefe 1 antrenman kaldıysa o cümle öncelikli', () {
      expect(h(5, 2, 3).line, RhythmLine.ongoingLastOne);
      expect(h(0, 2, 3, earlier: false).line, RhythmLine.firstWeekLastOne);
    });

    test('yeniden başlarken cümle haftaya göre döner', () {
      final a = h(0, 0, 3, weekIndex: 40).line;
      final b = h(0, 0, 3, weekIndex: 41).line;
      expect(a, isNot(b));
    });

    test('hiç kayıt yok → başlat', () {
      expect(h(0, 0, 3, earlier: false).line, RhythmLine.start);
    });
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
