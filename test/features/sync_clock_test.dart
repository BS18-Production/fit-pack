import 'package:drift/native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/sync_meta_dao.dart';
import 'package:fit_pack/features/sync/sync_clock.dart';
import 'package:fit_pack/features/sync/sync_push.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_sync_server.dart';

/// Sunucu saati farkı (docs/23 §2).
///
/// Kilitlenen hata: sunucu İLERİ sapmayı kırpıyor ama GERİ sapmayı kırpmıyor.
/// Saati geride olan telefonun gerçek düzenlemesi sunucudakinden küçük damga
/// taşır, `sync_guard` onu "eski" sayıp atlar, istemci ret çözümünde kendi
/// satırını sunucununkiyle değiştirir. Kullanıcı için: sessiz düzenleme kaybı.
void main() {
  late AppDatabase db;
  late FakeSyncServer remote;
  const user = '00000000-0000-4000-8000-000000000001';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    remote = FakeSyncServer();
  });

  tearDown(() => db.close());

  Future<int> offset() => SyncClock(db).offsetMs();

  Future<int> changedAtMs(String table) async {
    final r =
        await db.customSelect('SELECT changed_at_ms c FROM $table').getSingle();
    return r.read<int>('c');
  }

  group('fark öğrenme', () {
    test('başlangıçta fark 0 — düzeltme yok', () async {
      expect(await offset(), 0);
    });

    test('eşiği aşan geri sapma öğrenilir', () async {
      final clock = SyncClock(db);
      // Cihaz 2 saat GERİDE: sunucu damgası cihazınkinden 2 saat büyük.
      await clock.learn(serverMs: 7200000, sentAtMs: 0);
      expect(await offset(), 7200000);
    });

    test('eşiği aşan ileri sapma da öğrenilir', () async {
      await SyncClock(db).learn(serverMs: 0, sentAtMs: 7200000);
      expect(await offset(), -7200000);
    });

    test('eşiğin altındaki fark yok sayılır — ağ gecikmesi sapma değildir',
        () async {
      await SyncClock(db).learn(serverMs: 29000, sentAtMs: 0);
      expect(await offset(), 0,
          reason: '29 sn eşiğin (30 sn) altında; her turda damga oynamamalı');
    });

    test('bir günü aşan fark reddedilir — cihaz takvimi bozuk', () async {
      await SyncClock(db)
          .learn(serverMs: 0, sentAtMs: const Duration(days: 400).inMilliseconds);
      expect(await offset(), 0,
          reason: 'saçma farkı uygulamak bütün damgaları bozardı');
    });

    test('öğrenilmiş fark üstüne küçük değişiklik yazılmaz', () async {
      final clock = SyncClock(db);
      await clock.learn(serverMs: 7200000, sentAtMs: 0);
      await clock.learn(serverMs: 7205000, sentAtMs: 0); // 5 sn oynadı
      expect(await offset(), 7200000);
    });

    test('correctedNow farkı uygular', () async {
      await SyncClock(db).learn(serverMs: 7200000, sentAtMs: 0);
      final sabit = DateTime.utc(2026, 9, 22, 10);
      final clock = SyncClock(db, now: () => sabit);
      expect(await clock.correctedNow(), sabit.add(const Duration(hours: 2)));
    });
  });

  group('damgalama farkı uygular (tetikleyici, şema v13)', () {
    test('fark 0 iken damga cihaz saatine yakın', () async {
      await db.customStatement(
          "INSERT INTO routines (name, created_at) VALUES ('A', 1700000000)");
      final damga = await changedAtMs('routines');
      final simdi = DateTime.now().millisecondsSinceEpoch;
      expect((damga - simdi).abs(), lessThan(5000));
    });

    test('fark yazılınca damga o kadar kayar', () async {
      await SyncMetaDao(db)
          .write(SyncMetaDao.keyClockOffsetMs, '${7200000}'); // +2 saat
      await db.customStatement(
          "INSERT INTO routines (name, created_at) VALUES ('B', 1700000000)");

      final damga = await changedAtMs('routines');
      final beklenen = DateTime.now().millisecondsSinceEpoch + 7200000;
      expect((damga - beklenen).abs(), lessThan(5000),
          reason: 'tetikleyici clock_offset_ms terimini eklemeli');
    });

    test('anahtar silinse bile damga NULL olmaz', () async {
      // COALESCE olmasaydı alt sorgu NULL döner, damga NULL olur ve satır
      // sunucuda "damgasız" sayılıp reddedilirdi.
      await SyncMetaDao(db).remove(SyncMetaDao.keyClockOffsetMs);
      await db.customStatement(
          "INSERT INTO routines (name, created_at) VALUES ('C', 1700000000)");

      final damga = await changedAtMs('routines');
      final simdi = DateTime.now().millisecondsSinceEpoch;
      expect((damga - simdi).abs(), lessThan(5000));
    });

    test('mezar taşı damgası da farkı uygular', () async {
      await db.customStatement(
          "INSERT INTO routines (name, created_at) VALUES ('D', 1700000000)");
      // Mezar taşı yalnız sunucuya gitmiş OLABİLECEK satırlar için yazılır
      // (kullanılmamış seed katalog satırı iz bırakmaz) → sahibi olsun.
      await db.customStatement(
          "UPDATE routines SET user_id = '$user' WHERE name = 'D'");
      await SyncMetaDao(db).write(SyncMetaDao.keyClockOffsetMs, '${7200000}');
      await db.customStatement("DELETE FROM routines WHERE name = 'D'");

      final r = await db
          .customSelect('SELECT changed_at_ms c FROM sync_tombstones')
          .getSingle();
      final beklenen = DateTime.now().millisecondsSinceEpoch + 7200000;
      expect((r.read<int>('c') - beklenen).abs(), lessThan(5000));
    });
  });

  group('gönderim farkı öğretir (docs/23 §2.2)', () {
    test('sunucu damgası dönerse fark yazılır', () async {
      // Sunucu cihazdan 2 saat ileride.
      remote.serverNowMs =
          DateTime.now().millisecondsSinceEpoch + 7200000;
      await db.customStatement(
          "INSERT INTO routines (name, created_at) VALUES ('E', 1700000000)");

      await SyncPush(db, remote).pushAll(userId: user);

      final fark = await offset();
      expect((fark - 7200000).abs(), lessThan(5000),
          reason: 'fark gönderim cevabından ek tur atmadan öğrenilmeli');
    });

    test('sunucu damgayı dönmezse fark değişmez', () async {
      remote.serverNowMs = null; // eski sunucu
      await db.customStatement(
          "INSERT INTO routines (name, created_at) VALUES ('F', 1700000000)");

      await SyncPush(db, remote).pushAll(userId: user);

      expect(await offset(), 0,
          reason: 'damga yoksa öğrenecek bir şey yok; davranış eskisi gibi');
    });
  });
}
