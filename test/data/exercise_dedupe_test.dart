import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/seed/exercises_seed.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// #1 duplike temizliği — mergeExercise referansları koruyup duplikeyi siler.
void main() {
  late AppDatabase db;
  setUp(() => db = newTestDatabase());
  tearDown(() => db.close());

  test('mergeExercise: set + rutin referansı korunana taşınır, duplike silinir',
      () async {
    final dao = db.workoutDao;

    // İki "aynı" hareket: korunacak (küratörlü) + duplike (extended varyant).
    await dao.insertExercise(const ExercisesCompanion(
      name: Value('Muscle-Up'),
      category: Value('calisthenics'),
      muscleGroups: Value('["back"]'),
      isCustom: Value(false),
    ));
    await dao.insertExercise(const ExercisesCompanion(
      name: Value('Muscle Up'),
      category: Value('calisthenics'),
      muscleGroups: Value('["back"]'),
      isCustom: Value(false),
    ));
    final all = await dao.getAllExercises();
    final keep = all.firstWhere((e) => e.name == 'Muscle-Up');
    final dup = all.firstWhere((e) => e.name == 'Muscle Up');

    // Duplikeye bağlı bir seans + set.
    final sessionId = await dao.insertSession(WorkoutSessionsCompanion(
      date: Value(DateTime(2026, 6, 30)),
      phase: const Value(0),
      workoutType: const Value('Test'),
    ));
    await dao.insertSet(WorkoutSetsCompanion(
      sessionId: Value(sessionId),
      exerciseId: Value(dup.id),
      setNumber: const Value(1),
      reps: const Value(8),
    ));

    // Duplikeye bağlı bir rutin hareketi.
    final routineId = await dao.createRoutine(
        const RoutinesCompanion(name: Value('R')));
    await dao.addRoutineExercise(RoutineExercisesCompanion(
      routineId: Value(routineId),
      exerciseId: Value(dup.id),
      orderIndex: const Value(0),
    ));

    // Birleştir.
    await dao.mergeExercise(fromId: dup.id, toId: keep.id);

    // Duplike silindi.
    final after = await dao.getAllExercises();
    expect(after.where((e) => e.name == 'Muscle Up'), isEmpty);
    expect(after.where((e) => e.name == 'Muscle-Up'), hasLength(1));

    // Set artık korunan harekete bağlı (kayıp yok).
    final sets = await dao.getSetsForSession(sessionId);
    expect(sets, hasLength(1));
    expect(sets.single.exerciseId, keep.id);

    // Rutin hareketi de korunana taşındı.
    final rexs = await dao.getRoutineExercises(routineId);
    expect(rexs, hasLength(1));
    expect(rexs.single.exercise.id, keep.id);
  });

  test('yayınlanan katalogda kelime sırası/noktalama duplikesi yok (#1)', () {
    // 2026-09-18 ölçümü: gerçek cihazdaki 1015 harekette çakışma 0. Bu test
    // kaynak veriye bakar — yeni bir varyant eklenirse ("Bent Over Barbell
    // Row" ↔ "Bent-Over Barbell Row") burada yakalanır, kullanıcı iki ayrı
    // geçmişe bölünmeden önce.
    String norm(String n) {
      final words = n
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
          .split(' ')
          .where((w) => w.isNotEmpty)
          .toList()
        ..sort();
      return words.join(' ');
    }

    final names = <String>[
      for (final e in exerciseSeedData) e.name,
      for (final e in json.decode(
        File('assets/data/exercises_extended.json').readAsStringSync(),
      ) as List)
        (e as Map)['name'] as String,
    ];

    final byNorm = <String, List<String>>{};
    for (final n in names) {
      byNorm.putIfAbsent(norm(n), () => []).add(n);
    }
    final collisions = {
      for (final e in byNorm.entries)
        if (e.value.length > 1) e.key: e.value,
    };
    expect(collisions, isEmpty, reason: 'aynı hareketin iki yazımı var');
  });
}
