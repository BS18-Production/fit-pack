import 'package:shared_preferences/shared_preferences.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/utils/current_day.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/workout_dao.dart';
import '../../l10n/app_l10n.dart';
import 'routine_providers.dart' show estimateRoutineMinutes, rotationNext;

/// **Geri çağırma — "ara uzadı" hatırlatıcısı** (docs/51 ilk adım).
///
/// Eski "her gün sabit saat" antrenman hatırlatıcısı bu türe dönüştü
/// (karar 3): bildirim yalnız son antrenmandan [recallGapDays] gün sonra,
/// kullanıcının olağan antrenman saatinde gelir; antrenman girilince
/// kendiliğinden iptal olur. Öğün hatırlatıcısıyla aynı desen (docs/26):
/// bugün + 2 gün için tek seferlik bildirim kurulur, tablo değişince, öne
/// gelince ve ayar değişince hepsi silinip yeniden kurulur.
const recallGapDays = 2;
const recallDaysAhead = 3;
const recallMaxPerDay = 2; // günde 2 × 3 gün = NotificationService.recallSlots
const recallMaxPerWeek = 6;

/// Günün ikinci bildirimi birinciden bu kadar dakika SONRA; 22:00'yi
/// geçerse bu kadar ÖNCE.
const recallSecondGapMinutes = 3 * 60;
const recallQuietStartHour = 22; // 22:00–08:00 sessiz
const recallQuietEndHour = 8;
const recallQuietShiftMinute = 8 * 60 + 30; // sessiz saate düşen → 08:30
const recallMuteAfter = 3; // art arda tepkisiz GÜN (bildirim değil)
const recallMuteDays = 14;

/// Başlık çeşidi sayısı — hep aynı cümle görülmesin (docs/51 "Ton").
const recallTitleVariants = 3;

/// Olağan antrenman saati (gün içi dakika): son seansların BAŞLANGIÇ
/// saatlerinin ortancası. Başlangıç saati olmayan (geçmişe elle girilmiş)
/// seanslar sayılmaz. Veri yoksa `null` → ayardaki saat.
int? usualWorkoutMinute(Iterable<DateTime> starts) {
  final m = [for (final s in starts) s.hour * 60 + s.minute]..sort();
  if (m.isEmpty) return null;
  return m[m.length ~/ 2];
}

/// Sessiz saate (22:00–08:00) düşen an 08:30'a kayar: akşam geç saatse
/// ertesi sabaha, sabah erkense aynı sabaha.
DateTime shiftOutOfQuietHours(DateTime t) {
  DateTime at(DateTime day) => DateTime(day.year, day.month, day.day,
      recallQuietShiftMinute ~/ 60, recallQuietShiftMinute % 60);
  if (t.hour >= recallQuietStartHour) return at(addDays(t, 1));
  if (t.hour < recallQuietEndHour) return at(t);
  return t;
}

/// Kurulacak geri çağırma anları — saf karar, sahte saatle test edilir.
///
/// - Son antrenmandan [recallGapDays] takvim günü geçmeden bildirim yok;
///   hiç antrenman yoksa da yok (ilk hafta hatırlatması ikinci tur).
/// - Bugün + 2 gün, her gün [minuteOfDay]'de; ikincisi
///   [recallSecondGapMinutes] sonra (22:00'yi geçerse o kadar önce). Sessiz
///   saat kaydırması sonrası bir güne [recallMaxPerDay]'den fazla düşmez.
/// - Geçmişte gönderilenlerle ([sent]) birlikte herhangi 7 günde en fazla
///   [recallMaxPerWeek].
/// - [mutedUntil]'den önceki anlar atlanır.
///
/// Gün aritmetiği takvimle ([addDays]): yaz saati gününde 24 saat ≠ 1 gün.
List<DateTime> planRecall({
  required DateTime now,
  required DateTime? lastWorkout,
  required int minuteOfDay,
  Iterable<DateTime> sent = const [],
  DateTime? mutedUntil,
}) {
  if (lastWorkout == null) return const [];
  final earliest = addDays(dayStart(lastWorkout), recallGapDays);
  final today = dayStart(now);
  final out = <DateTime>[];
  for (var i = 0; i < recallDaysAhead; i++) {
    final day = addDays(today, i);
    if (day.isBefore(earliest)) continue;
    final first = shiftOutOfQuietHours(DateTime(day.year, day.month, day.day,
        minuteOfDay ~/ 60, minuteOfDay % 60));
    for (final t in [first, _secondOf(first)]) {
      if (t == null || !t.isAfter(now)) continue;
      if (mutedUntil != null && t.isBefore(mutedUntil)) continue;
      if (out.contains(t)) continue;
      final sameDay = out.where((o) => dayStart(o) == dayStart(t)).length;
      if (sameDay >= recallMaxPerDay) continue;
      final windowStart = addDays(t, -7);
      final inWindow = [...sent, ...out]
          .where((s) => s.isAfter(windowStart) && !s.isAfter(t))
          .length;
      if (inWindow >= recallMaxPerWeek) continue;
      out.add(t);
    }
  }
  out.sort();
  return out;
}

/// Günün ikinci anı: birinciden [recallSecondGapMinutes] sonra; sessiz saate
/// ya da ertesi güne taşarsa o kadar önce; o da sessiz saatteyse yok.
DateTime? _secondOf(DateTime first) {
  const gap = Duration(minutes: recallSecondGapMinutes);
  bool loud(DateTime t) =>
      dayStart(t) == dayStart(first) &&
      t.hour >= recallQuietEndHour &&
      t.hour < recallQuietStartHour;
  final later = first.add(gap);
  if (loud(later)) return later;
  final earlier = first.subtract(gap);
  return loud(earlier) ? earlier : null;
}

/// Gönderilen geri çağırmaların cihazdaki defteri (docs/51 §2) — analitik
/// yok, hiçbir yere gitmez. Haftalık sınır ve "art arda tepkisiz → sustur"
/// kuralı bundan hesaplanır.
class RecallLedger {
  /// Teslim edildiği varsayılan anlar (son 8 gün).
  final List<DateTime> sent;

  /// Son kurulumda takvime konan anlar. Bir sonraki kurulumda zamanı geçmiş
  /// olanlar "gönderildi" sayılır: arada tablo değişseydi yeniden kurulum
  /// onları zaten iptal ederdi.
  final List<DateTime> planned;

  /// Geri çağırma bildirimine son dokunma.
  final DateTime? lastTap;
  final DateTime? mutedUntil;

  const RecallLedger({
    this.sent = const [],
    this.planned = const [],
    this.lastTap,
    this.mutedUntil,
  });

  /// Zamanı geçen planlananları gönderilmiş say, eskileri buda, gerekirse
  /// sustur. Tepki = bildirime dokunma ya da sonrasında antrenman girme.
  RecallLedger reconcile({required DateTime now, DateTime? lastWorkout}) {
    final delivered = [
      ...sent,
      for (final p in planned)
        if (!p.isAfter(now)) p,
    ]..sort();
    final keepFrom = addDays(now, -8);
    final kept = delivered.where((s) => s.isAfter(keepFrom)).toList();
    final reactedAt = [lastTap, lastWorkout]
        .whereType<DateTime>()
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
    // Günde 2 bildirim olabildiği için tepkisiz GÜN sayılır: "3 kez" = 3
    // ayrı gün görmezden gelindi.
    final unanswered = {
      for (final s in kept)
        if (reactedAt == null || s.isAfter(reactedAt)) dayStart(s),
    }.length;
    var muted = mutedUntil;
    if (muted != null && !muted.isAfter(now)) muted = null;
    if (muted == null && unanswered >= recallMuteAfter) {
      muted = addDays(now, recallMuteDays);
    }
    return RecallLedger(
      sent: kept,
      planned: const [],
      lastTap: lastTap,
      mutedUntil: muted,
    );
  }

  RecallLedger withPlanned(List<DateTime> next) => RecallLedger(
        sent: sent,
        planned: next,
        lastTap: lastTap,
        mutedUntil: mutedUntil,
      );

  static const _kSent = 'recall_sent';
  static const _kPlanned = 'recall_planned';
  static const _kTap = 'recall_last_tap';
  static const _kMuted = 'recall_muted_until';

  static Future<RecallLedger> load() async {
    final p = await SharedPreferences.getInstance();
    List<DateTime> list(String k) => [
          for (final v in p.getStringList(k) ?? const <String>[])
            if (int.tryParse(v) case final ms?)
              DateTime.fromMillisecondsSinceEpoch(ms),
        ];
    DateTime? one(String k) => switch (p.getInt(k)) {
          final ms? => DateTime.fromMillisecondsSinceEpoch(ms),
          null => null,
        };
    return RecallLedger(
      sent: list(_kSent),
      planned: list(_kPlanned),
      lastTap: one(_kTap),
      mutedUntil: one(_kMuted),
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    List<String> enc(List<DateTime> l) =>
        [for (final d in l) '${d.millisecondsSinceEpoch}'];
    await p.setStringList(_kSent, enc(sent));
    await p.setStringList(_kPlanned, enc(planned));
    final tap = lastTap, muted = mutedUntil;
    tap == null
        ? await p.remove(_kTap)
        : await p.setInt(_kTap, tap.millisecondsSinceEpoch);
    muted == null
        ? await p.remove(_kMuted)
        : await p.setInt(_kMuted, muted.millisecondsSinceEpoch);
  }

  /// Bildirime dokunuldu — tepkisiz sayaç sıfırlanır.
  static Future<void> markTapped([DateTime? at]) async {
    final l = await load();
    await RecallLedger(
      sent: l.sent,
      planned: l.planned,
      lastTap: at ?? DateTime.now(),
      mutedUntil: l.mutedUntil,
    ).save();
  }

  /// Hesap değişimi: defter önceki hesabın antrenmanlarına göre tutuldu.
  static Future<void> clear() => const RecallLedger().save();
}

/// **Geri çağırma bildirimlerini yeniden kurar.** Her çağrıda eski günlük
/// hatırlatıcı ([NotificationService.idWorkout]) ve geri çağırma yuvaları
/// silinir; [enabled] ise plan baştan kurulur.
///
/// [fallbackHour]/[fallbackMinute]: seans geçmişinde başlangıç saati yoksa
/// kullanılan ayar saati (eski hatırlatıcının saati).
Future<void> syncRecallReminders({
  required NotificationService service,
  required WorkoutDao dao,
  required AppL10n l,
  required bool enabled,
  required int fallbackHour,
  required int fallbackMinute,
  DateTime? now,
}) async {
  await service.cancel(NotificationService.idWorkout);
  for (var i = 0; i < NotificationService.recallSlots; i++) {
    await service.cancel(NotificationService.idRecallBase + i);
  }
  final t = now ?? DateTime.now();
  final recent = await dao.getRecentSessions(10);
  final lastWorkout = recent.isEmpty ? null : recent.first.date;
  var ledger = (await RecallLedger.load())
      .reconcile(now: t, lastWorkout: lastWorkout);
  if (!enabled) {
    await ledger.save();
    return;
  }

  final minute = usualWorkoutMinute([for (final s in recent) ?s.startedAt]) ??
      fallbackHour * 60 + fallbackMinute;
  final plan = planRecall(
    now: t,
    lastWorkout: lastWorkout,
    minuteOfDay: minute,
    sent: ledger.sent,
    mutedUntil: ledger.mutedUntil,
  );

  final routines = await dao.getActiveRoutines();
  final rotation = rotationNext(routines, await dao.getLastSessionRoutineId());
  for (final (i, at) in plan.indexed) {
    final r = _routineFor(routines, rotation, at);
    final mins = r == null
        ? null
        : estimateRoutineMinutes([
            for (final e in await dao.getRoutineExercises(r.id))
              e.routineExercise,
          ]);
    await service.scheduleOnce(
      // Plan en fazla [recallDaysAhead] × [recallMaxPerDay] an → 40…45.
      id: NotificationService.idRecallBase + i,
      when: at,
      title: recallTitle(l, (ledger.sent.length + i) % recallTitleVariants),
      body: recallBody(l, r?.name, mins),
      payload: NotificationService.payloadRecall,
    );
  }
  ledger = ledger.withPlanned(plan);
  await ledger.save();
}

/// Bildirimde adı geçecek rutin: güne bağlı rutinler varsa o günün rutini
/// (yoksa adsız), değilse döngüde sıradaki (docs/49 §3 ile aynı kural).
Routine? _routineFor(List<Routine> routines, Routine? rotation, DateTime at) {
  final scheduled = routines.where((r) => r.scheduledWeekday != null);
  if (scheduled.isEmpty) return rotation;
  for (final r in scheduled) {
    if (r.scheduledWeekday == at.weekday) return r;
  }
  return null;
}

/// Suçlamayan başlıklar — bir sonraki adımı söyler (docs/51 "Ton").
String recallTitle(AppL10n l, int variant) => switch (variant) {
      1 => l.notifRecallTitle2,
      2 => l.notifRecallTitle3,
      _ => l.notifRecallTitle,
    };

String recallBody(AppL10n l, String? routine, int? minutes) =>
    switch ((routine, minutes)) {
      (final r?, final m?) => l.notifRecallBodyRoutine(r, m),
      (final r?, null) => l.notifRecallBodyRoutineOnly(r),
      _ => l.notifRecallBody,
    };
