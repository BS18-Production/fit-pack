import 'package:drift/drift.dart' show Value;
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/seed/seed_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

/// Seed v5 (2026-10-04): mevcut kurulumda "Hammer Curls" (çoğul tekrar)
/// "Hammer Curl"e birleşir — tekrara bağlı set kaybolmaz; "Neutral Grip Lat
/// Pulldown" eklenir ve görsel alır.
void main() {
  testWidgets('v4 kurulum açılışta v5 olur: tekrar birleşir, set korunur',
      (tester) async {
    SharedPreferences.setMockInitialValues({SeedManager.seedVersionKey: 4});
    final db = newTestDatabase();
    addTearDown(db.close);
    final dao = db.workoutDao;

    Future<int> hareket(String name) => dao.insertCustomExercise(
          ExercisesCompanion.insert(
            name: name,
            category: 'isolation',
            muscleGroups: '["biceps"]',
            isCustom: const Value(false),
          ),
        );
    final keepId = await hareket('Hammer Curl');
    final dupId = await hareket('Hammer Curls');
    final sessionId = await dao.insertSession(WorkoutSessionsCompanion(
      date: Value(DateTime(2026, 9, 1)),
      phase: const Value(1),
      workoutType: const Value('A'),
    ));
    await dao.insertSet(WorkoutSetsCompanion(
      sessionId: Value(sessionId),
      exerciseId: Value(dupId),
      setNumber: const Value(1),
      weightKg: const Value(12),
      reps: const Value(10),
    ));

    await tester.runAsync(() => SeedManager(db).seedIfNeeded());

    final all = await tester.runAsync(dao.getAllExercises);
    expect(all!.where((e) => e.name == 'Hammer Curls'), isEmpty);
    expect(all.where((e) => e.name == 'Hammer Curl'), hasLength(1));
    final sets = await tester.runAsync(() => dao.getSetsForSession(sessionId));
    expect(sets!.single.exerciseId, keepId, reason: 'set korunan harekete taşınır');

    final neutral = all.where((e) => e.name == 'Neutral Grip Lat Pulldown');
    expect(neutral, hasLength(1));
    expect(neutral.single.imagePath, isNotNull);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(SeedManager.seedVersionKey), SeedManager.seedVersion);
  });
}
