import 'package:fit_pack/core/theme/app_colors.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/nutrition/day_complete.dart';
import 'package:fit_pack/features/nutrition/nutrition_screen.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

/// "Bugünkü kaydım tamamlandı" kartı (docs/37 §1, Aşama 5) — gerçek
/// bellek-içi veritabanı + gerçek sağlayıcı: düğme işaretler, ✓ görünür,
/// geri al satırı silmeden açar.
void main() {
  late AppDatabase db;
  final gun = DateTime(2026, 10, 10);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = newTestDatabase();
  });
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> ac(WidgetTester tester, {bool isToday = true}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        selectedDateProvider.overrideWith((ref) => gun),
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: AppColors.lightScheme,
          extensions: [AppColors.lightSemantic],
        ),
        locale: const Locale('tr'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(body: DayCompleteCard(date: gun, isToday: isToday)),
      ),
    ));
    await settle(tester);
  }

  testWidgets('işaretle → ✓ "Kaydın tamam"; geri al → düğme geri gelir',
      (tester) async {
    await ac(tester);
    expect(find.text('Bugünün tüm öğünlerini girdim'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nutrition.dayComplete')));
    await settle(tester);
    expect(find.text('Tüm öğünler girildi'), findsOneWidget);
    expect(find.text('Tamamlandıktan sonra değişti'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('nutrition.dayReopen')));
    await settle(tester);
    expect(find.text('Bugünün tüm öğünlerini girdim'), findsOneWidget);
    final rows = await tester.runAsync(() => db.select(db.nutritionDays).get());
    expect(rows!.single.status, 'open', reason: 'geri al satırı silmez');
  });

  // CR-019: yazma başarısızsa kart değişmez, kullanıcı kısa mesaj görür.
  Future<void> bozYazma(String table) => db.customStatement(
      'CREATE TRIGGER test_fail_$table BEFORE INSERT ON $table '
      "BEGIN SELECT RAISE(ABORT, 'disk dolu'); END");

  testWidgets('işaretleme yazılamazsa uyarı çıkar, kart işaretsiz kalır',
      (tester) async {
    await ac(tester);
    await tester.runAsync(() => bozYazma('nutrition_days'));

    await tester.tap(find.byKey(const ValueKey('nutrition.dayComplete')));
    await settle(tester);

    expect(find.text('Kaydedilemedi, tekrar dene'), findsOneWidget);
    expect(find.text('Bugünün tüm öğünlerini girdim'), findsOneWidget);
    final rows = await tester.runAsync(() => db.select(db.nutritionDays).get());
    expect(rows, isEmpty);
  });

  testWidgets('geri açma yazılamazsa uyarı çıkar, gün tamam kalır',
      (tester) async {
    await ac(tester);
    await tester.tap(find.byKey(const ValueKey('nutrition.dayComplete')));
    await settle(tester);
    await tester.runAsync(() => db.customStatement(
        'CREATE TRIGGER test_fail_reopen BEFORE UPDATE ON nutrition_days '
        "BEGIN SELECT RAISE(ABORT, 'disk dolu'); END"));

    await tester.tap(find.byKey(const ValueKey('nutrition.dayReopen')));
    await settle(tester);

    expect(find.text('Kaydedilemedi, tekrar dene'), findsOneWidget);
    expect(find.text('Tüm öğünler girildi'), findsOneWidget);
  });

  testWidgets('geçmiş gün kendi metniyle', (tester) async {
    await ac(tester, isToday: false);
    expect(find.text('Bu günün tüm öğünlerini girdim'), findsOneWidget);
  });
}
