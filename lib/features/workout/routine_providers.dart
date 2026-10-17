import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/prefs/week_start_provider.dart';
import '../../core/utils/current_day.dart';
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

/// Arşivdeki rutinler (Antrenman sekmesi → Arşiv). Reaktif: arşivleme /
/// geri alma kendiliğinden yansır.
final archivedRoutinesProvider = StreamProvider<List<Routine>>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [db.routines],
      () => ref.read(workoutDaoProvider).getArchivedRoutines());
});

final routineExercisesProvider =
    StreamProvider.family<List<RoutineExerciseWithExercise>, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [db.routineExercises, db.exercises],
      () => ref.read(workoutDaoProvider).getRoutineExercises(id));
});

/// Bugünün rutini (Home dinlenme günü zekası). scheduledWeekday bugüne
/// eşit aktif rutin = antrenman günü; yoksa dinlenme + sıradaki rutin.
///
/// Hiçbir rutin güne bağlı değilse (hazır program kopyası, docs/28) sıra
/// döngüyle bulunur: son yapılan rutinden sonraki aktif rutin ([upNext],
/// docs/49 §3). Hiç aktif rutin yoksa [hasRoutines] false — Ana Sayfa iki
/// başlangıç yolunu gösterir.
class TodayRoutine {
  final Routine? today; // bugüne planlı rutin (yoksa dinlenme)
  final Routine? next; // sıradaki planlı rutin
  final Routine? upNext; // planlı rutin yokken döngüde sıradaki
  final bool hasRoutines;
  const TodayRoutine({
    this.today,
    this.next,
    this.upNext,
    this.hasRoutines = false,
  });
  bool get isRestDay => today == null;
}

/// Döngüde sıradaki rutin: [lastRoutineId]'den sonraki (sıralı listede,
/// başa sarar). Son yapılan listede yoksa ya da hiç yapılmadıysa ilk rutin.
Routine? rotationNext(List<Routine> active, int? lastRoutineId) {
  if (active.isEmpty) return null;
  final i = active.indexWhere((r) => r.id == lastRoutineId);
  return i < 0 ? active.first : active[(i + 1) % active.length];
}

/// Rutin süresi tahmini (dk): her set ~40 sn iş + hedef dinlenme. Hedef
/// yoksa 3 set / 90 sn varsayılır. 5'e yuvarlanır; boş rutinde null.
int? estimateRoutineMinutes(List<RoutineExercise> items) {
  if (items.isEmpty) return null;
  var sec = 0;
  for (final e in items) {
    final sets = e.targetSets ?? 3;
    sec += sets * (40 + (e.targetRestSec ?? 90));
  }
  final mins = (sec / 60 / 5).round() * 5;
  return mins < 5 ? 5 : mins;
}

/// "Bugün" içerdiği için [currentDayProvider]'ı izler (stream tablo
/// değişimini bilir ama gece yarısını bilmez).
final todayRoutineProvider = StreamProvider<TodayRoutine>((ref) {
  final db = ref.watch(databaseProvider);
  final day = ref.watch(currentDayProvider);
  return watchTables(db, [db.routines, db.workoutSessions], () async {
    final dao = ref.read(workoutDaoProvider);
    final routines = await dao.getActiveRoutines();
    final scheduled =
        routines.where((r) => r.scheduledWeekday != null).toList();
    if (scheduled.isEmpty) {
      if (routines.isEmpty) return const TodayRoutine();
      return TodayRoutine(
        hasRoutines: true,
        upNext: rotationNext(routines, await dao.getLastSessionRoutineId()),
      );
    }

    final wd = day.weekday; // 1=Pzt..7=Paz
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

    return TodayRoutine(today: today, next: next, hasRoutines: true);
  });
});

/// Bu hafta antrenman sayısı + toplam hacim (landing istatistik).
typedef WeekStats = ({int sessions, int volumeKg});

/// "Bu hafta" içerdiği için [currentDayProvider]'ı izler.
final weekWorkoutStatsProvider = StreamProvider<WeekStats>((ref) {
  final db = ref.watch(databaseProvider);
  final weekStart = ref.watch(weekStartProvider);
  final day = ref.watch(currentDayProvider);
  return watchTables(db, [db.workoutSessions, db.workoutSets], () async {
    final dao = ref.read(workoutDaoProvider);
    final start = startOfWeek(day, weekStart);
    final sessions =
        await dao.getSessionsByDateRange(start, addDays(start, 7));
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

