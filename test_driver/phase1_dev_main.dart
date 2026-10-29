// Test-only entrypoint. Never use the production endpoint during phase1 proof.
import 'package:fit_pack/core/config/supabase_config.dart';
import 'package:fit_pack/main.dart' as app;
import 'package:flutter/foundation.dart';

void verifyPhase1DevTarget({
  required String url,
  required String publishableKey,
  required bool analyticsEnabled,
}) {
  if (url != 'https://qecbnrkbordkqeogmevi.supabase.co' ||
      !publishableKey.startsWith('sb_publishable_') ||
      !analyticsEnabled) {
    throw StateError('Phase1 simulator requires the exact approved Dev target');
  }
}

void main() {
  verifyPhase1DevTarget(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
    analyticsEnabled: const bool.fromEnvironment('FITPACK_ANALYTICS_ENABLED'),
  );
  debugPrint('PHASE1_DEV_TARGET_VERIFIED qecbnrkbordkqeogmevi analytics=true');
  app.main();
}
