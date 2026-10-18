import '../../core/prefs/week_start_provider.dart';
import '../../data/database/daos/workout_dao.dart';
import '../workout/exercise_daily_best.dart';

/// İlerleme → Antrenman parçasının saf hesabı (docs/56 §1). Widget'sız,
/// birim testli. Girdi: kilo×tekrar dolu, ısınma hariç set noktaları
/// (`getWeightedSetPointsInRange`), tarih sırasıyla.

/// Ana hareket penceresi ve sayısı.
const trainingTopWindow = Duration(days: 56); // 8 hafta
const trainingTopCount = 5;

/// 4 haftalık fark penceresi.
const trainingDeltaWindow = Duration(days: 28);

/// Rekor penceresi.
const trainingRecordWindow = Duration(days: 30);

/// Haftalık hacim kaç hafta.
const trainingVolumeWeeks = 8;

class TopExercise {
  final int exerciseId;
  final String name;
  // Günlük en iyi e1RM (tahmini 1RM, Epley) — kg, eskiden yeniye.
  final List<({DateTime date, double e1rm})> daily;
  // Son günlük en iyi (kg).
  final double latest;
  // Son değer − 4 hafta önceki (o tarihte ya da önceki son) değer; yoksa null.
  final double? delta4w;
  const TopExercise({
    required this.exerciseId,
    required this.name,
    required this.daily,
    required this.latest,
    required this.delta4w,
  });

  /// Eğri en az iki farklı gün ister — tek seans "gelişim" değildir (A2 #6).
  bool get hasCurve => daily.length >= 2;
}

class RecordEvent {
  final int exerciseId;
  final String name;
  final DateTime date;
  final double e1rm; // kg
  const RecordEvent({
    required this.exerciseId,
    required this.name,
    required this.date,
    required this.e1rm,
  });
}

class TrainingProgress {
  final List<TopExercise> top;
  final List<RecordEvent> records; // yeniden eskiye
  // Son [trainingVolumeWeeks] haftanın başlangıcı ve hacmi (kg); kayıt yoksa
  // null — boşluk, 0 değil. Eskiden yeniye.
  final List<({DateTime weekStart, double? volumeKg})> weeklyVolume;
  // Penceredeki farklı antrenman günü sayısı (boş durum kararı için).
  final int trainingDays;
  const TrainingProgress({
    required this.top,
    required this.records,
    required this.weeklyVolume,
    required this.trainingDays,
  });

  bool get isEmpty => trainingDays == 0;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Son 8 haftada en sık yapılan (farklı gün sayısı) hareketler; eşitlikte en
/// son yapılan önce. En çok [count].
List<int> topExerciseIds(List<ExerciseProgressPoint> points, DateTime now,
    {int count = trainingTopCount}) {
  final since = _day(now).subtract(trainingTopWindow);
  final days = <int, Set<DateTime>>{};
  final last = <int, DateTime>{};
  for (final p in points) {
    if (p.date.isBefore(since)) continue;
    days.putIfAbsent(p.exerciseId, () => {}).add(_day(p.date));
    final l = last[p.exerciseId];
    if (l == null || p.date.isAfter(l)) last[p.exerciseId] = p.date;
  }
  final ids = days.keys.toList()
    ..sort((a, b) {
      final byDays = days[b]!.length.compareTo(days[a]!.length);
      return byDays != 0 ? byDays : last[b]!.compareTo(last[a]!);
    });
  return ids.take(count).toList();
}

/// 4 haftalık fark: son değer − (son tarihten [trainingDeltaWindow] önce ya da
/// daha eski) son değer. Öyle bir nokta yoksa null.
double? fourWeekDelta(List<({DateTime date, double e1rm})> daily) {
  if (daily.length < 2) return null;
  final last = daily.last;
  final cut = last.date.subtract(trainingDeltaWindow);
  ({DateTime date, double e1rm})? ref;
  for (final d in daily) {
    if (!d.date.isAfter(cut)) ref = d;
  }
  return ref == null ? null : last.e1rm - ref.e1rm;
}

TrainingProgress trainingProgressOf(
  List<ExerciseProgressPoint> points, {
  required DateTime now,
  required int weekStart,
}) {
  final byExercise = <int, List<ExerciseProgressPoint>>{};
  final names = <int, String>{};
  for (final p in points) {
    byExercise.putIfAbsent(p.exerciseId, () => []).add(p);
    names[p.exerciseId] = p.name;
  }
  List<({DateTime date, double e1rm})> dailyOf(int id) => dailyBestE1rm([
        for (final p in byExercise[id]!)
          ExerciseSetPoint(date: p.date, weightKg: p.weightKg, reps: p.reps),
      ]);

  final top = [
    for (final id in topExerciseIds(points, now))
      () {
        final daily = dailyOf(id);
        return TopExercise(
          exerciseId: id,
          name: names[id]!,
          daily: daily,
          latest: daily.isEmpty ? 0 : daily.last.e1rm,
          delta4w: fourWeekDelta(daily),
        );
      }(),
  ];

  // Rekor: önceki en iyiyi aşan gün (geçmişi olmayan ilk gün rekor değil —
  // record_calc kuralı), son 30 günde.
  final recordSince = _day(now).subtract(trainingRecordWindow);
  final records = <RecordEvent>[];
  for (final id in byExercise.keys) {
    var best = 0.0;
    for (final d in dailyOf(id)) {
      if (best > 0 && d.e1rm > best && !d.date.isBefore(recordSince)) {
        records.add(RecordEvent(
            exerciseId: id, name: names[id]!, date: d.date, e1rm: d.e1rm));
      }
      if (d.e1rm > best) best = d.e1rm;
    }
  }
  records.sort((a, b) => b.date.compareTo(a.date));

  // Haftalık hacim (Σ kg × tekrar).
  final thisWeek = startOfWeek(now, weekStart);
  final weeks = [
    for (var i = trainingVolumeWeeks - 1; i >= 0; i--)
      DateTime(thisWeek.year, thisWeek.month, thisWeek.day - 7 * i),
  ];
  final volume = <DateTime, double>{};
  for (final p in points) {
    final w = startOfWeek(p.date, weekStart);
    if (w.isBefore(weeks.first)) continue;
    volume[w] = (volume[w] ?? 0) + p.weightKg * p.reps;
  }

  final windowStart = _day(now).subtract(trainingTopWindow);
  final trainingDays = {
    for (final p in points)
      if (!p.date.isBefore(windowStart)) _day(p.date),
  }.length;

  return TrainingProgress(
    top: top,
    records: records.take(5).toList(),
    weeklyVolume: [for (final w in weeks) (weekStart: w, volumeKg: volume[w])],
    trainingDays: trainingDays,
  );
}
