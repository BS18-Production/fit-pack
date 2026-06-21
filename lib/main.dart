import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'data/providers.dart';
import 'data/seed/seed_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Türkçe tarih biçimlendirme verisini yükle. Olmadan DateFormat(..., 'tr_TR')
  // LocaleDataException fırlatır (V1'de eksikti — Aşama 0 sağlamlaştırma).
  await initializeDateFormatting('tr_TR', null);

  final container = ProviderContainer();
  final db = container.read(databaseProvider);

  // Seed initial data
  await SeedManager(db).seedIfNeeded();

  // İlk açılış (P-10) tamamlandı mı? seedIfNeeded profili garanti etti;
  // onboarded=false ise router onboarding ekranıyla başlar.
  final profile = await db.userProfileDao.getProfile();
  final onboarded = profile?.onboarded ?? false;

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: FitPackApp(onboarded: onboarded),
    ),
  );
}
