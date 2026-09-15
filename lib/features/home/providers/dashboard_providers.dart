import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/prefs/week_start_provider.dart';
import '../../../data/providers.dart';
import '../../../data/reactive.dart';
import '../dashboard_stats.dart';

/// Ana Sayfa dashboard sağlayıcıları (docs: dashboard reskin).
///
/// **Reaktif** (H-05, `watchTables`): antrenman/ölçüm/yemek değişince kendiliğinden
/// tazelenir — özellikle momentum hero'su (`last30WorkoutStats`), ki eski Future
/// hâlinde seans bitince invalidate edilmediği için "geç güncellenme" bug'ının
/// (H-05) kaynağıydı. `autoDispose`: Home'dan çıkınca bırakılır.

({DateTime start, DateTime next, DateTime prev}) _weekBounds(
    DateTime now, int weekStart) {
  final start = startOfWeek(now, weekStart);
  return (
    start: start,
    next: start.add(const Duration(days: 7)),
    prev: start.subtract(const Duration(days: 7)),
  );
}

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

/// "Bu Hafta" 2×2 grid verisi: antrenman/planlı gün, hacim+değişim, yakılan
/// kcal, protein hedefi ortalaması. Hepsi gerçek veriden.
typedef WeekDashboard = ({
  int workouts,
  int? scheduledDays,
  int volumeKg,
  int? volumeDeltaPct,
  int kcalBurned,
  int? proteinAvgPct,
});

final weekDashboardProvider =
    StreamProvider.autoDispose<WeekDashboard>((ref) {
  final db = ref.watch(databaseProvider);
  final weekStart = ref.watch(weekStartProvider);
  return watchTables(db, [
    db.workoutSessions,
    db.workoutSets,
    db.routines,
    db.foodLogs,
    db.userProfile,
    db.bodyMeasurements,
  ], () async {
    final wo = ref.read(workoutDaoProvider);
    final nut = ref.read(nutritionDaoProvider);
    final profile = await ref.read(userProfileDaoProvider).getProfile();
    final bw = (await ref.read(bodyDaoProvider).getLatestWeight())?.weightKg;

    final b = _weekBounds(DateTime.now(), weekStart);

    final thisSessions = await wo.getSessionsByDateRange(b.start, b.next);
    final thisSets =
        await wo.getSetsForSessions(thisSessions.map((s) => s.id).toList());
    final thisAgg = aggregateWorkouts(
        sessions: thisSessions, setsBySession: thisSets, bodyWeightKg: bw);

    final prevSessions = await wo.getSessionsByDateRange(b.prev, b.start);
    final prevSets =
        await wo.getSetsForSessions(prevSessions.map((s) => s.id).toList());
    final prevAgg = aggregateWorkouts(
        sessions: prevSessions, setsBySession: prevSets, bodyWeightKg: bw);

    // Planlı gün = aktif rutinlerin atadığı DISTINCT haftalık günler (yoksa null
    // → UI "X antrenman" gösterir, "X/Y" değil).
    final routines = await wo.getActiveRoutines();
    final scheduled =
        routines.map((r) => r.scheduledWeekday).whereType<int>().toSet();

    final logs = await nut.getLogsInRange(b.start, b.next);

    return (
      workouts: thisAgg.sessions,
      scheduledDays: scheduled.isEmpty ? null : scheduled.length,
      volumeKg: thisAgg.volumeKg,
      volumeDeltaPct: volumeDeltaPct(thisAgg.volumeKg, prevAgg.volumeKg),
      kcalBurned: thisAgg.kcalBurned,
      proteinAvgPct: weeklyProteinAdherencePct(logs, profile?.proteinGoal ?? 0),
    );
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
