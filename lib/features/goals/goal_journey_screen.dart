import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/formatting.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/units/units.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/glass.dart';
import '../home/providers/weekly_goal_provider.dart';
import '../home/today_task.dart';
import '../insights/weekly_review_providers.dart';
import '../onboarding/training_setup_providers.dart';
import '../workout/routine_providers.dart';
import 'goal_journey.dart';
import 'goal_journey_providers.dart';

String purposeLabel(AppL10n l, GoalPurpose purpose) => switch (purpose) {
  GoalPurpose.routine => l.goalPurposeRoutine,
  GoalPurpose.strength => l.goalPurposeStrength,
  GoalPurpose.returnToRoutine => l.goalPurposeReturn,
};

/// Yeni sekme yerine Home ve Hafta'dan açılan, cihaz içi hedef yolculuğu.
class GoalJourneyScreen extends ConsumerStatefulWidget {
  const GoalJourneyScreen({super.key});
  @override
  ConsumerState<GoalJourneyScreen> createState() => _GoalJourneyScreenState();
}

class _GoalJourneyScreenState extends ConsumerState<GoalJourneyScreen> {
  late final String? _owner;
  late final int _ownerGeneration;
  late final ProviderSubscription<String?> _ownerSubscription;
  bool _accountChanged = false;
  bool get _ownsEditor =>
      !_accountChanged &&
      _owner != null &&
      ref.read(weeklyGoalAccountProvider) == _owner &&
      ref.read(goalJourneyProvider.notifier).generation == _ownerGeneration;

  @override
  void initState() {
    super.initState();
    _owner = ref.read(weeklyGoalAccountProvider);
    _ownerGeneration = ref.read(goalJourneyProvider.notifier).generation;
    _ownerSubscription = ref.listenManual(weeklyGoalAccountProvider, (_, next) {
      if (next != _owner) _accountChanged = true;
    });
  }

  @override
  void dispose() {
    _ownerSubscription.close();
    super.dispose();
  }

  bool _busy = false;
  bool _recordsAccurate = false;
  DateTime? _reviewPeriodStart;
  bool _timeObstacle = false;

  Future<void> _save(Future<void> Function() action) async {
    if (_busy || !_ownsEditor) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final l = AppL10n.of(context);
    try {
      await action();
      if (mounted && _ownsEditor) {
        messenger.showSnackBar(SnackBar(content: Text(l.commonSaved)));
      }
    } catch (_) {
      if (mounted && _ownsEditor) {
        messenger.showSnackBar(SnackBar(content: Text(l.commonSaveFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final account = ref.watch(weeklyGoalAccountProvider);
    if (account != _owner || !_ownsEditor) {
      return Scaffold(
        appBar: AppBar(title: Text(l.goalTitle)),
        body: ErrorState(
          message: l.goalAccountChanged,
          onRetry: () => context.go(AppRoutes.home),
        ),
      );
    }
    final journey = ref.watch(goalJourneyProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.goalTitle)),
      body: journey.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorState(
          message: l.goalLoadError,
          onRetry: () {
            ref.invalidate(goalJourneyPreferencesProvider);
            ref.invalidate(goalJourneyProvider);
          },
        ),
        data: (j) => ListView(
          padding: AppSpacing.screen,
          children: [
            _GoalCard(
              title: l.goalWhyTitle,
              children: [
                Text(l.goalWhyDescription),
                AppSpacing.vGapMd,
                for (final purpose in GoalPurpose.values)
                  ChoiceChip(
                    label: Text(purposeLabel(l, purpose)),
                    selected: j?.purpose == purpose,
                    onSelected: _busy
                        ? null
                        : (_) {
                            final value = purpose;
                            _save(
                              () => ref
                                  .read(goalJourneyProvider.notifier)
                                  .save(
                                    j?.withPurpose(value) ??
                                        GoalJourney(
                                          purpose: value,
                                          startedAt: DateTime.now(),
                                        ),
                                    expectedAccount: _owner,
                                    expectedGeneration: _ownerGeneration,
                                  ),
                            );
                          },
                  ),
                Text(l.goalLocalOnly, style: context.texts.bodySmall),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _baseline(j),
            AppSpacing.vGapLg,
            _route(),
            AppSpacing.vGapLg,
            _nextAction(),
            if (j != null) ...[
              AppSpacing.vGapLg,
              _milestones(j),
              AppSpacing.vGapLg,
              _reflection(j),
            ],
            AppSpacing.vGapLg,
            _GoalCard(
              title: l.goalFlexTitle,
              children: [
                Text(l.goalFlexDescription),
                AppSpacing.vGapSm,
                Text(l.goalHealthBoundary, style: context.texts.bodySmall),
                TextButton(
                  onPressed: () => context.push(AppRoutes.notifications),
                  child: Text(l.goalReminderSettings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _baseline(GoalJourney? j) {
    final l = AppL10n.of(context);
    final evidence = ref.watch(goalEvidenceProvider);
    return _GoalCard(
      title: l.goalBaselineTitle,
      children: [
        evidence.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text(l.goalLoadError),
          data: (e) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.baselineSessions.isEmpty
                    ? (e.sessions.isNotEmpty ? l.goalRecordedStart : l.goalNoBaseline)
                    : l.goalBaselineCount(e.baselineTrainingDays),
              ),
              AppSpacing.vGapSm,
              Text(l.goalRecordsScope, style: context.texts.bodySmall),
              if (j?.purpose == GoalPurpose.strength &&
                  e.exercises.isNotEmpty) ...[
                AppSpacing.vGapMd,
                DropdownButton<int>(
                  value: e.exercises.containsKey(j?.exerciseId)
                      ? j?.exerciseId
                      : null,
                  isExpanded: true,
                  hint: Text(l.goalChooseExercise),
                  items: e.exercises.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (id) {
                          if (id != null && j != null) {
                            _save(
                              () => ref
                                  .read(goalJourneyProvider.notifier)
                                  .save(
                                    j.withExercise(id),
                                    expectedAccount: _owner,
                                    expectedGeneration: _ownerGeneration,
                                  ),
                            );
                          }
                        },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _route() {
    final l = AppL10n.of(context);
    final target = ref.watch(currentWeeklyTargetProvider);
    final next = ref.watch(nextWeeklyTargetProvider);
    final routines = ref.watch(activeRoutinesProvider);
    final setup = ref.watch(trainingSetupProfileProvider).valueOrNull;
    return _GoalCard(
      title: l.goalRouteTitle,
      children: [
        target.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text(l.goalLoadError),
          data: (p) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.targetKnown
                    ? l.goalWeeklyDays(p.targetDays!)
                    : l.goalTargetUnknown,
                style: context.texts.titleMedium,
              ),
              if (p.targetEffectiveFrom != null)
                Text(
                  l.goalEffectiveFrom(
                    context.dateFmt('yMMMd').format(p.targetEffectiveFrom!),
                  ),
                ),
            ],
          ),
        ),
        if (setup?.sessionBudgetMinutes != null) ...[
          AppSpacing.vGapSm,
          Text(l.goalTimeBudget(setup!.sessionBudgetMinutes!)),
        ],
        AppSpacing.vGapSm,
        routines.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text(l.goalLoadError),
          data: (rs) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(rs.isEmpty ? l.goalNoRoute : rs.map((r) => r.name).join(' · ')),
            if (setup?.recommendedProgram != null &&
                !rs.any((r) => r.programKey == setup!.recommendedProgram!.key)) ...[
              AppSpacing.vGapSm,
              Text(l.goalSetupRecovery),
              TextButton(onPressed: () => context.push(AppRoutes.program(setup!.recommendedProgram!.key)),
                child: Text(l.goalCompleteRoute)),
            ],
          ]),
        ),
        AppSpacing.vGapSm,
        Text(l.goalRouteExplanation, style: context.texts.bodySmall),
        next.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (p) => TextButton(
            onPressed: _busy ? null : () => _chooseTarget(p.targetDays),
            child: Text(l.goalChooseNextWeek),
          ),
        ),
      ],
    );
  }

  Future<void> _chooseTarget(int? current) async {
    if (!_ownsEditor) return;
    final l = AppL10n.of(context);
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.goalChooseNextWeek, style: context.texts.titleLarge),
              AppSpacing.vGapSm,
              Text(l.goalNextWeekOnly),
              AppSpacing.vGapMd,
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (var n = 1; n <= 7; n++)
                    ChoiceChip(
                      label: Text('$n'),
                      selected: current == n,
                      onSelected: (_) => Navigator.pop(sheetContext, n),
                    ),
                ],
              ),
              AppSpacing.vGapMd,
            ],
          ),
        ),
      ),
    );
    if (selected == null || !mounted || !_ownsEditor) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.goalConfirmTitle),
        content: Text(l.goalConfirmNextWeek(selected)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.commonSave),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted || !_ownsEditor) return;
    await _save(
      () => ref
          .read(selectedWeeklyGoalProvider.notifier)
          .scheduleGoal(selected, expectedAccount: _owner),
    );
  }

  Widget _nextAction() {
    final l = AppL10n.of(context);
    final task = ref.watch(todayTaskProvider);
    final resume = task.kind == TodayTaskKind.resume;
    return _GoalCard(
      title: l.goalTodayTitle,
      children: [
        Text(
          resume
              ? l.goalResumeAction
              : task.kind == TodayTaskKind.finishedToday
              ? l.goalTodayRecorded
              : task.routine?.name ?? l.goalTodayDescription,
        ),
        AppSpacing.vGapMd,
        FilledButton.icon(
          onPressed: () {
            if (resume) {
              context.push(AppRoutes.workoutActiveResume);
              return;
            }
            if (task.kind == TodayTaskKind.finishedToday &&
                task.session != null) {
              context.push(AppRoutes.summary(task.session!.id));
              return;
            }
            if (task.routine != null) {
              context.push(AppRoutes.routinePreview(task.routine!.id));
              return;
            }
            context.go(AppRoutes.workout);
          },
          icon: Icon(
            resume ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded,
          ),
          label: Text(resume ? l.goalResumeAction : l.goalOpenNextAction),
        ),
      ],
    );
  }

  Widget _milestones(GoalJourney j) {
    final l = AppL10n.of(context);
    final e = ref.watch(goalEvidenceProvider).valueOrNull;
    final points = e == null || j.exerciseId == null
        ? null
        : comparisonDays(e.points, j.exerciseId!);
    final units = ref.watch(unitsProvider);
    return _GoalCard(
      title: l.goalMilestonesTitle,
      children: [
        _step(l.goalMilestoneStart, e?.sessions.isNotEmpty ?? false),
        if (j.purpose == GoalPurpose.strength) ...[
          _step(l.goalMilestoneCompare, points != null && points.length >= 2),
          if (points != null && points.length >= 2) ...[
            for (final p in points)
              Text(
                '${context.dateFmt('yMMMd').format(p.date)} · '
                '${units.weight(p.weightKg)} × ${context.numFmt.format(p.reps)}',
              ),
            Text(l.goalComparisonBoundary, style: context.texts.bodySmall),
          ] else
            Text(l.goalNeedComparison),
        ] else ...[
          Text(
            j.purpose == GoalPurpose.returnToRoutine
                ? l.goalReturnEvidence
                : l.goalRhythmEvidence,
          ),
        ],
        _step(l.goalMilestoneReview, j.reviewedWeek != null),
      ],
    );
  }

  Widget _step(String label, bool done) {
    final l = AppL10n.of(context);
    return Semantics(
      label: '$label. ${done ? l.goalStepDone : l.goalStepPending}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(children: [
          Icon(done ? Icons.check_circle_rounded : Icons.circle_outlined),
          AppSpacing.hGapMd, Expanded(child: Text(label)),
        ]),
      ),
    );
  }

  Widget _reflection(GoalJourney j) {
    final l = AppL10n.of(context);
    final review = ref.watch(weeklyReviewProvider(1));
    return _GoalCard(
      title: l.goalReflectionTitle,
      children: [
        review.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text(l.goalLoadError),
          data: (r) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.goalRecordedDays(r.workout.trainingDays)),
              Text(
                r.workout.targetKnown && r.workout.targetCoversWholePeriod
                    ? l.goalWeeklyDays(r.workout.planned!)
                    : l.goalPastTargetUnknown,
              ),
              AppSpacing.vGapSm,
              Text(l.goalRecordsScope, style: context.texts.bodySmall),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.goalRecordsAccurate),
                value: _recordsAccurate && _reviewPeriodStart == r.period.start,
                onChanged: _busy
                    ? null
                    : (v) => setState(() {
                        _recordsAccurate = v ?? false;
                        _reviewPeriodStart = r.period.start;
                        _timeObstacle = false;
                      }),
              ),
              if (_recordsAccurate && _reviewPeriodStart == r.period.start) ...[
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.goalTimeObstacle),
                  value: _timeObstacle,
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _timeObstacle = v ?? false),
                ),
                if (_timeObstacle) ...[
                  Text(l.goalTimeReason(r.workout.trainingDays)),
                  if (r.workout.targetKnown &&
                      r.workout.targetCoversWholePeriod &&
                      r.workout.trainingDays > 0 &&
                      r.workout.trainingDays < r.workout.planned!)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _chooseTarget(r.workout.trainingDays),
                      child: Text(l.goalSuggestDays(r.workout.trainingDays)),
                    ),
                ],
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _save(
                          () => ref
                              .read(goalJourneyProvider.notifier)
                              .save(
                                j.withReview(r.period.start.toIso8601String()),
                                expectedAccount: _owner,
                                expectedGeneration: _ownerGeneration,
                              ),
                        ),
                  child: Text(l.goalMarkReviewed),
                ),
              ] else
                TextButton(
                  onPressed: () => context.push(AppRoutes.workoutLogPast),
                  child: Text(l.goalAddMissingRecord),
                ),
              TextButton(
                onPressed: () =>
                    context.push(AppRoutes.weeklyReviewWeeksBack(1)),
                child: Text(l.goalOpenWeek),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _GoalCard({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.texts.titleLarge),
        AppSpacing.vGapMd,
        ...children,
      ],
    ),
  );
}

class GoalJourneyEntryCard extends ConsumerWidget {
  const GoalJourneyEntryCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final async = ref.watch(goalJourneyProvider);
    final j = async.isLoading ? null : async.valueOrNull;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: GlassCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.route_rounded),
          title: Text(
            j == null ? l.goalEntryTitle : purposeLabel(l, j.purpose),
          ),
          subtitle: Text(l.goalEntryDescription),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push(AppRoutes.goalJourney),
        ),
      ),
    );
  }
}
