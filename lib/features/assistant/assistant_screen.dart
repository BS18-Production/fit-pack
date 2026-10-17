import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/i18n/formatting.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/database/app_database.dart';
import '../../data/providers.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/glass.dart';
import '../cloud/auth_service.dart';
import 'assistant_answer_card.dart';
import 'assistant_calculator.dart';
import 'assistant_contract.dart';
import 'assistant_labels.dart';
import 'assistant_providers.dart';
import 'assistant_remote.dart';
import 'assistant_routing.dart';
import 'assistant_selection_sheet.dart';

class AssistantEntryCard extends StatelessWidget {
  const AssistantEntryCard({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: GlassCard(
        onTap: () => context.push(AppRoutes.assistant),
        child: Row(
          children: [
            Icon(
              Icons.query_stats_rounded,
              color: context.colors.primary,
              size: AppIconSize.lg,
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.assistantTitle, style: context.texts.titleMedium),
                  Text(l.assistantSubtitle, style: context.texts.bodySmall),
                ],
              ),
            ),
            AppSpacing.hGapSm,
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});
  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _question = TextEditingController();
  bool _busy = false, _all = false;
  int _epoch = 0;
  AssistantSelection? _selection;
  AssistantSelection? _originalSelection;
  String? _eventId, _message;
  AssistantRoute? _multi;
  @override
  void dispose() {
    _epoch++;
    _question.dispose();
    super.dispose();
  }

  bool _valid(int epoch, String? owner) =>
      mounted && epoch == _epoch && ref.read(currentUserProvider)?.id == owner;
  Future<void> _record({
    required String id,
    required String source,
    required String decision,
    AssistantRoute? route,
    AssistantSelection? selection,
    AssistantEnvelope? envelope,
    String? error,
    String outcome = 'completed',
  }) async {
    final owner = ref.read(currentUserProvider)?.id;
    if (owner == null) return;
    try {
      await ref
          .read(databaseProvider)
          .assistantQualityDao
          .record(
            AssistantQualityEventsCompanion.insert(
              eventId: id,
              ownerId: owner,
              occurredAt: DateTime.now(),
              source: source,
              decision: decision,
              outcome: Value(outcome),
              model: Value(source == 'free' ? assistantModel : null),
              fingerprint: Value(
                source == 'free' ? assistantFingerprint : null,
              ),
              queryId: Value(route?.query.id ?? selection?.query.id),
              periodId: Value(
                route?.period ??
                    (selection == null ? null : periodId(selection.period)),
              ),
              exerciseType: Value(
                route == null
                    ? (selection?.exerciseId == null ? 'none' : 'local')
                    : route.exercise.startsWith('fam_')
                    ? 'family'
                    : route.exercise == 'none'
                    ? 'none'
                    : 'exact',
              ),
              wantsInterpretation: Value(
                route?.interpretation ?? selection?.interpretation ?? false,
              ),
              ambiguous: Value(route?.ambiguous ?? false),
              latencyMs: Value(envelope?.latencyMs),
              inputTokens: Value(envelope?.inputTokens),
              outputTokens: Value(envelope?.outputTokens),
              errorCode: Value(error),
            ),
            DateTime.now(),
          );
      if (mounted && ref.read(currentUserProvider)?.id == owner) _eventId = id;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppL10n.of(context).assistantQualityUnavailable),
          ),
        );
      }
    }
  }

  Future<void> _ready(AssistantQuery query, AssistantData data) async {
    final owner = ref.read(currentUserProvider)?.id, epoch = ++_epoch;
    final picked = await pickAssistantSelection(
      context,
      AssistantSelection(query: query, period: query.periods.first),
      data,
    );
    if (!_valid(epoch, owner)) return;
    if (picked == null) {
      await _record(
        id: const Uuid().v4(),
        source: 'ready',
        decision: 'ready',
        selection: AssistantSelection(
          query: query,
          period: query.periods.first,
        ),
        outcome: 'cancelled',
      );
      return;
    }
    setState(() {
      _selection = picked;
      _originalSelection = picked;
      _message = null;
      _multi = null;
      _eventId = null;
    });
    await _record(
      id: const Uuid().v4(),
      source: 'ready',
      decision: 'ready',
      selection: picked,
    );
  }

  Future<void> _correct(
    AssistantData data, {
    AssistantSelection? initial,
    bool clarified = false,
  }) async {
    final old = _originalSelection ?? _selection,
        owner = ref.read(currentUserProvider)?.id,
        epoch = _epoch,
        id = _eventId;
    final picked = await pickAssistantSelection(context, initial ?? old!, data);
    if (!_valid(epoch, owner)) return;
    if (picked == null) {
      if (clarified && id != null && owner != null) {
        try {
          await ref
              .read(databaseProvider)
              .assistantQualityDao
              .finish(id, owner, 'cancelled');
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppL10n.of(context).assistantQualityUnavailable),
              ),
            );
          }
        }
      }
      return;
    }
    setState(() {
      _selection = picked;
      _message = null;
      _multi = null;
    });
    if (id != null && owner != null) {
      try {
        await ref
            .read(databaseProvider)
            .assistantQualityDao
            .correct(
              eventId: id,
              ownerId: owner,
              queryId: picked.query.id,
              periodId: periodId(picked.period),
              exerciseChanged: old?.exerciseId != picked.exerciseId,
              clarified: clarified,
            );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppL10n.of(context).assistantQualityUnavailable),
            ),
          );
        }
      }
    }
  }

  Future<bool> _consent(String owner) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'assistant_gemini_consent_v2_$owner';
    if (prefs.getBool(key) == true) return true;
    if (!mounted) return false;
    final l = AppL10n.of(context);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.assistantPrivacyTitle),
        content: SingleChildScrollView(child: Text(l.assistantPrivacy)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.assistantPrivacyCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.assistantPrivacyAccept),
          ),
        ],
      ),
    );
    if (accepted != true ||
        !mounted ||
        ref.read(currentUserProvider)?.id != owner) {
      return false;
    }
    await prefs.setBool(key, true);
    return true;
  }

  AssistantSelection _fromRoute(
    AssistantRoute route,
    AssistantData data,
    FrozenAssistantRouter router, {
    AssistantQuery? query,
  }) {
    final q = query ?? route.query;
    final proposed = parsePeriod(route.period);
    final period = proposed != null && q.periods.contains(proposed)
        ? proposed
        : q.periods.first;
    final candidates = router.candidates(route.exercise, data.exercises.values);
    final frequency = <int, int>{};
    for (final sets in data.sets.values) {
      for (final s in sets) {
        if (s.isComplete && !s.isWarmup) {
          frequency[s.exerciseId] = (frequency[s.exerciseId] ?? 0) + 1;
        }
      }
    }
    candidates.sort((a, b) {
      final n = (frequency[b.id] ?? 0).compareTo(frequency[a.id] ?? 0);
      return n != 0 ? n : a.id.compareTo(b.id);
    });
    return AssistantSelection(
      query: q,
      period: period,
      interpretation: route.interpretation,
      exerciseId:
          q == AssistantQuery.exerciseHistory &&
              candidates.isNotEmpty &&
              (frequency[candidates.first.id] ?? 0) > 0
          ? candidates.first.id
          : null,
    );
  }

  Future<void> _ask(AssistantData data) async {
    final question = _question.text.trim();
    if (_busy || question.isEmpty) return;
    final l = AppL10n.of(context), owner = ref.read(currentUserProvider)?.id;
    final epoch = ++_epoch, id = const Uuid().v4();
    setState(() {
      _selection = null;
      _originalSelection = null;
      _multi = null;
      _message = null;
      _eventId = null;
      _busy = true;
    });
    try {
      if (owner == null) {
        setState(() => _message = l.assistantSignedOut);
        return;
      }
      if (assistantPrefilter(question) || assistantSensitiveInput(question)) {
        setState(
          () => _message = assistantSensitiveInput(question)
              ? l.assistantPrivateBlocked
              : l.assistantFallback,
        );
        await _record(
          id: id,
          source: 'free',
          decision: 'fallback',
          error: assistantSensitiveInput(question)
              ? 'private_input'
              : 'prefilter',
        );
        return;
      }
      if (!await _consent(owner) || !_valid(epoch, owner)) return;
      final router = await ref.read(assistantRouterProvider.future);
      if (!_valid(epoch, owner)) return;
      final envelope = await ref
          .read(assistantRemoteProvider)
          .route(question, id, router);
      if (!_valid(epoch, owner)) return;
      final route = envelope.route;
      final decision = router.decide(
        route,
        question,
        localNames: data.exercises.values.map((e) => e.name),
      );
      await _record(
        id: id,
        source: 'free',
        decision: decision.name,
        route: route,
        envelope: envelope,
        outcome:
            decision == RoutingDecision.clarify ||
                decision == RoutingDecision.multi
            ? 'pending'
            : 'completed',
      );
      if (!_valid(epoch, owner)) return;
      switch (decision) {
        case RoutingDecision.fallback:
          setState(() => _message = l.assistantFallback);
        case RoutingDecision.multi:
          setState(() {
            _multi = route;
            _message = l.assistantMulti;
          });
        case RoutingDecision.clarify:
          setState(() => _message = l.assistantClarify);
          await _correct(
            data,
            initial: _fromRoute(route, data, router),
            clarified: true,
          );
        case RoutingDecision.auto:
          setState(() {
            _selection = _fromRoute(route, data, router);
            _originalSelection = _selection;
          });
      }
    } on AssistantRemoteError catch (e) {
      if (!_valid(epoch, owner)) return;
      setState(
        () => _message = e.resetAt == null
            ? l.assistantUnavailable
            : l.assistantQuota(
                context.dateFmt('yMMMd HH:mm').format(e.resetAt!.toLocal()),
              ),
      );
      await _record(id: id, source: 'free', decision: 'error', error: e.code);
    } catch (_) {
      if (!_valid(epoch, owner)) return;
      setState(() => _message = l.assistantUnavailable);
      await _record(
        id: id,
        source: 'free',
        decision: 'error',
        error: 'unavailable',
      );
    } finally {
      if (_valid(epoch, owner)) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context), data = ref.watch(assistantDataProvider);
    ref.listen(currentUserProvider, (previous, next) {
      if (previous?.id != next?.id) {
        _epoch++;
        _question.clear();
        setState(() {
          _selection = null;
          _originalSelection = null;
          _eventId = null;
          _message = null;
          _multi = null;
          _busy = false;
        });
      }
    });
    final d = data.isLoading ? null : data.valueOrNull;
    final questions = const [
      AssistantQuery.workoutSummary,
      AssistantQuery.planAdherence,
      AssistantQuery.strengthProgress,
      AssistantQuery.nutritionSummary,
      AssistantQuery.proteinGoal,
      AssistantQuery.weightTrend,
      AssistantQuery.muscleBalance,
      AssistantQuery.todayRemaining,
      AssistantQuery.exerciseHistory,
      AssistantQuery.streak,
      AssistantQuery.topExercises,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.assistantTitle)),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            Text(l.assistantSubtitle, style: context.texts.bodyLarge),
            AppSpacing.vGapLg,
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _question,
                    maxLength: 500,
                    minLines: 1,
                    maxLines: 3,
                    enabled: !_busy,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (d != null) _ask(d);
                    },
                    decoration: InputDecoration(
                      hintText: l.assistantQuestionHint,
                    ),
                  ),
                  AppSpacing.vGapSm,
                  FilledButton.icon(
                    onPressed: _busy || d == null ? null : () => _ask(d),
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: AppIconSize.sm,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward_rounded),
                    label: Text(l.assistantAsk),
                  ),
                  TextButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: Text(l.assistantPrivacyTitle),
                        content: SingleChildScrollView(
                          child: Text(l.assistantPrivacy),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c),
                            child: Text(l.commonClose),
                          ),
                        ],
                      ),
                    ),
                    child: Text(l.assistantPrivacyTitle),
                  ),
                ],
              ),
            ),
            if (_message != null) ...[
              AppSpacing.vGapLg,
              Text(_message!, style: context.texts.bodyMedium),
            ],
            if (_multi != null && d != null) ...[
              AppSpacing.vGapMd,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final q in {
                    _multi!.query,
                    ..._multi!.alternatives,
                  }.where((q) => q != AssistantQuery.outOfScope).take(3))
                    ActionChip(
                      label: Text(queryLabel(l, q)),
                      onPressed: () async {
                        final r = await ref.read(
                          assistantRouterProvider.future,
                        );
                        if (mounted) {
                          await _correct(
                            d,
                            initial: _fromRoute(_multi!, d, r, query: q),
                            clarified: true,
                          );
                        }
                      },
                    ),
                ],
              ),
            ],
            if (data.hasError) ...[
              AppSpacing.vGapLg,
              Text(l.assistantError),
              TextButton(
                onPressed: () => ref.invalidate(assistantSnapshotProvider),
                child: Text(l.assistantRetry),
              ),
            ],
            if (data.isLoading) ...[
              AppSpacing.vGapLg,
              const Center(child: CircularProgressIndicator()),
            ],
            if (_selection != null && d != null) ...[
              AppSpacing.vGapLg,
              AssistantAnswerCard(
                answer: calculateAssistant(_selection!, d),
                onChange: () => _correct(d),
              ),
            ],
            AppSpacing.vGapXl,
            Text(l.assistantReady, style: context.texts.titleLarge),
            AppSpacing.vGapMd,
            for (final q in questions.take(_all ? questions.length : 8))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: GlassCard(
                  key: ValueKey(q),
                  onTap: _busy || d == null ? null : () => _ready(q, d),
                  child: Row(
                    children: [
                      Icon(
                        _queryIcon(q),
                        color: context.colors.primary,
                        size: AppIconSize.md,
                      ),
                      AppSpacing.hGapMd,
                      Expanded(
                        child: Text(
                          queryLabel(l, q),
                          style: context.texts.titleSmall,
                        ),
                      ),
                      AppSpacing.hGapSm,
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            TextButton(
              onPressed: () => setState(() => _all = !_all),
              child: Text(_all ? l.assistantLess : l.assistantAll),
            ),
            SizedBox(height: context.bottomScrollInset),
          ],
        ),
      ),
    );
  }
}

IconData _queryIcon(AssistantQuery q) => switch (q) {
  AssistantQuery.workoutSummary ||
  AssistantQuery.planAdherence => Icons.fitness_center_rounded,
  AssistantQuery.strengthProgress ||
  AssistantQuery.exerciseHistory => Icons.trending_up_rounded,
  AssistantQuery.nutritionSummary ||
  AssistantQuery.proteinGoal ||
  AssistantQuery.todayRemaining => Icons.restaurant_rounded,
  AssistantQuery.weightTrend => Icons.monitor_weight_rounded,
  AssistantQuery.muscleBalance => Icons.accessibility_new_rounded,
  AssistantQuery.streak => Icons.local_fire_department_rounded,
  _ => Icons.bar_chart_rounded,
};
