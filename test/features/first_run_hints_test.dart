import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fit_pack/core/onboarding/first_run_hints.dart';

/// docs/15 §B — mevcut kullanıcı koruması testleri.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mevcut kullanıcı (onboarded, ilk açılış) → ipuçları peşinen görüldü',
      () async {
    SharedPreferences.setMockInitialValues({});
    await FirstRunHints.initialize(onboarded: true);
    final prefs = await SharedPreferences.getInstance();
    for (final h in FirstRunHint.values) {
      expect(prefs.getBool('hint_seen_${h.name}'), true,
          reason: '${h.name} görüldü olmalı');
    }
    expect(prefs.getBool('hints_initialized'), true);
  });

  test('yeni kullanıcı (onboarded değil) → ipuçları görülmedi, marker set',
      () async {
    SharedPreferences.setMockInitialValues({});
    await FirstRunHints.initialize(onboarded: false);
    final prefs = await SharedPreferences.getInstance();
    for (final h in FirstRunHint.values) {
      expect(prefs.getBool('hint_seen_${h.name}'), isNull,
          reason: '${h.name} görülmemiş kalmalı');
    }
    expect(prefs.getBool('hints_initialized'), true);
  });

  test(
      'idempotent: onboarding biteli restart — marker varken onboarded=true '
      'gelse bile görülmemiş ipuçları SIFIRLANMAZ', () async {
    // Yeni kullanıcı onboarding'i bitirdi (onboarded=true) ama henüz hiçbir
    // sekmeyi gezmedi; ikinci açılışta ipuçları hâlâ gösterilmeli.
    SharedPreferences.setMockInitialValues({'hints_initialized': true});
    await FirstRunHints.initialize(onboarded: true);
    final prefs = await SharedPreferences.getInstance();
    for (final h in FirstRunHint.values) {
      expect(prefs.getBool('hint_seen_${h.name}'), isNull);
    }
  });
}
