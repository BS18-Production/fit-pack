import 'package:fit_pack/core/theme/app_colors.dart';
import 'package:fit_pack/features/workout/rpe_picker_sheet.dart';
import 'package:fit_pack/features/workout/rpe_scale.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// RPE seçicisi (docs/27 F4): ölçek mantığı + panel akışı (seç / temizle /
/// vazgeç üç ayrı sonuç).
void main() {
  group('rpe_scale', () {
    test('seçenekler 6–10 yarım adım, sıralı', () {
      expect(rpeChoices, [6, 7, 7.5, 8, 8.5, 9, 9.5, 10]);
    });

    test('kalan tekrar: tam sayı tek değer, yarım adım aralık, 6 ve altı 4+',
        () {
      expect(repsInReserve(10), (min: 0, max: 0));
      expect(repsInReserve(9), (min: 1, max: 1));
      expect(repsInReserve(8.5), (min: 1, max: 2));
      expect(repsInReserve(7), (min: 3, max: 3));
      expect(repsInReserve(6), (min: 4, max: null));
      expect(repsInReserve(5), (min: 4, max: null)); // eski kayıt
    });

    test('efor bandı sınırları', () {
      expect(rpeEffort(10), RpeEffort.max);
      expect(rpeEffort(9.5), RpeEffort.extremelyHard);
      expect(rpeEffort(9), RpeEffort.extremelyHard);
      expect(rpeEffort(8.5), RpeEffort.veryHard);
      expect(rpeEffort(7.5), RpeEffort.vigorous);
      expect(rpeEffort(6), RpeEffort.moderate);
      expect(rpeEffort(4), RpeEffort.light);
    });

    test('biçim: gereksiz .0 yok, ayırıcı dile göre', () {
      expect(formatRpe(8), '8');
      expect(formatRpe(7.5), '7.5');
      expect(formatRpe(7.5, decimalSep: ','), '7,5');
    });
  });

  group('panel', () {
    ({double? rpe})? sonuc;
    var kapandi = false;

    Future<void> ac(WidgetTester tester, {double? initial}) async {
      sonuc = null;
      kapandi = false;
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          colorScheme: AppColors.lightScheme,
          extensions: [AppColors.lightSemantic],
        ),
        locale: const Locale('tr'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  sonuc = await showRpePicker(context,
                      setNumber: 2, initial: initial, setSummary: '80 kg × 8');
                  kapandi = true;
                },
                child: const Text('panel'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('panel'));
      await tester.pumpAndSettle();
    }

    testWidgets('boş açılır; seçince etiket + kalan tekrar; Tamam değeri döner',
        (tester) async {
      await ac(tester);
      expect(find.text('Set 2 RPE'), findsOneWidget);
      expect(find.text('80 kg × 8'), findsOneWidget);
      expect(find.text('RPE seç'), findsOneWidget);
      expect(find.text('Temizle'), findsNothing); // önceki değer yok

      await tester.tap(find.byKey(const ValueKey('rpe-choice-8.5')));
      await tester.pumpAndSettle();
      expect(find.text('Çok zor'), findsOneWidget);
      expect(find.text('1–2 tekrar daha yapabilirdin'), findsOneWidget);

      await tester.tap(find.text('Tamam'));
      await tester.pumpAndSettle();
      expect(kapandi, isTrue);
      expect(sonuc, (rpe: 8.5));
    });

    testWidgets('RPE 10: tekrar kalmadı metni', (tester) async {
      await ac(tester);
      await tester.tap(find.byKey(const ValueKey('rpe-choice-10.0')));
      await tester.pumpAndSettle();
      expect(find.text('Maksimum efor'), findsOneWidget);
      expect(find.text('Bir tekrar daha yapamazdın'), findsOneWidget);
    });

    testWidgets('önceki değer varken Temizle → (rpe: null)', (tester) async {
      await ac(tester, initial: 7);
      expect(find.text('3 tekrar daha yapabilirdin'), findsOneWidget);
      await tester.tap(find.text('Temizle'));
      await tester.pumpAndSettle();
      expect(kapandi, isTrue);
      expect(sonuc, isNotNull);
      expect(sonuc!.rpe, isNull);
    });

    testWidgets('dışarı dokununca vazgeçilir → null (değer değişmez)',
        (tester) async {
      await ac(tester, initial: 7);
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(kapandi, isTrue);
      expect(sonuc, isNull);
    });

    testWidgets('eski kayıttaki 5 korunur ve gösterilir', (tester) async {
      await ac(tester, initial: 5);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Hafif efor'), findsOneWidget);
      expect(find.text('4+ tekrar daha yapabilirdin'), findsOneWidget);
    });
  });
}
