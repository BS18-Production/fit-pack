// Yalnız Simulator QA: bellek içi örnek veri; gerçek hesap/disk/bulut kullanılmaz.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fit_pack/core/theme/app_theme.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/assistant/assistant_screen.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:fit_pack/shared/widgets/glass.dart';
import 'design_fixture.dart';
import 'test_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await initializeDateFormatting('tr');
  await initializeDateFormatting('en');
  final db = newTestDatabase();
  await seedDesignFixture(db);
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        locale: const Locale('tr'),
        theme: AppTheme.dark,
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: const GlassBackground(child: AssistantScreen()),
      ),
    ),
  );
}
