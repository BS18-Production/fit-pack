import '../insights/insight_window.dart';

enum AssistantQuery {
  workoutSummary('workout_summary'),
  planAdherence('plan_adherence'),
  strengthProgress('strength_progress'),
  exerciseHistory('exercise_history'),
  nutritionSummary('nutrition_summary'),
  proteinGoal('protein_goal'),
  weightTrend('weight_trend'),
  muscleBalance('muscle_balance'),
  streak('streak'),
  todayRemaining('today_remaining'),
  topExercises('top_exercises'),
  outOfScope('out_of_scope');

  const AssistantQuery(this.id);
  final String id;
  static AssistantQuery parse(Object? id) =>
      values.firstWhere((q) => q.id == id);
  List<InsightPeriod> get periods => switch (this) {
    workoutSummary ||
    planAdherence ||
    nutritionSummary ||
    muscleBalance => const [InsightPeriod.thisWeek, InsightPeriod.lastWeek],
    strengthProgress ||
    proteinGoal ||
    weightTrend => const [InsightPeriod.thisWeek, InsightPeriod.last30Days],
    exerciseHistory => const [InsightPeriod.last30Days, InsightPeriod.allTime],
    topExercises => const [
      InsightPeriod.thisWeek,
      InsightPeriod.last30Days,
      InsightPeriod.allTime,
    ],
    todayRemaining => const [InsightPeriod.today],
    streak => const [InsightPeriod.allTime],
    outOfScope => const [],
  };
}

const assistantContractVersion = 2;
const assistantFingerprint = 'd879f8993e8be890';
const assistantModel = 'gemini-3.5-flash-lite';
const routingPeriods = {
  'today',
  'other_day',
  'this_week',
  'last_week',
  'last_30_days',
  'this_month',
  'last_month',
  'all_time',
  'unspecified',
};
String periodId(InsightPeriod p) => switch (p) {
  InsightPeriod.today => 'today',
  InsightPeriod.thisWeek => 'this_week',
  InsightPeriod.lastWeek => 'last_week',
  InsightPeriod.last30Days => 'last_30_days',
  InsightPeriod.allTime => 'all_time',
};
InsightPeriod? parsePeriod(String id) {
  for (final p in InsightPeriod.values) {
    if (periodId(p) == id) return p;
  }
  return null;
}

class AssistantSelection {
  final AssistantQuery query;
  final InsightPeriod period;
  final int? exerciseId;
  final String? mealType;
  final bool interpretation;
  const AssistantSelection({
    required this.query,
    required this.period,
    this.exerciseId,
    this.mealType,
    this.interpretation = true,
  });
}

enum RoutingDecision { auto, clarify, multi, fallback }

/// Donmuş sekiz alanın tamamı doğrulanır; modele rota/cümle yazdırılmaz.
class AssistantRoute {
  final AssistantQuery query;
  final String period, exercise;
  final bool multiIntent, advice, interpretation, ambiguous;
  final List<AssistantQuery> alternatives;
  const AssistantRoute({
    required this.query,
    required this.period,
    required this.exercise,
    required this.multiIntent,
    required this.advice,
    required this.interpretation,
    required this.ambiguous,
    required this.alternatives,
  });

  factory AssistantRoute.fromJson(
    Map<String, dynamic> j,
    Set<String> exercises,
  ) {
    const keys = {
      'query',
      'period',
      'exercise',
      'multi_intent',
      'advice',
      'wants_interpretation',
      'ambiguous',
      'alternatives',
    };
    if (j.length != keys.length ||
        !j.keys.every(keys.contains) ||
        !routingPeriods.contains(j['period']) ||
        !exercises.contains(j['exercise']) ||
        ![
          'multi_intent',
          'advice',
          'wants_interpretation',
          'ambiguous',
        ].every((k) => j[k] is bool) ||
        j['alternatives'] is! List ||
        (j['alternatives'] as List).length > 2) {
      throw const FormatException('Invalid routing contract');
    }
    return AssistantRoute(
      query: AssistantQuery.parse(j['query']),
      period: j['period'] as String,
      exercise: j['exercise'] as String,
      multiIntent: j['multi_intent'] as bool,
      advice: j['advice'] as bool,
      interpretation: j['wants_interpretation'] as bool,
      ambiguous: j['ambiguous'] as bool,
      alternatives: (j['alternatives'] as List)
          .map(AssistantQuery.parse)
          .toList(),
    );
  }
}
