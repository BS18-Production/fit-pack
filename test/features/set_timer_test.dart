import 'package:fit_pack/core/feedback/feedback_service.dart';
import 'package:fit_pack/core/theme/app_colors.dart';
import 'package:fit_pack/features/workout/set_timer.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Süreli set sayacı (docs/27 F3): hedef varsa geri sayar ve sıfırda süreyi
/// yazar; yoksa ileri sayar, durdurunca geçen süreyi yazar.
void main() {
  group('timerReading / timerResult', () {
    test('hedefsiz: ileri sayım, hiç bitmez', () {
      expect(timerReading(null, 75), (shown: 75, finished: false));
      expect(timerResult(null, 75), 75);
    });

    test('hedefli: geri sayım, sıfırda biter ve hedef yazılır', () {
      expect(timerReading(300, 120), (shown: 180, finished: false));
      expect(timerReading(300, 300), (shown: 0, finished: true));
      expect(timerReading(300, 310), (shown: 0, finished: true));
      expect(timerResult(300, 310), 300);
    });

    test('hedef dolmadan durdurulursa geçen süre yazılır', () {
      expect(timerResult(300, 95), 95);
    });

    test('aç-kapa (0 sn) hiçbir şey yazmaz', () {
      expect(timerResult(null, 0), isNull);
      expect(timerResult(300, 0), isNull);
    });
  });

  group('SetTimerButton', () {
    late DateTime saat;
    int? yazilan;
    var titresim = 0;

    Future<void> kur(WidgetTester tester, {int? hedef}) async {
      saat = DateTime(2026, 10, 4, 10);
      yazilan = null;
      titresim = 0;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          feedbackServiceProvider
              .overrideWithValue(_CountingFeedback(() => titresim++)),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: AppColors.lightScheme,
            extensions: [AppColors.lightSemantic],
          ),
          locale: const Locale('tr'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 48,
                child: SetTimerButton(
                  targetSec: hedef,
                  onDone: (s) => yazilan = s,
                  now: () => saat,
                ),
              ),
            ),
          ),
        ),
      ));
    }

    Future<void> ilerlet(WidgetTester tester, int sn) async {
      saat = saat.add(Duration(seconds: sn));
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('hedefsiz: ileri sayar, durdurunca geçen süre yazılır',
        (tester) async {
      await kur(tester);
      await tester.tap(find.byKey(const ValueKey('set-timer-start')));
      await tester.pump();
      await ilerlet(tester, 42);
      expect(find.text('0:42'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('set-timer-stop')));
      await tester.pump();
      expect(yazilan, 42);
      expect(find.byKey(const ValueKey('set-timer-start')), findsOneWidget);
    });

    testWidgets('hedef 5:00: geri sayar, sıfırda titreşir, durur, 300 yazar',
        (tester) async {
      await kur(tester, hedef: 300);
      await tester.tap(find.byKey(const ValueKey('set-timer-start')));
      await tester.pump();
      await ilerlet(tester, 60);
      expect(find.text('4:00'), findsOneWidget);
      expect(yazilan, isNull);

      await ilerlet(tester, 240);
      expect(yazilan, 300);
      expect(titresim, 1);
      expect(find.byKey(const ValueKey('set-timer-start')), findsOneWidget);
    });

    testWidgets('arka planda kalınan süre de sayılır (tık kaçsa bile)',
        (tester) async {
      await kur(tester, hedef: 300);
      await tester.tap(find.byKey(const ValueKey('set-timer-start')));
      await tester.pump();
      // Tek tıkta 10 dakika geçmiş gibi — dönüşte doğrudan biter.
      await ilerlet(tester, 600);
      expect(yazilan, 300);
    });
  });
}

class _CountingFeedback extends FeedbackService {
  final VoidCallback onRestDone;
  _CountingFeedback(this.onRestDone);

  @override
  void restDone() => onRestDone();
}
