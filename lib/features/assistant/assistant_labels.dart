import 'package:flutter/material.dart';
import '../../l10n/app_l10n.dart';
import '../../core/i18n/formatting.dart';
import '../../core/i18n/enum_labels.dart';
import '../../core/units/units.dart';
import '../insights/insight_rules.dart';
import '../insights/insight_window.dart';
import 'assistant_calculator.dart';
import 'assistant_contract.dart';

String queryLabel(AppL10n l, AssistantQuery q) => switch (q) {
  AssistantQuery.workoutSummary => l.assistantQueryWorkoutSummary,
  AssistantQuery.planAdherence => l.assistantQueryPlanAdherence,
  AssistantQuery.strengthProgress => l.assistantQueryStrengthProgress,
  AssistantQuery.exerciseHistory => l.assistantQueryExerciseHistory,
  AssistantQuery.nutritionSummary => l.assistantQueryNutritionSummary,
  AssistantQuery.proteinGoal => l.assistantQueryProteinGoal,
  AssistantQuery.weightTrend => l.assistantQueryWeightTrend,
  AssistantQuery.muscleBalance => l.assistantQueryMuscleBalance,
  AssistantQuery.streak => l.assistantQueryStreak,
  AssistantQuery.todayRemaining => l.assistantQueryTodayRemaining,
  AssistantQuery.topExercises => l.assistantQueryTopExercises,
  AssistantQuery.outOfScope => l.assistantFallback,
};
String assistantPeriodLabel(AppL10n l, InsightPeriod p) => switch (p) {
  InsightPeriod.today => l.assistantPeriodToday,
  InsightPeriod.thisWeek => l.assistantPeriodThisWeek,
  InsightPeriod.lastWeek => l.assistantPeriodLastWeek,
  InsightPeriod.last30Days => l.assistantPeriodLast30Days,
  InsightPeriod.allTime => l.assistantPeriodAllTime,
};
String metricLabel(AppL10n l, AssistantMetricKey k) => switch (k) {
  AssistantMetricKey.sessions => l.assistantMetricSessions,
  AssistantMetricKey.sets => l.assistantMetricSets,
  AssistantMetricKey.minutes => l.assistantMetricMinutes,
  AssistantMetricKey.volume => l.assistantMetricVolume,
  AssistantMetricKey.plannedDays => l.assistantMetricPlannedDays,
  AssistantMetricKey.doneDays => l.assistantMetricDoneDays,
  AssistantMetricKey.loggedDays => l.assistantMetricLoggedDays,
  AssistantMetricKey.completedDays => l.assistantMetricCompletedDays,
  AssistantMetricKey.excludedDays => l.assistantMetricExcludedDays,
  AssistantMetricKey.avgKcal => l.assistantMetricAvgKcal,
  AssistantMetricKey.avgProtein => l.assistantMetricAvgProtein,
  AssistantMetricKey.proteinGoal => l.assistantMetricProteinGoal,
  AssistantMetricKey.hitDays => l.assistantMetricHitDays,
  AssistantMetricKey.measurements => l.assistantMetricMeasurements,
  AssistantMetricKey.firstWeight => l.assistantMetricFirstWeight,
  AssistantMetricKey.lastWeight => l.assistantMetricLastWeight,
  AssistantMetricKey.change => l.assistantMetricChange,
  AssistantMetricKey.weeks => l.assistantMetricWeeks,
  AssistantMetricKey.weeklyGoal => l.assistantMetricWeeklyGoal,
  AssistantMetricKey.remainingKcal => l.assistantMetricRemainingKcal,
  AssistantMetricKey.remainingProtein => l.assistantMetricRemainingProtein,
  AssistantMetricKey.firstE1rm => l.assistantMetricFirstE1rm,
  AssistantMetricKey.lastE1rm => l.assistantMetricLastE1rm,
  AssistantMetricKey.portion => l.assistantMetricPortion,
  AssistantMetricKey.portionKcal => l.assistantMetricPortionKcal,
  AssistantMetricKey.portionProtein => l.assistantMetricPortionProtein,
};
String noteLabel(AppL10n l, CommentNote n) => switch (n) {
  CommentNote.generalGuideline => l.assistantNoteGeneralGuideline,
  CommentNote.consultProfessional => l.assistantNoteConsultProfessional,
  CommentNote.soFar => l.assistantNoteSoFar,
  CommentNote.completedSetsCounted => l.assistantNoteCompletedSetsCounted,
  CommentNote.fastLossCaution => l.assistantNoteFastLossCaution,
  CommentNote.leanMassInfo => l.assistantNoteLeanMassInfo,
  CommentNote.beginnerIntermediateRange =>
    l.assistantNoteBeginnerIntermediateRange,
  CommentNote.loggedOnly => l.assistantNoteLoggedOnly,
  CommentNote.completedDaysOnly => l.assistantNoteCompletedDaysOnly,
  CommentNote.chooseGoalDirection => l.assistantNoteChooseGoalDirection,
};
String commentLabel(BuildContext context, Units units, InsightComment c) {
  final l = AppL10n.of(context);
  String p(String key) {
    final v = c.params[key];
    if (v == null) return l.assistantNotAvailable;
    if (v is DateTime) return context.dateFmt('yMMMd').format(v);
    if (key == 'muscle') return muscleLabel(l, v.toString());
    if (key == 'metric') {
      return metricLabel(l, switch (v) {
        'volume' => AssistantMetricKey.volume,
        'sets' => AssistantMetricKey.sets,
        _ => AssistantMetricKey.sessions,
      });
    }
    if (v is num) {
      final weight =
          {
            'weeklyChangeKg',
            'rangeMinKg',
            'rangeMaxKg',
            'bodyWeightKg',
            'firstE1rm',
            'lastE1rm',
            'topKg',
          }.contains(key) ||
          (c.params['metric'] == 'volume' && {'value', 'median'}.contains(key));
      final fmt = context.numFmt..maximumFractionDigits = 2;
      final number = fmt.format(weight ? units.weightFromKg(v) : v);
      return weight ? '$number ${units.weightUnit}' : number;
    }
    return v.toString();
  }

  return switch (c.key) {
    CommentKey.muscleBelowTen => l.insightMuscleBelowTen(
      p('muscle'),
      p('sets'),
      p('level'),
    ),
    CommentKey.muscleAtTen => l.insightMuscleAtTen(
      p('muscle'),
      p('sets'),
      p('level'),
    ),
    CommentKey.muscleBeyondTwenty => l.insightMuscleBeyondTwenty(
      p('muscle'),
      p('sets'),
      p('limitedEvidenceAbove'),
    ),
    CommentKey.weightNotEnoughData => l.insightWeightNotEnoughData(
      p('count'),
      p('spanDays'),
      p('minDays'),
    ),
    CommentKey.weightAgainstGoal => l.insightWeightAgainstGoal(
      p('weeklyChangeKg'),
    ),
    CommentKey.weightNoClearChange => l.insightWeightNoClearChange(
      p('weeklyChangeKg'),
    ),
    CommentKey.weightLossSlower => l.insightWeightLossSlower(
      p('weeklyChangeKg'),
      p('rangeMinKg'),
      p('rangeMaxKg'),
    ),
    CommentKey.weightLossInRange => l.insightWeightLossInRange(
      p('weeklyChangeKg'),
      p('rangeMinKg'),
      p('rangeMaxKg'),
    ),
    CommentKey.weightLossFaster => l.insightWeightLossFaster(
      p('weeklyChangeKg'),
      p('rangeMinKg'),
      p('rangeMaxKg'),
    ),
    CommentKey.weightGainSlower => l.insightWeightGainSlower(
      p('pctPerWeek'),
      p('rangeMinPct'),
      p('rangeMaxPct'),
    ),
    CommentKey.weightGainInRange => l.insightWeightGainInRange(
      p('pctPerWeek'),
      p('rangeMinPct'),
      p('rangeMaxPct'),
    ),
    CommentKey.weightGainFaster => l.insightWeightGainFaster(
      p('pctPerWeek'),
      p('rangeMinPct'),
      p('rangeMaxPct'),
    ),
    CommentKey.weightStable => l.insightWeightStable(
      p('totalChangePct'),
      p('stablePct'),
    ),
    CommentKey.weightDriftUp => l.insightWeightDriftUp(p('totalChangePct')),
    CommentKey.weightDriftDown => l.insightWeightDriftDown(p('totalChangePct')),
    CommentKey.workoutNotEnoughHistory => l.insightWorkoutNotEnoughHistory(
      p('metric'),
      p('value'),
      p('minWeeks'),
      p('baselineWeeks'),
    ),
    CommentKey.workoutNoBaseline => l.insightWorkoutNoBaseline(
      p('metric'),
      p('value'),
    ),
    CommentKey.workoutSoFar => l.insightWorkoutSoFar(
      p('metric'),
      p('value'),
      p('baselineWeeks'),
      p('median'),
    ),
    CommentKey.workoutAboveMedian => l.insightWorkoutAboveMedian(
      p('metric'),
      p('value'),
      p('median'),
      p('pct'),
    ),
    CommentKey.workoutAtMedian => l.insightWorkoutAtMedian(
      p('metric'),
      p('value'),
      p('median'),
    ),
    CommentKey.workoutBelowMedian => l.insightWorkoutBelowMedian(
      p('metric'),
      p('value'),
      p('median'),
      p('pct'),
    ),
    CommentKey.strengthNotApplicable => l.insightStrengthNotApplicable,
    CommentKey.strengthNotEnoughData => l.insightStrengthNotEnoughData(
      p('days'),
    ),
    CommentKey.strengthUp => l.insightStrengthUp(
      p('firstE1rm'),
      p('lastE1rm'),
      p('pct'),
    ),
    CommentKey.strengthStable => l.insightStrengthStable(
      p('firstE1rm'),
      p('lastE1rm'),
    ),
    CommentKey.strengthDown => l.insightStrengthDown(
      p('firstE1rm'),
      p('lastE1rm'),
      p('pct'),
    ),
    CommentKey.strengthPlateau => l.insightStrengthPlateau(
      p('topKg'),
      p('weeks'),
    ),
    CommentKey.nutritionNoLogs => l.insightNutritionNoLogs,
    CommentKey.proteinGoalDays => l.insightProteinGoalDays(
      p('goal'),
      p('hitDays'),
      p('loggedDays'),
    ),
    CommentKey.kcalVsGoal => l.insightKcalVsGoal(
      p('loggedDays'),
      p('avgKcal'),
      p('goal'),
      p('pctOfGoal'),
    ),
    CommentKey.proteinPerKgBelow => l.insightProteinPerKgBelow(
      p('gPerKg'),
      p('breakpoint'),
      p('bodyWeightKg'),
      p('bodyWeightDate'),
    ),
    CommentKey.proteinPerKgInRange => l.insightProteinPerKgInRange(
      p('gPerKg'),
      p('breakpoint'),
      p('upper'),
      p('bodyWeightKg'),
      p('bodyWeightDate'),
    ),
    CommentKey.proteinPerKgAbove => l.insightProteinPerKgAbove(
      p('gPerKg'),
      p('breakpoint'),
      p('bodyWeightKg'),
      p('bodyWeightDate'),
    ),
    CommentKey.todayNoGoal => l.insightTodayNoGoal(
      p('loggedKcal'),
      p('loggedProtein'),
    ),
    CommentKey.todayRemaining => l.insightTodayRemaining(p('remainingKcal')),
    CommentKey.todayGoalReached => l.insightTodayGoalReached(
      p('remainingKcal'),
    ),
  };
}
