import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/nutrition_dao.dart';
import 'package:fit_pack/features/nutrition/meal_reminder_copy.dart';
import 'package:fit_pack/features/nutrition/meal_reminders.dart';
import 'package:fit_pack/features/nutrition/nutrition_habits.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

/// Öğün hatırlatıcısı metni çeşitli olmalı (Samet, 2026-10-07: "Hep aynı
/// bildirimler çok bayar insanı").
void main() {
  FoodLogWithFood item(int id, String name) => FoodLogWithFood(
        log: FoodLog(
          id: id,
          date: DateTime(2026, 10, 1),
          mealType: 'breakfast',
          foodId: id,
          grams: 100,
          computedKcal: 100,
          computedProtein: 1,
          computedCarb: 0,
          computedFat: 0,
        ),
        food: Food(
          id: id,
          name: name,
          kcalPer100g: 100,
          proteinPer100g: 1,
          carbPer100g: 0,
          fatPer100g: 0,
          source: 'local',
          isCustom: false,
          isRecipe: false,
        ),
      );

  final usual = UsualMeal(
    mealType: 'breakfast',
    items: [item(1, 'Yulaf'), item(2, 'Muz'), item(3, 'Süt')],
    timesLogged: 3,
  );

  MealReminderCopy pick(DateTime at,
          {int dayOffset = 0, MealReminderFacts? facts, String meal = 'breakfast'}) =>
      pickMealReminderCopy(
          mealType: meal, at: at, dayOffset: dayOffset, facts: facts);

  test('art arda günlerde başlık tekrar etmez', () {
    for (var d = 1; d < 20; d++) {
      final a = pick(DateTime(2026, 10, d, 10));
      final b = pick(DateTime(2026, 10, d + 1, 10));
      expect(a.title, isNot(b.title), reason: 'gün $d');
    }
  });

  test('genel havuzun hepsi bir hafta içinde döner', () {
    final seen = <int>{
      for (var d = 1; d <= mealBodyVariants; d++)
        (pick(DateTime(2026, 10, d, 10)).body as GenericBody).index,
    };
    expect(seen, hasLength(mealBodyVariants));
  });

  test('aynı gün yeniden kurulumda metin zıplamaz', () {
    final at = DateTime(2026, 10, 7, 10);
    const facts = (usual: null, weekDays: 2, todayCounted: false);
    final a = pick(at, facts: facts);
    final b = pick(at, facts: facts);
    expect(a.title, b.title);
    expect(a.body.runtimeType, b.body.runtimeType);
  });

  test('bugün kişisel metin günaşırı gelir; ileri günler hep genel', () {
    final facts = (usual: usual, weekDays: 2, todayCounted: false);
    final kinds = <Type>{
      for (var d = 1; d <= 8; d++) pick(DateTime(2026, 10, d, 10), facts: facts).body.runtimeType,
    };
    expect(kinds, containsAll([GenericBody, UsualBody, WeekProgressBody]));
    for (var d = 1; d <= 8; d++) {
      expect(pick(DateTime(2026, 10, d, 10), dayOffset: 1, facts: facts).body,
          isA<GenericBody>());
    }
  });

  test('bugün sayılmışsa haftalık ilerleme yazılmaz; hedef dolduysa kutlanır',
      () {
    for (var d = 1; d <= 8; d++) {
      final at = DateTime(2026, 10, d, 20);
      expect(
          pick(at, meal: 'dinner',
                  facts: (usual: null, weekDays: 3, todayCounted: true))
              .body,
          isNot(isA<WeekProgressBody>()));
      final met = pick(at, meal: 'dinner',
          facts: (usual: null, weekDays: 5, todayCounted: true)).body;
      expect(met, anyOf(isA<GenericBody>(), isA<WeekGoalMetBody>()));
    }
  });

  test('metinler: her zamanki öğün 2 besin + …, haftalık ilerleme', () async {
    final l = await AppL10n.delegate.load(const Locale('tr'));
    expect(mealReminderBody(l, 'breakfast', const UsualBody('Yulaf, Muz +1')),
        'Her zamanki kahvaltın: Yulaf, Muz +1. Tek dokunuşla ekle.');
    expect(mealReminderBody(l, 'lunch', const WeekProgressBody(3, 5)),
        'Bu hafta 3/5 gün kayıt. Bugünü eklersen 4/5.');
    expect(mealReminderBody(l, 'lunch', const WeekProgressBody(0, 5)),
        'Bu haftanın ilk kaydı seni bekliyor.');
    final usualPick = [
      for (var d = 1; d <= 8; d++)
        pick(DateTime(2026, 10, d, 10),
                facts: (usual: usual, weekDays: 5, todayCounted: false))
            .body,
    ].whereType<UsualBody>().first;
    expect(usualPick.foods, 'Yulaf, Muz +1');
  });

  test('haftalık metin aynı gün ikinci öğünde tekrar etmez', () {
    for (var d = 1; d <= 8; d++) {
      final c = pickMealReminderCopy(
        mealType: 'dinner',
        at: DateTime(2026, 10, d, 20),
        dayOffset: 0,
        facts: (usual: null, weekDays: 2, todayCounted: false),
        usedToday: {WeekProgressBody},
      );
      expect(c.body, isA<GenericBody>());
    }
  });
}
