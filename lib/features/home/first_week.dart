import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/current_day.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';
import '../cloud/auth_service.dart';

/// İlk hafta rehberi (docs/49 §3): üç ilk adım — antrenman, öğün, kilo.
///
/// Ayrı tablo ya da tercih YOK: adımlar mevcut veriden okunur, senkronla
/// öbür cihazda da aynı görünür. Kart hesabın ilk [firstWeekWindowDays]
/// gününde ve üç adım bitmediyse çıkar.
const firstWeekWindowDays = 14;

class FirstWeekProgress {
  final bool workout, meal, weight;
  const FirstWeekProgress({
    this.workout = false,
    this.meal = false,
    this.weight = false,
  });

  int get doneCount => [workout, meal, weight].where((d) => d).length;
  bool get allDone => doneCount == 3;
}

/// Kart görünür mü? Hesap tarihi bilinmiyorsa (oturum yok) gösterilmez.
bool showFirstWeek({
  required DateTime? accountCreated,
  required DateTime today,
  required FirstWeekProgress progress,
}) {
  if (accountCreated == null || progress.allDone) return false;
  final c = accountCreated.toLocal();
  final start = DateTime(c.year, c.month, c.day);
  return calendarDaysBetween(start, today) < firstWeekWindowDays;
}

/// [from] ile [to] arasındaki takvim günü farkı (yaz saatinden bağımsız).
int calendarDaysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;

/// Üç adımın durumu — ilgili tablolar değişince kendiliğinden tazelenir.
final firstWeekProgressProvider = StreamProvider<FirstWeekProgress>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(
    db,
    [db.workoutSessions, db.foodLogs, db.bodyMeasurements],
    () async {
      final r = await db.customSelect(
        'SELECT '
        '(SELECT EXISTS(SELECT 1 FROM workout_sessions)) AS w, '
        '(SELECT EXISTS(SELECT 1 FROM food_logs)) AS m, '
        '(SELECT EXISTS(SELECT 1 FROM body_measurements '
        'WHERE weight_kg > ? AND COALESCE(hidden, 0) = 0)) AS b',
        variables: [Variable.withReal(0)],
      ).getSingle();
      return FirstWeekProgress(
        workout: r.read<int>('w') == 1,
        meal: r.read<int>('m') == 1,
        weight: r.read<int>('b') == 1,
      );
    },
  );
});

/// Hesabın açılış tarihi — Supabase oturumundan, ağ sormadan.
final accountCreatedProvider = Provider<DateTime?>((ref) {
  final raw = ref.watch(currentUserProvider)?.createdAt;
  return raw == null ? null : DateTime.tryParse(raw);
});

/// Ana Sayfa kartı için: görünürse ilerleme, değilse null.
final firstWeekCardProvider = Provider<FirstWeekProgress?>((ref) {
  final progress = ref.watch(firstWeekProgressProvider).valueOrNull;
  if (progress == null) return null;
  final show = showFirstWeek(
    accountCreated: ref.watch(accountCreatedProvider),
    today: ref.watch(currentDayProvider),
    progress: progress,
  );
  return show ? progress : null;
});
