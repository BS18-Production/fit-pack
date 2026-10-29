import '../../core/prefs/week_start_provider.dart';

/// Haftalık hedef bazlı antrenman serisi — saf mantık, widget'sız
/// (CONVENTIONS §1).
///
/// Eski seri ardışık TAKVİM GÜNÜ sayıyordu: haftada 3-4 gün antrenman yapan
/// kullanıcının serisi her dinlenme gününde kırılıyordu — Ana Sayfa'nın
/// "dinlenme günü zekası"yla çelişki. Yeni tanım: hafta içinde hedef kadar
/// (planlanmış gün sayısı) antrenman günü = hafta tamamlandı; seri, ardışık
/// tamamlanan hafta sayısıdır. Devam eden hafta henüz tamamlanmadıysa seriyi
/// KIRMAZ (hafta bitmedi), tamamlandıysa seriye dahildir.

class WeeklyStreak {
  /// Ardışık tamamlanan hafta sayısı (bu hafta tamamlandıysa dahil).
  final int weeks;

  /// Bu hafta antrenman yapılan benzersiz gün sayısı.
  final int thisWeekDone;

  /// Haftalık hedef gün (planlanmış rutin günü sayısı; plan yoksa 1).
  final int weeklyGoal;

  /// Bu haftadan ÖNCE en az bir antrenman var mı. Seri 0 iken "hiç
  /// başlamadı" ile "önceki hafta kaçtı" durumlarını ayırır (docs/24 §2).
  final bool hasEarlierSessions;

  /// Varsayılan 3, kullanıcıya ait doğrulanmış hedef sayılmaz.
  final bool targetKnown;

  /// Eski haftaların hedefi kaydedilmemişse seri yalnız bilinen dönemleri
  /// kapsar; bilinmeyen hafta başarısızlık olarak yorumlanmaz.
  final bool historyLimited;

  const WeeklyStreak({
    required this.weeks,
    required this.thisWeekDone,
    required this.weeklyGoal,
    this.hasEarlierSessions = false,
    this.targetKnown = true,
    this.historyLimited = false,
  });

  bool get thisWeekComplete => targetKnown && thisWeekDone >= weeklyGoal;

  /// Hedefe kalan antrenman günü (tamamlandıysa 0).
  int get remaining => !targetKnown || thisWeekDone >= weeklyGoal
      ? 0
      : weeklyGoal - thisWeekDone;
}

/// Gün anahtarı: yerel günü UTC gün-epoch'una indirger. DST/saat oynamalarına
/// dayanıklı tamsayı aritmetiği için (7 gün çıkarma hiç sapmaz).
int _dayKey(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

WeeklyStreak computeWeeklyStreak({
  required Iterable<DateTime> sessionDates,
  required int weeklyGoal,
  required DateTime now,
  required int weekStart, // DateTime.monday | DateTime.sunday
  int? Function(DateTime periodStart)? goalForWeek,
  bool targetKnown = true,
}) {
  final goal = weeklyGoal < 1 ? 1 : weeklyGoal;

  // Hafta anahtarı (haftanın ilk gününün gün-epoch'u) → benzersiz antrenman
  // günleri. Aynı güne iki seans tek gün sayılır.
  final daysPerWeek = <int, Set<int>>{};
  for (final d in sessionDates) {
    final week = _dayKey(startOfWeek(d, weekStart));
    daysPerWeek.putIfAbsent(week, () => <int>{}).add(_dayKey(d));
  }

  final thisWeek = _dayKey(startOfWeek(now, weekStart));
  final thisWeekDone = daysPerWeek[thisWeek]?.length ?? 0;

  int? targetAt(int dayKey) {
    if (goalForWeek == null) return targetKnown ? goal : null;
    final utc = DateTime.fromMillisecondsSinceEpoch(
      dayKey * Duration.millisecondsPerDay,
      isUtc: true,
    );
    final target = goalForWeek(DateTime(utc.year, utc.month, utc.day));
    return target != null && target >= 1 && target <= 7 ? target : null;
  }

  final currentTarget = targetAt(thisWeek);
  final currentKnown = targetKnown && currentTarget != null;

  // Bu hafta tamamlandıysa ondan, tamamlanmadıysa (devam ediyor — kırmaz)
  // geçen haftadan geriye ardışık tamamlanan haftaları say.
  var cursor = currentKnown && thisWeekDone >= currentTarget
      ? thisWeek
      : thisWeek - 7;
  var weeks = 0;
  var historyLimited = false;
  while (true) {
    final target = targetAt(cursor);
    if (target == null) {
      historyLimited = true;
      break;
    }
    if ((daysPerWeek[cursor]?.length ?? 0) < target) break;
    weeks++;
    cursor -= 7;
  }

  return WeeklyStreak(
    weeks: weeks,
    thisWeekDone: thisWeekDone,
    weeklyGoal: currentTarget ?? goal,
    hasEarlierSessions: daysPerWeek.keys.any((w) => w < thisWeek),
    targetKnown: currentKnown,
    historyLimited: historyLimited,
  );
}
