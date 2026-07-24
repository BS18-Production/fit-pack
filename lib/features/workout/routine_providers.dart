import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/prefs/week_start_provider.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/workout_dao.dart';

/// Antrenman V2 — rutin provider'ları (docs/09-workout-v2.md, Faz B).
/// Hepsi **reaktif** (H-05, `watchTables`) — ilgili tablo değişince tazelenir.

final activeRoutinesProvider = StreamProvider<List<Routine>>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [db.routines],
      () => ref.read(workoutDaoProvider).getActiveRoutines());
});

final routineExercisesProvider =
    StreamProvider.family<List<RoutineExerciseWithExercise>, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [db.routineExercises, db.exercises],
      () => ref.read(workoutDaoProvider).getRoutineExercises(id));
});

/// Bugünün rutini (Home dinlenme günü zekası). scheduledWeekday bugüne
/// eşit aktif rutin = antrenman günü; yoksa dinlenme + sıradaki rutin.
class TodayRoutine {
  final Routine? today; // bugüne planlı rutin (yoksa dinlenme)
  final Routine? next; // sıradaki planlı rutin
  const TodayRoutine({this.today, this.next});
  bool get isRestDay => today == null;
}

/// "Bugün" içerdiği için gün dönümünde `app.dart` bunu invalidate eder
/// (stream tablo değişimini bilir ama gece yarısını bilmez).
final todayRoutineProvider = StreamProvider<TodayRoutine>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [db.routines], () async {
    final routines = await ref.read(workoutDaoProvider).getActiveRoutines();
    final scheduled =
        routines.where((r) => r.scheduledWeekday != null).toList();
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
});

/// Bu hafta antrenman sayısı + toplam hacim (landing istatistik).
typedef WeekStats = ({int sessions, int volumeKg});

/// "Bu hafta" içerdiği için gün dönümünde `app.dart` bunu invalidate eder.
final weekWorkoutStatsProvider = StreamProvider<WeekStats>((ref) {
  final db = ref.watch(databaseProvider);
  final weekStart = ref.watch(weekStartProvider);
  return watchTables(db, [db.workoutSessions, db.workoutSets], () async {
    final dao = ref.read(workoutDaoProvider);
    final start = startOfWeek(DateTime.now(), weekStart);
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
});

// Haftaiçi adları artık locale'den üretilir (docs/14):
// `context.weekdayName/weekdayShort` — core/i18n/formatting.dart.

