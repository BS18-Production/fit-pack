import 'package:drift/drift.dart' hide isNull;
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/workout/set_prefill.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// G-2 — önceki setin değerini sonrakine taşıma. Kural: alanlar kendiliğinden
/// dolmaz; öneri ✓'e basılınca yalnız BOŞ alanlara yazılır.
void main() {
  const w140x7 = SetValues(weightKg: 140, reps: 7);
  const w60x10 = SetValues(weightKg: 60, reps: 10);
  const empty = SetValues();

  CurrentSet cur(SetValues v, {bool warmup = false}) =>
      (values: v, warmup: warmup);

  group('suggestionFor — öneri kaynağı', () {
    test('bugün değer değiştirildiyse o değer sonraki sete taşınır', () {
      // Geçen hafta 130×8, bugün 140×7 yapıldı → 2. sete 140×7 önerilir.
      final s = suggestionFor(
        index: 1,
        current: [cur(w140x7), cur(empty)],
        lastSession: const [SetValues(weightKg: 130, reps: 8), w60x10],
        measure: 'weight_reps',
      );
      expect(s, w140x7);
    });

    test('geçen seans takip ediliyorsa piramit korunur', () {
      // Geçen seans 100×10 → 120×9; bugün 1. set aynen 100×10 yapıldı.
      const w100x10 = SetValues(weightKg: 100, reps: 10);
      const w120x9 = SetValues(weightKg: 120, reps: 9);
      final s = suggestionFor(
        index: 1,
        current: [cur(w100x10), cur(empty)],
        lastSession: const [w100x10, w120x9],
        measure: 'weight_reps',
      );
      expect(s, w120x9);
    });

    test('takip ederken geçen seansı aşan sette üstteki set taşınır', () {
      final s = suggestionFor(
        index: 1,
        current: [cur(w140x7), cur(empty)],
        lastSession: const [w140x7],
        measure: 'weight_reps',
      );
      expect(s, w140x7);
    });

    test('yukarıdaki boşsa daha yukarıdaki dolu set kullanılır', () {
      final s = suggestionFor(
        index: 2,
        current: [cur(w140x7), cur(empty), cur(empty)],
        lastSession: const [],
        measure: 'weight_reps',
      );
      expect(s, w140x7);
    });

    test('ısınma seti çalışma setine öneri olmaz → geçen seansa düşer', () {
      final s = suggestionFor(
        index: 1,
        current: [cur(w60x10, warmup: true), cur(empty)],
        lastSession: const [SetValues(weightKg: 40, reps: 12), w140x7],
        measure: 'weight_reps',
      );
      expect(s, w140x7);
    });

    test('hedef set de ısınmaysa ısınma değeri taşınır', () {
      final s = suggestionFor(
        index: 1,
        current: [cur(w60x10, warmup: true), cur(empty, warmup: true)],
        lastSession: const [],
        measure: 'weight_reps',
      );
      expect(s, w60x10);
    });

    test('ilk set: geçen seansın AYNI numaralı seti', () {
      final s = suggestionFor(
        index: 0,
        current: [cur(empty), cur(empty)],
        lastSession: const [w140x7, SetValues(weightKg: 140, reps: 6)],
        measure: 'weight_reps',
      );
      expect(s, w140x7);
    });

    test('geçen seansta o numara yoksa ve yukarısı boşsa öneri yok', () {
      final s = suggestionFor(
        index: 2,
        current: [cur(empty), cur(empty), cur(empty)],
        lastSession: const [w140x7],
        measure: 'weight_reps',
      );
      expect(s, isNull);
    });

    test('ölçüm tipine göre "dolu" sayılır — süre hareketinde kilo yetmez', () {
      final s = suggestionFor(
        index: 1,
        current: [cur(const SetValues(weightKg: 10)), cur(empty)],
        lastSession: const [],
        measure: 'time',
      );
      expect(s, isNull);
    });
  });

  group('fillMissing — yalnız boş alanlar dolar', () {
    test('tamamen boş set öneriyi alır', () {
      expect(fillMissing(empty, w140x7, 'weight_reps'), w140x7);
    });

    test('kullanıcının yazdığı tekrar korunur, eksik kilo dolar', () {
      final r = fillMissing(const SetValues(reps: 5), w140x7, 'weight_reps');
      expect(r, const SetValues(weightKg: 140, reps: 5));
    });

    test('dolu set değişmez', () {
      const typed = SetValues(weightKg: 145, reps: 6);
      expect(fillMissing(typed, w140x7, 'weight_reps'), typed);
    });

    test('tekrar hareketi yalnız tekrarı alır', () {
      final r = fillMissing(empty, w140x7, 'reps');
      expect(r, const SetValues(reps: 7));
    });

    test('süre hareketi yalnız süreyi alır', () {
      final r = fillMissing(
        empty,
        const SetValues(weightKg: 5, durationSec: 60),
        'time',
      );
      expect(r, const SetValues(durationSec: 60));
    });

    test('mesafe hareketi mesafe + süreyi alır', () {
      final r = fillMissing(
        const SetValues(durationSec: 1500),
        const SetValues(distanceM: 5000, durationSec: 1800),
        'distance',
      );
      expect(r, const SetValues(distanceM: 5000, durationSec: 1500));
    });
  });

  group('getLastSessionSetsForExercise — geçen seansın setleri', () {
    late AppDatabase db;
    setUp(() => db = newTestDatabase());
    tearDown(() => db.close());

    Future<int> exercise(String name) => db.workoutDao.insertCustomExercise(
      ExercisesCompanion.insert(
        name: name,
        category: 'compound',
        muscleGroups: 'chest',
      ),
    );

    Future<void> session(
      DateTime date,
      List<WorkoutSetsCompanion> Function(int) sets,
    ) => db.workoutDao.insertSessionWithSets(
      WorkoutSessionsCompanion(
        date: Value(date),
        phase: const Value(0),
        workoutType: const Value('Test'),
      ),
      sets,
    );

    WorkoutSetsCompanion set(
      int sessionId,
      int exId,
      int no,
      double kg, {
      bool warmup = false,
    }) => WorkoutSetsCompanion(
      sessionId: Value(sessionId),
      exerciseId: Value(exId),
      setNumber: Value(no),
      weightKg: Value(kg),
      reps: const Value(5),
      isWarmup: Value(warmup),
      setType: Value(warmup ? 'warmup' : 'normal'),
    );

    test(
      'en son seansın setleri, set sırasıyla; diğer hareketler hariç',
      () async {
        final bench = await exercise('Bench');
        final squat = await exercise('Squat');
        await session(
          DateTime(2026, 9, 1),
          (id) => [set(id, bench, 1, 100), set(id, bench, 2, 100)],
        );
        // Daha yeni seans — ekleme sırası karışık, ısınma dahil.
        await session(
          DateTime(2026, 9, 8),
          (id) => [
            set(id, bench, 2, 110),
            set(id, squat, 1, 150),
            set(id, bench, 1, 60, warmup: true),
            set(id, bench, 3, 112.5),
          ],
        );

        final sets = await db.workoutDao.getLastSessionSetsForExercise(bench);
        expect(sets.map((s) => s.setNumber), [1, 2, 3]);
        expect(sets.map((s) => s.weightKg), [60, 110, 112.5]);
        expect(sets.first.isWarmup, isTrue);
      },
    );

    test('hareket hiç yapılmadıysa boş liste', () async {
      final bench = await exercise('Bench');
      expect(await db.workoutDao.getLastSessionSetsForExercise(bench), isEmpty);
    });

    test(
      'geçmişe tarihlenmiş seans "en son" sayılmaz — tarih belirler',
      () async {
        final bench = await exercise('Bench');
        await session(DateTime(2026, 9, 8), (id) => [set(id, bench, 1, 110)]);
        // Sonradan girilen ama daha ESKİ tarihli kayıt.
        await session(DateTime(2026, 8, 1), (id) => [set(id, bench, 1, 90)]);

        final sets = await db.workoutDao.getLastSessionSetsForExercise(bench);
        expect(sets.single.weightKg, 110);
      },
    );
  });
}
