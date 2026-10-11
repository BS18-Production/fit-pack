import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/i18n/enum_labels.dart';
import '../../core/i18n/formatting.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/units/units.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/glass.dart';
import '../insights/insight_queries.dart';
import '../insights/insight_rules.dart';
import 'assistant_calculator.dart';
import 'assistant_contract.dart';
import 'assistant_labels.dart';

class AssistantAnswerCard extends ConsumerWidget {
  final AssistantAnswer answer;
  final VoidCallback onChange;
  const AssistantAnswerCard({
    super.key,
    required this.answer,
    required this.onChange,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context),
        units = ref.watch(unitsProvider),
        s = answer.selection;
    final window = answer.window;
    final end = DateTime(window.end.year, window.end.month, window.end.day - 1);
    final range =
        '${window.start == null ? l.assistantUnknownStart : context.dateFmt('yMMMd').format(window.start!)} · ${context.dateFmt('yMMMd').format(end)}';
    final route = switch (answer.destination) {
      AssistantDestination.workout => AppRoutes.workoutHistory,
      AssistantDestination.nutrition => AppRoutes.nutrition,
      AssistantDestination.progress => AppRoutes.progress,
      AssistantDestination.exercise =>
        s.exerciseId == null
            ? AppRoutes.exercises
            : AppRoutes.exerciseDetail(s.exerciseId!),
    };
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.assistantUnderstood,
            style: context.texts.labelLarge?.copyWith(
              color: context.colors.primary,
            ),
          ),
          AppSpacing.vGapSm,
          Text(queryLabel(l, s.query), style: context.texts.titleLarge),
          TextButton(onPressed: onChange, child: Text(l.assistantChange)),
          Text(
            '${assistantPeriodLabel(l, s.period)} · $range',
            style: context.texts.bodySmall,
          ),
          Text(
            l.assistantRecords(context.numFmt.format(answer.records)),
            style: context.texts.bodySmall,
          ),
          if (!window.isComplete)
            Text(l.assistantSoFar, style: context.texts.labelMedium),
          AppSpacing.vGapLg,
          if (answer.status != AssistantDataStatus.ready)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(switch (answer.status) {
                AssistantDataStatus.noData => l.assistantNoData,
                AssistantDataStatus.insufficientData => l.assistantInsufficient,
                AssistantDataStatus.noGoal => l.assistantNoGoal,
                AssistantDataStatus.noPlan => l.assistantNoPlan,
                AssistantDataStatus.incompleteDays => l.assistantIncompleteDays,
                _ => '',
              }),
            ),
          if (answer.nutritionBasis != null)
            Text(
              answer.nutritionBasis == NutritionBasis.completedDays
                  ? l.assistantCompletedBasis
                  : l.assistantLoggedBasis,
            ),
          if (s.query == AssistantQuery.planAdherence ||
              s.query == AssistantQuery.streak)
            Text(l.assistantCurrentPlan, style: context.texts.bodySmall),
          if (s.query == AssistantQuery.todayRemaining && s.mealType != null)
            Text(l.assistantFoodBasis, style: context.texts.bodySmall),
          if (answer.status != AssistantDataStatus.noData) ...[
            for (final metric in answer.metrics)
              _MetricRow(metric: metric, units: units),
            for (final detail in answer.details)
              Padding(
                key: ValueKey(detail.exerciseId ?? detail.name),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      s.query == AssistantQuery.muscleBalance
                          ? muscleLabel(l, detail.name)
                          : detail.name.isEmpty
                          ? l.assistantUnknownExercise
                          : detail.name,
                      style: context.texts.titleMedium,
                    ),
                    for (final m in detail.metrics)
                      _MetricRow(metric: m, units: units),
                    for (final c in detail.comments)
                      _CommentCard(comment: c, units: units),
                  ],
                ),
              ),
            for (final c in answer.comments)
              _CommentCard(comment: c, units: units),
          ],
          AppSpacing.vGapLg,
          OutlinedButton(
            onPressed: () =>
                answer.destination == AssistantDestination.nutrition ||
                    answer.destination == AssistantDestination.progress
                ? context.go(route)
                : context.push(route),
            child: Text(l.assistantOpenRecords),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final AssistantMetric metric;
  final Units units;
  const _MetricRow({required this.metric, required this.units});
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context), v = metric.value;
    final fmt = context.numFmt..maximumFractionDigits = 1;
    final value = v == null
        ? '—'
        : fmt.format(
            metric.unit == AssistantUnit.kilograms ? units.weightFromKg(v) : v,
          );
    final suffix = switch (metric.unit) {
      AssistantUnit.kilograms => units.weightUnit,
      AssistantUnit.kcal => 'kcal',
      AssistantUnit.grams => 'g',
      AssistantUnit.minutes => l.unitMinShort,
      _ => '',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metricLabel(l, metric.key), style: context.texts.labelMedium),
          Text(
            '$value${v == null || suffix.isEmpty ? '' : ' $suffix'}',
            style: context.texts.titleLarge,
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final InsightComment comment;
  final Units units;
  const _CommentCard({required this.comment, required this.units});
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context), c = comment;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (c.basis != CommentBasis.none)
            Text(
              c.basis == CommentBasis.guideline
                  ? l.assistantGuideline
                  : l.assistantOwnHistory,
              style: context.texts.labelLarge?.copyWith(
                color: context.colors.primary,
              ),
            ),
          Text(commentLabel(context, units, c)),
          for (final n in c.notes)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(noteLabel(l, n), style: context.texts.bodySmall),
            ),
          if (c.sources.isNotEmpty)
            Text(l.assistantSources, style: context.texts.labelMedium),
          for (final source in c.sources)
            TextButton(
              onPressed: () async {
                try {
                  if (!await launchUrl(
                    Uri.parse(_sourceUrl(source)),
                    mode: LaunchMode.externalApplication,
                  )) {
                    throw StateError('launch');
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.assistantUnavailable)),
                    );
                  }
                }
              },
              child: Text(source.citation),
            ),
        ],
      ),
    );
  }
}

String _sourceUrl(EvidenceSource source) => switch (source) {
  EvidenceSource.schoenfeld2017 =>
    'https://doi.org/10.1080/02640414.2016.1210197',
  EvidenceSource.cdcWeightLoss =>
    'https://www.cdc.gov/healthy-weight-growth/losing-weight/index.html',
  EvidenceSource.garthe2011 => 'https://pubmed.ncbi.nlm.nih.gov/21558571/',
  EvidenceSource.iraki2019 => 'https://doi.org/10.3390/sports7070154',
  EvidenceSource.morton2018 => 'https://doi.org/10.1136/bjsports-2017-097608',
};
