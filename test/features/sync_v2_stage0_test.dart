import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/sync/sync_pull.dart';
import 'package:fit_pack/features/sync/sync_push.dart';
import 'package:flutter_test/flutter_test.dart';

/// **Senkron v2 — Aşama 0/1 testleri** (docs/20 §10.1, §11).
///
/// Dördü de önce BUGÜNKÜ koda karşı yazıldı ve kırmızı oldukları görüldü
/// (2026-09-18); **Aşama 1 ile yeşile döndüler**. Artık regresyon bekçisi:
/// biri kırmızıya dönerse o hata geri gelmiş demektir.
///
/// | Test | Önlediği hata | Çözen mekanizma |
/// |---|---|---|
/// | S-1 | Gönderim sürerken yapılan düzenleme sessizce kaybolurdu | `local_seq` ile temiz işaretleme |
/// | S-2 | Aynı saniyedeki iki düzenleme ayırt edilemezdi | `local_seq` + `changed_at_ms` |
/// | S-4 | Çekme sürerken eklenen satır kuyruğa girmezdi | `capture` bayrağı (tetikleyici düşürülmüyor) |
/// | S-6 | Düşen tetikleyici geri gelmezdi, senkron sessizce ölürdü | açılışta onarım |
void main() {
  late AppDatabase db;
  const user = '00000000-0000-4000-8000-000000000001';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get(); // şema + tetikleyiciler kurulsun
  });

  tearDown(() => db.close());

  Future<void> addRoutine(String name) => db.customStatement(
    "INSERT INTO routines (name, created_at) VALUES ('$name', 1700000000)",
  );

  Future<int> pending(String table) async {
    final r = await db
        .customSelect('SELECT COUNT(*) c FROM $table WHERE sync_state = 1')
        .getSingle();
    return r.read<int>('c');
  }

  test(
    'S-1 · gönderim SÜRERKEN yapılan düzenleme kuyrukta kalır',
    () async {
      await addRoutine('Push');

      // Sunucu yazması askıda dururken kullanıcı satırı düzenler. Tetikleyici
      // `updated_at`'i saniye çözünürlüğüyle "şimdi"ye çeker; gönderimle aynı
      // saniyeye düştüğü için istemci satırı kendi gönderdiği sürüm sanıp
      // temiz işaretliyor → düzenleme kayboluyor.
      final held = Completer<void>();
      final remote = _SlowRemote(onUpsert: (_) async {
        await db.customStatement("UPDATE routines SET name = 'Pull'");
        held.complete();
      });

      await SyncPush(db, remote).pushAll(userId: user);
      await held.future;

      expect(await pending('routines'), 1,
          reason: 'uçuştaki düzenleme kuyrukta kalmalı');
    },
  );

  test('S-2 · aynı saniyedeki iki düzenleme ayırt edilir', () async {
    await addRoutine('Push');
    final first = await db
        .customSelect('SELECT updated_at, changed_at_ms, local_seq FROM routines')
        .getSingle();

    await db.customStatement("UPDATE routines SET name = 'Pull'");
    final second = await db
        .customSelect('SELECT updated_at, changed_at_ms, local_seq FROM routines')
        .getSingle();

    // Saniyelik damga aynı kalabilir — sorun buydu.
    expect(second.read<int>('updated_at'), first.read<int>('updated_at'),
        reason: 'test aynı saniye içinde koşmalı, yoksa hiçbir şey ölçmez');
    // Ayırt eden: cihaz sayacı (ve milisaniyelik damga).
    expect(second.read<int>('local_seq'),
        greaterThan(first.read<int>('local_seq')),
        reason: 'her düzenleme yeni bir sayaç değeri almalı');
    expect(second.read<int>('changed_at_ms'),
        greaterThanOrEqualTo(first.read<int>('changed_at_ms')));
  });

  test(
    'S-4 · çekme SÜRERKEN eklenen satır kuyruğa girer',
    () async {
      // Çekme, kendi yazımları yankılanmasın diye tetikleyicileri DÜŞÜRÜYOR.
      // O aralıkta kullanıcının eklediği satır da tetikleyicisiz kalıyor:
      // uid'siz, damgasız ve kuyruğa girmemiş → sunucuya hiç gitmiyor.
      final remote = _SlowRemote(onFetch: (table) async {
        if (table == 'routines') {
          await db.customStatement(
            "INSERT INTO routines (name, created_at) VALUES ('Çekme sırasında', 1700000000)",
          );
        }
      });

      await SyncPull(db, remote).pullAll(userId: user);

      final row = await db
          .customSelect(
            "SELECT uid, sync_state FROM routines WHERE name = 'Çekme sırasında'",
          )
          .getSingle();
      expect(row.read<int>('sync_state'), 1, reason: 'kuyruğa girmeli');
      expect(row.read<String?>('uid'), isNotNull, reason: 'uid üretilmeli');
    },
  );

  test(
    'S-6 · düşen tetikleyici veritabanı yeniden açılınca geri gelir',
    () async {
      // Göç yarıda kesilir ya da çekme sırasında uygulama ölürse tetikleyici
      // eksik kalır; o andan sonra hiçbir değişiklik kuyruğa girmez —
      // senkron sessizce ölür. Açılışta onarım şart.
      // Gerçek dosya şart: "yeniden açılış" AYNI veritabanını yeniden açmak
      // demek (bellek-içi DB kapanınca yok olur, onarım ölçülemez).
      final dir = Directory.systemTemp.createTempSync('fitpack_s6');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/fit_pack.sqlite');

      final first = AppDatabase.forTesting(NativeDatabase(file));
      await first.customSelect('SELECT 1').get();
      await first.customStatement('DROP TRIGGER IF EXISTS routines_sync_ins');
      await first.close();

      final reopened = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(reopened.close);
      final exists = await reopened
          .customSelect(
            "SELECT COUNT(*) c FROM sqlite_master "
            "WHERE type = 'trigger' AND name = 'routines_sync_ins'",
          )
          .getSingle();
      expect(exists.read<int>('c'), 1, reason: 'tetikleyici onarılmalı');
    },
  );
}

/// Çağrı sırasında araya girebilen sahte sunucu: gerçek yarışı kurar.
class _SlowRemote implements SyncRemote {
  _SlowRemote({this.onUpsert, this.onFetch});

  final Future<void> Function(String table)? onUpsert;
  final Future<void> Function(String table)? onFetch;
  final Map<String, List<Map<String, Object?>>> store = {};

  @override
  Future<void> upsert(String table, List<Map<String, Object?>> rows) async {
    await onUpsert?.call(table);
    store.putIfAbsent(table, () => []).addAll(rows);
  }

  @override
  Future<List<Map<String, Object?>>> fetch(String table, String userId) async {
    await onFetch?.call(table);
    return const [];
  }
}
