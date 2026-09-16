import 'package:fit_pack/core/utils/weight_goal.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/workout/history_summary.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paket 1 (2026-09-16) — Codex arayüz incelemesinden doğrulanan
/// düzeltmelerin saf mantığı.
void main() {
  group('C-31 weightChangeTone — renk hedef kilo yönüne göre', () {
    test('kilo almak isteyen için artış olumlu', () {
      expect(weightChangeTone(fromKg: 85, toKg: 88, goalKg: 92),
          WeightChangeTone.good);
    });

    test('kilo almak isteyen için düşüş nötr (kırmızı değil)', () {
      expect(weightChangeTone(fromKg: 88, toKg: 85, goalKg: 92),
          WeightChangeTone.neutral);
    });

    test('kilo vermek isteyen için düşüş olumlu, artış nötr', () {
      expect(weightChangeTone(fromKg: 90, toKg: 88, goalKg: 80),
          WeightChangeTone.good);
      expect(weightChangeTone(fromKg: 88, toKg: 90, goalKg: 80),
          WeightChangeTone.neutral);
    });

    test('hedef yoksa ya da değişim yoksa nötr', () {
      expect(weightChangeTone(fromKg: 85, toKg: 88),
          WeightChangeTone.neutral);
      expect(weightChangeTone(fromKg: 85, toKg: 85, goalKg: 90),
          WeightChangeTone.neutral);
    });

    test('başlangıç zaten hedefteyse sapma olumlu sayılmaz', () {
      expect(weightChangeTone(fromKg: 85, toKg: 86, goalKg: 85),
          WeightChangeTone.neutral);
    });
  });

  group('C-19 sessionTotals — geçmiş kartı özeti', () {
    WorkoutSet s({double? kg, int? reps, int? dur}) => WorkoutSet(
          syncState: 0,
          id: 1,
          sessionId: 1,
          exerciseId: 1,
          setNumber: 1,
          weightKg: kg,
          reps: reps,
          durationSec: dur,
          isWarmup: false,
          setType: 'normal',
          isComplete: true,
        );

    test('set sayısı + Σ kg×tekrar', () {
      final t = sessionTotals([
        s(kg: 100, reps: 5),
        s(kg: 100, reps: 5),
        s(kg: 80, reps: 8),
      ]);
      expect(t.sets, 3);
      expect(t.volumeKg, 1640);
    });

    test('kilosuz/tekrarsız set sayılır ama hacme katılmaz', () {
      final t = sessionTotals([s(dur: 60), s(reps: 12), s(kg: 50, reps: 10)]);
      expect(t.sets, 3);
      expect(t.volumeKg, 500);
    });

    test('boş seans', () {
      final t = sessionTotals(const []);
      expect(t.sets, 0);
      expect(t.volumeKg, 0);
    });
  });

  group('C-19 historyDatePattern — eski yıllarda yıl yazılır', () {
    final now = DateTime(2026, 9, 16);
    test('bu yıl: yıl yok', () {
      expect(historyDatePattern(DateTime(2026, 3, 12), now), 'd MMMM EEEE');
    });
    test('önceki yıl: yıl var', () {
      expect(historyDatePattern(DateTime(2025, 12, 31), now),
          'd MMMM y, EEEE');
    });
  });
}
