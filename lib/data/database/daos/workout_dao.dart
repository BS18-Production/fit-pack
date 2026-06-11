import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/workout_tables.dart';

part 'workout_dao.g.dart';

@DriftAccessor(tables: [Exercises, WorkoutSessions, WorkoutSets])
class WorkoutDao extends DatabaseAccessor<AppDatabase> with _$WorkoutDaoMixin {
  WorkoutDao(super.db);

  // === Exercises ===
  Future<List<Exercise>> getAllExercises() => select(exercises).get();

  Future<List<Exercise>> getExercisesByCategory(String category) =>
      (select(exercises)..where((e) => e.category.equals(category))).get();

  Future<List<Exercise>> getPostureExercises() =>
      (select(exercises)..where((e) => e.isPosture.equals(true))).get();

  Future<void> insertExercise(ExercisesCompanion entry) =>
      into(exercises).insert(entry);

  Future<void> insertExercises(List<ExercisesCompanion> entries) async {
    await batch((b) => b.insertAll(exercises, entries));
  }

  // === Workout Sessions ===
  Future<List<WorkoutSession>> getAllSessions() =>
      (select(workoutSessions)..orderBy([(s) => OrderingTerm.desc(s.date)])).get();

  Future<List<WorkoutSession>> getSessionsByDateRange(DateTime start, DateTime end) =>
      (select(workoutSessions)
            ..where((s) => s.date.isBetweenValues(start, end))
            ..orderBy([(s) => OrderingTerm.desc(s.date)]))
          .get();

  Future<WorkoutSession?> getLastSession() =>
      (select(workoutSessions)
            ..orderBy([(s) => OrderingTerm.desc(s.date)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> insertSession(WorkoutSessionsCompanion entry) =>
      into(workoutSessions).insert(entry);

  Future<bool> updateSession(WorkoutSession entry) =>
      update(workoutSessions).replace(entry);

  Future<int> deleteSession(int id) =>
      (delete(workoutSessions)..where((s) => s.id.equals(id))).go();

  // === Workout Sets ===
  Future<List<WorkoutSet>> getSetsForSession(int sessionId) =>
      (select(workoutSets)
            ..where((s) => s.sessionId.equals(sessionId))
            ..orderBy([(s) => OrderingTerm.asc(s.setNumber)]))
          .get();

  /// Bulk-fetch all sets across sessions in [sessionIds]. Used by export to
  /// avoid N+1 round-trips. Returns empty map when [sessionIds] is empty.
  Future<Map<int, List<WorkoutSet>>> getSetsForSessions(
    List<int> sessionIds,
  ) async {
    if (sessionIds.isEmpty) return const {};
    final rows = await (select(workoutSets)
          ..where((s) => s.sessionId.isIn(sessionIds))
          ..orderBy([
            (s) => OrderingTerm.asc(s.sessionId),
            (s) => OrderingTerm.asc(s.setNumber),
          ]))
        .get();
    final grouped = <int, List<WorkoutSet>>{};
    for (final r in rows) {
      grouped.putIfAbsent(r.sessionId, () => []).add(r);
    }
    return grouped;
  }

  Future<void> insertSet(WorkoutSetsCompanion entry) =>
      into(workoutSets).insert(entry);

  Future<void> insertSets(List<WorkoutSetsCompanion> entries) async {
    await batch((b) => b.insertAll(workoutSets, entries));
  }

  Future<bool> updateSet(WorkoutSet entry) =>
      update(workoutSets).replace(entry);

  Future<int> deleteSet(int id) =>
      (delete(workoutSets)..where((s) => s.id.equals(id))).go();

  // === Analytics ===
  Future<int> getSessionCount() async {
    final count = countAll();
    final query = selectOnly(workoutSessions)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<int> getSessionCountInRange(DateTime start, DateTime end) async {
    final count = countAll();
    final query = selectOnly(workoutSessions)
      ..addColumns([count])
      ..where(workoutSessions.date.isBetweenValues(start, end));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Bu antrenman tipinin (örn. FullA) EN SON seansı + setleri. Seans
  /// ekranında "geçen seans" ghost değerleri için: kullanıcı her sette
  /// neyi geçmesi gerektiğini görür (progressive overload'un kalbi).
  Future<(WorkoutSession, List<WorkoutSet>)?> getLastSessionWithSets(
      String workoutType) async {
    final session = await (select(workoutSessions)
          ..where((s) => s.workoutType.equals(workoutType))
          ..orderBy([(s) => OrderingTerm.desc(s.date)])
          ..limit(1))
        .getSingleOrNull();
    if (session == null) return null;
    final sets = await getSetsForSession(session.id);
    return (session, sets);
  }

  /// Get the last recorded weight for an exercise
  Future<WorkoutSet?> getLastSetForExercise(int exerciseId) async {
    final query = select(workoutSets).join([
      innerJoin(workoutSessions, workoutSessions.id.equalsExp(workoutSets.sessionId)),
    ])
      ..where(workoutSets.exerciseId.equals(exerciseId) & workoutSets.isWarmup.equals(false))
      ..orderBy([OrderingTerm.desc(workoutSessions.date), OrderingTerm.desc(workoutSets.setNumber)])
      ..limit(1);
    final result = await query.getSingleOrNull();
    return result?.readTable(workoutSets);
  }

  /// Weekly posture volume (total sets)
  Future<int> getWeeklyPostureVolume(DateTime weekStart, DateTime weekEnd) async {
    final count = countAll();
    final query = selectOnly(workoutSets).join([
      innerJoin(exercises, exercises.id.equalsExp(workoutSets.exerciseId)),
      innerJoin(workoutSessions, workoutSessions.id.equalsExp(workoutSets.sessionId)),
    ])
      ..addColumns([count])
      ..where(exercises.isPosture.equals(true) &
          workoutSets.isWarmup.equals(false) &
          workoutSessions.date.isBetweenValues(weekStart, weekEnd));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}
