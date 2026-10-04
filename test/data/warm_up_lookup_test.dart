import 'package:drift/drift.dart' show Value;
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/seed/exercises_seed.dart';
import 'package:fit_pack/features/workout/workout_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Isınma kısayolu (docs/27 F3) hazır hareketi adıyla bulur; kullanıcının
/// aynı adla açtığı özel hareket ya da arşivlenmiş kayıt dönmemeli.
void main() {
  late AppDatabase db;
  setUp(() => db = newTestDatabase());
  tearDown(() => db.close());

  Future<void> ekle(String name, {bool custom = false, bool archived = false}) =>
      db.workoutDao.insertExercise(ExercisesCompanion(
        name: Value(name),
        category: const Value('flexibility'),
        muscleGroups: const Value('["full_body"]'),
        measurementType: const Value('time'),
        isCustom: Value(custom),
        isArchived: Value(archived),
      ));

  test('seed listesinde ısınma hareketi var ve süreli', () {
    final seed = exerciseSeedData
        .where((e) => e.name == WorkoutUi.warmUpExerciseName)
        .toList();
    expect(seed, hasLength(1));
    expect(WorkoutUi.isTimed(seed.single.measurement), isTrue);
  });

  test('özel ve arşivli kayıtlar atlanır, hazır olan döner', () async {
    await ekle(WorkoutUi.warmUpExerciseName, custom: true);
    await ekle(WorkoutUi.warmUpExerciseName, archived: true);
    expect(await db.workoutDao.getSeedExerciseByName(WorkoutUi.warmUpExerciseName),
        isNull);

    await ekle(WorkoutUi.warmUpExerciseName);
    final ex = await db.workoutDao
        .getSeedExerciseByName(WorkoutUi.warmUpExerciseName);
    expect(ex, isNotNull);
    expect(ex!.isCustom, isFalse);
    expect(ex.isArchived, isFalse);
  });
}
