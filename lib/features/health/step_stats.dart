import '../insights/insight_window.dart' show dayOf;

/// **Adım — saf hesap** (docs/39 §2, S-2…S-5).
///
/// Veritabanı ve platform bilmez, metin üretmez. Günlük adımlar
/// [StepSource]'tan (platformun tekilleştiren toplam sorgusu) gelir; burada
/// yalnız pencere, "veri yok" kuralı ve hedef ilerlemesi hesaplanır.

/// Bir günün penceresi `[start, end)`, takvim günüyle (S-2).
typedef DayWindow = ({DateTime start, DateTime end});

/// [now]'dan geriye [days] günün pencereleri, eskiden yeniye; sonuncusu bugün.
List<DayWindow> stepDayWindows(DateTime now, {int days = 7}) => [
  for (var i = days - 1; i >= 0; i--)
    (
      start: DateTime(now.year, now.month, now.day - i),
      end: DateTime(now.year, now.month, now.day - i + 1),
    ),
];

/// Ham platform değeri → adım. **0 ya da boş = veri yok** (S-3): iOS okuma
/// iznini bildirmez, reddedilen izin 0 döner; taşınan telefonda gerçek 0
/// adımlı gün pratikte olmaz.
int? normalizeSteps(int? raw) => (raw == null || raw <= 0) ? null : raw;

class DaySteps {
  final DateTime day;

  /// `null` = veri yok (S-3). Ekran "0" değil "—" yazar.
  final int? steps;

  const DaySteps(this.day, this.steps);
}

enum StepWeekState {
  /// En az bir günde veri var.
  ok,

  /// Hiçbir günde veri yok → "Sağlık izinlerini kontrol et" (S-4).
  noData,
}

class StepWeek {
  /// Eskiden yeniye; sonuncusu bugün.
  final List<DaySteps> days;
  final StepWeekState state;

  /// Yalnız verili günlerin ortalaması (yuvarlanmış); veri yoksa `null`.
  final int? average;

  /// Kullanıcının hedefi; yoksa `null` → ilerleme çizgisi yok (S-5).
  final int? goal;

  const StepWeek({
    required this.days,
    required this.state,
    required this.average,
    required this.goal,
  });

  int? get today => days.isEmpty ? null : days.last.steps;

  /// Bugünün hedefe oranı (0…∞, kırpılmaz — ekran kırpar). Hedef ya da
  /// bugünkü veri yoksa `null`.
  double? get todayProgress {
    final g = goal;
    final t = today;
    if (g == null || g <= 0 || t == null) return null;
    return t / g;
  }
}

/// [stepsByDay]: gün başı (00:00) → ham platform değeri. Eksik gün = veri yok.
StepWeek buildStepWeek({
  required DateTime now,
  required Map<DateTime, int?> stepsByDay,
  int? goal,
  int days = 7,
}) {
  final out = [
    for (final w in stepDayWindows(now, days: days))
      DaySteps(w.start, normalizeSteps(stepsByDay[dayOf(w.start)])),
  ];
  final withData = [
    for (final d in out)
      if (d.steps != null) d.steps!,
  ];
  return StepWeek(
    days: out,
    state: withData.isEmpty ? StepWeekState.noData : StepWeekState.ok,
    average: withData.isEmpty
        ? null
        : (withData.reduce((a, b) => a + b) / withData.length).round(),
    goal: (goal != null && goal > 0) ? goal : null,
  );
}
