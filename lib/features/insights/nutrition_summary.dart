import '../../data/database/app_database.dart';
import 'insight_window.dart';

/// Haftalık değerlendirme ve asistan aynı gün temelini kullanır (docs/37).
enum NutritionBasis { completedDays, loggedDays }

class NutritionStats {
  final int loggedDays;
  final NutritionBasis basis;
  final int completedDays;
  final int excludedLoggedDays;
  final int knownDays;
  final double? avgKcal;
  final double? avgProtein;

  /// Kayıtlı günlerde görülen sayı da tutulur; başarı oranı ancak
  /// [basis] tamamlanmış günlerse gösterilebilir.
  final int proteinGoalDays;
  final int kcalGoal;
  final int proteinGoal;

  const NutritionStats({
    required this.loggedDays,
    required this.avgKcal,
    required this.avgProtein,
    required this.proteinGoalDays,
    required this.kcalGoal,
    required this.proteinGoal,
    this.basis = NutritionBasis.loggedDays,
    this.completedDays = 0,
    this.excludedLoggedDays = 0,
    int? knownDays,
  }) : knownDays = knownDays ?? loggedDays;

  int get sampleDays =>
      basis == NutritionBasis.completedDays ? completedDays : loggedDays;
  int? get completedProteinGoalDays =>
      basis == NutritionBasis.completedDays && proteinGoal > 0
      ? proteinGoalDays
      : null;
}

/// Yalnız açıkça tamamlanmış boş gün sıfır sayılır. Diğer kayıtsız günler
/// bilinmeyendir. Tamamlanmış gün yoksa kayıtlı günlerin betimsel özeti.
NutritionStats nutritionStats({
  required DateWindow window,
  required List<FoodLog> logs,
  Set<DateTime> completedDays = const {},
  int kcalGoal = 0,
  int proteinGoal = 0,
}) {
  final kcal = <DateTime, double>{};
  final protein = <DateTime, double>{};
  for (final l in logs) {
    if (!window.contains(l.date)) continue;
    final day = dayOf(l.date);
    kcal[day] = (kcal[day] ?? 0) + l.computedKcal;
    protein[day] = (protein[day] ?? 0) + l.computedProtein;
  }
  final done = {
    for (final d in completedDays)
      if (window.contains(dayOf(d))) dayOf(d),
  };
  final days = done.isEmpty ? kcal.keys.toSet() : done;
  final n = days.length;
  return NutritionStats(
    loggedDays: kcal.length,
    basis: done.isEmpty
        ? NutritionBasis.loggedDays
        : NutritionBasis.completedDays,
    completedDays: done.length,
    excludedLoggedDays: done.isEmpty
        ? 0
        : kcal.keys.where((d) => !done.contains(d)).length,
    knownDays: {...kcal.keys, ...done}.length,
    avgKcal: n == 0
        ? null
        : days.fold<double>(0, (s, d) => s + (kcal[d] ?? 0)) / n,
    avgProtein: n == 0
        ? null
        : days.fold<double>(0, (s, d) => s + (protein[d] ?? 0)) / n,
    proteinGoalDays: proteinGoal <= 0
        ? 0
        : days.where((d) => (protein[d] ?? 0) >= proteinGoal).length,
    kcalGoal: kcalGoal,
    proteinGoal: proteinGoal,
  );
}
