import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/sync/sync_pull.dart';
import 'package:fit_pack/features/sync/sync_push.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_sync_server.dart';

/// Çekme (pull) hattı — docs/18 §6.4–6.5.
///
/// Ana senaryo Samet'in gerçek hatası: bir "cihazda" oluşup sunucuya giden veri,
/// yerel verisi silinmiş ikinci bir "cihaza" giriş yapınca geri inmeli. Push ile
/// pull'u aynı sahte sunucuda uçtan uca zincirliyoruz.
void main() {
  const user = '00000000-0000-4000-8000-0000000000aa';

  late FakeSyncServer remote;

  setUp(() => remote = FakeSyncServer());

  Future<AppDatabase> freshDb() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get(); // onCreate + tetikleyiciler
    return db;
  }

  Future<int> count(AppDatabase db, String table, [String where = '1=1']) async {
    final r =
        await db.customSelect('SELECT COUNT(*) c FROM $table WHERE $where').getSingle();
    return r.read<int>('c');
  }

  test('round-trip: A\'nın verisi sunucuya gider, boş B\'ye iner', () async {
    // ── Cihaz A: veri üret + sunucuya gönder ──
    final a = await freshDb();
    await a.userProfileDao.completeOnboarding(
        kcalGoal: 3100, proteinGoal: 155, phase: 3, heightCm: 180);
    await a.into(a.bodyMeasurements).insert(BodyMeasurementsCompanion(
        date: Value(DateTime.now()), weightKg: const Value(84.7)));
    // Bir seans + o seansa bağlı bir set (FK zincirini sınar).
    final sessionId = await a.into(a.workoutSessions).insert(
        WorkoutSessionsCompanion(
            date: Value(DateTime.now()),
            phase: const Value(0),
            workoutType: const Value('Full Body A')));
    final exId = await a.into(a.exercises).insert(ExercisesCompanion(
        name: const Value('Bench Press'),
        category: const Value('compound'),
        muscleGroups: const Value('["chest"]'),
        isCustom: const Value(true)));
    await a.into(a.workoutSets).insert(WorkoutSetsCompanion(
        sessionId: Value(sessionId),
        exerciseId: Value(exId),
        setNumber: const Value(1),
        weightKg: const Value(60),
        reps: const Value(10)));

    final pushA = await SyncPush(a, remote).pushAll(userId: user);
    expect(pushA.failed, 0);
    expect(remote.count('workout_sessions'), 1);
    expect(remote.count('workout_sets'), 1);
    await a.close();

    // ── Cihaz B: bomboş, giriş yapıp pull ──
    final b = await freshDb();
    // B kendi seed profilini kurar (uid farklı) — junk gibi.
    await b.userProfileDao.ensureProfile();
    final result = await SyncPull(b, remote).pullAll(userId: user);

    expect(result.ok, isTrue);
    // Profil indi: tek satır, sunucunun değerleri.
    final profile = await b.userProfileDao.getProfile();
    expect(profile!.onboarded, isTrue);
    expect(profile.kcalGoal, 3100);
    expect(profile.heightCm, 180);
    expect(await count(b, 'user_profile'), 1); // TEK profil, ikiz yok
    // Ölçüm + seans + set indi, FK yerelde çözüldü.
    expect(await count(b, 'body_measurements'), 1);
    expect(await count(b, 'workout_sessions'), 1);
    final sets = await b.customSelect(
            'SELECT ws.reps, s.workout_type sname, e.name ename FROM workout_sets ws '
            'JOIN workout_sessions s ON s.id = ws.session_id '
            'JOIN exercises e ON e.id = ws.exercise_id')
        .get();
    expect(sets, hasLength(1));
    expect(sets.first.data['reps'], 10);
    expect(sets.first.data['sname'], 'Full Body A');
    expect(sets.first.data['ename'], 'Bench Press');
    await b.close();
  });

  test('inen satırlar kuyruğa GİRMEZ (yankı yok)', () async {
    final a = await freshDb();
    await a.into(a.bodyMeasurements).insert(BodyMeasurementsCompanion(
        date: Value(DateTime.now()), weightKg: const Value(80)));
    await SyncPush(a, remote).pushAll(userId: user);
    await a.close();

    final b = await freshDb();
    await SyncPull(b, remote).pullAll(userId: user);

    // İnen ölçüm temiz (sync_state=0/NULL) olmalı — yoksa hemen geri gönderilir.
    final dirty = await count(b, 'body_measurements',
        'sync_state = 1');
    expect(dirty, 0);
    // Tetikleyiciler geri kurulmuş olmalı: yeni bir yazma yine kuyruğa girer.
    await b.into(b.bodyMeasurements).insert(BodyMeasurementsCompanion(
        date: Value(DateTime.now()), weightKg: const Value(81)));
    expect(await count(b, 'body_measurements', 'sync_state = 1'), 1);
    await b.close();
  });

  test('junk profil (farklı uid) sunucunun gerçeğiyle DEĞİŞİR', () async {
    // Sunucuda gerçek profil.
    final a = await freshDb();
    await a.userProfileDao.completeOnboarding(
        kcalGoal: 3100, proteinGoal: 155, phase: 3, heightCm: 180);
    await SyncPush(a, remote).pushAll(userId: user);
    await a.close();

    // Cihazda yeniden-onboarding junk'ı: farklı uid, daha YENİ zaman damgası,
    // düşük değerler.
    final b = await freshDb();
    await b.userProfileDao.completeOnboarding(
        kcalGoal: 1200, proteinGoal: 60, phase: 1);
    final junk = await b.userProfileDao.getProfile();

    await SyncPull(b, remote).pullAll(userId: user);

    final healed = await b.userProfileDao.getProfile();
    // Junk daha yeni olsa da farklı kimlik → sunucu benimsenir (kayıp yok).
    expect(healed!.kcalGoal, 3100);
    expect(healed.heightCm, 180);
    expect(await count(b, 'user_profile'), 1);
    // Junk artık kuyrukta değil → gerçek profili sunucuda ezmez.
    expect(await count(b, 'user_profile', 'sync_state = 1'), 0);
    expect(healed.uid, isNot(junk!.uid)); // sunucunun uid'ini aldı
    await b.close();
  });

  test('çakışma: yerel aynı-uid daha yeni ise KORUNUR (LWW)', () async {
    // A profili kurar, gönderir.
    final a = await freshDb();
    await a.userProfileDao.completeOnboarding(
        kcalGoal: 2000, proteinGoal: 150, phase: 2);
    await SyncPush(a, remote).pushAll(userId: user);
    final serverUid = (await a.userProfileDao.getProfile())!.uid;
    await a.close();

    // B: aynı uid'li profili al (pull), sonra ÇEVRİMDIŞI düzenle → daha yeni.
    final b = await freshDb();
    await b.userProfileDao.ensureProfile();
    await SyncPull(b, remote).pullAll(userId: user);
    expect((await b.userProfileDao.getProfile())!.uid, serverUid);

    // Yerel düzenleme (updated_at ileri gider, tetikleyici damgalar).
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    final p = await b.userProfileDao.getProfile();
    await b.userProfileDao.updateProfile(p!.copyWith(kcalGoal: 2600));

    // Tekrar pull: sunucu ESKİ (2000), yerel YENİ (2600) → yerel korunur.
    await SyncPull(b, remote).pullAll(userId: user);
    expect((await b.userProfileDao.getProfile())!.kcalGoal, 2600);
    await b.close();
  });

  test('katalog: aynı isimli seed satırı benimsenir, ikiz oluşmaz', () async {
    // A: seed hareketini bir sette kullanır → push onu kuyruğa alıp gönderir.
    final a = await freshDb();
    final seedId = await a.into(a.exercises).insert(ExercisesCompanion(
        name: const Value('Squat'),
        category: const Value('compound'),
        muscleGroups: const Value('["legs"]'),
        isCustom: const Value(false))); // seed (katalog)
    final sId = await a.into(a.workoutSessions).insert(WorkoutSessionsCompanion(
        date: Value(DateTime.now()),
        phase: const Value(0),
        workoutType: const Value('Boş Antrenman')));
    await a.into(a.workoutSets).insert(WorkoutSetsCompanion(
        sessionId: Value(sId),
        exerciseId: Value(seedId),
        setNumber: const Value(1),
        reps: const Value(5)));
    await SyncPush(a, remote).pushAll(userId: user);
    expect(remote.count('exercises'), 1); // seed sette kullanılınca gitti
    await a.close();

    // B: kendi seed katalogunda "Squat" var (FARKLI uid). Pull ikiz açmamalı.
    final b = await freshDb();
    await b.into(b.exercises).insert(ExercisesCompanion(
        name: const Value('Squat'),
        category: const Value('compound'),
        muscleGroups: const Value('["legs"]'),
        isCustom: const Value(false)));
    await SyncPull(b, remote).pullAll(userId: user);

    // Tek "Squat" kalmalı (benimsendi), set ona bağlanmalı.
    expect(await count(b, 'exercises', "name = 'Squat'"), 1);
    final joined = await b.customSelect(
            'SELECT e.name FROM workout_sets ws '
            'JOIN exercises e ON e.id = ws.exercise_id')
        .get();
    expect(joined.single.data['name'], 'Squat');
    await b.close();
  });

  test('boş sunucu → hiçbir şey değişmez, temiz döner', () async {
    final b = await freshDb();
    await b.userProfileDao.ensureProfile();
    final result = await SyncPull(b, remote).pullAll(userId: user);
    expect(result.ok, isTrue);
    expect(result.changed, 0);
    await b.close();
  });
}
