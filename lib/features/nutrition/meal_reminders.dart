import '../../core/notifications/notification_service.dart';
import '../../data/database/daos/nutrition_dao.dart';
import '../../l10n/app_l10n.dart';
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
  for (final r in plan) {
    final meal = reminderMeals.indexOf(r.mealType);
    await service.scheduleOnce(
      id: NotificationService.idMealBase + meal * reminderDaysAhead + r.dayOffset,
      when: r.at,
      title: switch (r.mealType) {
        'breakfast' => l.notifMealBreakfastTitle,
        'lunch' => l.notifMealLunchTitle,
        _ => l.notifMealDinnerTitle,
      },
      body: l.notifMealBody,
      payload: NotificationService.payloadNutrition,
    );
  }
}
