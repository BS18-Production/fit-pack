import 'package:drift/native.dart';
import 'package:fit_pack/core/ids/deterministic_uid.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/sync/sync_pull.dart';
import 'package:fit_pack/features/sync/sync_push.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_sync_server.dart';

/// Beslenme günü tamamlandı — **iki cihaz** senkronu (docs/37 Aşama 2).
///
/// Senkron katmanı tablo listesinden genel çalışıyor; bu test yeni tablonun
/// gerçekten uçtan uca aktığını ve belirlenimci kimliğin iki cihazda tek satıra
/// birleştiğini ölçer (telefon + simülatör aynı hesap — docs/21 #8 gerekçesi).
void main() {
  const user = '00000000-0000-4000-8000-0000000000bb';
  final day = DateTime(2026, 10, 10);

  late FakeSyncServer remote;
  late AppDatabase phone;
  late AppDatabase sim;

  setUp(() async {
    remote = FakeSyncServer();
    phone = AppDatabase.forTesting(NativeDatabase.memory());
    sim = AppDatabase.forTesting(NativeDatabase.memory());
    await phone.customSelect('SELECT 1').get();
    await sim.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await phone.close();
    await sim.close();
  });

  Future<void> sync(AppDatabase db) async {
    await SyncPush(db, remote).pushAll(userId: user);
    await SyncPull(db, remote, cursorLag: 0).pullAll(userId: user);
  }

  Future<List<NutritionDay>> days(AppDatabase db) =>
      db.select(db.nutritionDays).get();

  test('iki cihaz aynı günü işaretler → sunucuda ve cihazlarda TEK satır',
      () async {
    await phone.nutritionDao.markDayComplete(day);
    await sim.nutritionDao.markDayComplete(day);
    await sync(phone);
    await sync(sim);
    await sync(phone);

    expect(remote.rowCount('nutrition_days'), 1);
    final sent = remote.store['nutrition_days']!.values.single;
    expect(sent['uid'], nutritionDayUid('2026-10-10'));
    expect(sent['day'], '2026-10-10');
    expect(sent['status'], 'complete');
    expect(sent.containsKey('id'), isFalse, reason: 'yerel id sunucuya gitmez');

    for (final db in [phone, sim]) {
      final rows = await days(db);
      expect(rows, hasLength(1));
      expect(rows.single.status, 'complete');
      expect(rows.single.syncState, 0, reason: 'senkron sonrası temiz');
    }
  });

  test('bir cihazda geri al → öteki cihaza "open" olarak iner, satır silinmez',
      () async {
    await phone.nutritionDao.markDayComplete(day);
    await sync(phone);
    await sync(sim);
    expect((await days(sim)).single.status, 'complete');

    await phone.nutritionDao.reopenDay(day);
    await sync(phone);
    await sync(sim);

    final rows = await days(sim);
    expect(rows, hasLength(1), reason: 'geri al silme değil');
    expect(rows.single.status, 'open');
    expect(rows.single.completedAtMs, isNull);
    expect(remote.rowCount('nutrition_days'), 1);
  });

  test('geri alınan gün yeniden işaretlenebilir (silinmiş kimlik sorunu yok)',
      () async {
    await phone.nutritionDao.markDayComplete(day);
    await sync(phone);
    await phone.nutritionDao.reopenDay(day);
    await sync(phone);
    await phone.nutritionDao.markDayComplete(day);
    await sync(phone);
    await sync(sim);

    expect((await days(sim)).single.status, 'complete');
    expect(remote.store['nutrition_days']!.values.single['status'], 'complete');
  });
}
