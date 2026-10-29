import 'package:flutter_test/flutter_test.dart';
import '../../test_driver/phase1_dev_main.dart';

void main() {
  test('only exact approved Dev target can launch the test entrypoint', () {
    expect(
      () => verifyPhase1DevTarget(
        url: 'https://qecbnrkbordkqeogmevi.supabase.co',
        publishableKey: 'sb_publishable_synthetic',
        analyticsEnabled: true,
      ),
      returnsNormally,
    );
  });
  test('production and lookalike endpoints fail before app initialization', () {
    for (final url in [
      'https://jkviihbyogktwboreydn.supabase.co',
      'https://qecbnrkbordkqeogmevi.supabase.co.example.invalid',
    ]) {
      expect(
        () => verifyPhase1DevTarget(
          url: url,
          publishableKey: 'sb_publishable_synthetic',
          analyticsEnabled: true,
        ),
        throwsStateError,
      );
    }
  });
  test('missing analytics flag or non-publishable credential fails closed', () {
    for (final value in [
      (false, 'sb_publishable_synthetic'),
      (true, 'not-a-public-key'),
    ]) {
      expect(
        () => verifyPhase1DevTarget(
          url: 'https://qecbnrkbordkqeogmevi.supabase.co',
          publishableKey: value.$2,
          analyticsEnabled: value.$1,
        ),
        throwsStateError,
      );
    }
  });
}
