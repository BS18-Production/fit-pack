import 'package:fit_pack/core/prefs/training_prefs.dart';
import 'package:fit_pack/core/units/units.dart';
import 'package:fit_pack/features/workout/progression.dart';
import 'package:fit_pack/features/workout/set_prefill.dart';
import 'package:fit_pack/features/workout/workout_draft.dart';
import 'package:flutter_test/flutter_test.dart';

/// docs/21 #3 — antrenmanda sonraki hedef (çift ilerleme). Kilo artışı
/// kendiliğinden uygulanmaz; kullanıcı düğmeye basınca yalnız o seansın
/// önerileri değişir.
void main() {
  SetValues s(double kg, int reps) => SetValues(weightKg: kg, reps: reps);

  ProgressionAdvice? advise(
    List<SetValues> sets, {
    int? min = 8,
    int? max = 12,
  }) => progressionFor(lastWorkingSets: sets, repsMin: min, repsMax: max);

  group('karar', () {
    test('tüm setler üst sınırda → kilo artırma önerisi', () {
      final a = advise([s(60, 12), s(60, 12), s(60, 13)])!;
      expect(a.kind, ProgressionKind.increaseWeight);
      expect(a.lastTopWeightKg, 60);
      expect(a.actionable, isTrue);
    });

    test('aralık içinde → +1 tekrar önerisi', () {
      final a = advise([s(15, 10), s(15, 10), s(15, 9)])!;
      expect(a.kind, ProgressionKind.addRep);
      expect(a.lastReps, [10, 10, 9]);
    });

    test('bir set alt sınırın altında → aynı hedef, düğme yok', () {
      final a = advise([s(100, 10), s(120, 9), s(140, 7)])!;
      expect(a.kind, ProgressionKind.repeat);
      expect(a.lastTopWeightKg, 140);
      expect(a.actionable, isFalse);
    });

    test('aralık yok / ters / geçmiş yok / kilo yok → öneri yok', () {
      expect(advise([s(60, 12)], min: null), isNull);
      expect(advise([s(60, 12)], min: 12, max: 8), isNull);
      expect(advise(const []), isNull);
      expect(advise(const [SetValues(reps: 12)]), isNull);
    });
  });

  group('uygulama', () {
    test('kilo artışı: kilo + artış, tekrar = alt sınır', () {
      final a = advise([s(60, 12), s(60, 12)])!;
      expect(a.apply(s(60, 12), incrementKg: 1.25), s(61.25, 8));
    });

    test('tekrar artışı üst sınırı aşmaz, kilo aynı', () {
      final a = advise([s(15, 10), s(15, 12)])!;
      expect(a.apply(s(15, 10), incrementKg: 1.25), s(15, 11));
      expect(a.apply(s(15, 12), incrementKg: 1.25), s(15, 12));
    });

    test('tekrar önerisi hiçbir şeyi değiştirmez', () {
      final a = advise([s(100, 10), s(140, 7)])!;
      expect(a.apply(s(140, 7), incrementKg: 1.25), s(140, 7));
    });

    test('uygulanan öneri set önerisine yansır (G-2 ile birlikte)', () {
      final a = advise([s(60, 12), s(60, 12)])!;
      final last = [
        for (final v in [s(60, 12), s(60, 12)]) a.apply(v, incrementKg: 1.25),
      ];
      final empty = const SetValues();
      // 1. set: geçen seansın uyarlanmış hali
      expect(
        suggestionFor(
          index: 0,
          current: [
            (values: empty, warmup: false),
            (values: empty, warmup: false),
          ],
          lastSession: last,
          measure: 'weight_reps',
        ),
        s(61.25, 8),
      );
      // 1. set öneriyle yapıldı → 2. set de uyarlanmış öneriyi takip eder
      expect(
        suggestionFor(
          index: 1,
          current: [
            (values: s(61.25, 8), warmup: false),
            (values: empty, warmup: false),
          ],
          lastSession: last,
          measure: 'weight_reps',
        ),
        s(61.25, 8),
      );
    });
  });

  group('artış miktarı', () {
    const metric = Units(UnitSystem.metric);
    const imperial = Units(UnitSystem.imperial);

    test('varsayılan: metrik 1,25 kg, imperial 2,5 lb', () {
      expect(effectiveIncrementKg(null, metric), 1.25);
      expect(
        imperial.weightFromKg(effectiveIncrementKg(null, imperial)),
        closeTo(2.5, 1e-9),
      );
    });

    test('kayıtlı değer varsayılanı geçer', () {
      expect(effectiveIncrementKg(2.5, metric), 2.5);
      expect(effectiveIncrementKg(2.5, imperial), 2.5);
    });

    test('kilo gösterimi 1,25 artışını kaybetmez', () {
      expect(metric.liftValue(61.25), '61.25');
      expect(metric.liftValue(62.5), '62.5');
      expect(metric.liftValue(60), '60');
      expect(metric.lift(1.25), '1.25 kg');
    });
  });

  group('taslak', () {
    test('uygulanan artış taslakta saklanır; eski taslakta alan yok', () {
      final d = DraftExercise(
        exerciseId: 1,
        restSec: 60,
        previous: null,
        sets: const [],
        appliedIncrementKg: 1.25,
      );
      expect(DraftExercise.fromJson(d.toJson()).appliedIncrementKg, 1.25);
      final old = DraftExercise.fromJson({'id': 1, 'rest': 60, 'sets': []});
      expect(old.appliedIncrementKg, isNull);
      expect(
        DraftExercise(
          exerciseId: 1,
          restSec: 60,
          previous: null,
          sets: const [],
        ).toJson().containsKey('inc'),
        isFalse,
      );
    });
  });
}
