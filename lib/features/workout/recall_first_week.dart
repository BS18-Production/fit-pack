import 'package:shared_preferences/shared_preferences.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/utils/current_day.dart';
import '../../data/database/daos/workout_dao.dart';
import '../../l10n/app_l10n.dart';
import '../home/first_week.dart' show calendarDaysBetween, firstWeekWindowDays;
import 'recall_reminders.dart' show shiftOutOfQuietHours;
import 'routine_providers.dart' show estimateRoutineMinutes, rotationNext;

/// **İlk hafta hatırlatması** (docs/51 ikinci tur, docs/49 ile bağ).
///
/// Hesabın ilk [firstWeekWindowDays] gününde rehberin ilk adımı (ilk
/// antrenman) bitmemişse **tek** hatırlatma: hesabın 2. günü akşamı
/// [firstWeekHour]'da. Ömür boyu en fazla bir kez; zamanı kaçtıysa geç
/// gönderilmez. Geri çağırma sınırlarına (günde/haftada) sayılmaz — tek
/// seferlik — ama sessiz saate düşmez.
const firstWeekHour = 19;

/// Kurulacak an — saf karar, sahte saatle test edilir. `null` = kurma.
///
/// - Hesap tarihi bilinmiyorsa, antrenman varsa ya da daha önce gönderildiyse
///   yok.
/// - An = hesabın açıldığı takvim günü + 1 gün, [firstWeekHour]:00
///   ([addDays] — yaz saati gününde de 19:00).
/// - An geçtiyse yok (geç gönderilmez); ilk hafta penceresinin dışındaysa yok.
DateTime? planFirstWeek({
  required DateTime now,
  required DateTime? accountStart,
  required bool hasWorkout,
  required bool alreadySent,
}) {
  if (accountStart == null || hasWorkout || alreadySent) return null;
  final start = dayStart(accountStart.toLocal());
  final day = addDays(start, 1);
  final at = shiftOutOfQuietHours(
      DateTime(day.year, day.month, day.day, firstWeekHour));
  if (!at.isAfter(now)) return null;
  if (calendarDaysBetween(start, at) >= firstWeekWindowDays) return null;
  return at;
}

/// Tek seferlik bayrak: takvime konan an. Zamanı geçtiyse "gönderildi"
/// sayılır (arada antrenman girilseydi yeniden kurulum onu iptal ederdi).
/// Hesaba bağlı — hesap değişiminde [clear].
class FirstWeekReminder {
  static const _kAt = 'recall_first_week_at';

  static Future<DateTime?> load() async {
    final ms = (await SharedPreferences.getInstance()).getInt(_kAt);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> save(DateTime? at) async {
    final p = await SharedPreferences.getInstance();
    at == null
        ? await p.remove(_kAt)
        : await p.setInt(_kAt, at.millisecondsSinceEpoch);
  }

  static Future<void> clear() => save(null);
}

/// **İlk hafta hatırlatmasını yeniden kurar.** Her çağrıda [idFirstWeek]
/// silinir; gönderilmemiş (gelecekteki) kayıt da silinir, [enabled] ise
/// plan baştan kurulur. İzin İSTENMEZ: [enabled] = antrenman hatırlatıcısı
/// açık (izin daha önce alınmış).
Future<void> syncFirstWeekReminder({
  required NotificationService service,
  required WorkoutDao dao,
  required AppL10n l,
  required bool enabled,
  required DateTime? accountCreated,
  DateTime? now,
}) async {
  await service.cancel(NotificationService.idFirstWeek);
  final t = now ?? DateTime.now();
  final stored = await FirstWeekReminder.load();
  final sent = stored != null && !stored.isAfter(t);
  if (stored != null && !sent) await FirstWeekReminder.save(null);
  if (!enabled) return;

  final at = planFirstWeek(
    now: t,
    accountStart: accountCreated,
    hasWorkout: (await dao.getRecentSessions(1)).isNotEmpty,
    alreadySent: sent,
  );
  if (at == null) return;

  final routines = await dao.getActiveRoutines();
  final r = rotationNext(routines, await dao.getLastSessionRoutineId());
  final mins = r == null
      ? null
      : estimateRoutineMinutes([
          for (final e in await dao.getRoutineExercises(r.id))
            e.routineExercise,
        ]);
  await service.scheduleOnce(
    id: NotificationService.idFirstWeek,
    when: at,
    title: l.notifFirstWeekTitle,
    body: firstWeekBody(l, r?.name, mins),
    // Dokununca Ana Sayfa: "Bugün" kartı ve ilk hafta rehberi orada.
    payload: NotificationService.payloadRecall,
  );
  await FirstWeekReminder.save(at);
}

String firstWeekBody(AppL10n l, String? routine, int? minutes) =>
    switch ((routine, minutes)) {
      (final r?, final m?) => l.notifFirstWeekBodyRoutine(r, m),
      (final r?, null) => l.notifFirstWeekBodyRoutineOnly(r),
      _ => l.notifFirstWeekBody,
    };
