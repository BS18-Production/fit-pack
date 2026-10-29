import '../../data/database/daos/workout_dao.dart';

/// Amaç, haftalık gün hedefinden ayrıdır. Sağlık sonucu garantisi içermez.
enum GoalPurpose { routine, strength, returnToRoutine }

class GoalJourney {
  final GoalPurpose purpose;
  final DateTime startedAt;
  final int? exerciseId;
  final String? reviewedWeek;

  const GoalJourney({
    required this.purpose,
    required this.startedAt,
    this.exerciseId,
    this.reviewedWeek,
  });

  GoalJourney withPurpose(GoalPurpose value) => GoalJourney(
    purpose: value,
    startedAt: startedAt,
    exerciseId: exerciseId,
    reviewedWeek: reviewedWeek,
  );

  GoalJourney withExercise(int value) => GoalJourney(
    purpose: purpose,
    startedAt: startedAt,
    exerciseId: value,
    reviewedWeek: reviewedWeek,
  );

  GoalJourney withReview(String value) => GoalJourney(
    purpose: purpose,
    startedAt: startedAt,
    exerciseId: exerciseId,
    reviewedWeek: value,
  );

  Map<String, Object?> toJson() => {
    'version': 1,
    'purpose': purpose.name,
    'startedAt': startedAt.toIso8601String(),
    'exerciseId': exerciseId,
    'reviewedWeek': reviewedWeek,
  };

  factory GoalJourney.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1 ||
        json['purpose'] is! String ||
        json['startedAt'] is! String ||
        (json['exerciseId'] != null && json['exerciseId'] is! int) ||
        (json['reviewedWeek'] != null && json['reviewedWeek'] is! String)) {
      throw const FormatException('invalid_goal_journey');
    }
    final purpose = GoalPurpose.values.byName(json['purpose'] as String);
    final startedAt = DateTime.parse(json['startedAt'] as String);
    final exerciseId = json['exerciseId'] as int?;
    if (exerciseId != null && exerciseId <= 0) {
      throw const FormatException('invalid_goal_exercise');
    }
    return GoalJourney(
      purpose: purpose,
      startedAt: startedAt,
      exerciseId: exerciseId,
      reviewedWeek: json['reviewedWeek'] as String?,
    );
  }
}

/// İki FARKLI gündeki gerçek çalışma seti. Değişim puanı üretmez.
List<ExerciseProgressPoint> comparisonDays(
  List<ExerciseProgressPoint> points,
  int exerciseId,
) {
  final best = <DateTime, ExerciseProgressPoint>{};
  for (final p in points) {
    if (p.exerciseId != exerciseId || p.weightKg <= 0 || p.reps <= 0) continue;
    final day = DateTime(p.date.year, p.date.month, p.date.day);
    final existing = best[day];
    if (existing == null || p.e1rm! > existing.e1rm!) best[day] = p;
  }
  final days = best.keys.toList()..sort();
  if (days.length < 2) return days.map((d) => best[d]!).toList();
  return [best[days.first]!, best[days.last]!];
}
