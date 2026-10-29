import 'dart:async';
import 'dart:convert';

import 'package:fit_pack/features/home/providers/weekly_goal_provider.dart';
import 'package:fit_pack/features/onboarding/program_recommendation.dart';
import 'package:fit_pack/features/onboarding/training_setup.dart';
import 'package:fit_pack/features/onboarding/training_setup_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TrainingSetupProfile catalog({
    int days = 3,
    int? minutes,
    TrainingExperience experience = TrainingExperience.beginner,
  }) => TrainingSetupProfile(
    planSource: TrainingPlanSource.catalog,
    experience: experience,
    exactDays: days,
    sessionBudgetMinutes: minutes,
  );

  test('kesin seçim korunur; katalog farkı açık karardır', () {
    final two = catalog(days: 2);
    expect(two.exactDays, 2);
    expect(two.recommendedProgram!.key, 'fullbody_beginner');
    expect(two.recommendedProgram!.daysPerWeek, 3);
    expect(two.catalogFrequencyMatches, isFalse);
    final six = catalog(days: 6);
    expect(six.exactDays, 6);
    expect(six.recommendedProgram!.daysPerWeek, 4);
    expect(six.catalogFrequencyMatches, isFalse);
  });

  test('deneyim gerçek öneriyi değiştirir, kendi rotasında öneri yok', () {
    expect(catalog().recommendedProgram!.key, 'fullbody_beginner');
    expect(
      catalog(experience: TrainingExperience.long).recommendedProgram!.key,
      'fullbody_advanced',
    );
    final own = TrainingSetupProfile(
      planSource: TrainingPlanSource.own,
      experience: null,
      exactDays: 2,
      sessionBudgetMinutes: 30,
    );
    expect(own.recommendedProgram, isNull);
    expect(own.longestRoutineMinutes, isNull);
    expect(own.exceedsTimeBudget, isFalse);
  });

  test('süre sınırı katalog içeriğini değiştirmeden uyumsuzluk verir', () {
    final plan = catalog(
      days: 6,
      minutes: 30,
      experience: TrainingExperience.long,
    );
    expect(plan.longestRoutineMinutes, greaterThan(30));
    expect(plan.exceedsTimeBudget, isTrue);
    final unbounded = catalog(days: 6, experience: TrainingExperience.long);
    expect(plan.recommendedProgram, same(unbounded.recommendedProgram));
    expect(plan.estimatedRoutineMinutes, unbounded.estimatedRoutineMinutes);
    expect(unbounded.exceedsTimeBudget, isFalse);
  });

  test('sürümlü JSON tam döner; bozuk veri varsayılana dönmez', () {
    final initial = catalog(
      days: 4,
      minutes: 45,
      experience: TrainingExperience.some,
    );
    final read = TrainingSetupProfile.fromJson(
      jsonDecode(jsonEncode(initial.toJson())) as Map<String, dynamic>,
    );
    expect(read.toJson(), initial.toJson());
    expect(read.recommendedProgram!.key, 'upperlower_intermediate');
    for (final invalid in [
      {...initial.toJson(), 'version': 2},
      {...initial.toJson(), 'exactDays': 0},
      {...initial.toJson(), 'experience': null},
      {...initial.toJson(), 'unexpected': 'text'},
    ]) {
      expect(
        () => TrainingSetupProfile.fromJson(invalid),
        throwsFormatException,
      );
    }
  });

  test('hesap değişimi ve yeniden yüklemede tercih sızmaz', () async {
    SharedPreferences.setMockInitialValues({});
    final account = StateProvider<String?>((ref) => 'a');
    final container = ProviderContainer(
      overrides: [
        weeklyGoalAccountProvider.overrideWith((ref) => ref.watch(account)),
      ],
    );
    addTearDown(container.dispose);
    expect(await container.read(trainingSetupProfileProvider.future), isNull);
    await container.read(trainingSetupProfileProvider.notifier).save(catalog());
    container.read(account.notifier).state = 'b';
    expect(await container.read(trainingSetupProfileProvider.future), isNull);
    container.read(account.notifier).state = 'a';
    expect(
      (await container.read(trainingSetupProfileProvider.future))!.exactDays,
      3,
    );
    container.invalidate(trainingSetupProfileProvider);
    expect(
      (await container.read(trainingSetupProfileProvider.future))!.experience,
      TrainingExperience.beginner,
    );
    container.read(account.notifier).state = null;
    expect(await container.read(trainingSetupProfileProvider.future), isNull);
    await expectLater(
      container.read(trainingSetupProfileProvider.notifier).save(catalog()),
      throwsStateError,
    );
  });

  test(
    'hesap değişen bekleyen yazma yeni hesaba veya eski hesaba yazmaz',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final pending = Completer<SharedPreferences>();
      final account = StateProvider<String?>((ref) => 'a');
      final container = ProviderContainer(
        overrides: [
          weeklyGoalAccountProvider.overrideWith((ref) => ref.watch(account)),
          trainingSetupPreferencesProvider.overrideWith(
            (ref) => pending.future,
          ),
        ],
      );
      addTearDown(container.dispose);
      final write = container
          .read(trainingSetupProfileProvider.notifier)
          .save(catalog());
      container.read(account.notifier).state = 'b';
      pending.complete(prefs);
      await expectLater(write, throwsStateError);
      expect(prefs.containsKey('training_setup_v1_a'), isFalse);
      expect(prefs.containsKey('training_setup_v1_b'), isFalse);
      expect(await container.read(trainingSetupProfileProvider.future), isNull);
    },
  );

  test('başarısız yazma başarı durumu yayınlamaz', () async {
    final container = ProviderContainer(
      overrides: [
        weeklyGoalAccountProvider.overrideWithValue('a'),
        trainingSetupPreferencesProvider.overrideWith(
          (ref) async => _RejectingPreferences(),
        ),
      ],
    );
    addTearDown(container.dispose);
    expect(await container.read(trainingSetupProfileProvider.future), isNull);
    await expectLater(
      container.read(trainingSetupProfileProvider.notifier).save(catalog()),
      throwsStateError,
    );
    expect(await container.read(trainingSetupProfileProvider.future), isNull);
  });

  test('bozuk kayıtlı JSON hata taşır', () async {
    SharedPreferences.setMockInitialValues({'training_setup_v1_a': '{broken'});
    final container = ProviderContainer(
      overrides: [weeklyGoalAccountProvider.overrideWithValue('a')],
    );
    addTearDown(container.dispose);
    await expectLater(
      container.read(trainingSetupProfileProvider.future),
      throwsFormatException,
    );
  });
}

class _RejectingPreferences extends Fake implements SharedPreferences {
  @override
  String? getString(String key) => null;

  @override
  Future<bool> setString(String key, String value) async => false;
}
