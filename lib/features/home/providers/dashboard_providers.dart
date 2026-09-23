import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers.dart';
import '../../../data/reactive.dart';
import '../dashboard_stats.dart';

/// Ana Sayfa dashboard sağlayıcıları (docs: dashboard reskin).
///
/// **Reaktif** (H-05, `watchTables`): antrenman/ölçüm/yemek değişince kendiliğinden
/// tazelenir — özellikle momentum hero'su (`last30WorkoutStats`), ki eski Future
/// hâlinde seans bitince invalidate edilmediği için "geç güncellenme" bug'ının
/// (H-05) kaynağıydı. `autoDispose`: Home'dan çıkınca bırakılır.

/// Son 30 gün: antrenman sayısı + toplam hacim + tahmini yakılan kalori.
/// (Takvim ayı yerine kayan pencere — momentum hero ayın 1'inde de dolu kalır.)
final last30WorkoutStatsProvider =
    StreamProvider.autoDispose<WorkoutAggregate>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(
      db, [db.workoutSessions, db.workoutSets, db.bodyMeasurements], () async {
    final wo = ref.read(workoutDaoProvider);
    final bw = (await ref.read(bodyDaoProvider).getLatestWeight())?.weightKg;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 30));
    final end = DateTime(today.year, today.month, today.day)
        .add(const Duration(days: 1));
    final sessions = await wo.getSessionsByDateRange(start, end);
    final sets = await wo.getSetsForSessions(sessions.map((s) => s.id).toList());
    return aggregateWorkouts(
        sessions: sessions, setsBySession: sets, bodyWeightKg: bw);
  });
});

/// Son ~6 haftada en çok gelişen hareket (e1RM artışı). Yeterli veri yoksa
/// null → içgörü kartı gösterilmez.
final topProgressProvider =
    StreamProvider.autoDispose<TopProgress?>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [db.workoutSessions, db.workoutSets], () async {
    final wo = ref.read(workoutDaoProvider);
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 42));
    final end = DateTime(today.year, today.month, today.day)
        .add(const Duration(days: 1));
    final points = await wo.getWeightedSetPointsInRange(start, end);
    return topProgressExercise(points);
  });
});
