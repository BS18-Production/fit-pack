import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/onboarding/first_run_hints.dart';
import 'data/providers.dart';
import 'data/seed/seed_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tarih biçimlendirme verisini yükle (docs/14 — çok dilli). Desteklenen her
  // dil için gerekir; olmadan DateFormat(..., locale) LocaleDataException
  // fırlatır. `en` + `tr` yeter (uygulama iki dili destekliyor).
  await initializeDateFormatting('en', null);
  await initializeDateFormatting('tr', null);

  // Bulut yedek/hesap için Supabase (docs/13). Hata olsa bile uygulama
  // yerel-öncelikli çalışmaya devam eder — bulut opsiyonel bir katman.
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // Yeni sb_publishable_ anahtarı (eski anonKey yerine).
      publishableKey: SupabaseConfig.anonKey,
    );
  } catch (_) {
    // Ağ yok / yanlış config → bulut özellikleri pasif, yerel akış bozulmaz.
  }

  final container = ProviderContainer();
  final db = container.read(databaseProvider);

  // Seed initial data
  await SeedManager(db).seedIfNeeded();

  // İlk açılış (P-10) tamamlandı mı? seedIfNeeded profili garanti etti;
  // onboarded=false ise router onboarding ekranıyla başlar.
  final profile = await db.userProfileDao.getProfile();
  final onboarded = profile?.onboarded ?? false;

  // İlk-kullanım ipuçları (docs/15 §B): mevcut kullanıcıya güncelleme sonrası
  // coach mark gösterme — yalnız yeni onboarding'den geçenler görür.
  await FirstRunHints.initialize(onboarded: onboarded);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: FitPackApp(onboarded: onboarded),
    ),
  );
}
