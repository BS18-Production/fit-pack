import 'dart:io';
import 'dart:ui' as ui;

import 'package:fit_pack/core/theme/app_theme.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/nutrition/add_food_sheet.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final language in ['en', 'tr']) {
    testWidgets('Long portion label fits narrow large text ($language)', (
      t,
    ) async {
      final key = GlobalKey();
      final unit = language == 'tr'
          ? 'Büyük ev yapımı porsiyon'
          : 'Large homemade portion';
      const grams = 180.0;
      double? saved;
      t.view.physicalSize = const Size(640, 2000);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: language == 'tr' ? AppTheme.dark : AppTheme.light,
            locale: Locale(language),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.8)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: FoodAmountPanel(
                  food: Food(
                    id: 1,
                    name: 'Test yogurt',
                    kcalPer100g: 65,
                    proteinPer100g: 4,
                    carbPer100g: 5,
                    fatPer100g: 3,
                    source: 'local',
                    isCustom: false,
                    isRecipe: false,
                    defaultPortionGrams: grams,
                    unitLabel: unit,
                  ),
                  initial: (grams: grams, units: 1, unit: unit),
                  addLabel: language == 'tr' ? 'Güncelle' : 'Update',
                  saving: false,
                  onClose: () {},
                  onAdd: (amount) => saved = amount,
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      // Render/layout exceptions are failures; none are caught or logged away.
      expect(t.takeException(), isNull);
      expect(t.getSize(find.byType(EditableText)).width, greaterThan(60));
      await t.tap(find.widgetWithText(ChoiceChip, '2'));
      await t.pumpAndSettle();
      final save = find.byType(FilledButton);
      await t.ensureVisible(save);
      await t.tap(save);
      expect(saved, 360);
      expect(t.takeException(), isNull);
      final directory = Platform.environment['FITPACK_CAPTURE_DIR'];
      if (directory != null) {
        await t.runAsync(() async {
          final rendered =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final bytes = await rendered.toByteData(
            format: ui.ImageByteFormat.png,
          );
          await Directory(directory).create(recursive: true);
          await File(
            '$directory/nutrition-long-portion-$language.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          rendered.dispose();
        });
      }
    });
  }
}
