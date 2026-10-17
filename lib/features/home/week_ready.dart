import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/prefs/week_start_provider.dart';
import '../../core/utils/current_day.dart';

/// "Haftan hazır" kartı (docs/50 Faz 2): hafta kapanınca (son günün
/// 20:00'si) değerlendirme açılana kadar Ana Sayfa'da durur; ertesi günün
/// sonunda kendiliğinden kalkar.
///
/// "Açıldı" bilgisi cihazda tek bir tarih (kapanan haftanın başlangıcı) —
/// cihaz başına kolaylık, senkron gerekmez (docs/50: yeni tablo yok).

/// Haftanın kapandığı akşamın saati (mevcut haftalık bildirimle aynı).
const weekReadyHour = 20;

/// [now] kartın görünme aralığındaysa kapanan haftanın başlangıcı, değilse
/// `null`. Aralık: haftanın son günü 20:00 → yeni haftanın ilk günü bitene
/// kadar. [weekStart] 1=Pzt…7=Paz (`weekStartProvider`).
DateTime? closedWeekStart(DateTime now, int weekStart) {
  final today = dayStart(now);
  final thisWeek = startOfWeek(today, weekStart);
  final lastDay = addDays(thisWeek, 6);
  if (today == lastDay && now.hour >= weekReadyHour) return thisWeek;
  if (today == thisWeek) return addDays(thisWeek, -7);
  return null;
}

/// Kart görünür mü: aralıktayız ve o hafta henüz açılmadı.
bool weekReadyVisible({
  required DateTime now,
  required int weekStart,
  required DateTime? openedWeek,
}) {
  final closed = closedWeekStart(now, weekStart);
  return closed != null && openedWeek != closed;
}

/// Kartın açacağı hafta: kapanış akşamı içinde bulunulan hafta (0), ertesi
/// gün geçen hafta (1) — `weeklyReviewProvider` parametresi.
int weekReadyOffset(DateTime now, int weekStart) {
  final closed = closedWeekStart(now, weekStart);
  if (closed == null) return 0;
  return closed == startOfWeek(dayStart(now), weekStart) ? 0 : 1;
}

/// Açılan son haftanın başlangıcı (cihaz tercihi). [loaded] false iken kart
/// gösterilmez — tercih yüklenene dek "açılmış" haftada kart flaşlamasın.
typedef WeekReadyOpenedState = ({bool loaded, DateTime? week});

class WeekReadyOpened extends Notifier<WeekReadyOpenedState> {
  static const _key = 'week_ready_opened';

  @override
  WeekReadyOpenedState build() {
    _load();
    return (loaded: false, week: null);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    state = (loaded: true, week: s == null ? null : DateTime.tryParse(s));
  }

  /// Kapanan haftayı açıldı say (kart kalkar). Aralık dışında bir şey
  /// yapmaz — başka zamanda değerlendirmeye bakmak kartı etkilemez.
  Future<void> markOpened(DateTime now, int weekStart) async {
    final closed = closedWeekStart(now, weekStart);
    if (closed == null) return;
    state = (loaded: true, week: closed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, closed.toIso8601String());
  }
}

final weekReadyOpenedProvider =
    NotifierProvider<WeekReadyOpened, WeekReadyOpenedState>(
        WeekReadyOpened.new);

/// Saat — testte sabitlenir.
final weekReadyClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Kart görünür mü. Kapanış saati (20:00) gün dönümü değildir; o an ön
/// planda geçilirse kart bir sonraki yeniden çizimde (sekme dönüşü, öne
/// gelme, gün dönümü) çıkar — yalnız bunun için zamanlayıcı kurulmaz.
final weekReadyVisibleProvider = Provider<bool>((ref) {
  ref.watch(currentDayProvider);
  final opened = ref.watch(weekReadyOpenedProvider);
  if (!opened.loaded) return false;
  return weekReadyVisible(
    now: ref.watch(weekReadyClockProvider)(),
    weekStart: ref.watch(weekStartProvider),
    openedWeek: opened.week,
  );
});
