import 'package:drift/drift.dart' show Value, Variable;
import 'package:drift/native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/sync_meta_dao.dart';
import 'package:fit_pack/data/database/tables/sync_columns.dart';
import 'package:fit_pack/features/sync/sync_pull.dart';
import 'package:fit_pack/features/sync/sync_push.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_sync_server.dart';

/// **Senkron v2 — Aşama 5: silme protokolü** (docs/20 §5.3, §6.2).
///
/// Kapattığı hata #1'dir ve Samet'in en somut şikâyeti: *"sildiğim öğün bir
/// sonraki açılışta geri geliyor."* Bugüne kadar silme sunucuya HİÇ gitmiyor,
/// çekme de satırı geri ekliyordu.
void main() {
  const user = '00000000-0000-4000-8000-0000000000aa';

  late AppDatabase db;
  late FakeSyncServer remote;
  late SyncPush push;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remote = FakeSyncServer();
    push = SyncPush(db, remote);
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() => db.close());

  Future<int> addRoutine(String name) => db.into(db.routines).insert(
        RoutinesCompanion.insert(name: name, createdAt: DateTime.now()),
      );

  Future<int> count(String table) async {
    final r =
        await db.customSelect('SELECT COUNT(*) c FROM $table').getSingle();
    return r.read<int>('c');
  }

  Future<String> uidOf(String name) async {
    final r = await db
        .customSelect('SELECT uid FROM routines WHERE name = ?',
            variables: [Variable(name)])
        .getSingle();
    return r.read<String>('uid');
  }

  // ─────────────────── 1. Yerel silme sunucuya gidiyor ───────────────────

  test('silinen satır sunucudan da kalkar', () async {
    await addRoutine('Bacak');
    await push.pushAll(userId: user);
    expect(remote.rowCount('routines'), 1);
    final uid = await uidOf('Bacak');

    await db.customStatement('DELETE FROM routines WHERE uid = ?', [uid]);
    expect(await count('sync_tombstones'), 1,
        reason: 'silme tetikleyicisi mezar taşı bırakmalı');

    final result = await push.pushAll(userId: user);

    expect(result.deleted, 1);
    expect(remote.rowCount('routines'), 0, reason: 'sunucudan da silinmeli');
    expect(await count('sync_tombstones'), 0,
        reason: 'onay gelince mezar taşı kalkar — yoksa her turda tekrar gider');
  });

  test('hiç gönderilmemiş satırın silmesi sunucuya iz bırakmaz', () async {
    // Satır sunucuya hiç gitmediyse "silindi" bilgisi kimseye bir şey
    // anlatmaz; işaret biriktirmek boşuna yer kaplar.
    await addRoutine('Gitmeden silindi');
    final uid = await uidOf('Gitmeden silindi');
    await db.customStatement('DELETE FROM routines WHERE uid = ?', [uid]);

    final result = await push.pushAll(userId: user);

    expect(result.deleted, 0, reason: 'sunucuda silinecek bir şey yoktu');
    expect(remote.deletedMarks['routines'] ?? const <String>{}, isEmpty,
        reason: 'işaret yazılmamalı');
    expect(await count('sync_tombstones'), 0,
        reason: 'mezar taşı yine de kuyruktan kalkmalı');
  });

  test('mezar taşları yazmalardan SONRA gider', () async {
    // Aynı turda "ekle + sil": ters sırada silme boşa giderdi (satır henüz
    // sunucuda yok), ardından ekleme onu diriltirdi.
    await addRoutine('Bir');
    await push.pushAll(userId: user);
    final uid = await uidOf('Bir');

    await addRoutine('İki');
    await db.customStatement('DELETE FROM routines WHERE uid = ?', [uid]);

    remote.calls.clear();
    await push.pushAll(userId: user);

    final yazmaIndex = remote.calls.indexOf('routines');
    final silmeIndex = remote.calls.indexOf('deleteRows:routines');
    expect(yazmaIndex, isNonNegative);
    expect(silmeIndex, greaterThan(yazmaIndex),
        reason: 'önce yazma, sonra silme');
    expect(remote.rowCount('routines'), 1, reason: 'yalnız "İki" kalmalı');
  });

  test('ağ koparsa mezar taşı kuyrukta kalır', () async {
    await addRoutine('Bacak');
    await push.pushAll(userId: user);
    final uid = await uidOf('Bacak');
    await db.customStatement('DELETE FROM routines WHERE uid = ?', [uid]);

    remote.fail = true;
    final result = await push.pushAll(userId: user);
    expect(result.ok, isFalse);
    expect(await count('sync_tombstones'), 1,
        reason: 'onay gelmeden mezar taşı silinmez');

    remote.fail = false;
    await push.pushAll(userId: user);
    expect(remote.rowCount('routines'), 0, reason: 'sonraki turda gitmeli');
    expect(await count('sync_tombstones'), 0);
  });

  test('çocuk tablo önce silinir (ters sıra)', () async {
    // workout_sets, workout_sessions'a referans veriyor. Sunucuda zincirleme
    // silme var; çocuğu önce göndermek bu cihazın niyetini olduğu gibi aktarır.
    final exerciseId = await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
            name: 'Bench Press',
            category: 'push',
            muscleGroups: 'chest',
          ),
        );
    final sessionId = await db.into(db.workoutSessions).insert(
          WorkoutSessionsCompanion.insert(
            date: DateTime.now(),
            phase: 1,
            workoutType: 'push',
          ),
        );
    await db.into(db.workoutSets).insert(
          WorkoutSetsCompanion.insert(
            sessionId: sessionId,
            exerciseId: exerciseId,
            setNumber: 1,
          ),
        );
    await push.pushAll(userId: user);

    await db.customStatement('DELETE FROM workout_sets');
    await db.customStatement('DELETE FROM workout_sessions');

    remote.calls.clear();
    await push.pushAll(userId: user);

    final setIndex = remote.calls.indexOf('deleteRows:workout_sets');
    final seansIndex = remote.calls.indexOf('deleteRows:workout_sessions');
    expect(setIndex, isNonNegative);
    expect(seansIndex, greaterThan(setIndex),
        reason: 'çocuk (set) ebeveynden (seans) önce silinmeli');
  });

  // ─────────────────── 2. Sunucudaki silme yerele iniyor ───────────────────

  test('#1 · öteki cihazda silinen satır BU cihazdan da kalkar', () async {
    // Epiğin ana vaadi. Bugüne kadar bu satır yerelde kalıyor ve her
    // açılışta geri geliyordu.
    await addRoutine('Bacak');
    await push.pushAll(userId: user);
    final uid = await uidOf('Bacak');

    // "Öteki cihaz" sildi.
    await remote.deleteRows('routines', user, [uid]);

    final pull = SyncPull(db, remote, cursorLag: 0);
    final result = await pull.pullAll(userId: user);

    expect(result.ok, isTrue);
    expect(await count('routines'), 0,
        reason: 'silme bu cihaza taşınmalı — hata #1 tam buydu');
    expect(await count('sync_tombstones'), 0,
        reason: 'inen silme yeni mezar taşı üretmemeli (yankı olmaz)');
  });

  test('inen silme imleci ilerletir, ikinci turda tekrar inmez', () async {
    await addRoutine('Bacak');
    await push.pushAll(userId: user);
    await remote.deleteRows('routines', user, [await uidOf('Bacak')]);

    final pull = SyncPull(db, remote, cursorLag: 0);
    await pull.pullAll(userId: user);

    final imlec = await SyncMetaDao(db)
        .read(SyncMetaDao.pullCursorKey(user, syncDeletedTable));
    expect(imlec, isNotNull);
    expect(int.parse(imlec!), greaterThan(0));
  });

  test('bekleyen düzenlemesi olan satır da silinir — silme kazanır', () async {
    await addRoutine('Bacak');
    await push.pushAll(userId: user);
    final uid = await uidOf('Bacak');

    await remote.deleteRows('routines', user, [uid]);
    // Bu cihazda satır hâlâ var ve düzenleniyor (kuyruğa girer).
    await db.customStatement(
        "UPDATE routines SET name = 'Yerel düzenleme' WHERE uid = ?", [uid]);

    final pull = SyncPull(db, remote, cursorLag: 0);
    await pull.pullAll(userId: user);

    expect(await count('routines'), 0,
        reason: 'silme her zaman kazanır (K-3) — düzenleme atılır');
  });

  test('bilmediğimiz tablo adı taşıyan işaret yok sayılır', () async {
    // İşaretin tablo adı ham SQL'e giriyor; sunucudan gelen her şeye
    // güvenilmez.
    remote.deletedMarks['pg_shadow; drop table routines'] = {'x'};
    await addRoutine('Dursun');

    final pull = SyncPull(db, remote, cursorLag: 0);
    final result = await pull.pullAll(userId: user);

    expect(result.ok, isTrue, reason: 'çekme patlamamalı');
    expect(await count('routines'), 1, reason: 'veri yerinde durmalı');
  });

  // ─────────────────── 3. Çift yönlü yarış ───────────────────

  test('yerelde silinen kimlik sunucudan GERİ EKLENMEZ', () async {
    // Silme henüz gönderilmemişken çekme çalışırsa: satır bir an geri gelip
    // sonra kaybolurdu. docs/20 §6.2 son satır.
    await addRoutine('Bacak');
    await push.pushAll(userId: user);
    final uid = await uidOf('Bacak');

    await db.customStatement('DELETE FROM routines WHERE uid = ?', [uid]);
    expect(await count('sync_tombstones'), 1);

    // Sunucuda satır hâlâ canlı; çekme onu görür.
    final pull = SyncPull(db, remote, cursorLag: 0);
    await pull.pullAll(userId: user);

    expect(await count('routines'), 0,
        reason: 'bekleyen silme varken satır geri eklenmemeli');
    expect(await count('sync_tombstones'), 1,
        reason: 'silme hâlâ gönderilmeyi bekliyor');

    // Gönderim silmeyi iletince sunucu da temizlenir.
    await push.pushAll(userId: user);
    expect(remote.rowCount('routines'), 0);
  });

  // ─────────────────── 4. Rutin kaydetme farkı (§5.4) ───────────────────
  //
  // Eskiden düzenleme "hepsini sil, yeniden ekle" yapıyordu. Senkron v2'yle
  // her silme bir mezar taşı, her ekleme yeni bir kimlik üretiyor: tek bir
  // tekrar sayısını değiştirmek rutinin BÜTÜN hareketlerini sunucuda silip
  // yeniden yaratıyordu.

  Future<int> addExercise(String name) => db.into(db.exercises).insert(
        ExercisesCompanion.insert(
          name: name,
          category: 'push',
          muscleGroups: 'chest',
        ),
      );

  Future<int> saveRoutine({
    required int routineId,
    required List<int> exerciseIds,
    int sets = 3,
    bool isNew = false,
  }) =>
      db.workoutDao.saveRoutineWithExercises(
        routine: RoutinesCompanion(
          id: Value(routineId),
          name: const Value('Program'),
          createdAt: Value(DateTime.now()),
        ),
        isNew: isNew,
        buildExercises: (id) => [
          for (var i = 0; i < exerciseIds.length; i++)
            RoutineExercisesCompanion(
              routineId: Value(id),
              exerciseId: Value(exerciseIds[i]),
              orderIndex: Value(i),
              targetSets: Value(sets),
            ),
        ],
      );

  test('rutin düzenleme DEĞİŞMEYEN hareketlere dokunmaz', () async {
    final e1 = await addExercise('Bench');
    final e2 = await addExercise('Incline');
    final routineId = await addRoutine('Program');
    await saveRoutine(routineId: routineId, exerciseIds: [e1, e2]);
    await push.pushAll(userId: user);

    final oncekiKimlikler = await db
        .customSelect('SELECT uid FROM routine_exercises ORDER BY order_index')
        .get()
        .then((rows) => rows.map((r) => r.read<String>('uid')).toList());

    // Yalnız ikinci hareketin set sayısı değişiyor... ama builder hepsine
    // aynı değeri veriyor, o yüzden ikisi de değişir. Önce HİÇBİR ŞEYİN
    // değişmediği durumu ölçelim: aynı listeyi tekrar kaydet.
    await saveRoutine(routineId: routineId, exerciseIds: [e1, e2]);

    final sonrakiKimlikler = await db
        .customSelect('SELECT uid FROM routine_exercises ORDER BY order_index')
        .get()
        .then((rows) => rows.map((r) => r.read<String>('uid')).toList());

    expect(sonrakiKimlikler, oncekiKimlikler,
        reason: 'kimlikler korunmalı — silinip yeniden yaratılmamalı');
    expect(await count('sync_tombstones'), 0,
        reason: 'değişmeyen kayıt mezar taşı üretmemeli');
    expect(
      await db
          .customSelect(
              'SELECT COUNT(*) c FROM routine_exercises WHERE sync_state = 1')
          .getSingle()
          .then((r) => r.read<int>('c')),
      0,
      reason: 'değişmeyen satır kuyruğa girmemeli',
    );
  });

  test('rutinden hareket çıkarınca yalnız O satır silinir', () async {
    final e1 = await addExercise('Bench');
    final e2 = await addExercise('Incline');
    final e3 = await addExercise('Fly');
    final routineId = await addRoutine('Program');
    await saveRoutine(routineId: routineId, exerciseIds: [e1, e2, e3]);
    await push.pushAll(userId: user);

    final ilkIki = await db
        .customSelect('SELECT uid FROM routine_exercises '
            'ORDER BY order_index LIMIT 2')
        .get()
        .then((rows) => rows.map((r) => r.read<String>('uid')).toList());

    await saveRoutine(routineId: routineId, exerciseIds: [e1, e2]);

    expect(await count('routine_exercises'), 2);
    expect(await count('sync_tombstones'), 1,
        reason: 'yalnız çıkarılan hareket için mezar taşı — eskiden 3 olurdu');

    final kalanlar = await db
        .customSelect('SELECT uid FROM routine_exercises ORDER BY order_index')
        .get()
        .then((rows) => rows.map((r) => r.read<String>('uid')).toList());
    expect(kalanlar, ilkIki, reason: 'kalan hareketlerin kimliği korunmalı');
  });

  test('rutine hareket eklemek yalnız yeni satır yazar', () async {
    final e1 = await addExercise('Bench');
    final e2 = await addExercise('Incline');
    final routineId = await addRoutine('Program');
    await saveRoutine(routineId: routineId, exerciseIds: [e1]);
    await push.pushAll(userId: user);
    final ilkUid = await db
        .customSelect('SELECT uid FROM routine_exercises')
        .getSingle()
        .then((r) => r.read<String>('uid'));

    await saveRoutine(routineId: routineId, exerciseIds: [e1, e2]);

    expect(await count('routine_exercises'), 2);
    expect(await count('sync_tombstones'), 0, reason: 'silinen yok');
    expect(
      await db
          .customSelect(
              'SELECT COUNT(*) c FROM routine_exercises WHERE sync_state = 1')
          .getSingle()
          .then((r) => r.read<int>('c')),
      1,
      reason: 'yalnız yeni satır kuyruğa girmeli',
    );
    final kalan = await db
        .customSelect('SELECT uid FROM routine_exercises ORDER BY order_index')
        .get()
        .then((rows) => rows.map((r) => r.read<String>('uid')).toList());
    expect(kalan.first, ilkUid, reason: 'mevcut satırın kimliği korunmalı');
  });

  test('sunucuda silinen kimlik bekleyen mezar taşını da temizler', () async {
    // İki cihaz aynı satırı sildi. Sunucu zaten temiz; bizim silme isteğimiz
    // gereksiz. Mezar taşı kalsaydı her turda boşuna sync_delete çağrılırdı.
    await addRoutine('Bacak');
    await push.pushAll(userId: user);
    final uid = await uidOf('Bacak');

    await remote.deleteRows('routines', user, [uid]); // öteki cihaz sildi
    await db.customStatement(
        'DELETE FROM routines WHERE uid = ?', [uid]); // biz de sildik
    expect(await count('sync_tombstones'), 1);

    final pull = SyncPull(db, remote, cursorLag: 0);
    await pull.pullAll(userId: user);

    expect(await count('sync_tombstones'), 0,
        reason: 'sunucu zaten sildi — bizim isteğimiz düşer');
  });
}
