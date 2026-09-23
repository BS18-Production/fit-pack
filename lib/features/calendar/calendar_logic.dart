import '../activity/activity_providers.dart';

/// Ana sayfa haftalık şeridi + ay görünümü (docs/24) — saf mantık, widget'sız
/// (CONVENTIONS §1). Gün aritmetiği `DateTime(y, m, d + n)` ile yapılır:
/// `Duration(days: n)` eklemek yaz saati geçişinde saati kaydırır.

/// [day]'in gece yarısı (saat bilgisi atılır).
DateTime dateOnly(DateTime day) => DateTime(day.year, day.month, day.day);

/// [a] ile [b] aynı takvim günü mü?
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Hafta başından itibaren 7 gün.
List<DateTime> weekDays(DateTime weekStartDay) => [
      for (var i = 0; i < 7; i++)
        DateTime(weekStartDay.year, weekStartDay.month, weekStartDay.day + i),
    ];

/// Hafta başını [weeks] hafta kaydırır (eksi = geçmiş).
DateTime shiftWeek(DateTime weekStartDay, int weeks) => DateTime(
    weekStartDay.year, weekStartDay.month, weekStartDay.day + 7 * weeks);

/// Günlerin düştüğü ayların ilk günleri — bir hafta iki aya taşabilir, şerit
/// her ayın verisini ayrı ister ([monthActivityProvider] ay bazlı).
List<DateTime> monthsOf(List<DateTime> days) {
  final out = <DateTime>[];
  for (final d in days) {
    final m = DateTime(d.year, d.month, 1);
    if (!out.contains(m)) out.add(m);
  }
  return out;
}

/// [day] bugünden sonra mı? Gelecek gün dokunulmaz ve başarısız sayılmaz.
bool isFutureDay(DateTime day, DateTime now) =>
    dateOnly(day).isAfter(dateOnly(now));

/// Takvimde bir günün işareti.
enum DayMark {
  /// Kayıt yok (boş gün — başarısızlık değil, bilinmiyor).
  none,

  /// Beslenme ya da su kaydı var, antrenman yok.
  record,

  /// En az bir antrenman seansı var.
  workout,
}

DayMark dayMarkOf(DayActivity? act) {
  if (act == null || act.isEmpty) return DayMark.none;
  return act.hasWorkout ? DayMark.workout : DayMark.record;
}
