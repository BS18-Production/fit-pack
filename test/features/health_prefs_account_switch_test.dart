import 'package:drift/native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/sync_meta_dao.dart';
import 'package:fit_pack/features/auth/account_switch.dart';
import 'package:fit_pack/features/auth/auth_gate.dart';
import 'package:fit_pack/features/health/health_prefs.dart';
import 'package:fit_pack/features/health/step_providers.dart';
import 'package:fit_pack/features/health/step_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hesap değişiminde sağlık tercihinin BELLEKTEKİ kopyası da sıfırlanır
/// (CR-007). Disk temizliği tek başına yetmez: yaşayan provider A'nın
/// "bağlı" ve adım hedefi değerini B'ye taşırdı.
class _FakeSource implements StepSource {
  @override
  Future<StepPlatformStatus> platformStatus() async =>
      StepPlatformStatus.available;
  @override
  Future<bool> requestAccess() async => true;
  @override
  Future<bool?> hasAccess() async => null; // iOS: tercihe güvenilir
  @override
  Future<int?> stepsBetween(DateTime start, DateTime end) async => 5000;
  @override
  Future<void> openInstall() async {}
}

void main() {
  const userA = '00000000-0000-4000-8000-00000000000a';
  const userB = '00000000-0000-4000-8000-00000000000b';

  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer c;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'health_connected': true,
      'health_step_goal': 9000,
    });
    db = AppDatabase.forTesting(NativeDatabase.memory());
    c = ProviderContainer(
      overrides: [stepSourceProvider.overrideWithValue(_FakeSource())],
    );
    // A hesabında tercihler yüklü, adım kartı bağlı.
    c.read(healthPrefsProvider);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(healthPrefsProvider).connected, isTrue);
    expect(await c.read(stepLinkStateProvider.future), StepLinkState.connected);
    await db.syncMetaDao.write(SyncMetaDao.keyLastUser, userA);
  });

  tearDown(() async {
    c.dispose();
    await db.close();
  });

  Future<void> expectCleared() async {
    c.read(healthPrefsProvider);
    await Future<void>.delayed(Duration.zero);
    final p = c.read(healthPrefsProvider);
    expect(p.connected, isFalse, reason: "B, A'nın bağlantısını devralmaz");
    expect(p.stepGoal, isNull, reason: "B, A'nın adım hedefini devralmaz");
    expect(
        await c.read(stepLinkStateProvider.future), StepLinkState.notConnected);
  }

  test('yarım kalmış temizlik açılışta tamamlanınca bellek de sıfırlanır',
      () async {
    await db.syncMetaDao.write(SyncMetaDao.keySwitchInProgress, userB);
    var wiped = 0;
    final gate = AuthGate(db, onLocalDataWiped: () {
      wiped++;
      c.invalidate(healthPrefsProvider);
    });
    addTearDown(gate.dispose);

    await gate.bootstrap();

    expect(wiped, 1);
    await expectCleared();
  });

  test('temizlik yoksa kanca çağrılmaz, tercih korunur', () async {
    var wiped = 0;
    final gate = AuthGate(db, onLocalDataWiped: () => wiped++);
    addTearDown(gate.dispose);

    await gate.bootstrap();

    expect(wiped, 0);
    expect(c.read(healthPrefsProvider).connected, isTrue);
  });

  test('kanca olmadan da sağlık dönemi tercihi yeniden okutur (docs/40)',
      () async {
    // health-next: temizlik `healthEpoch`'u artırır, notifier diskten yeniden
    // okur — kanca ikinci güvence.
    expect(await AccountSwitchGuard.apply(db, userB), AccountSwitch.wiped);
    await expectCleared();
  });
}
