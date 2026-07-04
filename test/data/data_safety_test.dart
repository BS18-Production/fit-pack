import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/settings/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Batch 1 — Veri güvenliği regresyonları (CODE_REVIEW.md: C-01, H-06, M-05).
/// Seans/rutin yazımlarının atomikliği + yedek şema sürümü okuyucusu.
void main() {
  late AppDatabase db;

  setUp(() => db = newTestDatabase());
  tearDown(() => db.close());

  Future<int> insertExercise(String name) =>
      db.workoutDao.insertCustomExercise(ExercisesCompanion(
        name: Value(name),
        category: const Value('push'),
        muscleGroups: const Value('[]'),
      ));

  group('insertSessionWithSets (H-06)', () {
    test('seans + setler birlikte yazılır', () async {
      final exId = await insertExercise('Bench Press');
      final id = await db.workoutDao.insertSessionWithSets(
        WorkoutSessionsCompanion(
          date: Value(DateTime(2026, 7, 1, 18)),
          phase: const Value(0),
          workoutType: const Value('Push Day'),
        ),
        (sessionId) => [
          WorkoutSetsCompanion(
            sessionId: Value(sessionId),
            exerciseId: Value(exId),
            setNumber: const Value(1),
            weightKg: const Value(60),
            reps: const Value(8),
          ),
          WorkoutSetsCompanion(
            sessionId: Value(sessionId),
            exerciseId: Value(exId),
            setNumber: const Value(2),
            weightKg: const Value(60),
            reps: const Value(7),
          ),
        ],
      );

      final sets = await db.workoutDao.getSetsForSession(id);
      expect(sets, hasLength(2));
      expect((await db.workoutDao.getAllSessions()), hasLength(1));
    });

    test('set yazımı başarısız olursa seans da yazılmaz (rollback)', () async {
      await insertExercise('Bench Press');
      await expectLater(
        db.workoutDao.insertSessionWithSets(
          WorkoutSessionsCompanion(
            date: Value(DateTime(2026, 7, 1, 18)),
            phase: const Value(0),
            workoutType: const Value('Push Day'),
          ),
          // Var olmayan exerciseId → FK ihlali → transaction geri alınmalı.
          (sessionId) => [
            WorkoutSetsCompanion(
              sessionId: Value(sessionId),
              exerciseId: const Value(999999),
              setNumber: const Value(1),
              weightKg: const Value(60),
              reps: const Value(8),
            ),
          ],
        ),
        throwsA(anything),
      );

      expect(await db.workoutDao.getAllSessions(), isEmpty,
          reason: 'Yarım seans DB\'de kalmamalı');
    });
  });

  group('saveRoutineWithExercises (M-05)', () {
    test('düzenleme yarıda kesilirse mevcut hareket listesi korunur',
        () async {
      final exId = await insertExercise('Squat');
      final routineId = await db.workoutDao.saveRoutineWithExercises(
        routine: const RoutinesCompanion(name: Value('Leg Day')),
        isNew: true,
        buildExercises: (id) => [
          RoutineExercisesCompanion(
            routineId: Value(id),
            exerciseId: Value(exId),
            orderIndex: const Value(0),
          ),
        ],
      );
      expect(await db.workoutDao.getRoutineExercises(routineId), hasLength(1));

      // Düzenleme: "sil + yeniden yaz" içinde FK ihlaliyle patlat.
      final existing = (await db.workoutDao.getRoutine(routineId))!;
      await expectLater(
        db.workoutDao.saveRoutineWithExercises(
          routine: RoutinesCompanion(
            id: Value(routineId),
            name: const Value('Leg Day v2'),
            createdAt: Value(existing.createdAt),
            orderIndex: Value(existing.orderIndex),
            isArchived: Value(existing.isArchived),
            scheduledWeekday: const Value(null),
          ),
          isNew: false,
          buildExercises: (id) => [
            RoutineExercisesCompanion(
              routineId: Value(id),
              exerciseId: const Value(999999), // FK ihlali
              orderIndex: const Value(0),
            ),
          ],
        ),
        throwsA(anything),
      );

      // Transaction geri alındı: ad eski, hareket listesi duruyor.
      final after = (await db.workoutDao.getRoutine(routineId))!;
      expect(after.name, 'Leg Day');
      expect(await db.workoutDao.getRoutineExercises(routineId), hasLength(1),
          reason: 'clearRoutineExercises geri alınmış olmalı');
    });
  });

  group('readSqliteUserVersion (C-01/L-07)', () {
    test('gerçek DB dosyasından şema sürümünü okur', () async {
      final dir = await Directory.systemTemp.createTemp('fit_pack_test');
      final file = File('${dir.path}/version_probe.sqlite');
      // Gerçek bir drift DB'si oluştur → user_version = schemaVersion yazılır.
      final probe = AppDatabase.forTesting(NativeDatabase(file));
      await probe.customSelect('SELECT 1').get(); // aç + migration
      await probe.close();

      expect(await readSqliteUserVersion(file), db.schemaVersion);
      await dir.delete(recursive: true);
    });

    test('kısa/bozuk dosyada 0 döner', () async {
      final dir = await Directory.systemTemp.createTemp('fit_pack_test');
      final file = File('${dir.path}/short.bin');
      await file.writeAsBytes([1, 2, 3]);
      expect(await readSqliteUserVersion(file), 0);
      await dir.delete(recursive: true);
    });
  });
}
