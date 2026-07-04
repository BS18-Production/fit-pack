import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers.dart';
import '../dashboard_stats.dart';
import 'home_providers.dart';

/// Ana Sayfa dashboard sağlayıcıları (docs: dashboard reskin).
///
/// Hepsi `autoDispose`: Home sekmesinden çıkınca atılır, dönünce taze
/// hesaplanır (antrenman/ölçüm/yemek değişiklikleri yansısın). AppShell
/// `context.go` ile route değiştirir (IndexedStack yok) → ekran dispose olur.
/// Ayrıca Home pull-to-refresh bunları elle invalidate eder.

({DateTime monday, DateTime nextMonday, DateTime prevMonday}) _weekBounds(
    DateTime now) {
  final monday = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
  return (
    monday: monday,
    nextMonday: monday.add(const Duration(days: 7)),
    prevMonday: monday.subtract(const Duration(days: 7)),
  );
}

/// Son 30 gün: antrenman sayısı + toplam hacim + tahmini yakılan kalori.
/// (Takvim ayı yerine kayan pencere — momentum hero ayın 1'inde de dolu kalır.)
final last30WorkoutStatsProvider =
    FutureProvider.autoDispose<WorkoutAggregate>((ref) async {
  final wo = ref.watch(workoutDaoProvider);
  final bw = (await ref.watch(latestWeightProvider.future))?.weightKg;
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day)
      .subtract(const Duration(days: 30));
  final end =
      DateTime(today.year, today.month, today.day).add(const Duration(days: 1));
  final sessions = await wo.getSessionsByDateRange(start, end);
  final sets = await wo.getSetsForSessions(sessions.map((s) => s.id).toList());
  return aggregateWorkouts(
      sessions: sessions, setsBySession: sets, bodyWeightKg: bw);
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
    FutureProvider.autoDispose<WeekDashboard>((ref) async {
  final wo = ref.watch(workoutDaoProvider);
  final nut = ref.watch(nutritionDaoProvider);
  final profile = await ref.watch(userProfileProvider.future);
  final bw = (await ref.watch(latestWeightProvider.future))?.weightKg;

  final b = _weekBounds(DateTime.now());

  final thisSessions = await wo.getSessionsByDateRange(b.monday, b.nextMonday);
  final thisSets =
      await wo.getSetsForSessions(thisSessions.map((s) => s.id).toList());
  final thisAgg = aggregateWorkouts(
      sessions: thisSessions, setsBySession: thisSets, bodyWeightKg: bw);

  final prevSessions = await wo.getSessionsByDateRange(b.prevMonday, b.monday);
  final prevSets =
      await wo.getSetsForSessions(prevSessions.map((s) => s.id).toList());
  final prevAgg = aggregateWorkouts(
      sessions: prevSessions, setsBySession: prevSets, bodyWeightKg: bw);

  // Planlı gün = aktif rutinlerin atadığı DISTINCT haftalık günler (yoksa null
  // → UI "X antrenman" gösterir, "X/Y" değil).
  final routines = await wo.getActiveRoutines();
  final scheduled =
      routines.map((r) => r.scheduledWeekday).whereType<int>().toSet();

  final logs = await nut.getLogsInRange(b.monday, b.nextMonday);

  return (
    workouts: thisAgg.sessions,
    scheduledDays: scheduled.isEmpty ? null : scheduled.length,
    volumeKg: thisAgg.volumeKg,
    volumeDeltaPct: volumeDeltaPct(thisAgg.volumeKg, prevAgg.volumeKg),
    kcalBurned: thisAgg.kcalBurned,
    proteinAvgPct: weeklyProteinAdherencePct(logs, profile?.proteinGoal ?? 0),
  );
});

/// Son ~6 haftada en çok gelişen hareket (e1RM artışı). Yeterli veri yoksa
/// null → içgörü kartı gösterilmez.
final topProgressProvider =
    FutureProvider.autoDispose<TopProgress?>((ref) async {
  final wo = ref.watch(workoutDaoProvider);
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day)
      .subtract(const Duration(days: 42));
  final end =
      DateTime(today.year, today.month, today.day).add(const Duration(days: 1));
  final points = await wo.getWeightedSetPointsInRange(start, end);
  return topProgressExercise(points);
});
