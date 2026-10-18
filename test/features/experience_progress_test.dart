import 'dart:math' as math;
import 'package:drift/drift.dart' show Value;
import 'package:fl_chart/fl_chart.dart';
import 'package:fit_pack/core/onboarding/first_run_hints.dart';
import 'package:fit_pack/core/theme/app_theme.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/body_metrics/body_metrics_screen.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_database.dart';
void main() {
  for (final dark in [true, false]) {
    testWidgets('kilo varken ilk kilo ipucu yok; grafik ipucu kontrastı ${dark ? 'koyu' : 'açık'}', (t) async {
      SharedPreferences.setMockInitialValues({});
      await FirstRunHints.initialize(onboarded: false);
      final db = newTestDatabase();
      addTearDown(db.close);
      for (var i=0; i<2; i++) {
        await db.bodyDao.insertMeasurement(BodyMeasurementsCompanion(
          date: Value(DateTime(2026, 10, 10+i)), weightKg: Value(84.5-i)));
      }
      await t.pumpWidget(ProviderScope(overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(theme: dark ? AppTheme.dark : AppTheme.light,
          locale: const Locale('tr'), localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales, home: const BodyMetricsScreen())));
      for (var i=0; i<8; i++) {
        await t.runAsync(() => Future<void>.delayed(Duration.zero));
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(CoachMark), findsNothing);
      await t.scrollUntilVisible(find.byType(LineChart), 200, scrollable: find.byType(Scrollable).first);
      final chart = t.widget<LineChart>(find.byType(LineChart));
      final data = chart.data.lineTouchData.touchTooltipData;
      final spot = LineBarSpot(chart.data.lineBarsData.first, 0, chart.data.lineBarsData.first.spots.first);
      final bg = data.getTooltipColor(spot);
      final fg = data.getTooltipItems([spot]).first!.textStyle.color!;
      final ratio = (math.max(bg.computeLuminance(), fg.computeLuminance()) + .05) /
          (math.min(bg.computeLuminance(), fg.computeLuminance()) + .05);
      expect(ratio, greaterThanOrEqualTo(4.5));
      expect(data.getTooltipItems([spot]).first!.text, contains('84,5'));
      expect(t.takeException(), isNull);
    });
  }
}
