import '../../core/prefs/week_start_provider.dart';

/// **"Verime sor" dönem pencereleri** (docs/36 §1, docs/35 sözleşme v2).
///
/// Saf Dart: veritabanı bilmez. Her pencere yarı açık `[start, end)`
/// (CONVENTIONS §3). Gün aritmetiği takvim günüyle yapılır
/// (`DateTime(y, m, d ± n)`), `Duration` ile değil — yaz saati haftasında 23
/// saatlik gün pencereyi kaydırmasın (bkz. [startOfWeek]).

/// Jev'in `period` seçeneklerinden hesap desteği olanlar.
enum InsightPeriod { today, thisWeek, lastWeek, last30Days, allTime }

class DateWindow {
  /// Başlangıç (dahil). `null` = tüm zamanlar.
  final DateTime? start;

  /// Bitiş (hariç).
  final DateTime end;

  /// Pencere bitti mi? Bitmediyse ekran "şu ana kadar" der (docs/36 §2).
  final bool isComplete;

  const DateWindow({this.start, required this.end, required this.isComplete});

  bool contains(DateTime t) =>
      (start == null || !t.isBefore(start!)) && t.isBefore(end);

  /// Penceredeki takvim günü sayısı; tüm zamanlarda `null`.
  int? get days => start == null ? null : calendarDaysBetween(start!, end);
}

DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// İki gece yarısı arasındaki takvim günü farkı (yaz saatinden etkilenmez).
int calendarDaysBetween(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// [now] anına göre dönemin penceresi. [weekStart]: `DateTime.monday` ya da
/// `DateTime.sunday` (Ayarlar → hafta başlangıcı).
///
/// "Son 30 gün" bugünü **içerir**: `[bugün − 29, yarın)`.
DateWindow windowFor(
  InsightPeriod p,
  DateTime now, {
  int weekStart = DateTime.monday,
}) {
  final d0 = dayOf(now);
  final tomorrow = DateTime(d0.year, d0.month, d0.day + 1);
  final sow = startOfWeek(now, weekStart);
  switch (p) {
    case InsightPeriod.today:
      return DateWindow(start: d0, end: tomorrow, isComplete: false);
    case InsightPeriod.thisWeek:
      return DateWindow(
        start: sow,
        end: DateTime(sow.year, sow.month, sow.day + 7),
        isComplete: false,
      );
    case InsightPeriod.lastWeek:
      return DateWindow(
        start: DateTime(sow.year, sow.month, sow.day - 7),
        end: sow,
        isComplete: true,
      );
    case InsightPeriod.last30Days:
      return DateWindow(
        start: DateTime(d0.year, d0.month, d0.day - 29),
        end: tomorrow,
        isComplete: false,
      );
    case InsightPeriod.allTime:
      return DateWindow(end: tomorrow, isComplete: false);
  }
}
