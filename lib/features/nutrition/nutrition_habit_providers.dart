import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/prefs/week_start_provider.dart';
import '../../core/utils/current_day.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';
import 'meal_copy_sheet.dart' show mealCopyWindowDays;
import 'nutrition_habits.dart';

/// Bu oturumda "şimdi değil" denen öneriler (`yyyy-m-d|öğün`). Kalıcı
/// değil: ertesi gün ya da sonraki açılışta öneri yeniden gelebilir.
final usualMealDismissedProvider = StateProvider<Set<String>>((ref) => {});

String usualMealDismissKey(DateTime day, String mealType) =>
    '${day.year}-${day.month}-${day.day}|$mealType';

/// Saat kaynağı — testte sahte saat verilir.
final mealSlotClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Şu anki öğün dilimi ([mealForTime]). Bir sonraki dilim sınırına tek
/// zamanlayıcı kurar ([nextMealSlotBoundary], +1 sn pay); sınırda kendini
/// yeniden kurar. Dakikalık tick YOK: değer gün içinde en fazla dört kez
/// değişir ve yalnız değişince izleyenler yeniden kurulur. Arka planda
/// zamanlayıcı bekleyebilir; öne gelişte öneri zaten tablo/gün değişiminde
/// tazelenir, dilim de ilk tetikte yakalanır.
final currentMealSlotProvider = Provider<String>((ref) {
  final t = ref.watch(mealSlotClockProvider)();
  final timer = Timer(
    nextMealSlotBoundary(t).difference(t) + const Duration(seconds: 1),
    ref.invalidateSelf,
  );
  ref.onDispose(timer.cancel);
  return mealForTime(t);
});

/// Şu anki öğün için "her zamanki" öneri (docs/26). O öğün bugün girildiyse
/// ya da kullanıcı bu oturumda geçtiyse `null`. **Reaktif**: öğün eklenince
/// kart kendiliğinden kalkar; öğün dilimi değişince (kahvaltı → öğle)
/// [currentMealSlotProvider] üzerinden yeni dilimin önerisine geçer.
final usualMealProvider = StreamProvider<UsualMeal?>((ref) {
  final db = ref.watch(databaseProvider);
  final dismissed = ref.watch(usualMealDismissedProvider);
  final today = ref.watch(currentDayProvider);
  final meal = ref.watch(currentMealSlotProvider);
  final clock = ref.watch(mealSlotClockProvider);
  return watchTables(db, [db.foodLogs, db.foods], () async {
    final now = clock();
    if (dismissed.contains(usualMealDismissKey(today, meal))) return null;
    final dao = ref.read(nutritionDaoProvider);
    final todays = await dao.getLogsForDate(today);
    if (todays.any((l) => l.mealType == meal)) return null;
    final days = await dao.getMealDays(
      meal,
      exclude: today,
      days: mealCopyWindowDays,
      today: now,
    );
    return usualMealOf(meal, days);
  });
});

/// Bu haftanın kayıt hedefi durumu (haftada [weeklyLogGoalDays] gün).
final logWeekProvider = StreamProvider<LogWeek>((ref) {
  final db = ref.watch(databaseProvider);
  final weekStart = ref.watch(weekStartProvider);
  final day = ref.watch(currentDayProvider);
  return watchTables(db, [db.foodLogs], () async {
    final start = startOfWeek(day, weekStart);
    final end = addDays(start, 7);
    final totals = await ref
        .read(nutritionDaoProvider)
        .getDailyTotalsInRange(start, end);
    return logWeekOf(totals.keys.toSet());
  });
});
