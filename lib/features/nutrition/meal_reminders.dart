import '../../core/notifications/notification_service.dart';
import '../../data/database/daos/nutrition_dao.dart';
import '../../l10n/app_l10n.dart';
import 'meal_copy_sheet.dart' show mealCopyWindowDays;
import 'meal_reminder_copy.dart';
import 'nutrition_habits.dart';

/// **Öğün hatırlatıcılarını yeniden kurar** (docs/26).
///
/// Tek seferlik bildirimler bugün + 2 gün için kurulur; her kayıt
/// değişiminde, uygulama öne gelince ve ayar değişince hepsi silinip yeniden
/// kurulur. Böylece:
/// - bugün girilen öğünün bildirimi **iptal olur** (kayıt varsa bildirim yok),
/// - saat, kişinin kayıt alışkanlığıyla birlikte kayar,
/// - uygulama 1-2 gün açılmasa da hatırlatma sürer.
///
/// Tekrar eden (günlük) bildirim kullanılmaz: "bugün girildiyse gönderme"
/// koşulu tekrar eden bildirimde kurulamaz.
Future<void> syncMealReminders({
  required NotificationService service,
  required NutritionDao dao,
  required AppL10n l,
  required bool enabled,
  required DateTime weekStart,
  DateTime? now,
}) async {
  for (var i = 0; i < NotificationService.mealReminderSlots; i++) {
    await service.cancel(NotificationService.idMealBase + i);
  }
  if (!enabled) return;

  final t = now ?? DateTime.now();
  final today = DateTime(t.year, t.month, t.day);
  // Alışkanlık penceresi: son 21 gün (hafta içi/sonu farkı karışsın diye 3 hafta).
  final logs = await dao.getLogsInRange(
      DateTime(t.year, t.month, t.day - 21), DateTime(t.year, t.month, t.day + 1));
  final loggedToday = {
    for (final log in logs)
      if (!log.date.isBefore(today)) log.mealType,
  };
  final plan = planMealReminders(
    now: t,
    loggedToday: loggedToday,
    minutes: reminderMinutesFrom(logs),
  );
  // Bugünün kişisel metni için (meal_reminder_copy.dart): haftalık kayıt
  // günleri + öğün başına "her zamanki" içerik.
  final weekDays = {
    for (final log in logs)
      if (!log.date.isBefore(weekStart))
        DateTime(log.date.year, log.date.month, log.date.day),
  }.length;
  final usual = <String, UsualMeal?>{};
  for (final r in plan.where((r) => r.dayOffset == 0)) {
    final days = await dao.getMealDays(r.mealType,
        exclude: today, days: mealCopyWindowDays, today: t);
    usual[r.mealType] = usualMealOf(r.mealType, days);
  }

  final usedToday = <Type>{};
  for (final r in plan) {
    final meal = reminderMeals.indexOf(r.mealType);
    final copy = pickMealReminderCopy(
      mealType: r.mealType,
      at: r.at,
      dayOffset: r.dayOffset,
      facts: (
        usual: usual[r.mealType],
        weekDays: weekDays,
        todayCounted: loggedToday.isNotEmpty,
      ),
      usedToday: usedToday,
    );
    if (r.dayOffset == 0) usedToday.add(copy.body.runtimeType);
    await service.scheduleOnce(
      id: NotificationService.idMealBase + meal * reminderDaysAhead + r.dayOffset,
      when: r.at,
      title: mealReminderTitle(l, r.mealType, copy.title),
      body: mealReminderBody(l, r.mealType, copy.body),
      payload: NotificationService.payloadNutrition,
    );
  }
}

/// Başlık çeşidi → metin ([mealTitleVariants] çeşit).
String mealReminderTitle(AppL10n l, String mealType, int variant) =>
    switch ((mealType, variant)) {
      ('breakfast', 1) => l.notifMealBreakfastTitle2,
      ('breakfast', 2) => l.notifMealBreakfastTitle3,
      ('breakfast', _) => l.notifMealBreakfastTitle,
      ('lunch', 1) => l.notifMealLunchTitle2,
      ('lunch', 2) => l.notifMealLunchTitle3,
      ('lunch', _) => l.notifMealLunchTitle,
      (_, 1) => l.notifMealDinnerTitle2,
      (_, 2) => l.notifMealDinnerTitle3,
      _ => l.notifMealDinnerTitle,
    };

/// Gövde türü → metin.
String mealReminderBody(AppL10n l, String mealType, MealReminderBody body) =>
    switch (body) {
      GenericBody(index: 1) => l.notifMealBody2,
      GenericBody(index: 2) => l.notifMealBody3,
      GenericBody(index: 3) => l.notifMealBody4,
      GenericBody(index: 4) => l.notifMealBody5,
      GenericBody(index: 5) => l.notifMealBody6,
      GenericBody() => l.notifMealBody,
      UsualBody(:final foods) => switch (mealType) {
          'breakfast' => l.notifMealUsualBreakfast(foods),
          'lunch' => l.notifMealUsualLunch(foods),
          _ => l.notifMealUsualDinner(foods),
        },
      WeekProgressBody(done: 0) => l.notifMealWeekStart,
      WeekProgressBody(:final done, :final goal) =>
        l.notifMealWeekProgress(done, goal, done + 1),
      WeekGoalMetBody() => l.notifMealWeekMet,
    };
