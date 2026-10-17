import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/adaptive_tdee.dart';
import '../../core/utils/current_day.dart';
import '../../data/database/daos/nutrition_dao.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';

/// Gerçek harcama tahmini (docs/43). Kilo, öğün ya da "gün tamamlandı"
/// değişince kendiliğinden yeniden hesaplanır; gün dönünce de (dün tamamlanan
/// gün yeni yazma beklemeden hesaba girer).
final adaptiveTdeeProvider = StreamProvider<TdeeEstimate>((ref) {
  final db = ref.watch(databaseProvider);
  ref.watch(currentDayProvider);
  return watchTables(
    db,
    [db.bodyMeasurements, db.foodLogs, db.nutritionDays],
    () async {
      final now = DateTime.now();
      final end = DateTime(now.year, now.month, now.day);
      final start = DateTime(end.year, end.month, end.day - kTdeeWindowDays);
      final nut = ref.read(nutritionDaoProvider);
      final completed = await nut.getCompletedDays(start, end);
      final intake = <DateTime, double>{};
      for (final l in await nut.getLogsInRange(start, end)) {
        final day = DateTime(l.date.year, l.date.month, l.date.day);
        // A-2: yalnız tamamlanmış gün.
        if (!completed.contains(NutritionDao.dayKey(day))) continue;
        intake[day] = (intake[day] ?? 0) + l.computedKcal;
      }
      // Tamamlandı işaretli ama hiç kaydı olmayan gün: 0 kcal yemiş sayılmaz,
      // hesaba girmez (oruç günü nadir; eksik kayıt daha olası).
      final weights = [
        for (final m
            in await ref
                .read(bodyDaoProvider)
                .getDailyMeasurementsInRange(start, end))
          if (m.weightKg != null) (date: m.date, kg: m.weightKg!),
      ];
      return estimateTdee(now: now, weights: weights, completedIntake: intake);
    },
  );
});
