import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';
import 'history_summary.dart';

/// Geçmiş listesindeki bir seansın özeti (docs/31).
class HistoryEntry {
  final WorkoutSession session;
  final List<ExerciseBrief> exercises;
  final SessionTotals totals;
  final int records;

  const HistoryEntry({
    required this.session,
    required this.exercises,
    required this.totals,
    required this.records,
  });
}

typedef WorkoutHistory = ({
  List<HistoryEntry> entries,
  Map<int, Exercise> exercisesById,
});

/// Tüm seansların özeti, yeniden eskiye — Geçmiş ekranı ve Antrenman
/// sekmesindeki "Son antrenmanlar". Setler tek sorguda (N+1 yok); rekorlar
/// tek geçişte. **Reaktif:** seans/set/hareket değişince tazelenir.
final workoutHistoryProvider = StreamProvider<WorkoutHistory>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [db.workoutSessions, db.workoutSets, db.exercises],
      () async {
    final dao = ref.read(workoutDaoProvider);
    final sessions = await dao.getAllSessions();
    final sets = await dao.getSetsForSessions(sessions.map((s) => s.id).toList());
    final usedIds = {for (final l in sets.values) ...l.map((s) => s.exerciseId)};
    final exercises = await dao.getExercisesByIds(usedIds);
    final records = recordCountsBySession(sessions, sets);
    return (
      entries: [
        for (final s in sessions)
          HistoryEntry(
            session: s,
            exercises: exerciseBriefs(sets[s.id] ?? const []),
            totals: sessionTotals(sets[s.id] ?? const []),
            records: records[s.id] ?? 0,
          ),
      ],
      exercisesById: {for (final e in exercises) e.id: e},
    );
  });
});
