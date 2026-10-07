import 'package:drift/drift.dart' hide isNull;
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/seed/exercises_seed.dart';
import 'package:fit_pack/features/explore/program_catalog.dart';
import 'package:fit_pack/features/explore/program_install.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// docs/28 — hazır program kataloğu.
void main() {
  final seedNames = {for (final e in exerciseSeedData) e.name};

  group('katalog bekçisi', () {
    test('9 program: 3 seviye × 3 bölünme, anahtarlar tekil', () {
      expect(programCatalog, hasLength(9));
      expect(programCatalog.map((p) => p.key).toSet(), hasLength(9));
      for (final lv in ProgramLevel.values) {
        for (final sp in ProgramSplit.values) {
          expect(
              programCatalog.where((p) => p.level == lv && p.split == sp),
              hasLength(1),
              reason: '$lv × $sp');
        }
      }
    });

    test('her hareket adı seed\'de birebir var', () {
      for (final p in programCatalog) {
        for (final r in p.routines) {
          for (final e in r.exercises) {
            expect(seedNames, contains(e.name), reason: '${p.key} / ${e.name}');
          }
        }
      }
    });

    test('hedefler mantıklı: set 2–5, tekrar aralığı geçerli, rutin ≥ 5 hareket',
        () {
      for (final p in programCatalog) {
        for (final r in p.routines) {
          expect(r.exercises.length, greaterThanOrEqualTo(5),
              reason: '${p.key} ${r.name}');
          for (final e in r.exercises) {
            expect(e.sets, inInclusiveRange(2, 5), reason: e.name);
            expect(e.repsMin, lessThanOrEqualTo(e.repsMax), reason: e.name);
            expect(e.repsMin, greaterThanOrEqualTo(3), reason: e.name);
          }
        }
      }
    });
  });

  group('programı ekle', () {
    late AppDatabase db;
    setUp(() async {
      db = newTestDatabase();
      // Seed hareketleri (yalnız katalogda geçenler yeter).
      for (final e in exerciseSeedData) {
        await db.into(db.exercises).insert(ExercisesCompanion.insert(
              name: e.name,
              category: e.category,
              muscleGroups: '[]',
              primaryMuscle: Value(e.primaryMuscle),
              equipment: Value(e.equipment),
              measurementType: Value(e.measurement),
            ));
      }
    });
    tearDown(() => db.close());

    test('rutinler sona, program anahtarıyla, hedefleriyle kopyalanır',
        () async {
      final l = await AppL10n.delegate.load(const Locale('tr'));
      await db.workoutDao.createRoutine(
          const RoutinesCompanion(name: Value('Benim'), orderIndex: Value(0)));
      final p = programByKey('ppl_intermediate')!;

      final ids = await installCatalogProgram(db.workoutDao, l, p);

      expect(ids, hasLength(3));
      final routines = await db.workoutDao.getActiveRoutines();
      expect(routines.map((r) => r.name), ['Benim', 'İtme', 'Çekme', 'Bacak']);
      expect(routines.skip(1).every((r) => r.programKey == p.key), isTrue);
      expect(routines.first.programKey, isNull);

      final push = await db.workoutDao.getRoutineExercises(ids.first);
      expect(push, hasLength(p.routines.first.exercises.length));
      final bench = push.first;
      expect(bench.exercise.name, 'Barbell Bench Press');
      expect(bench.routineExercise.targetSets, 4);
      expect(
          (bench.routineExercise.targetRepsMin,
              bench.routineExercise.targetRepsMax),
          (6, 8));
      expect(bench.routineExercise.targetRestSec, 180);
    });
  });
}
