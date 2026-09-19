import 'dart:io';

import 'package:fit_pack/core/theme/app_colors.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/data/services/photo_storage.dart';
import 'package:fit_pack/features/progress_photos/progress_photos_providers.dart';
import 'package:fit_pack/features/progress_photos/progress_photos_screen.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

/// İlerleme fotoğrafları galerisi (docs/19 §2). Gerçek bellek-içi DB, geçici
/// dizin; görsel içerik önemli değil — ölçülen akış ve metinler.
void main() {
  late AppDatabase db;
  late Directory tmp;
  late PhotoStorage store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = newTestDatabase();
    tmp = Directory.systemTemp.createTempSync('fitpack_pp_ui');
    store = PhotoStorage(() async => Directory(p.join(tmp.path, 'pp')));
  });
  tearDown(() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  Future<void> ekle(DateTime d, String angle) async {
    final src = File(p.join(tmp.path, 'src.jpg'))..writeAsBytesSync([0]);
    await ProgressPhotoActions(db.bodyDao, store).add(src, d, angle);
  }

  Future<void> ac(WidgetTester tester) async {
    // Telefon boyutu: varsayılan test ekranı (800×600) ikinci gün grubunu
    // görünmez bırakıyor ve tembel liste onu hiç kurmuyor.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        photoStorageProvider.overrideWithValue(store),
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: AppColors.lightScheme,
          extensions: [AppColors.lightSemantic],
        ),
        locale: const Locale('tr'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: const ProgressPhotosScreen(),
      ),
    ));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('boş galeri: "yalnız bu cihazda" notu + ekleme çağrısı',
      (tester) async {
    await ac(tester);
    expect(find.textContaining('yalnız bu cihazda saklanır'), findsOneWidget,
        reason: 'kullanıcı fotoğrafların yedeklendiğini sanmamalı');
    expect(find.text('Henüz fotoğraf yok'), findsOneWidget);
    expect(find.text('Fotoğraf ekle'), findsWidgets);
  });

  testWidgets('açı süzgeci yalnız o açıyı gösterir', (tester) async {
    await tester.runAsync(() async {
      await ekle(DateTime(2026, 9, 19, 8), 'front');
      await ekle(DateTime(2026, 9, 19, 8, 1), 'side');
    });
    await ac(tester);

    // Izgarada iki kare, köşe etiketleriyle.
    expect(find.text('Ön'), findsNWidgets(2), reason: 'çip + kare etiketi');
    expect(find.text('Yan'), findsNWidgets(2));

    await tester.tap(find.widgetWithText(ChoiceChip, 'Yan'));
    await tester.pump();
    expect(find.text('Ön'), findsOneWidget, reason: 'yalnız çip kaldı');
    expect(find.text('Yan'), findsNWidgets(2));
  });

  testWidgets('karşılaştırma: iki fotoğraf seçilince düğme çıkar',
      (tester) async {
    await tester.runAsync(() async {
      await ekle(DateTime(2026, 9, 1, 8), 'front');
      await ekle(DateTime(2026, 9, 19, 8), 'front');
    });
    await ac(tester);

    await tester.tap(find.byTooltip('Karşılaştır'));
    await tester.pump();
    expect(find.text('0/2 seçildi'), findsOneWidget);
    expect(find.widgetWithText(FloatingActionButton, 'Karşılaştır'),
        findsNothing);

    final kareler = find.byWidgetPredicate(
        (w) => w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('photo-'));
    expect(kareler, findsNWidgets(2));
    await tester.tap(kareler.at(0));
    await tester.pump();
    await tester.tap(kareler.at(1));
    await tester.pump();

    expect(find.text('2/2 seçildi'), findsOneWidget);
    expect(find.widgetWithText(FloatingActionButton, 'Karşılaştır'),
        findsOneWidget);
  });
}
