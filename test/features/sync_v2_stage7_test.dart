import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/sync/sync_controller.dart';
import 'package:fit_pack/features/sync/sync_errors.dart';
import 'package:fit_pack/features/sync/sync_health.dart';
import 'package:fit_pack/features/sync/sync_pull.dart';
import 'package:fit_pack/features/sync/sync_push.dart';
import 'package:fit_pack/features/sync/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../helpers/fake_sync_server.dart';

/// **Senkron v2 — Aşama 7: durum ve operasyon** (docs/20 §9).
///
/// Ölçülen üç şey:
/// 1. Hata **sınıflandırma** — hangi hata tekrar denenir, hangisi satırı
///    kuyruktan ayırır.
/// 2. **Tek bozuk satır kuyruğu kilitlemez** — eskiden kalıcı bir hata bütün
///    tabloyu ve arkasındaki her şeyi sonsuza kadar durduruyordu.
/// 3. **Sağlık kaydı** — "Son yedekleme" ve 3 günlük kesinti uyarısı.
void main() {
  group('hata sınıflandırma', () {
    test('ağ hataları → sunucuya ulaşılamıyor', () {
      expect(classifySyncError(const SocketException('yok')),
          SyncErrorKind.unreachable);
      expect(classifySyncError(TimeoutException('yavaş')),
          SyncErrorKind.unreachable);
      expect(classifySyncError(http.ClientException('koptu')),
          SyncErrorKind.unreachable);
    });

    test('5xx → sunucuya ulaşılamıyor (proje duraklatılmış olabilir)', () {
      expect(
          classifySyncError(
              const PostgrestException(message: 'down', code: '503')),
          SyncErrorKind.unreachable);
    });

    test('yetki ve tekillik → KALICI', () {
      for (final code in ['42501', '403', '23505', '409']) {
        expect(
            classifySyncError(PostgrestException(message: 'x', code: code)),
            SyncErrorKind.permanent,
            reason: code);
      }
    });

    test('oturum düşmüş → oturum yok', () {
      expect(classifySyncError(const AuthException('süre doldu')),
          SyncErrorKind.noSession);
      expect(
          classifySyncError(
              const PostgrestException(message: 'jwt', code: 'PGRST301')),
          SyncErrorKind.noSession);
    });

    test('NOT NULL → onarılabilir', () {
      expect(
          classifySyncError(
              const PostgrestException(message: 'null', code: '23502')),
          SyncErrorKind.repairable);
    });

    test('tanınmayan hata GEÇİCİ sayılır — yanlışlıkla satır düşürülmez', () {
      // Yanlış "kalıcı" satırı kuyruktan atar; yanlış "geçici" yalnız bir
      // deneme daha yapar. Belirsizlikte ucuz olan seçilir.
      expect(classifySyncError(StateError('?')), SyncErrorKind.transient);
      expect(
          classifySyncError(
              const PostgrestException(message: '?', code: 'XX999')),
          SyncErrorKind.transient);
    });
  });

  group('kalıcı hata kuyruğu kilitlemez', () {
    const user = '00000000-0000-4000-8000-0000000000aa';
    late AppDatabase db;
    late _PoisonServer remote;
    late SyncPush push;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      remote = _PoisonServer();
      push = SyncPush(db, remote);
      await db.customSelect('SELECT 1').get();
    });
    tearDown(() => db.close());

    Future<void> addRoutine(String name) => db.into(db.routines).insert(
          RoutinesCompanion.insert(name: name, createdAt: DateTime.now()),
        );

    Future<int> countState(String table, int state) async {
      final r = await db
          .customSelect(
              'SELECT COUNT(*) c FROM $table WHERE sync_state = ?',
              variables: [Variable(state)])
          .getSingle();
      return r.read<int>('c');
    }

    test('bozuk satır ayrılır, sağlamlar gider', () async {
      await addRoutine('Sağlam 1');
      await addRoutine('BOZUK');
      await addRoutine('Sağlam 2');

      final result = await push.pushAll(userId: user);

      expect(result.ok, isTrue,
          reason: 'tur başarılı sayılmalı — kalıcı hata tekrar denenmez');
      expect(result.pushed, 2, reason: 'iki sağlam satır gitmeli');
      expect(result.permanent, 1);
      expect(remote.rowCount('routines'), 2);
      expect(await countState('routines', 2), 1,
          reason: 'bozuk satır hatalı işaretlenmeli');
      expect(await countState('routines', 1), 0,
          reason: 'kuyrukta bekleyen kalmamalı');
    });

    test('bozuk satır arkasındaki TABLOLARI da durdurmaz', () async {
      // Eskiden tablo hatası `break` ile turu bitiriyordu: routines'teki tek
      // bozuk satır yüzünden seanslar, öğünler, ölçümler hiç gönderilmezdi.
      await addRoutine('BOZUK');
      await db.into(db.bodyMeasurements).insert(
            BodyMeasurementsCompanion.insert(date: DateTime.now()),
          );

      await push.pushAll(userId: user);

      expect(remote.rowCount('body_measurements'), 1,
          reason: 'sonraki tablo gönderilmeli');
    });

    test('hatalı satır verisi yerelde DURUR — silinmez', () async {
      await addRoutine('BOZUK');
      await push.pushAll(userId: user);
      final r = await db
          .customSelect("SELECT COUNT(*) c FROM routines WHERE name = 'BOZUK'")
          .getSingle();
      expect(r.read<int>('c'), 1);
    });

    test('düzenlenen hatalı satır kendiliğinden yeniden kuyruğa girer',
        () async {
      await addRoutine('BOZUK');
      await push.pushAll(userId: user);
      expect(await countState('routines', 2), 1);

      await db.customStatement(
          "UPDATE routines SET note = 'düzelttim' WHERE name = 'BOZUK'");

      expect(await countState('routines', 1), 1,
          reason: 'kullanıcı düzenlerse yeniden denenmeli');
    });

    test('"tekrar dene" hatalı satırları kuyruğa alır ve gönderir', () async {
      await addRoutine('BOZUK');
      await push.pushAll(userId: user);
      expect(await countState('routines', 2), 1);

      final ctrl = SyncController(
        db: db,
        push: push,
        currentUserId: () => user,
        debounce: Duration.zero,
      );
      addTearDown(ctrl.stop);
      expect(await ctrl.failedCount(), 1);

      remote.healed = true; // sunucu tarafı düzeltildi
      await ctrl.retryFailed();

      expect(await ctrl.failedCount(), 0);
      expect(remote.rowCount('routines'), 1, reason: 'bu sefer gitmeli');
    });

    test('GEÇİCİ hata satırı hatalı işaretlemez', () async {
      await addRoutine('Sağlam');
      remote.fail = true; // ağ yok

      final result = await push.pushAll(userId: user);

      expect(result.ok, isFalse);
      expect(result.permanent, 0);
      expect(await countState('routines', 2), 0,
          reason: 'ağ hatası satırı kuyruktan düşürmemeli');
      expect(await countState('routines', 1), 1, reason: 'kuyrukta beklemeli');
    });
  });

  group('sağlık kaydı', () {
    const user = '00000000-0000-4000-8000-0000000000aa';
    late AppDatabase db;
    late FakeSyncServer remote;
    var simdi = DateTime(2026, 9, 19, 14, 32);

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      remote = FakeSyncServer();
      simdi = DateTime(2026, 9, 19, 14, 32);
      await db.customSelect('SELECT 1').get();
    });
    tearDown(() => db.close());

    SyncHealth health() => SyncHealth(db, now: () => simdi);

    test('başarılı gönderim "son yedekleme" zamanını yazar', () async {
      await db.into(db.routines).insert(
            RoutinesCompanion.insert(name: 'A', createdAt: DateTime.now()),
          );
      await SyncPush(db, remote, health: health()).pushAll(userId: user);

      expect(await health().lastPushOk(), simdi);
      expect(await health().unreachableSince(), isNull);
    });

    test('başarılı çekme de temas sayılır', () async {
      await SyncPull(db, remote, health: health()).pullAll(userId: user);
      expect(await health().lastContactOk(), simdi);
    });

    test('ulaşılamama kesintinin BAŞLANGICINI yazar, ileri kaydırmaz',
        () async {
      await db.into(db.routines).insert(
            RoutinesCompanion.insert(name: 'A', createdAt: DateTime.now()),
          );
      remote.fail = true;
      remote.failWith = const SocketException('ağ yok');

      final ilk = simdi;
      await SyncPush(db, remote, health: health()).pushAll(userId: user);
      expect(await health().unreachableSince(), ilk);

      simdi = simdi.add(const Duration(days: 2));
      await SyncPush(db, remote, health: health()).pushAll(userId: user);
      expect(await health().unreachableSince(), ilk,
          reason: 'ileri kaysaydı "3 gündür" uyarısı hiç dolmazdı');
    });

    test('bağlantı dönünce kesinti kaydı silinir', () async {
      await db.into(db.routines).insert(
            RoutinesCompanion.insert(name: 'A', createdAt: DateTime.now()),
          );
      remote.fail = true;
      remote.failWith = const SocketException('ağ yok');
      await SyncPush(db, remote, health: health()).pushAll(userId: user);
      expect(await health().unreachableSince(), isNotNull);

      remote.fail = false;
      await SyncPush(db, remote, health: health()).pushAll(userId: user);
      expect(await health().unreachableSince(), isNull);
    });

    test('kalıcı/geçici hata kesinti sayılmaz — yalnız ulaşılamama', () async {
      await health().recordError(
          const PostgrestException(message: 'yetki', code: '42501'));
      expect(await health().unreachableSince(), isNull);
    });
  });

  group('3 gün uyarısı', () {
    final simdi = DateTime(2026, 9, 19, 12);

    test('3 günden kısa kesintide uyarı YOK', () {
      final s = SyncStatus(
        pending: 1,
        state: SyncState.failed,
        unreachableSince: simdi.subtract(const Duration(days: 2, hours: 23)),
        now: simdi,
      );
      expect(s.longOutageDays, isNull,
          reason: 'bir gün çevrimdışı kaldı diye kullanıcıyı korkutma');
    });

    test('3 gün ve fazlasında uyarı, gün sayısıyla', () {
      final s = SyncStatus(
        pending: 1,
        state: SyncState.failed,
        unreachableSince: simdi.subtract(const Duration(days: 4, hours: 2)),
        now: simdi,
      );
      expect(s.longOutageDays, 4);
    });

    test('kesinti yoksa uyarı yok', () {
      final s = SyncStatus(pending: 0, state: SyncState.synced, now: simdi);
      expect(s.longOutageDays, isNull);
    });
  });
}

/// "BOZUK" adlı rutini içeren her gönderimi yetki hatasıyla (42501) reddeden
/// sunucu — gerçekte bir RLS ihlali ya da tekillik çakışması.
class _PoisonServer extends FakeSyncServer {
  /// true olunca sunucu tarafı "düzeltilmiş" sayılır.
  bool healed = false;

  @override
  Future<List<AcceptedRow>> upsert(
      String table, List<Map<String, Object?>> rows) async {
    if (!healed && rows.any((r) => r['name'] == 'BOZUK')) {
      throw const PostgrestException(
          message: 'new row violates row-level security policy',
          code: '42501');
    }
    return super.upsert(table, rows);
  }
}
