import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/onboarding/first_run_hints.dart';
import 'data/providers.dart';
import 'data/seed/seed_manager.dart';
import 'features/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Liquid glass zemin sistem çubuklarının ARKASINA uzansın (edge-to-edge):
  // status bar + gesture çubuğu transparan; yoksa gri/siyah bant zemini keser.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  ));

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

  // Zorunlu giriş kapısı (docs/18 §5.1). `runApp` ÖNCESİ kurulur: oturum varsa
  // hesap değişimi kontrolü çalışır ve `onboarded` diskten okunur. Kapı kararı
  // gevşek bir provider'ın varsayılanına bırakılmaz (Kural 2) — ilk kare doğru
  // ekranı çizsin.
  final gate = container.read(authGateProvider);
  await gate.bootstrap();

  // İlk-kullanım ipuçları (docs/15 §B): mevcut kullanıcıya güncelleme sonrası
  // coach mark gösterme — yalnız yeni onboarding'den geçenler görür.
  await FirstRunHints.initialize(onboarded: gate.onboarded);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FitPackApp(),
    ),
  );
}
