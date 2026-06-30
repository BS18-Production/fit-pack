import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/workout_tables.dart';

part 'workout_dao.g.dart';

@DriftAccessor(
    tables: [Exercises, WorkoutSessions, WorkoutSets, Routines, RoutineExercises])
class WorkoutDao extends DatabaseAccessor<AppDatabase> with _$WorkoutDaoMixin {
  WorkoutDao(super.db);

  // === Antrenman V2 — Rutinler (docs/09-workout-v2.md, Faz B) ===

  Future<List<Routine>> getActiveRoutines() => (select(routines)
        ..where((r) => r.isArchived.equals(false))
        ..orderBy([(r) => OrderingTerm.asc(r.orderIndex), (r) => OrderingTerm.asc(r.id)]))
      .get();

  Future<Routine?> getRoutine(int id) =>
      (select(routines)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<int> createRoutine(RoutinesCompanion entry) =>
      into(routines).insert(entry.createdAt.present
          ? entry
          : entry.copyWith(createdAt: Value(DateTime.now())));

  Future<bool> updateRoutine(RoutinesCompanion entry) =>
      update(routines).replace(entry);

  /// Rutini arşivler (silme yerine — geçmiş seanslar routineId ile bağlı).
  Future<void> archiveRoutine(int id) =>
      (update(routines)..where((r) => r.id.equals(id)))
          .write(const RoutinesCompanion(isArchived: Value(true)));

  /// Bir rutinin hareketleri (sıralı) + hareket bilgisiyle join.
  Future<List<RoutineExerciseWithExercise>> getRoutineExercises(
      int routineId) async {
    final q = select(routineExercises).join([
      innerJoin(exercises, exercises.id.equalsExp(routineExercises.exerciseId)),
    ])
      ..where(routineExercises.routineId.equals(routineId))
      ..orderBy([OrderingTerm.asc(routineExercises.orderIndex)]);
    final rows = await q.get();
    return rows
        .map((r) => RoutineExerciseWithExercise(
              r.readTable(routineExercises),
              r.readTable(exercises),
            ))
        .toList();
  }

  Future<int> addRoutineExercise(RoutineExercisesCompanion entry) =>
      into(routineExercises).insert(entry);

  /// Rutinin tüm hareketlerini siler (oluşturucuda yeniden yazmadan önce).
  Future<void> clearRoutineExercises(int routineId) =>
      (delete(routineExercises)..where((e) => e.routineId.equals(routineId)))
          .go();

  Future<int> routineExerciseCount(int routineId) async {
    final c = countAll(filter: routineExercises.routineId.equals(routineId));
    final q = selectOnly(routineExercises)..addColumns([c]);
    return (await q.getSingle()).read(c) ?? 0;
  }

  /// Bir hareketin tüm set geçmişi (tarihle, ısınma hariç) — eskiden yeniye.
  /// Hareket detayı: geçmiş listesi, grafik, PR hesabı (docs/09 Faz D).
  Future<List<ExerciseSetPoint>> getExerciseHistory(int exerciseId) async {
    final q = select(workoutSets).join([
      innerJoin(
          workoutSessions, workoutSessions.id.equalsExp(workoutSets.sessionId)),
    ])
      ..where(workoutSets.exerciseId.equals(exerciseId) &
          workoutSets.isWarmup.equals(false))
      ..orderBy([OrderingTerm.asc(workoutSessions.date)]);
    final rows = await q.get();
    return rows.map((r) {
      final s = r.readTable(workoutSets);
      final sess = r.readTable(workoutSessions);
      return ExerciseSetPoint(
        date: sess.date,
        weightKg: s.weightKg,
        reps: s.reps,
      );
    }).toList();
  }

  // === Exercises ===
  Future<List<Exercise>> getAllExercises() => select(exercises).get();

  Future<List<Exercise>> getExercisesByCategory(String category) =>
      (select(exercises)..where((e) => e.category.equals(category))).get();

  Future<Exercise?> getExerciseById(int id) =>
      (select(exercises)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<void> insertExercise(ExercisesCompanion entry) =>
      into(exercises).insert(entry);

  /// İki hareketi birleştir (#1 duplike temizliği): [fromId]'e bağlı tüm
  /// set ve rutin referanslarını [toId]'e taşır, sonra [fromId]'i siler.
  /// Kayıpsız — kullanıcının girdiği setler korunur, sadece doğru harekete bağlanır.
  Future<void> mergeExercise({required int fromId, required int toId}) async {
    await transaction(() async {
      await customUpdate(
        'UPDATE workout_sets SET exercise_id = ? WHERE exercise_id = ?',
        variables: [Variable.withInt(toId), Variable.withInt(fromId)],
        updates: {workoutSets},
      );
      await customUpdate(
        'UPDATE routine_exercises SET exercise_id = ? WHERE exercise_id = ?',
        variables: [Variable.withInt(toId), Variable.withInt(fromId)],
        updates: {routineExercises},
      );
      await (delete(exercises)..where((e) => e.id.equals(fromId))).go();
    });
  }

  Future<void> insertExercises(List<ExercisesCompanion> entries) async {
    await batch((b) => b.insertAll(exercises, entries));
  }

  // === Antrenman V2 — Hareket Kütüphanesi (docs/09-workout-v2.md) ===

  /// Arşivlenmemiş tüm hareketler (kütüphane). Özel olanlar üstte, sonra ada
  /// göre alfabetik.
  Future<List<Exercise>> getLibraryExercises() async {
    final list = await (select(exercises)
          ..where((e) => e.isArchived.equals(false))
          ..orderBy([
            (e) => OrderingTerm.desc(e.isCustom),
            (e) => OrderingTerm.asc(e.name),
          ]))
        .get();
    return list;
  }

  Future<int> insertCustomExercise(ExercisesCompanion entry) =>
      into(exercises).insert(entry);

  /// Hareketi arşivle (silme yerine — geçmiş set'ler FK ile bağlı kalır).
  Future<bool> archiveExercise(int id) =>
      (update(exercises)..where((e) => e.id.equals(id)))
          .write(const ExercisesCompanion(isArchived: Value(true)))
          .then((n) => n > 0);

  Future<bool> updateExerciseMeta(int id, ExercisesCompanion meta) =>
      (update(exercises)..where((e) => e.id.equals(id)))
          .write(meta)
          .then((n) => n > 0);

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

  /// Seansı ve ona bağlı tüm setleri siler (FK sırası: önce setler).
  Future<void> deleteSessionWithSets(int id) => transaction(() async {
        await (delete(workoutSets)..where((s) => s.sessionId.equals(id))).go();
        await (delete(workoutSessions)..where((s) => s.id.equals(id))).go();
      });

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

}

/// Rutin hareketi + hareket bilgisi (join sonucu — UI'da ad/ekipman göster).
class RoutineExerciseWithExercise {
  final RoutineExercise routineExercise;
  final Exercise exercise;
  const RoutineExerciseWithExercise(this.routineExercise, this.exercise);
}

/// Hareket geçmişinde tek set noktası (tarih + kg + tekrar).
class ExerciseSetPoint {
  final DateTime date;
  final double? weightKg;
  final int? reps;
  const ExerciseSetPoint({required this.date, this.weightKg, this.reps});

  /// Tahmini 1RM (Epley): kg × (1 + tekrar/30).
  double? get e1rm =>
      (weightKg != null && reps != null && weightKg! > 0 && reps! > 0)
          ? weightKg! * (1 + reps! / 30)
          : null;
}
