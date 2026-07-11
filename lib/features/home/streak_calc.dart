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

  const WeeklyStreak({
    required this.weeks,
    required this.thisWeekDone,
    required this.weeklyGoal,
  });

  bool get thisWeekComplete => thisWeekDone >= weeklyGoal;
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

  // Bu hafta tamamlandıysa ondan, tamamlanmadıysa (devam ediyor — kırmaz)
  // geçen haftadan geriye ardışık tamamlanan haftaları say.
  var cursor = thisWeekDone >= goal ? thisWeek : thisWeek - 7;
  var weeks = 0;
  while ((daysPerWeek[cursor]?.length ?? 0) >= goal) {
    weeks++;
    cursor -= 7;
  }

  return WeeklyStreak(
      weeks: weeks, thisWeekDone: thisWeekDone, weeklyGoal: goal);
}
