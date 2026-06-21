import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/nutrition_dao.dart';
import '../../data/providers.dart';

/// Aktivite takvimi (docs/10-activity-calendar.md) — Faz A: veri katmanı.
/// Bir ayın her günü için birleşik aktivite (makro + su + antrenman).
/// Halka doluluğu UI'da profil hedefleriyle hesaplanır; burada ham değerler.

/// Bir günün ham aktivite verisi (hedefe göre normalize edilmemiş).
class DayActivity {
  final double kcal;
  final double protein;
  final double carb;
  final double fat;
  final int waterMl;
  final bool hasWorkout;
  final String? workoutName; // o günün ilk seansının adı
  final int volumeKg; // o günkü toplam hacim (Σ kg×tekrar)
  final int setCount;

  const DayActivity({
    this.kcal = 0,
    this.protein = 0,
    this.carb = 0,
    this.fat = 0,
    this.waterMl = 0,
    this.hasWorkout = false,
    this.workoutName,
    this.volumeKg = 0,
    this.setCount = 0,
  });

  /// Hiç kayıt yok (boş gün → takvimde gri halkalar).
  bool get isEmpty =>
      kcal == 0 && protein == 0 && waterMl == 0 && !hasWorkout;
}

/// DAO sonuçlarını ayın günü (1..31) → [DayActivity] haritasına birleştirir.
/// Saf fonksiyon — kolayca test edilir (provider ince sarmalayıcı).
Map<int, DayActivity> buildMonthActivity({
  required int year,
  required int month,
  required Map<DateTime, DailyNutrition> totals,
  required Map<DateTime, int> water,
  required List<WorkoutSession> sessions,
  required Map<int, List<WorkoutSet>> setsBySession,
}) {
  DateTime keyOf(DateTime d) => DateTime(d.year, d.month, d.day);

  // Gün → o güne ait seanslar.
  final sessionsByDay = <int, List<WorkoutSession>>{};
  for (final s in sessions) {
    if (s.date.year != year || s.date.month != month) continue;
    sessionsByDay.putIfAbsent(s.date.day, () => []).add(s);
  }

  final result = <int, DayActivity>{};
  final daysInMonth = DateTime(year, month + 1, 0).day;
  for (var day = 1; day <= daysInMonth; day++) {
    final key = DateTime(year, month, day);
    final nut = totals[keyOf(key)];
    final ml = water[keyOf(key)] ?? 0;
    final daySessions = sessionsByDay[day] ?? const [];

    var volume = 0;
    var setCount = 0;
    for (final s in daySessions) {
      final sets = setsBySession[s.id] ?? const [];
      setCount += sets.length;
      for (final set in sets) {
        volume += ((set.weightKg ?? 0) * (set.reps ?? 0)).round();
      }
    }

    final act = DayActivity(
      kcal: nut?.kcal ?? 0,
      protein: nut?.protein ?? 0,
      carb: nut?.carb ?? 0,
      fat: nut?.fat ?? 0,
      waterMl: ml,
      hasWorkout: daySessions.isNotEmpty,
      // V2'de seans adı workoutType'ta tutulur (rutin adının snapshot'ı).
      workoutName:
          daySessions.isEmpty ? null : daySessions.first.workoutType,
      volumeKg: volume,
      setCount: setCount,
    );
    if (!act.isEmpty) result[day] = act;
  }
  return result;
}

/// Bir ayın aktivite haritası. Aile anahtarı = ayın herhangi bir günü
/// (yıl+ay kullanılır). Tek sorgu seti ile tüm ay doldurulur.
///
/// autoDispose: İlerleme sekmesinden çıkınca atılır; geri dönünce taze
/// hesaplanır (su/yemek/antrenman değişiklikleri yansısın). AppShell
/// `context.go` ile route değiştirir (IndexedStack yok) → ekran dispose olur.
final monthActivityProvider = FutureProvider.autoDispose
    .family<Map<int, DayActivity>, DateTime>((ref, month) async {
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 1)
      .subtract(const Duration(milliseconds: 1));

  final nut = ref.watch(nutritionDaoProvider);
  final wo = ref.watch(workoutDaoProvider);

  final totals = await nut.getDailyTotalsInRange(start, end);
  final water = await nut.getWaterInRange(start, end);
  final sessions = await wo.getSessionsByDateRange(start, end);
  final setsBySession =
      await wo.getSetsForSessions(sessions.map((s) => s.id).toList());

  return buildMonthActivity(
    year: month.year,
    month: month.month,
    totals: totals,
    water: water,
    sessions: sessions,
    setsBySession: setsBySession,
  );
});
