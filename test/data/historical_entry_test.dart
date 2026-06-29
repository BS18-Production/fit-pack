import 'package:drift/drift.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Geçmişe dönük veri girişi (docs/10-historical-entry.md).
///
/// Kritik invariant: seansın yazıldığı `date` mantıksal gündür ve tüm
/// istatistikler (haftalık aralık, sayım, geçmiş) bu alandan türer. Geçmişe
/// tarihlenen bir seans doğru güne düşmeli; kaydetme anındaki saate değil.
void main() {
  late AppDatabase db;
  setUp(() => db = newTestDatabase());
  tearDown(() => db.close());

  DateTime day(int y, int m, int d) => DateTime(y, m, d, 12);

  Future<int> addSession(DateTime date, {String type = 'Geçmiş Antrenman'}) {
    return db.workoutDao.insertSession(WorkoutSessionsCompanion(
      date: Value(date),
      phase: const Value(0),
      workoutType: Value(type),
      startedAt: Value(date),
    ));
  }

  test('geçmiş tarihli seans doğru haftaya/aralığa düşer', () async {
    // 2 gün önceki bir seans — geçen Cumartesi.
    final past = day(2026, 6, 20);
    await addSession(past);

    // O günü kapsayan aralık seansı görür.
    final inRange = await db.workoutDao.getSessionsByDateRange(
        day(2026, 6, 15), day(2026, 6, 22).add(const Duration(days: 1)));
    expect(inRange, hasLength(1));
    expect(inRange.first.date, past);

    // O günü KAPSAMAYAN aralık (sonraki hafta) görmez.
    final outRange = await db.workoutDao.getSessionsByDateRange(
        day(2026, 6, 23), day(2026, 6, 30));
    expect(outRange, isEmpty);
  });

  test('getSessionCountInRange geçmiş güne göre sayar', () async {
    await addSession(day(2026, 6, 18));
    await addSession(day(2026, 6, 20));
    await addSession(day(2026, 6, 25));

    final count = await db.workoutDao.getSessionCountInRange(
        day(2026, 6, 15), day(2026, 6, 21).add(const Duration(days: 1)));
    expect(count, 2); // 18 + 20, 25 hariç
  });

  test('seansın tarihini düzenlemek istatistikleri yeni güne taşır (H-D)',
      () async {
    // Yanlışlıkla bugüne (29) yazılmış, aslında 20'sinde yapılmış.
    final id = await addSession(day(2026, 6, 29));
    var sessions = await db.workoutDao.getAllSessions();
    final original = sessions.firstWhere((s) => s.id == id);

    // Tarihi 20'sine çek.
    await db.workoutDao.updateSession(original.copyWith(date: day(2026, 6, 20)));

    final movedIn = await db.workoutDao.getSessionsByDateRange(
        day(2026, 6, 15), day(2026, 6, 21).add(const Duration(days: 1)));
    expect(movedIn.map((s) => s.id), contains(id)); // artık eski haftada

    final stillToday = await db.workoutDao.getSessionsByDateRange(
        day(2026, 6, 29), day(2026, 6, 29).add(const Duration(days: 1)));
    expect(stillToday, isEmpty); // bugünden gitti
  });

  test('seansı setleriyle birlikte siler (deleteSessionWithSets)', () async {
    final id = await addSession(day(2026, 6, 20));
    // exercises FK için bir hareket gerek — seed'siz test DB'de ekleyelim.
    final exId = await db.workoutDao.insertCustomExercise(
      const ExercisesCompanion(
        name: Value('Test Hareket'),
        category: Value('compound'),
        muscleGroups: Value('["chest"]'),
        isCustom: Value(true),
      ),
    );
    await db.workoutDao.insertSet(WorkoutSetsCompanion(
      sessionId: Value(id),
      exerciseId: Value(exId),
      setNumber: const Value(1),
      weightKg: const Value(50),
      reps: const Value(8),
    ));

    expect(await db.workoutDao.getSetsForSession(id), hasLength(1));

    await db.workoutDao.deleteSessionWithSets(id);

    expect(await db.workoutDao.getAllSessions(), isEmpty);
    expect(await db.workoutDao.getSetsForSession(id), isEmpty);
  });
}
