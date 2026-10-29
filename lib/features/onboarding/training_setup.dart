import '../explore/program_catalog.dart';
import 'program_recommendation.dart';

enum TrainingPlanSource { catalog, own }

/// Hesaba bağlı cihaz tercihi; sağlık profili veya antrenman reçetesi değil.
class TrainingSetupProfile {
  final TrainingPlanSource planSource;
  final TrainingExperience? experience;
  final int exactDays;
  final int? sessionBudgetMinutes;

  TrainingSetupProfile({
    required this.planSource,
    required this.experience,
    required this.exactDays,
    this.sessionBudgetMinutes,
  }) {
    if (exactDays < 1 || exactDays > 7) {
      throw ArgumentError.value(exactDays, 'exactDays');
    }
    if (planSource == TrainingPlanSource.catalog && experience == null) {
      throw ArgumentError('Katalog önerisi deneyim seçimi gerektirir');
    }
    if (planSource == TrainingPlanSource.own && experience != null) {
      throw ArgumentError('Kendi rutininde deneyim cevabı saklanmaz');
    }
    if (sessionBudgetMinutes != null &&
        !trainingSetupBudgets.contains(sessionBudgetMinutes)) {
      throw ArgumentError.value(sessionBudgetMinutes, 'sessionBudgetMinutes');
    }
  }

  CatalogProgram? get recommendedProgram {
    if (planSource == TrainingPlanSource.own) return null;
    final range = exactDays <= 3
        ? WeeklyDays.twoThree
        : exactDays == 4
        ? WeeklyDays.four
        : WeeklyDays.fiveSix;
    return programByKey(recommendProgram(experience!, range));
  }

  bool get catalogFrequencyMatches =>
      recommendedProgram?.daysPerWeek == exactDays;

  /// Var olan rutin tahminiyle aynı varsayım: set başına 40 sn çalışma +
  /// hedef dinlenme. Isınma, ekipman geçişi ve bekleme dahil değildir.
  List<int> get estimatedRoutineMinutes => [
    for (final routine in recommendedProgram?.routines ?? <CatalogRoutine>[])
      estimateCatalogRoutineMinutes(routine),
  ];

  int? get longestRoutineMinutes {
    final values = estimatedRoutineMinutes;
    return values.isEmpty ? null : values.reduce((a, b) => a > b ? a : b);
  }

  bool get exceedsTimeBudget =>
      sessionBudgetMinutes != null &&
      longestRoutineMinutes != null &&
      longestRoutineMinutes! > sessionBudgetMinutes!;

  Map<String, Object?> toJson() => {
    'version': 1,
    'planSource': planSource.name,
    'experience': planSource == TrainingPlanSource.catalog
        ? experience?.name
        : null,
    'exactDays': exactDays,
    'sessionBudgetMinutes': sessionBudgetMinutes,
  };

  factory TrainingSetupProfile.fromJson(Map<String, dynamic> json) {
    const keys = {
      'version',
      'planSource',
      'experience',
      'exactDays',
      'sessionBudgetMinutes',
    };
    if (json.length != keys.length ||
        !json.keys.every(keys.contains) ||
        json['version'] != 1 ||
        json['exactDays'] is! int ||
        (json['sessionBudgetMinutes'] != null &&
            json['sessionBudgetMinutes'] is! int)) {
      throw const FormatException('Geçersiz antrenman kurulumu');
    }
    try {
      return TrainingSetupProfile(
        planSource: TrainingPlanSource.values.byName(
          json['planSource'] as String,
        ),
        experience: json['experience'] == null
            ? null
            : TrainingExperience.values.byName(json['experience'] as String),
        exactDays: json['exactDays'] as int,
        sessionBudgetMinutes: json['sessionBudgetMinutes'] as int?,
      );
    } on Object {
      throw const FormatException('Geçersiz antrenman kurulumu');
    }
  }
}

const trainingSetupBudgets = [30, 45, 60, 75];

int estimateCatalogRoutineMinutes(CatalogRoutine routine) {
  final seconds = routine.exercises.fold<int>(
    0,
    (total, item) => total + item.sets * (40 + (item.restSec ?? 90)),
  );
  final minutes = (seconds / 60 / 5).round() * 5;
  return minutes < 5 ? 5 : minutes;
}
