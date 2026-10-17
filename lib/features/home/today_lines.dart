import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/prefs/training_prefs.dart';
import '../../core/utils/current_day.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/workout_dao.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';
import '../insights/insight_queries.dart';
import '../workout/progression.dart';
import '../workout/routine_providers.dart';
import '../workout/set_prefill.dart';

/// Ana Sayfa "Bugün" satırları (docs/50 Faz 1): Sıradaki antrenman kartının
/// altında en çok iki kısa satır — antrenman önerisi + beslenmede kalan.
///
/// Kural tabanlı, cihazda, ağ yok. Satırlar öneridir; hiçbir şeyi
/// kendiliğinden değiştirmez (Samet kuralı, 2026-09-17). Motor canlı seansla
/// AYNI (`progressionFor`, `computeTodayRemaining`) — sayılar tutarlı kalır.

/// Antrenman satırı: sıradaki rutinde uygulanabilir ilk ilerleme önerisi.
class TrainingLine {
  final String exerciseName;
  final ProgressionKind kind;

  /// Önerilen kilo (kg): kilo artışında yeni kilo, +1 tekrarda mevcut kilo.
  final double weightKg;

  /// Rutin önizlemesine gitmek için.
  final int routineId;

  const TrainingLine({
    required this.exerciseName,
    required this.kind,
    required this.weightKg,
    required this.routineId,
  });
}

/// Rutin hareketi + geçmiş setleri — [buildTrainingLine] girdisi.
class RoutineExerciseHistory {
  final RoutineExerciseWithExercise item;
  final List<WorkoutSet> lastSets;
  final List<WorkoutSet> prevSets;
  const RoutineExerciseHistory(this.item, this.lastSets, this.prevSets);
}

/// Rutin sırasıyla ilk "kilo artır" ya da "+1 tekrar" önerisi. Canlı
/// seanstaki `_adviceFor` ile aynı süzgeç: kilo×tekrar hareketi, rutin hedef
/// aralığı, ısınma setleri hariç. Öneri yoksa `null` — satır çıkmaz.
TrainingLine? buildTrainingLine({
  required int routineId,
  required List<RoutineExerciseHistory> exercises,
  required double incrementKg,
}) {
  for (final e in exercises) {
    final ex = e.item.exercise;
    final target = e.item.routineExercise;
    if (ex.measurementType != 'weight_reps') continue;
    final working = [for (final s in e.lastSets) if (!s.isWarmup) s];
    final advice = progressionFor(
      lastWorkingSets: [for (final s in working) SetValues.fromSet(s)],
      lastRpe: [for (final s in working) s.rpe],
      previousWorkingSets: [
        for (final s in e.prevSets)
          if (!s.isWarmup) SetValues.fromSet(s),
      ],
      repsMin: target.targetRepsMin,
      repsMax: target.targetRepsMax,
    );
    if (advice == null) continue;
    switch (advice.kind) {
      case ProgressionKind.increaseWeight:
        return TrainingLine(
          exerciseName: ex.name,
          kind: advice.kind,
          weightKg: advice.lastTopWeightKg + incrementKg,
          routineId: routineId,
        );
      case ProgressionKind.addRep:
        return TrainingLine(
          exerciseName: ex.name,
          kind: advice.kind,
          weightKg: advice.lastTopWeightKg,
          routineId: routineId,
        );
      case ProgressionKind.repeat:
      case ProgressionKind.holdAtFailure:
      case ProgressionKind.decreaseWeight:
        // Kilo düşürme yargı içerir; canlı seansta gerekçesiyle görünür,
        // Ana Sayfa'da değil (docs/50 §2: yalnız artır / +1 tekrar).
        continue;
    }
  }
  return null;
}

/// Beslenme satırı (docs/50 §2).
sealed class NutritionLine {
  const NutritionLine();
}

/// Bugün hiç öğün kaydı yok.
class NutritionLineFirstMeal extends NutritionLine {
  const NutritionLineFirstMeal();
}

/// Hedefe kalan; yalnız pozitif olanlar dolu (ikisi birden boş olmaz).
class NutritionLineRemaining extends NutritionLine {
  final int? proteinG;
  final int? kcal;
  const NutritionLineRemaining({this.proteinG, this.kcal});
}

/// Kayıt yoksa "ilk öğün"; hedef varsa ve kalan pozitifse kalan; hedef
/// tutmuş ya da hedef yoksa `null` (satır çıkmaz — "Harika iş!" yok).
NutritionLine? buildNutritionLine({
  required bool hasLogsToday,
  required TodayRemaining remaining,
}) {
  if (!hasLogsToday) return const NutritionLineFirstMeal();
  final p = remaining.remainingProtein;
  final k = remaining.remainingKcal;
  final protein = p != null && p >= 1 ? p.round() : null;
  final kcal = k != null && k >= 1 ? k.round() : null;
  if (protein == null && kcal == null) return null;
  return NutritionLineRemaining(proteinG: protein, kcal: kcal);
}

/// Antrenman satırı. Bugün seans yapıldıysa ya da sıradaki rutin yoksa
/// `null`. Rutin seçimi kartla aynı: bugüne planlı, yoksa döngüde sıradaki.
final todayTrainingLineProvider = StreamProvider<TrainingLine?>((ref) {
  final db = ref.watch(databaseProvider);
  final day = ref.watch(currentDayProvider);
  final incrementKg = ref.watch(effectiveIncrementKgProvider);
  final routine = ref.watch(todayRoutineProvider).valueOrNull;
  final r = routine?.today ?? routine?.upNext;
  return watchTables(
    db,
    [db.workoutSessions, db.workoutSets, db.routineExercises],
    () async {
      if (r == null) return null;
      final dao = ref.read(workoutDaoProvider);
      final done = await dao.getSessionsByDateRange(day, addDays(day, 1));
      if (done.isNotEmpty) return null;
      final items = await dao.getRoutineExercises(r.id);
      final history = <RoutineExerciseHistory>[];
      for (final it in items) {
        if (it.exercise.measurementType != 'weight_reps') continue;
        history.add(RoutineExerciseHistory(
          it,
          await dao.getLastSessionSetsForExercise(it.exercise.id),
          await dao.getPreviousSessionSetsForExercise(it.exercise.id),
        ));
      }
      return buildTrainingLine(
        routineId: r.id,
        exercises: history,
        incrementKg: incrementKg,
      );
    },
  );
});

/// Beslenme satırı — bugünkü kayıtlar + profil hedefleri.
final todayNutritionLineProvider = StreamProvider<NutritionLine?>((ref) {
  final db = ref.watch(databaseProvider);
  final day = ref.watch(currentDayProvider);
  return watchTables(db, [db.foodLogs, db.userProfile], () async {
    final logs = await ref
        .read(nutritionDaoProvider)
        .getLogsInRange(day, addDays(day, 1));
    final profile = await ref.read(userProfileDaoProvider).getProfile();
    final now = DateTime.now();
    final remaining = computeTodayRemaining(
      now: DateTime(day.year, day.month, day.day, now.hour, now.minute),
      logs: logs,
      kcalGoal: profile?.kcalGoal ?? 0,
      proteinGoal: profile?.proteinGoal ?? 0,
      maxSuggestions: 0,
    );
    return buildNutritionLine(
      hasLogsToday: logs.isNotEmpty,
      remaining: remaining,
    );
  });
});
