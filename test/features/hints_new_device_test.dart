import 'package:drift/native.dart';
import 'package:fit_pack/core/onboarding/first_run_hints.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/auth/auth_gate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// docs/49 E — yeni telefonda eski hesapla giren kullanıcıya ilk-kullanım
/// ipuçları gösterilmez; kurulumu bu cihazda yapan yeni kullanıcı görür.
void main() {
  const userA = '00000000-0000-4000-8000-00000000000a';

  late AppDatabase db;
  late ProviderContainer c;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Taze kurulum: açılışta oturum yok → `initialize(onboarded: false)`.
    SharedPreferences.setMockInitialValues({});
    await FirstRunHints.initialize(onboarded: false);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    c = ProviderContainer();
  });

  tearDown(() async {
    c.dispose();
    await db.close();
  });

  Future<Set<FirstRunHint>> seenOnDisk() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final h in FirstRunHint.values)
        if (prefs.getBool('hint_seen_${h.name}') ?? false) h,
    };
  }

  AuthGate gateWith(Future<void> Function(String) pull, void Function() hook) {
    final gate = AuthGate(db, pull: pull, onOnboardedFromAccount: hook);
    addTearDown(gate.dispose);
    return gate;
  }

  Future<void> serverHasOnboardedProfile(String _) =>
      db.userProfileDao.completeOnboarding(
        kcalGoal: 2400,
        proteinGoal: 150,
        phase: 0,
      );

  test('taze kurulum + kurulumu bitmiş hesap → ipuçları görüldü sayılır',
      () async {
    var calls = 0;
    final gate = gateWith(serverHasOnboardedProfile, () {
      calls++;
      c.read(firstRunHintsProvider.notifier).markAllSeen();
    });

    await gate.applyAccountForTest(userA);
    await pumpEventQueue();

    expect(gate.onboarded, isTrue, reason: 'kurulum tekrar gösterilmez');
    expect(calls, 1);
    expect(await seenOnDisk(), FirstRunHint.values.toSet());
    expect(c.read(firstRunHintsProvider), FirstRunHint.values.toSet());
  });

  test('taze kurulum + yeni hesap kurulumu bu cihazda bitirir → ipuçları kalır',
      () async {
    var calls = 0;
    final gate = gateWith((_) async {}, () => calls++);

    await gate.applyAccountForTest(userA);
    expect(gate.onboarded, isFalse, reason: 'sunucuda profil yok');

    // Kurulum ekranı bitti.
    await serverHasOnboardedProfile(userA);
    gate.markOnboarded();
    await pumpEventQueue();

    expect(calls, 0);
    expect(await seenOnDisk(), isEmpty);
  });

  test('kurulumu bu cihazda bitirip uygulamayı yeniden açan → ipuçları kalır',
      () async {
    await serverHasOnboardedProfile(userA);
    var calls = 0;
    final gate = gateWith((_) async {}, () => calls++);

    // Açılış: oturum yok (testte Supabase yok), onboarded diskten okunur.
    await gate.bootstrap();

    expect(gate.onboarded, isTrue);
    expect(calls, 0, reason: 'açılış okuması sunucudan gelmiş sayılmaz');
    expect(await seenOnDisk(), isEmpty);
  });
}
