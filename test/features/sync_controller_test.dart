import 'package:drift/native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/sync/sync_controller.dart';
import 'package:fit_pack/features/sync/sync_push.dart';
import 'package:flutter_test/flutter_test.dart';

/// Senkron zamanlaması — ne zaman çalışır, ne zaman çalışmaz (docs/18 §6).
class _CountingRemote implements SyncRemote {
  int calls = 0;
  bool fail = false;

  @override
  Future<void> upsert(String table, List<Map<String, Object?>> rows) async {
    calls++;
    if (fail) throw Exception('ağ yok');
  }

  @override
  Future<List<Map<String, Object?>>> fetch(String table, String userId) async =>
      const [];
}

void main() {
  late AppDatabase db;
  late _CountingRemote remote;
  late SyncController ctrl;
  String? user = '00000000-0000-4000-8000-000000000001';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    remote = _CountingRemote();
    user = '00000000-0000-4000-8000-000000000001';
    ctrl = SyncController(
      db: db,
      push: SyncPush(db, remote),
      currentUserId: () => user,
      debounce: const Duration(milliseconds: 10),
    );
  });

  tearDown(() async {
    await ctrl.stop();
    await db.close();
  });

  Future<void> addRoutine(String name) => db.customStatement(
      "INSERT INTO routines (name, created_at) VALUES ('$name', 1700000000)");

  test('oturum yoksa senkron çalışmaz, satır kuyrukta bekler', () async {
    user = null; // çıkış yapılmış
    await addRoutine('Push');

    await ctrl.syncNow();

    expect(remote.calls, 0, reason: 'oturumsuz sunucuya gidilmez');
    expect(await ctrl.pendingCount(), 1, reason: 'kayıp yok, kuyrukta');
  });

  test('bekleyen yoksa boşa tur atmaz', () async {
    await ctrl.syncNow();
    expect(remote.calls, 0);
  });

  test('DÖNGÜ KORUMASI: başarılı turdan sonra kendini tetiklemez', () async {
    await addRoutine('Push');
    await ctrl.syncNow();
    final after = remote.calls;
    expect(after, greaterThan(0));
    expect(await ctrl.pendingCount(), 0);

    // Temiz işaretleme de bir yazmadır; ikinci tur bekleyen bulamamalı.
    await ctrl.syncNow();
    expect(remote.calls, after,
        reason: 'senkron kendi yazmasıyla yeniden tetiklenmemeli');
  });

  test('eşzamanlı çağrıda tek tur çalışır', () async {
    await addRoutine('A');
    await Future.wait([ctrl.syncNow(), ctrl.syncNow(), ctrl.syncNow()]);
    expect(remote.calls, 1, reason: 'aynı satır üç kez gönderilmemeli');
  });

  test('hata sonrası artan bekleme basamağı ilerler', () async {
    await addRoutine('Push');
    remote.fail = true;

    await ctrl.syncNow();
    expect(ctrl.failureCount, 1);
    expect(await ctrl.pendingCount(), 1, reason: 'hata → kuyrukta kalır');

    await ctrl.syncNow();
    expect(ctrl.failureCount, 2, reason: 'basamak ilerlemeli');

    // Ağ döndü → basamak sıfırlanır.
    remote.fail = false;
    await ctrl.syncNow();
    expect(ctrl.failureCount, 0);
    expect(await ctrl.pendingCount(), 0);
  });

  test('yazma geciktirmeli tetikler, fırtına tek tura toplanır', () async {
    ctrl.start();
    // Seans kaydeder gibi art arda yazma.
    for (var i = 0; i < 10; i++) {
      await addRoutine('R$i');
    }
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(remote.calls, lessThanOrEqualTo(2),
        reason: '10 yazma için 10 istek atılmamalı');
    expect(await ctrl.pendingCount(), 0, reason: 'hepsi gönderilmiş olmalı');
  });

  test('son sonuç okunabilir (Aşama G arayüzü için)', () async {
    await addRoutine('Push');
    await ctrl.syncNow();
    expect(ctrl.last.value?.pushed, greaterThan(0));
    expect(ctrl.last.value?.ok, isTrue);
  });
}
