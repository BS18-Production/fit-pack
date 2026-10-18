import 'package:fit_pack/data/database/daos/workout_dao.dart';
import 'package:fit_pack/features/progress/training_progress.dart';
import 'package:flutter_test/flutter_test.dart';

/// İlerleme → Antrenman hesabı (docs/56 §1).
void main() {
  final now = DateTime(2026, 10, 18); // Pazar
  ExerciseProgressPoint p(int id, DateTime d, double kg, int reps,
          {String? name}) =>
      ExerciseProgressPoint(
          exerciseId: id,
          name: name ?? 'Ex$id',
          date: d,
          weightKg: kg,
          reps: reps);

  group('ana hareket seçimi', () {
    test('farklı gün sayısına göre; eşitlikte en son yapılan önce', () {
      final points = [
        p(1, DateTime(2026, 10, 1), 60, 8),
        p(1, DateTime(2026, 10, 1), 60, 8), // aynı gün tek sayılır
        p(2, DateTime(2026, 10, 2), 50, 8),
        p(2, DateTime(2026, 10, 9), 50, 8),
        p(3, DateTime(2026, 10, 3), 40, 8),
        p(3, DateTime(2026, 10, 12), 40, 8),
      ];
      expect(topExerciseIds(points, now), [3, 2, 1]);
    });

    test('8 haftadan eski kayıt sayılmaz; en çok 5 hareket', () {
      final points = [
        p(9, DateTime(2026, 8, 1), 100, 5), // pencere dışı
        for (var id = 1; id <= 6; id++) p(id, DateTime(2026, 10, id), 50, 8),
      ];
      final ids = topExerciseIds(points, now);
      expect(ids, hasLength(5));
      expect(ids, isNot(contains(9)));
    });
  });

  group('4 haftalık fark', () {
    test('son değer − 28 gün önce ya da daha eski son değer', () {
      final daily = [
        (date: DateTime(2026, 9, 1), e1rm: 70.0),
        (date: DateTime(2026, 9, 15), e1rm: 75.0),
        (date: DateTime(2026, 10, 15), e1rm: 80.0),
      ];
      expect(fourWeekDelta(daily), 5.0); // 80 − 75 (15 Eyl ≤ 17 Eyl)
    });

    test('4 hafta öncesinde nokta yoksa fark yok', () {
      final daily = [
        (date: DateTime(2026, 10, 1), e1rm: 70.0),
        (date: DateTime(2026, 10, 15), e1rm: 72.0),
      ];
      expect(fourWeekDelta(daily), isNull);
    });
  });

  test('tek gün → eğri yok (tek seans gelişim değil)', () {
    final r = trainingProgressOf([
      p(1, DateTime(2026, 10, 15), 60, 8),
      p(1, DateTime(2026, 10, 15), 62.5, 6),
    ], now: now, weekStart: DateTime.monday);
    expect(r.top.single.hasCurve, isFalse);
    expect(r.top.single.daily, hasLength(1));
    expect(r.trainingDays, 1);
  });

  test('rekor: önceki en iyiyi aşan gün, son 30 gün; ilk gün rekor değil', () {
    final r = trainingProgressOf([
      p(1, DateTime(2026, 8, 1), 60, 8), // ilk gün: rekor değil
      p(1, DateTime(2026, 10, 1), 65, 8), // rekor (30 gün içinde)
      p(1, DateTime(2026, 10, 8), 62, 8), // düşük: rekor değil
    ], now: now, weekStart: DateTime.monday);
    expect(r.records, hasLength(1));
    expect(r.records.single.date, DateTime(2026, 10, 1));
  });

  test('haftalık hacim: kayıtsız hafta boşluk (null), 0 değil', () {
    final r = trainingProgressOf([
      p(1, DateTime(2026, 10, 13), 50, 10), // bu hafta (13 Eki Pzt)
      p(1, DateTime(2026, 9, 29), 40, 10), // 3. hafta önce
    ], now: now, weekStart: DateTime.monday);
    expect(r.weeklyVolume, hasLength(8));
    expect(r.weeklyVolume.last.weekStart, DateTime(2026, 10, 12));
    expect(r.weeklyVolume.last.volumeKg, 500);
    expect(r.weeklyVolume[6].volumeKg, isNull);
    expect(r.weeklyVolume[5].volumeKg, 400);
  });
}
