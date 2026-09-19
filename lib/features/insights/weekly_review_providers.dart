import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/prefs/week_start_provider.dart';
import '../../data/database/app_database.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';
import 'weekly_review.dart';

/// Haftalık değerlendirme (docs/22). Parametre = kaç hafta geriye:
/// 0 bu hafta, 1 geçen hafta.
/// **Reaktif**: antrenman, beslenme, ölçüm
/// ya da profil değişince kendiliğinden yeniden hesaplanır (`watchTables`,
/// H-05) — elle `invalidate` gerektirmez.
///
/// Motor saf; bu sağlayıcı yalnız girdiyi toplar. Sayılar ana sayfayla AYNI
/// fonksiyondan geçer (W-9).
final weeklyReviewProvider =
    StreamProvider.autoDispose.family<WeeklyReview, int>((ref, offset) {
  final db = ref.watch(databaseProvider);
  final weekStart = ref.watch(weekStartProvider);
  return watchTables(db, [
    db.workoutSessions,
    db.workoutSets,
    db.routines,
    db.routineExercises,
    db.foodLogs,
    db.bodyMeasurements,
    db.userProfile,
  ], () async {
    final wo = ref.read(workoutDaoProvider);
    final nut = ref.read(nutritionDaoProvider);
    final body = ref.read(bodyDaoProvider);
    final profile = await ref.read(userProfileDaoProvider).getProfile();

    final now = DateTime.now();
    final start = startOfWeek(now, weekStart)
        .subtract(Duration(days: 7 * offset));
    final end = start.add(const Duration(days: 7));
    final prevStart = start.subtract(const Duration(days: 7));

    final sessions = await wo.getSessionsByDateRange(start, end);
    final sets = await wo.getSetsForSessions(sessions.map((s) => s.id).toList());
    final prevSessions = await wo.getSessionsByDateRange(prevStart, start);
    final prevSets =
        await wo.getSetsForSessions(prevSessions.map((s) => s.id).toList());

    // Hareket ilerlemesi + "3 haftadır aynı kilo" kuralı: bu hafta + önceki 3.
    final points = await wo.getWeightedSetPointsInRange(
      start.subtract(const Duration(days: 21)),
      end,
      onlyComplete: true,
    );

    final exerciseIds = <int>{
      for (final list in sets.values)
        for (final st in list) st.exerciseId,
    };
    final exercises = {
      for (final e in await wo.getExercisesByIds(exerciseIds)) e.id: e,
    };

    // Aktif rutinlerin planlı günleri + hareket başına hedef tekrar üst sınırı.
    final routines = await wo.getActiveRoutines();
    final scheduled =
        routines.map((r) => r.scheduledWeekday).whereType<int>().toSet();
    final targetMax = <int, int>{};
    for (final r in routines) {
      for (final re in await wo.getRoutineExercises(r.id)) {
        final max = re.routineExercise.targetRepsMax;
        if (max == null) continue;
        final id = re.exercise.id;
        // Aynı hareket iki rutinde farklı aralıkla varsa düşük olanı al:
        // "aralığın üstünde" iddiası ancak ikisini de aşınca doğru olur.
        final cur = targetMax[id];
        targetMax[id] = cur == null || max < cur ? max : cur;
      }
    }

    return buildWeeklyReview(WeeklyReviewInput(
      weekStart: start,
      now: now,
      sessions: sessions,
      setsBySession: sets,
      prevSessions: prevSessions,
      prevSetsBySession: prevSets,
      exercises: exercises,
      scheduledWeekdays: scheduled,
      targetRepsMaxByExercise: targetMax,
      progressPoints: points,
      foodLogs: await nut.getLogsInRange(start, end),
      kcalGoal: profile?.kcalGoal ?? 0,
      proteinGoal: profile?.proteinGoal ?? 0,
      measurements: await body.getMeasurementsInRange(
          start.subtract(const Duration(days: 14)), end),
      bodyWeightKg: (await body.getLatestWeight())?.weightKg,
      goalDirection: GoalDirection.tryParse(profile?.goalDirection),
      goalDirectionSince: profile?.goalDirectionSince,
    ));
  });
});

/// Profildeki hedef çelişkisi (docs/22 §9 soru 2): seçilen yön ile hedef kilo
/// birbirini tutmuyor mu? Örn. "kilo al" seçili ama hedef kilo şu ankinin
/// altında. **Otomatik düzeltme YOK** — ekran yalnız fark ettirir, hedefi
/// kullanıcı değiştirir.
bool goalConflicts({
  required GoalDirection? direction,
  required double? goalWeightKg,
  required double? currentWeightKg,
}) {
  if (direction == null || goalWeightKg == null || currentWeightKg == null) {
    return false;
  }
  const pay = 1.0; // kg — küçük farklar çelişki sayılmaz
  return switch (direction) {
    GoalDirection.gain => goalWeightKg < currentWeightKg - pay,
    GoalDirection.lose => goalWeightKg > currentWeightKg + pay,
    GoalDirection.maintain => (goalWeightKg - currentWeightKg).abs() > 3,
  };
}

/// Hedef çelişkisi için gereken iki değer — ekran bunu izler.
final goalConflictProvider = StreamProvider.autoDispose<bool>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [db.userProfile, db.bodyMeasurements], () async {
    final UserProfileData? p =
        await ref.read(userProfileDaoProvider).getProfile();
    final w = (await ref.read(bodyDaoProvider).getLatestWeight())?.weightKg;
    return goalConflicts(
      direction: GoalDirection.tryParse(p?.goalDirection),
      goalWeightKg: p?.goalWeightKg,
      currentWeightKg: w,
    );
  });
});
