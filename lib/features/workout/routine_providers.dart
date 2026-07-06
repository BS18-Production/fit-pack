import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/prefs/week_start_provider.dart';
import '../../data/providers.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/workout_dao.dart';

/// Antrenman V2 — rutin provider'ları (docs/09-workout-v2.md, Faz B).

final activeRoutinesProvider = FutureProvider<List<Routine>>((ref) {
  return ref.watch(workoutDaoProvider).getActiveRoutines();
});

final routineExercisesProvider =
    FutureProvider.family<List<RoutineExerciseWithExercise>, int>((ref, id) {
  return ref.watch(workoutDaoProvider).getRoutineExercises(id);
});

/// Bugünün rutini (Home dinlenme günü zekası). scheduledWeekday bugüne
/// eşit aktif rutin = antrenman günü; yoksa dinlenme + sıradaki rutin.
class TodayRoutine {
  final Routine? today; // bugüne planlı rutin (yoksa dinlenme)
  final Routine? next; // sıradaki planlı rutin
  const TodayRoutine({this.today, this.next});
  bool get isRestDay => today == null;
}

final todayRoutineProvider = FutureProvider<TodayRoutine>((ref) async {
  final routines = await ref.watch(activeRoutinesProvider.future);
  final scheduled = routines.where((r) => r.scheduledWeekday != null).toList();
  if (scheduled.isEmpty) return const TodayRoutine();

  final wd = DateTime.now().weekday; // 1=Pzt..7=Paz
  Routine? today;
  for (final r in scheduled) {
    if (r.scheduledWeekday == wd) {
      today = r;
      break;
    }
  }

  // Sıradaki planlı rutin (bugünden sonraki ilk gün, döngüsel).
  Routine? next;
  for (var i = 1; i <= 7; i++) {
    final day = (wd - 1 + i) % 7 + 1;
    final match = scheduled.where((r) => r.scheduledWeekday == day);
    if (match.isNotEmpty) {
      next = match.first;
      break;
    }
  }

  return TodayRoutine(today: today, next: next);
});

/// Bu hafta antrenman sayısı + toplam hacim (landing istatistik).
typedef WeekStats = ({int sessions, int volumeKg});

final weekWorkoutStatsProvider = FutureProvider<WeekStats>((ref) async {
  final dao = ref.watch(workoutDaoProvider);
  final start = startOfWeek(DateTime.now(), ref.watch(weekStartProvider));
  final sessions = await dao.getSessionsByDateRange(
      start, start.add(const Duration(days: 7)));
  int volume = 0;
  if (sessions.isNotEmpty) {
    final setsBySession =
        await dao.getSetsForSessions(sessions.map((s) => s.id).toList());
    for (final sets in setsBySession.values) {
      for (final s in sets) {
        volume += ((s.weightKg ?? 0) * (s.reps ?? 0)).round();
      }
    }
  }
  return (sessions: sessions.length, volumeKg: volume);
});

// Haftaiçi adları artık locale'den üretilir (docs/14):
// `context.weekdayName/weekdayShort` — core/i18n/formatting.dart.

