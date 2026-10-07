import 'package:drift/drift.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Arşivlenen rutin görünür olmalı ve geri alınabilmeli (Samet, 2026-10-07:
/// "Arşivlenen rutinler nereye gidiyor?" — önceden hiçbir yerde görünmüyordu).
void main() {
  late AppDatabase db;
  setUp(() => db = newTestDatabase());
  tearDown(() => db.close());

  Future<int> routine(String name, int order) => db.workoutDao.createRoutine(
        RoutinesCompanion(name: Value(name), orderIndex: Value(order)),
      );

  test('arşivle → aktiften düşer, arşivde görünür; geri al → eski yerine döner',
      () async {
    final push = await routine('Push', 0);
    await routine('Pull', 1);
    await routine('Legs', 2);

    await db.workoutDao.archiveRoutine(push);
    expect((await db.workoutDao.getActiveRoutines()).map((r) => r.name),
        ['Pull', 'Legs']);
    expect((await db.workoutDao.getArchivedRoutines()).map((r) => r.name),
        ['Push']);

    await db.workoutDao.unarchiveRoutine(push);
    expect((await db.workoutDao.getActiveRoutines()).map((r) => r.name),
        ['Push', 'Pull', 'Legs']);
    expect(await db.workoutDao.getArchivedRoutines(), isEmpty);
  });

  test('arşiv ada göre sıralı', () async {
    final b = await routine('Upper B', 0);
    final a = await routine('Upper A', 1);
    await db.workoutDao.archiveRoutine(b);
    await db.workoutDao.archiveRoutine(a);
    expect((await db.workoutDao.getArchivedRoutines()).map((r) => r.name),
        ['Upper A', 'Upper B']);
  });

  test('geri alma senkron kuyruğuna girer (arşivleme gibi)', () async {
    final id = await routine('Push', 0);
    await db.customStatement('UPDATE routines SET sync_state = 0');
    await db.workoutDao.unarchiveRoutine(id);
    final r = await db.workoutDao.getRoutine(id);
    expect(r!.syncState, 1);
  });
}
