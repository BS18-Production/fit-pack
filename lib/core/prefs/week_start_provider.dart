import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Haftanın ilk günü tercihi (docs/16 §2.2, S8). Değer `DateTime.weekday`
/// uzayında: 1 = Pazartesi (varsayılan, TR/ISO), 7 = Pazar (ABD alışkanlığı).
/// Haftalık istatistik pencereleri + aktivite takvimi bu tercihe göre kurulur.
///
/// `locale_provider` ile aynı desen: build() kayıtlı tercihi asenkron yükler.
class WeekStartNotifier extends Notifier<int> {
  static const _key = 'week_start';

  @override
  int build() {
    _load();
    return DateTime.monday; // varsayılan: Pazartesi
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_key);
    if (saved == DateTime.monday || saved == DateTime.sunday) state = saved!;
  }

  Future<void> setWeekStart(int weekday) async {
    assert(weekday == DateTime.monday || weekday == DateTime.sunday);
    state = weekday;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, weekday);
  }
}

final weekStartProvider =
    NotifierProvider<WeekStartNotifier, int>(WeekStartNotifier.new);

/// [day]'in içinde bulunduğu haftanın başlangıç gecesi (00:00).
/// Dart'ta `%` negatif olmayan sonuç verir → weekStart=7 (Pazar) için de doğru:
/// Pzt(1)−7 = −6 → %7 = 1 gün geri (dün Pazar'dı).
DateTime startOfWeek(DateTime day, int weekStart) {
  final d = DateTime(day.year, day.month, day.day);
  return d.subtract(Duration(days: (d.weekday - weekStart) % 7));
}
