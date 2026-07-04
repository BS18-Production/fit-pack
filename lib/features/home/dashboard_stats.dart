import '../../data/database/app_database.dart';
import '../../data/database/daos/workout_dao.dart';
import '../workout/calorie_estimate.dart';

/// Ana Sayfa dashboard'unun saf (widget'sız, DB'siz) hesap katmanı.
/// DAO sonuçlarını alır, gösterilecek metrikleri üretir — kolayca test edilir.

/// Bir dönemin (hafta/ay) antrenman özeti: seans sayısı, toplam hacim (Σ
/// kg×tekrar), tahmini yakılan kalori (ACSM — [estimateWorkoutKcal]).
typedef WorkoutAggregate = ({int sessions, int volumeKg, int kcalBurned});

WorkoutAggregate aggregateWorkouts({
  required List<WorkoutSession> sessions,
  required Map<int, List<WorkoutSet>> setsBySession,
  required double? bodyWeightKg,
}) {
  var volume = 0;
  var kcal = 0.0;
  for (final s in sessions) {
    final sets = setsBySession[s.id] ?? const [];
    for (final st in sets) {
      volume += ((st.weightKg ?? 0) * (st.reps ?? 0)).round();
    }
    final intensity = sessionIntensity(sets);
    final k = estimateWorkoutKcal(
      bodyWeightKg: bodyWeightKg,
      durationMin: s.durationMin,
      avgRpe: intensity.avgRpe,
      isCardio: intensity.isCardio || s.workoutType == 'Cardio',
    );
    if (k != null) kcal += k;
  }
  return (sessions: sessions.length, volumeKg: volume, kcalBurned: kcal.round());
}

/// Hacim değişimi yüzdesi (bu dönem vs önceki dönem). Önceki 0/eksi ise null
/// (yüzde değişimi tanımsız → UI rozet göstermez).
int? volumeDeltaPct(int current, int previous) {
  if (previous <= 0) return null;
  return (((current - previous) / previous) * 100).round();
}

/// "En çok gelişen hareket" içgörüsü.
typedef TopProgress = ({String name, double deltaE1rm});

/// Penceredeki set noktalarından en çok gelişen hareketi bulur: her hareket
/// için GÜN bazında en iyi e1RM (Epley) alınır; en az 2 farklı gün gerekir;
/// delta = son gün − ilk gün. En büyük POZİTİF delta kazanır. Yeterli veri
/// yoksa null → UI içgörü kartını hiç göstermez (sahte içgörü yok).
TopProgress? topProgressExercise(List<ExerciseProgressPoint> points) {
  final byExercise =
      <int, ({String name, Map<DateTime, double> bestByDay})>{};
  for (final p in points) {
    final e1 = p.e1rm;
    if (e1 == null) continue;
    final day = DateTime(p.date.year, p.date.month, p.date.day);
    final entry = byExercise.putIfAbsent(
        p.exerciseId, () => (name: p.name, bestByDay: <DateTime, double>{}));
    final cur = entry.bestByDay[day];
    if (cur == null || e1 > cur) entry.bestByDay[day] = e1;
  }

  TopProgress? best;
  for (final e in byExercise.values) {
    if (e.bestByDay.length < 2) continue;
    final days = e.bestByDay.keys.toList()..sort();
    final delta = e.bestByDay[days.last]! - e.bestByDay[days.first]!;
    if (delta <= 0) continue;
    if (best == null || delta > best.deltaE1rm) {
      best = (name: e.name, deltaE1rm: delta);
    }
  }
  return best;
}

/// Haftalık protein hedefi uyumu (%): kayıt GİRİLEN günlerde (günlük protein /
/// hedef) oranlarının ortalaması. Kayıtlı gün yoksa ya da hedef ≤0 ise null.
int? weeklyProteinAdherencePct(List<FoodLog> logs, int proteinGoal) {
  if (proteinGoal <= 0) return null;
  final byDay = <DateTime, double>{};
  for (final l in logs) {
    final day = DateTime(l.date.year, l.date.month, l.date.day);
    byDay[day] = (byDay[day] ?? 0) + l.computedProtein;
  }
  if (byDay.isEmpty) return null;
  final avg =
      byDay.values.map((p) => p / proteinGoal).reduce((a, b) => a + b) /
          byDay.length;
  return (avg * 100).round();
}
