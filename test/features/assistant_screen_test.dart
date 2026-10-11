import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fit_pack/core/theme/app_theme.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/assistant/assistant_calculator.dart';
import 'package:fit_pack/features/assistant/assistant_contract.dart';
import 'package:fit_pack/features/assistant/assistant_providers.dart';
import 'package:fit_pack/features/assistant/assistant_routing.dart';
import 'package:fit_pack/features/assistant/assistant_screen.dart';
import 'package:fit_pack/features/assistant/assistant_answer_card.dart';
import 'package:fit_pack/features/assistant/assistant_selection_sheet.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:fit_pack/shared/widgets/glass.dart';
import '../helpers/design_fixture.dart';
import '../helpers/test_database.dart';

void main() {
  for (final scenario in [
    (lang: 'tr', dark: true, width: 393.0, scale: 1.0),
    (lang: 'en', dark: false, width: 393.0, scale: 1.0),
    (lang: 'tr', dark: true, width: 320.0, scale: 1.3),
    (lang: 'en', dark: true, width: 320.0, scale: 1.6),
  ]) {
    testWidgets(
      'Asistan ${scenario.lang} ${scenario.width} ${scenario.scale}: ekran, tüm sonuçlar, seçim',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        GoogleFonts.config.allowRuntimeFetching = false;
        await initializeDateFormatting(scenario.lang);
        final db = newTestDatabase();
        await seedDesignFixture(db);
        final sessions = await db.workoutDao.getAllSessions();
        final now = DateTime.now();
        final data = AssistantData(
          now: now,
          sessions: sessions,
          sets: await db.workoutDao.getSetsForSessions(
            sessions.map((s) => s.id).toList(),
          ),
          exercises: {
            for (final e in await db.workoutDao.getAllExercises()) e.id: e,
          },
          points: await db.workoutDao.getWeightedSetPointsInRange(
            DateTime(1970),
            DateTime(2100),
            onlyComplete: true,
          ),
          logs: await db.nutritionDao.getLogsInRange(
            DateTime(1970),
            DateTime(2100),
          ),
          measurements: await db.bodyDao.getAllMeasurements(),
          profile: await db.userProfileDao.getProfile(),
        );
        tester.view.physicalSize = Size(scenario.width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          await db.close();
        });
        Future<void> show(Widget child) async {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                databaseProvider.overrideWithValue(db),
                assistantDataProvider.overrideWith((ref) => Stream.value(data)),
                assistantRouterProvider.overrideWith(
                  (ref) async => FrozenAssistantRouter(
                    jsonDecode(
                      File(
                        'assets/data/assistant_router_v2.json',
                      ).readAsStringSync(),
                    ),
                  ),
                ),
              ],
              child: MaterialApp(
                locale: Locale(scenario.lang),
                localizationsDelegates: AppL10n.localizationsDelegates,
                supportedLocales: AppL10n.supportedLocales,
                theme: scenario.dark ? AppTheme.dark : AppTheme.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scenario.scale)),
                  child: child!,
                ),
                home: GlassBackground(child: child),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        await show(const AssistantScreen());
        await tester.scrollUntilVisible(
          find.text(scenario.lang == 'tr' ? 'Tüm sorular' : 'All questions').hitTestable(),
          300,
          scrollable: find
              .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(
          find
              .text(scenario.lang == 'tr' ? 'Tüm sorular' : 'All questions')
              .hitTestable(),
        );
        await tester.pumpAndSettle();
        for (final q in AssistantQuery.values.where(
          (q) => q != AssistantQuery.outOfScope,
        )) {
          final selection = AssistantSelection(
            query: q,
            period: q.periods.first,
            exerciseId: data.exercises.keys.first,
          );
          await show(
            Scaffold(
              body: SingleChildScrollView(
                child: AssistantAnswerCard(
                  answer: calculateAssistant(selection, data),
                  onChange: () {},
                ),
              ),
            ),
          );
          await show(
            Scaffold(
              body: AssistantSelectionSheet(initial: selection, data: data),
            ),
          );
        }
      },
    );
  }
}
