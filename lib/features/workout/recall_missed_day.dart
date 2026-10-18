import '../../core/notifications/notification_service.dart';
import '../../core/utils/current_day.dart';
import '../../data/database/app_database.dart';
import '../../l10n/app_l10n.dart';
import 'recall_reminders.dart';

/// **Geri çağırma — "planlı gün kaçtı"** (docs/51 durum 1).
///
/// Rutinler haftanın günlerine bağlıysa, planlı günün akşamı o gün antrenman
/// yoksa tek bildirim: "Bugün Bacak günüydü — yarın da olur." "Ara uzadı"
/// ile aynı desen: bugün + 2 gün için tek seferlik kurulur, antrenman
/// girilince yeniden kurulumda düşer. Sınırları (günde/haftada) ve
/// susturmayı "ara uzadı" ile **ortak** paylaşır ([mergeRecallPlans]).
const missedDayDefaultMinute = 20 * 60; // akşam 20:00
const missedDayLateUsualMinute = 18 * 60 + 30; // olağan saat bundan geçse…
const missedDayAfterUsualMinutes = 90; // …olağan + 90 dk
const missedDayLatestMinute = 21 * 60 + 30; // en geç 21:30 (sessiz saat 22)

/// Akşam bildiriminin saati (gün içi dakika): varsayılan 20:00; olağan
/// antrenman saati 18:30'dan geçse olağan + 90 dk, en geç 21:30.
int missedDayMinute(int? usualMinute) {
  if (usualMinute == null || usualMinute <= missedDayLateUsualMinute) {
    return missedDayDefaultMinute;
  }
  final m = usualMinute + missedDayAfterUsualMinutes;
  return m > missedDayLatestMinute ? missedDayLatestMinute : m;
}

/// Kurulacak "planlı gün kaçtı" anları — saf karar, sahte saatle test edilir.
///
/// - Güne bağlı rutin yoksa boş (o kullanıcıda "ara uzadı" çalışır).
/// - Hiç antrenman girmemiş hesapta boş: yeni kullanıcıya ilk hafta
///   hatırlatması bakar (docs/51 "İlk hafta").
/// - Bugün + 2 gün; günün planlı rutini (aynı güne birden çok bağlıysa
///   ilki), o gün antrenman yoksa ([sessionDays]) akşam saatinde.
/// - Geçmiş ve [mutedUntil] öncesi anlar atlanır.
List<(DateTime, Routine)> planMissedDay({
  required DateTime now,
  required List<Routine> routines,
  required Set<DateTime> sessionDays,
  required bool hasWorkouts,
  int? usualMinute,
  DateTime? mutedUntil,
}) {
  if (!hasWorkouts) return const [];
  final scheduled = routines.where((r) => r.scheduledWeekday != null).toList();
  if (scheduled.isEmpty) return const [];
  final minute = missedDayMinute(usualMinute);
  final today = dayStart(now);
  final out = <(DateTime, Routine)>[];
  for (var i = 0; i < NotificationService.missedDaySlots; i++) {
    final day = addDays(today, i);
    if (sessionDays.contains(day)) continue;
    final r = scheduled.where((r) => r.scheduledWeekday == day.weekday);
    if (r.isEmpty) continue;
    final t = DateTime(day.year, day.month, day.day, minute ~/ 60, minute % 60);
    if (!t.isAfter(now)) continue;
    if (mutedUntil != null && t.isBefore(mutedUntil)) continue;
    out.add((t, r.first));
  }
  return out;
}

/// İki türü ortak sınırla birleştirir: önce "planlı gün kaçtı" (daha
/// özgül), sonra "ara uzadı" anları zaman sırasıyla eklenir. Bir an ancak
/// günde [recallMaxPerDay] ve geçmişte gönderilenlerle ([sent]) birlikte
/// herhangi 7 günde [recallMaxPerWeek] aşılmıyorsa girer — sonradan
/// eklenen erken bir an, önceden kabul edilmiş geç bir anın haftasını
/// taşırmasın diye bütün pencereler denetlenir.
({List<DateTime> missed, List<DateTime> gap}) mergeRecallPlans({
  required List<DateTime> missed,
  required List<DateTime> gap,
  Iterable<DateTime> sent = const [],
}) {
  final accepted = <DateTime>[];
  bool fits(DateTime x) {
    final next = [...accepted, x];
    if (next.where((a) => dayStart(a) == dayStart(x)).length >
        recallMaxPerDay) {
      return false;
    }
    final all = [...sent, ...next];
    for (final end in next) {
      final from = addDays(end, -7);
      final n = all.where((s) => s.isAfter(from) && !s.isAfter(end)).length;
      if (n > recallMaxPerWeek) return false;
    }
    return true;
  }

  final keptMissed = <DateTime>[];
  for (final m in [...missed]..sort()) {
    if (accepted.contains(m) || !fits(m)) continue;
    accepted.add(m);
    keptMissed.add(m);
  }
  final keptGap = <DateTime>[];
  for (final g in [...gap]..sort()) {
    if (accepted.contains(g) || !fits(g)) continue;
    accepted.add(g);
    keptGap.add(g);
  }
  return (missed: keptMissed, gap: keptGap);
}

/// "Planlı gün kaçtı" bildirimini kurar ([NotificationService.idMissedDayBase]
/// yuvaları; iptal [syncRecallReminders]'da). Dokunma "ara uzadı" ile aynı
/// yükü taşır → aynı tepki sayacı.
Future<void> scheduleMissedDay({
  required NotificationService service,
  required AppL10n l,
  required List<(DateTime, Routine)> plan,
  required List<DateTime> keep,
}) async {
  var i = 0;
  for (final (at, r) in plan) {
    if (!keep.contains(at)) continue;
    await service.scheduleOnce(
      id: NotificationService.idMissedDayBase + i++,
      when: at,
      title: l.notifMissedTitle(r.name),
      body: l.notifMissedBody,
      payload: NotificationService.payloadRecall,
    );
  }
}
