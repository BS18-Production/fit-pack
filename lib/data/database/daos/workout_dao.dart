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

  /// Rutin + hareket listesini TEK transaction'da yazar. Rutin id'sini döner.
  ///
  /// **Düzenlemede FARK uygulanır** (docs/20 §5.4): eskiden "hepsini sil,
  /// yeniden ekle" yapılıyordu. Senkron v2'yle her silme bir mezar taşı, her
  /// ekleme yeni bir kimlik üretiyor — yani hedef sürede tek bir tekrar
  /// sayısını değiştirmek, rutinin BÜTÜN hareketlerini sunucuda silip yeniden
  /// yaratıyordu. Fark uygulaması bunu dokunulan satırla sınırlar.
  ///
  /// Eşleştirme **sıraya** göre: i. satır i. satırla karşılaştırılır. Aynıysa
  /// hiç yazılmaz (gereksiz yazma satırı kuyruğa sokar), farklıysa güncellenir;
  /// artan satırlar eklenir, eksilenler silinir.
  Future<int> saveRoutineWithExercises({
    required RoutinesCompanion routine,
    required bool isNew,
    required List<RoutineExercisesCompanion> Function(int routineId)
        buildExercises,
  }) =>
      transaction(() async {
        final int id;
        if (isNew) {
          id = await createRoutine(routine);
          final items = buildExercises(id);
          if (items.isNotEmpty) {
            await batch((b) => b.insertAll(routineExercises, items));
          }
          return id;
        }

        id = routine.id.value;
        await updateRoutine(routine);
        await _applyRoutineExerciseDiff(id, buildExercises(id));
        return id;
      });

  /// Rutinin hareket listesini [items] ile eşitler — farkı uygular.
  Future<void> _applyRoutineExerciseDiff(
    int routineId,
    List<RoutineExercisesCompanion> items,
  ) async {
    final mevcut = await (select(routineExercises)
          ..where((e) => e.routineId.equals(routineId))
          ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
        .get();

    final ortak = mevcut.length < items.length ? mevcut.length : items.length;

    for (var i = 0; i < ortak; i++) {
      if (_sameRoutineExercise(mevcut[i], items[i])) continue;
      await (update(routineExercises)..where((e) => e.id.equals(mevcut[i].id)))
          .write(items[i]);
    }

    for (var i = ortak; i < items.length; i++) {
      await into(routineExercises).insert(items[i]);
    }

    if (mevcut.length > items.length) {
      final fazlalik = [
        for (var i = ortak; i < mevcut.length; i++) mevcut[i].id,
      ];
      await (delete(routineExercises)..where((e) => e.id.isIn(fazlalik))).go();
    }
  }

  /// Mevcut satır ile yazılmak istenen aynı mı? Aynıysa hiç yazma: gereksiz
  /// UPDATE satırı senkron kuyruğuna sokar ve sunucuya boşuna trafik çıkarır.
  ///
  /// Companion'da **belirtilmemiş** (`absent`) alan "değiştirme" demektir, o
  /// yüzden farklılık sayılmaz.
  static bool _sameRoutineExercise(
    RoutineExercise mevcut,
    RoutineExercisesCompanion yeni,
  ) {
    bool ayni<T>(Value<T> v, T simdiki) => !v.present || v.value == simdiki;
    return ayni(yeni.exerciseId, mevcut.exerciseId) &&
        ayni(yeni.orderIndex, mevcut.orderIndex) &&
        ayni(yeni.targetSets, mevcut.targetSets) &&
        ayni(yeni.targetRepsMin, mevcut.targetRepsMin) &&
        ayni(yeni.targetRepsMax, mevcut.targetRepsMax) &&
        ayni(yeni.targetRestSec, mevcut.targetRestSec) &&
        ayni(yeni.note, mevcut.note);
  }

  /// Rutinin tüm hareketlerini siler.
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

  /// Verilen kimliklerdeki hareketler (tek sorgu).
  Future<List<Exercise>> getExercisesByIds(Iterable<int> ids) {
    final list = ids.toSet().toList();
    if (list.isEmpty) return Future.value(const []);
    return (select(exercises)..where((e) => e.id.isIn(list))).get();
  }

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

  /// [start, end) aralığındaki seanslar — bitiş HARİÇ (CODE_REVIEW H-01:
  /// gece yarısı kayıtları iki döneme birden sayılmasın).
  Future<List<WorkoutSession>> getSessionsByDateRange(DateTime start, DateTime end) =>
      (select(workoutSessions)
            ..where((s) =>
                s.date.isBiggerOrEqualValue(start) &
                s.date.isSmallerThanValue(end))
            ..orderBy([(s) => OrderingTerm.desc(s.date)]))
          .get();

  Future<WorkoutSession?> getSessionById(int id) =>
      (select(workoutSessions)..where((s) => s.id.equals(id)))
          .getSingleOrNull();

  Future<WorkoutSession?> getLastSession() =>
      (select(workoutSessions)
            ..orderBy([(s) => OrderingTerm.desc(s.date)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> insertSession(WorkoutSessionsCompanion entry) =>
      into(workoutSessions).insert(entry);

  /// Seans + setlerini TEK transaction'da yazar: yazım yarıda kesilirse
  /// (çökme, disk hatası) DB'de yarım seans kalmaz — ya hepsi ya hiçbiri.
  /// [buildSets] yeni seans id'siyle set companion'larını üretir.
  Future<int> insertSessionWithSets(
    WorkoutSessionsCompanion session,
    List<WorkoutSetsCompanion> Function(int sessionId) buildSets,
  ) =>
      transaction(() async {
        final id = await into(workoutSessions).insert(session);
        final sets = buildSets(id);
        if (sets.isNotEmpty) {
          await batch((b) => b.insertAll(workoutSets, sets));
        }
        return id;
      });

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
      ..where(workoutSessions.date.isBiggerOrEqualValue(start) &
          workoutSessions.date.isSmallerThanValue(end));
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

  /// Ana Sayfa "en çok gelişen hareket" içgörüsü (dashboard): [start, end)
  /// aralığındaki ağırlıklı set noktaları + hareket adı. Isınma hariç; yalnız
  /// kg ve tekrarı DOLU olanlar (e1RM hesaplanabilsin). Tek sorgu (N+1 yok).
  ///
  /// [onlyComplete]: yalnız tamamlanmış (✓) setler. Haftalık değerlendirme
  /// bunu ister — yarım bırakılmış taslak set "en iyi set" sayılmamalı.
  /// Ana sayfa içgörüsü eski davranışla (hepsi) kalır.
  Future<List<ExerciseProgressPoint>> getWeightedSetPointsInRange(
      DateTime start, DateTime end,
      {bool onlyComplete = false}) async {
    var kosul = workoutSets.isWarmup.equals(false) &
        workoutSets.weightKg.isNotNull() &
        workoutSets.reps.isNotNull() &
        workoutSessions.date.isBiggerOrEqualValue(start) &
        workoutSessions.date.isSmallerThanValue(end);
    if (onlyComplete) kosul = kosul & workoutSets.isComplete.equals(true);
    final q = select(workoutSets).join([
      innerJoin(
          workoutSessions, workoutSessions.id.equalsExp(workoutSets.sessionId)),
      innerJoin(exercises, exercises.id.equalsExp(workoutSets.exerciseId)),
    ])
      ..where(kosul)
      ..orderBy([OrderingTerm.asc(workoutSessions.date)]);
    final rows = await q.get();
    return rows.map((r) {
      final s = r.readTable(workoutSets);
      final sess = r.readTable(workoutSessions);
      final ex = r.readTable(exercises);
      return ExerciseProgressPoint(
        exerciseId: ex.id,
        name: ex.name,
        date: sess.date,
        weightKg: s.weightKg!,
        reps: s.reps!,
      );
    }).toList();
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

  /// [since]'ten beri yapılan hareketler: kaç sette kullanıldığı ve en son
  /// ne zaman — en yenisi önce (hareket arama v2: "son kullandıkların" ve
  /// kişisel sıralama). Tarih aralığı `[since, …)`.
  Future<List<ExerciseUsage>> getExerciseUsageSince(DateTime since) async {
    final count = workoutSets.id.count();
    final last = workoutSessions.date.max();
    final q = selectOnly(workoutSets).join([
      innerJoin(workoutSessions, workoutSessions.id.equalsExp(workoutSets.sessionId)),
    ])
      ..addColumns([workoutSets.exerciseId, count, last])
      ..where(workoutSessions.date.isBiggerOrEqualValue(since))
      ..groupBy([workoutSets.exerciseId])
      ..orderBy([OrderingTerm.desc(last)]);
    final rows = await q.get();
    return [
      for (final r in rows)
        ExerciseUsage(
          exerciseId: r.read(workoutSets.exerciseId)!,
          sets: r.read(count) ?? 0,
          lastUsed: r.read(last)!,
        ),
    ];
  }

  /// Hareketin yapıldığı EN SON seanstaki setleri, set numarası sırasıyla
  /// (G-2): aktif seansta "ÖNCEKİ" sütunu ve ✓ önerisi set numarasına göre
  /// eşleşir. Isınma setleri dahildir — sıra numarası kayıttakiyle aynı kalsın.
  /// Hareket hiç yapılmadıysa boş liste.
  Future<List<WorkoutSet>> getLastSessionSetsForExercise(int exerciseId) async {
    final latest = select(workoutSets).join([
      innerJoin(workoutSessions, workoutSessions.id.equalsExp(workoutSets.sessionId)),
    ])
      ..where(workoutSets.exerciseId.equals(exerciseId))
      ..orderBy([
        OrderingTerm.desc(workoutSessions.date),
        OrderingTerm.desc(workoutSessions.id),
      ])
      ..limit(1);
    final row = await latest.getSingleOrNull();
    if (row == null) return const [];
    final sessionId = row.readTable(workoutSets).sessionId;
    return (select(workoutSets)
          ..where((s) => s.sessionId.equals(sessionId) & s.exerciseId.equals(exerciseId))
          ..orderBy([(s) => OrderingTerm.asc(s.setNumber)]))
        .get();
  }

}

/// Bir hareketin son dönemdeki kullanımı (hareket arama v2).
class ExerciseUsage {
  final int exerciseId;
  final int sets;
  final DateTime lastUsed;
  const ExerciseUsage(
      {required this.exerciseId, required this.sets, required this.lastUsed});
}

/// Rutin hareketi + hareket bilgisi (join sonucu — UI'da ad/ekipman göster).
class RoutineExerciseWithExercise {
  final RoutineExercise routineExercise;
  final Exercise exercise;
  const RoutineExerciseWithExercise(this.routineExercise, this.exercise);
}

/// Dashboard içgörüsü için set noktası: hareket kimliği/adı + tarih + kg×tekrar.
/// [ExerciseSetPoint]'ten farkı: hareket kimliği/adını taşır (çok-hareketli
/// tarama için) ve kg/tekrar zorunlu (e1RM hep hesaplanır).
class ExerciseProgressPoint {
  final int exerciseId;
  final String name;
  final DateTime date;
  final double weightKg;
  final int reps;
  const ExerciseProgressPoint({
    required this.exerciseId,
    required this.name,
    required this.date,
    required this.weightKg,
    required this.reps,
  });

  /// Tahmini 1RM (Epley): kg × (1 + tekrar/30). kg/tekrar > 0 değilse null.
  double? get e1rm =>
      (weightKg > 0 && reps > 0) ? weightKg * (1 + reps / 30) : null;
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
