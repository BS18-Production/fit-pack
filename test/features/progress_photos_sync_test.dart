import 'package:drift/native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/tables/sync_columns.dart';
import 'package:fit_pack/features/auth/account_switch.dart';
import 'package:fit_pack/features/sync/sync_controller.dart';
import 'package:fit_pack/features/sync/sync_pull.dart';
import 'package:fit_pack/features/sync/sync_push.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_sync_server.dart';

/// İlerleme fotoğrafları **cihazdan çıkmaz** (docs/19 §3 K-2, §6 kural 1).
///
/// Satır yerel tabloda durur ve hesap değişiminde silinir, ama gönderim,
/// çekme ve senkron göstergesi onu hiç görmez.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const user = '00000000-0000-4000-8000-0000000000aa';
  late AppDatabase db;
  late FakeSyncServer remote;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remote = FakeSyncServer();
    await db.customSelect('SELECT 1').get();
  });
  tearDown(() => db.close());

  Future<void> fotografEkle() => db.bodyDao.insertPhoto(
        ProgressPhotosCompanion.insert(
          date: DateTime.now(),
          angle: 'front',
          imagePath: '2026-09-19T08-00-00-000_front.jpg',
        ),
      );

  test('fotoğraf satırı sunucuya GÖNDERİLMEZ', () async {
    await fotografEkle();
    await SyncPush(db, remote).pushAll(userId: user);

    expect(remote.calls, isNot(contains('progress_photos')),
        reason: 'dosya adı yalnız bu cihazda anlamlı — öteki cihaz kırık '
            'kayıt çekerdi');
    expect(remote.rowCount('progress_photos'), 0);
  });

  test('sunucudan fotoğraf satırı ÇEKİLMEZ', () async {
    remote.serverSideWrite('progress_photos', 'p1', {
      'uid': 'p1',
      'user_id': user,
      'date': '2026-09-19T08:00:00Z',
      'angle': 'front',
      'image_path': 'baska-cihaz.jpg',
      'updated_at': '2026-09-19T08:00:00Z',
      'changed_at_ms': 1,
    });
    await SyncPull(db, remote, cursorLag: 0).pullAll(userId: user);

    expect(remote.calls, isNot(contains('fetchSince:progress_photos')));
    final n = await db
        .customSelect('SELECT COUNT(*) c FROM progress_photos')
        .getSingle();
    expect(n.read<int>('c'), 0);
  });

  test('senkron göstergesi fotoğrafı "yüklenmeyi bekliyor" saymaz', () async {
    await fotografEkle();
    final ctrl = SyncController(
      db: db,
      push: SyncPush(db, remote),
      currentUserId: () => user,
    );
    addTearDown(ctrl.stop);

    expect(await ctrl.pendingCount(), 0,
        reason: 'hiç gönderilmeyecek satır "bekliyor" gösterilirse gösterge '
            'sonsuza kadar yalan söyler');
    expect(await ctrl.hasPending(), isFalse);
  });

  test('hesap değişimi uyarısı fotoğrafı SAYAR — sessizce silinmesin',
      () async {
    await fotografEkle();
    expect(await AccountSwitchGuard.pendingRowCount(db), 1,
        reason: 'temizlik fotoğrafları geri dönüşsüz siler; kullanıcı '
            'uyarılmalı');
  });

  test('hesap temizliği fotoğraf satırlarını siler (gizlilik)', () async {
    await fotografEkle();
    await AccountSwitchGuard.wipeLocalUserData(db);
    final n = await db
        .customSelect('SELECT COUNT(*) c FROM progress_photos')
        .getSingle();
    expect(n.read<int>('c'), 0,
        reason: "A'nın vücut fotoğrafları B'ye görünmemeli");
  });

  test('muaf küme ile uzak liste tutarlı', () {
    expect(syncRemoteTables, isNot(contains('progress_photos')));
    expect(syncPushOrder, contains('progress_photos'),
        reason: 'temizlik listesinden çıkarsa hesap değişiminde fotoğraflar '
            'cihazda kalır');
  });
}
