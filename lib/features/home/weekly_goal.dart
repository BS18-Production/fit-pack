import '../onboarding/program_recommendation.dart';
import '../explore/program_catalog.dart';
import '../../data/database/app_database.dart';

int onboardingWeeklyGoal(WeeklyDays days) => switch (days) {
  WeeklyDays.twoThree => 3,
  WeeklyDays.four => 4,
  WeeklyDays.fiveSix => 6,
};

/// docs/52: açık seçim, katalog programı, planlı günler, varsayılan.
int resolveWeeklyGoal({int? selected, required List<Routine> routines}) {
  return resolveKnownWeeklyGoal(selected: selected, routines: routines) ?? 3;
}

/// Sayısal facade için eski 3 varsayılanı korunur; ancak kullanıcının
/// doğruladığı/hedefi anlaşılabilen bir plan yoksa hedef BİLİNMİYOR'dur.
int? resolveKnownWeeklyGoal({int? selected, required List<Routine> routines}) {
  if (selected != null && selected >= 1 && selected <= 7) return selected;
  var programDays = 0;
  for (final routine in routines.where((r) => !r.isArchived)) {
    for (final p in programCatalog) {
      if (p.key == routine.programKey && p.daysPerWeek > programDays) {
        programDays = p.daysPerWeek;
      }
    }
  }
  if (programDays > 0) return programDays;
  final scheduled = routines
      .where((r) => !r.isArchived)
      .map((r) => r.scheduledWeekday)
      .whereType<int>()
      .where((d) => d >= 1 && d <= 7)
      .toSet()
      .length;
  return scheduled > 0 ? scheduled : null;
}
