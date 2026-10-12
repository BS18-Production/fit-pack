import 'dart:io';

import 'package:fit_pack/core/feedback/rest_sound.dart';
import 'package:fit_pack/core/notifications/notification_prefs.dart';
import 'package:fit_pack/features/nutrition/today_meals_card.dart';
import 'package:fit_pack/features/workout/workout_draft.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// docs/45 — mola sesi seçimi, taslakta dinlenme, Öğün günlüğü kartı.
void main() {
  group('mola sesi', () {
    test('bilinmeyen/eski kimlik varsayılana düşer', () {
      expect(RestSound.fromId(null), RestSound.digitalBeep);
      expect(RestSound.fromId('silinmis_ses'), RestSound.digitalBeep);
      expect(RestSound.fromId('boxing_bell'), RestSound.boxingBell);
    });

    test('her sesin iki dosyası da varlıklarda', () {
      for (final s in RestSound.values) {
        expect(File(s.countdownAsset).existsSync(), isTrue, reason: s.id);
        expect(File(s.endAsset).existsSync(), isTrue, reason: s.id);
        expect(s.countdownSource, 'sounds/rest_${s.id}.m4a');
      }
    });

    test('tercih kalıcı: yeniden açılışta aynı ses', () async {
      SharedPreferences.setMockInitialValues({});
      final c1 = ProviderContainer();
      c1.read(notificationPrefsProvider);
      await Future<void>.delayed(Duration.zero);
      await c1.read(notificationPrefsProvider.notifier).update(
          c1.read(notificationPrefsProvider).copyWith(restSound: RestSound.softChime));
      c1.dispose();

      final c2 = ProviderContainer();
      c2.read(notificationPrefsProvider);
      await Future<void>.delayed(Duration.zero);
      expect(c2.read(notificationPrefsProvider).restSound, RestSound.softChime);
      c2.dispose();
    });
  });

  group('taslakta dinlenme', () {
    test('bitiş anı JSON gidiş-dönüşünde korunur; eski taslakta yok', () {
      final d = WorkoutDraft(
        title: 'İtme',
        routineId: 1,
        startedAtMs: 1000,
        sessionDateMs: 0,
        restStartedAtMs: 5000,
        restEndsAtMs: 95000,
        exercises: [],
      );
      final back = WorkoutDraft.decode(d.encode())!;
      expect(back.restEndsAt, DateTime.fromMillisecondsSinceEpoch(95000));
      expect(back.restStartedAt, DateTime.fromMillisecondsSinceEpoch(5000));

      final old = WorkoutDraft.decode(
          '{"title":"x","startedAtMs":1,"sessionDateMs":0,"exercises":[]}')!;
      expect(old.restEndsAt, isNull);
    });
  });

  test('sıradaki öğün saate göre', () {
    expect(suggestedMeal(DateTime(2026, 10, 11, 8)), 'breakfast');
    expect(suggestedMeal(DateTime(2026, 10, 11, 13)), 'lunch');
    expect(suggestedMeal(DateTime(2026, 10, 11, 19)), 'dinner');
    expect(suggestedMeal(DateTime(2026, 10, 11, 23)), 'snack');
  });
}
