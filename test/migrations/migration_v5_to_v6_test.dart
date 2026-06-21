import 'package:drift/drift.dart' show Value;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'schema/schema.dart';
import 'schema/schema_v5.dart' as v5;

/// v5 → v6 göç testi (Antrenman V2 Faz B+C — docs/09-workout-v2.md).
///
/// v6: routines + routine_exercises tabloları, workout_sessions
/// +routineId/+startedAt/+endedAt, workout_sets +rpe/+setType/+isComplete/
/// +distanceM/+durationSec. Hepsi additive → eski seans/set kayıpsız.
void main() {
  late SchemaVerifier verifier;
  setUp(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v5 → v6 şema göçü yapısal olarak geçerli', () async {
    final connection = await verifier.startAt(5);
    final db = AppDatabase.forTesting(connection);
    await verifier.migrateAndValidate(db, 6);
    await db.close();
  });

  test('v5 → v6 lossless: eski seans + set korunur, rutin tablosu çalışır',
      () async {
    final schema = await verifier.schemaAt(5);

    // v5 şemasıyla eski bir seans + hareket + set yaz.
    final oldDb = v5.DatabaseAtV5(schema.newConnection());
    await oldDb.customStatement(
      "INSERT INTO exercises (name, category, muscle_groups, measurement_type, "
      "is_custom, is_archived, is_posture, is_arm) "
      "VALUES ('Bench Press', 'compound', '[\"chest\"]', 'weight_reps', 0, 0, 0, 0)",
    );
    await oldDb.customStatement(
      "INSERT INTO workout_sessions (date, phase, workout_type, knee_status, is_deload) "
      "VALUES (1700000000, 3, 'UpperA', 'normal', 0)",
    );
    await oldDb.customStatement(
      "INSERT INTO workout_sets (session_id, exercise_id, set_number, weight_kg, "
      "reps, is_warmup) VALUES (1, 1, 1, 60.0, 8, 0)",
    );
    await oldDb.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, 6);

    // Eski seans + set korundu.
    final sessions = await db.workoutDao.getAllSessions();
    expect(sessions, hasLength(1));
    expect(sessions.single.workoutType, 'UpperA');
    final sets = await db.workoutDao.getSetsForSession(sessions.single.id);
    expect(sets, hasLength(1));
    expect(sets.single.weightKg, 60.0);
    // Yeni set kolonu default geldi.
    expect(sets.single.setType, 'normal');
    expect(sets.single.isComplete, isFalse);

    // Rutin tablosu çalışıyor: oluştur + hareket ekle.
    final rid = await db.workoutDao.createRoutine(
        const RoutinesCompanion(name: Value('Push Day')));
    await db.workoutDao.addRoutineExercise(RoutineExercisesCompanion(
      routineId: Value(rid),
      exerciseId: const Value(1),
      orderIndex: const Value(0),
      targetSets: const Value(3),
    ));
    final routines = await db.workoutDao.getActiveRoutines();
    expect(routines, hasLength(1));
    expect(routines.single.name, 'Push Day');

    await db.close();
  });
}
