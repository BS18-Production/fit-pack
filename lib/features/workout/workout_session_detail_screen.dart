import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/formatting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/units/units.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/workout_dao.dart' show ExerciseSetPoint;
import '../../data/providers.dart';
import '../../data/reactive.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/app_state_views.dart';
import '../home/providers/home_providers.dart';
import 'calorie_estimate.dart';
import 'history_card.dart';
import 'history_summary.dart';
import 'record_calc.dart';
import 'workout_summary_screen.dart' show WorkoutRecordsCard;
import 'workout_ui.dart';

/// Detaydaki tek hareket: setler, en iyi set, geçen sefere göre fark.
class _ExerciseDetail {
  final Exercise? exercise;
  final List<WorkoutSet> sets;
  final SetDelta? delta;
  final NewRecord? record;
  const _ExerciseDetail(this.exercise, this.sets, this.delta, this.record);
}

class _SessionDetailData {
  final WorkoutSession session;
  final List<WorkoutSet> sets;
  final List<_ExerciseDetail> exercises;
  final List<(String, int)> muscles;
  const _SessionDetailData(
      this.session, this.sets, this.exercises, this.muscles);

  List<NewRecord> get records =>
      [for (final e in exercises) if (e.record != null) e.record!];
}

/// Seans detayı — her hareketin geçmişi ayrı sorgu (seans başına ~5-8
/// hareket; liste ekranı N+1 yapmaz, yalnız açılan seans). **Reaktif.**
final _sessionDetailProvider = StreamProvider.autoDispose
    .family<_SessionDetailData?, int>((ref, sessionId) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [db.workoutSessions, db.workoutSets, db.exercises],
      () async {
    final dao = ref.read(workoutDaoProvider);
    final session = await dao.getSessionById(sessionId);
    if (session == null) return null; // silindi
    final sets = await dao.getSetsForSession(sessionId);
    final briefs = exerciseBriefs(sets);
    final exById = {
      for (final e in await dao.getExercisesByIds(briefs.map((b) => b.exerciseId)))
        e.id: e,
    };
    final exercises = <_ExerciseDetail>[];
    for (final b in briefs) {
      final exSets = sets.where((s) => s.exerciseId == b.exerciseId).toList()
        ..sort((a, c) => a.id.compareTo(c.id));
      final history = await dao.getExerciseHistory(b.exerciseId);
      final record = newRecordFor(
        name: exById[b.exerciseId]?.name ?? '?',
        priorHistory: history.where((p) => p.date.isBefore(session.date)),
        sessionPoints: exSets.where((s) => !s.isWarmup).map((s) =>
            ExerciseSetPoint(
                date: session.date, weightKg: s.weightKg, reps: s.reps)),
      );
      exercises.add(_ExerciseDetail(
        exById[b.exerciseId],
        exSets,
        deltaVsPrevious(b.best, previousBest(history, session.date)),
        record,
      ));
    }
    final muscles = muscleSplit(
        sets, {for (final e in exById.values) e.id: e.primaryMuscle});
    return _SessionDetailData(session, sets, exercises, muscles);
  });
});

/// Antrenman seansı detayı (docs/31): özet şerit, rekorlar, çalışan kaslar,
/// hareket başına setler (RPE ve rekor işaretiyle) + geçen sefere göre fark.
class WorkoutSessionDetailScreen extends ConsumerWidget {
  final int sessionId;
  const WorkoutSessionDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final async = ref.watch(_sessionDetailProvider(sessionId));
    final data = async.valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(data?.session.workoutType ?? l.workoutHistory),
        actions: [
          if (data != null)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'date') _editDate(context, ref, data.session);
                if (v == 'delete') _delete(context, ref, data.session);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'date',
                  child: ListTile(
                      leading: const Icon(Icons.event_rounded),
                      title: Text(l.whEditDate),
                      contentPadding: EdgeInsets.zero),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                      leading: const Icon(Icons.delete_outline_rounded),
                      title: Text(l.commonDelete),
                      contentPadding: EdgeInsets.zero),
                ),
              ],
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorState(
          message: l.whLoadError,
          onRetry: () => ref.invalidate(_sessionDetailProvider(sessionId)),
        ),
        data: (d) => d == null
            ? EmptyState(
                icon: Icons.history_rounded,
                title: l.whEmptyTitle,
                message: l.whEmptyMsg)
            : _Body(data: d),
      ),
    );
  }

  Future<void> _editDate(
      BuildContext context, WidgetRef ref, WorkoutSession session) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: session.date,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked == null || !context.mounted) return;
    // Günü değiştir, saati koru → istatistikler doğru güne kayar.
    final newDate = DateTime(picked.year, picked.month, picked.day,
        session.date.hour, session.date.minute);
    try {
      await ref.read(workoutDaoProvider).updateSession(session.copyWith(
            date: newDate,
            startedAt: Value(session.startedAt == null
                ? null
                : DateTime(picked.year, picked.month, picked.day,
                    session.startedAt!.hour, session.startedAt!.minute)),
          ));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppL10n.of(context).asSaveError)));
      }
    }
    // Liste + istatistikler reaktif (H-05) → değişiklik kendiliğinden yansır.
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, WorkoutSession session) async {
    final l = AppL10n.of(context);
    final ok = await confirmAction(
      context,
      title: l.whDeleteTitle,
      message: l.whDeleteMsg,
      confirmLabel: l.commonDelete,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(workoutDaoProvider).deleteSessionWithSets(session.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.asSaveError)));
      }
      return;
    }
    // Liste + haftalık istatistik + seri reaktif (H-05).
    if (context.mounted) context.pop();
  }
}

class _Body extends ConsumerWidget {
  final _SessionDetailData data;
  const _Body({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final units = ref.watch(unitsProvider);
    final bodyWeight = ref.watch(latestWeightProvider).valueOrNull?.weightKg;
    final s = data.session;
    final totals = sessionTotals(data.sets);
    final intensity = sessionIntensity(data.sets);
    final kcal = estimateWorkoutKcal(
      bodyWeightKg: bodyWeight,
      durationMin: s.durationMin,
      avgRpe: intensity.avgRpe,
      isCardio: intensity.isCardio || s.workoutType == 'Cardio',
    );
    final muted = context.colors.onSurfaceVariant;
    final date = context.dateFmt(historyDatePattern(s.date, DateTime.now()));
    final time = s.startedAt == null
        ? ''
        : '  ·  ${context.dateFmt('HH:mm').format(s.startedAt!)}'
            '${s.endedAt == null ? '' : '–${context.dateFmt('HH:mm').format(s.endedAt!)}'}';
    final hasRpe = data.sets.any((x) => x.rpe != null);

    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg,
          AppSpacing.xxxl + MediaQuery.paddingOf(context).bottom),
      children: [
        Text('${date.format(s.date)}$time',
            style: context.texts.bodyMedium?.copyWith(color: muted)),
        AppSpacing.vGapMd,
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.lg, horizontal: AppSpacing.sm),
            child: Row(
              children: [
                if ((s.durationMin ?? 0) > 0)
                  _StatCol(Icons.schedule_rounded,
                      '${s.durationMin} ${l.unitMinShort}', l.labelDuration),
                if (totals.volumeKg > 0)
                  _StatCol(Icons.fitness_center_rounded,
                      units.weight(totals.volumeKg, frac: 0), l.labelVolume),
                _StatCol(Icons.format_list_numbered_rounded,
                    '${totals.sets}', l.labelSets),
                if (intensity.avgRpe != null)
                  _StatCol(Icons.speed_rounded,
                      _fmtRpe(intensity.avgRpe!), l.whAvgRpe),
                if (kcal != null)
                  _StatCol(Icons.local_fire_department_rounded,
                      '~${kcal.round()}', 'kcal'),
              ],
            ),
          ),
        ),
        if (data.records.isNotEmpty) ...[
          AppSpacing.vGapMd,
          WorkoutRecordsCard(records: data.records, units: units),
        ],
        if (data.muscles.isNotEmpty) ...[
          AppSpacing.vGapLg,
          Text(l.whMuscles, style: context.texts.titleSmall),
          AppSpacing.vGapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final m in data.muscles)
                WorkoutChip(
                    '${WorkoutUi.muscleLabel(m.$1)} · ${l.workoutSetCount(m.$2)}'),
            ],
          ),
        ],
        if ((s.notes ?? '').trim().isNotEmpty) ...[
          AppSpacing.vGapLg,
          Text(l.whNotes, style: context.texts.titleSmall),
          AppSpacing.vGapXs,
          Text(s.notes!.trim(), style: context.texts.bodyMedium),
        ],
        AppSpacing.vGapLg,
        if (data.exercises.isEmpty)
          Text(l.whNoSets,
              style: context.texts.bodySmall?.copyWith(color: muted)),
        for (final e in data.exercises) _ExerciseBlock(detail: e, units: units),
        if (hasRpe || kcal != null) ...[
          AppSpacing.vGapSm,
          Text(
            [if (hasRpe) l.whRpeLegend, if (kcal != null) l.whCalorieNote]
                .join('\n'),
            style: context.texts.bodySmall
                ?.copyWith(color: muted.withValues(alpha: 0.8)),
          ),
        ],
      ],
    );
  }
}

/// RPE 8 / 8,5 — yarım değer destekli, tam sayıda ondalık yok.
String _fmtRpe(double v) {
  final r = (v * 2).round() / 2;
  return r == r.roundToDouble() ? '${r.round()}' : r.toStringAsFixed(1);
}

class _StatCol extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _StatCol(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: AppIconSize.sm, color: context.colors.primary),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: context.texts.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.labelSmall
                  ?.copyWith(color: context.colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Tek hareketin blok: ad, setler (tip rozeti · değer · RPE · rekor kupası),
/// geçen sefere göre fark.
class _ExerciseBlock extends StatelessWidget {
  final _ExerciseDetail detail;
  final Units units;
  const _ExerciseBlock({required this.detail, required this.units});

  static const _typeBadge = {'warmup': 'I', 'drop': 'D', 'failure': 'F'};

  String? _deltaText(AppL10n l) => switch (detail.delta) {
        WeightDelta(:final kg) =>
          '${kg > 0 ? '+' : '−'}${units.weight(kg.abs())}',
        RepsDelta(:final reps) =>
          l.whDeltaReps('${reps > 0 ? '+' : '−'}${reps.abs()}'),
        SameAsLast() => l.whDeltaSame,
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.colors;
    final rec = detail.record;
    // Rekor setini işaretle: rekor değerine eşit ilk çalışma seti.
    final recordSetId = rec == null
        ? null
        : detail.sets
            .where((s) =>
                !s.isWarmup &&
                s.weightKg == rec.weightKg &&
                (s.reps ?? 0) == rec.reps)
            .firstOrNull
            ?.id;
    final delta = _deltaText(l);
    final deltaColor = switch (detail.delta) {
      WeightDelta(:final kg) when kg < 0 => c.onSurfaceVariant,
      RepsDelta(:final reps) when reps < 0 => c.onSurfaceVariant,
      SameAsLast() => c.onSurfaceVariant,
      _ => context.semantic.success,
    };
    var no = 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(detail.exercise?.name ?? '?',
                style: context.texts.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            if (detail.exercise != null)
              Text(
                  WorkoutUi.muscleEquip(detail.exercise!.primaryMuscle,
                      detail.exercise!.equipment),
                  style: context.texts.bodySmall
                      ?.copyWith(color: c.onSurfaceVariant)),
            AppSpacing.vGapSm,
            for (final s in detail.sets)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.onSurface.withValues(alpha: 0.06),
                        borderRadius: AppRadius.brSm,
                      ),
                      child: Text(
                          _typeBadge[s.setType] ??
                              (s.isWarmup ? 'I' : '${++no}'),
                          style: context.texts.labelMedium?.copyWith(
                              color: _typeBadge.containsKey(s.setType) ||
                                      s.isWarmup
                                  ? c.primary
                                  : c.onSurfaceVariant,
                              fontWeight: FontWeight.w700)),
                    ),
                    AppSpacing.hGapMd,
                    Expanded(
                      child: Text(historySetValue(l, s, units),
                          style: context.texts.bodyMedium?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ])),
                    ),
                    if (s.id == recordSetId) ...[
                      Icon(Icons.emoji_events_rounded,
                          size: AppIconSize.sm,
                          color: context.semantic.warning),
                      AppSpacing.hGapSm,
                    ],
                    if (s.rpe != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.primary.withValues(alpha: 0.12),
                          borderRadius: AppRadius.brSm,
                        ),
                        child: Text(l.whSetsWithRpe(_fmtRpe(s.rpe!)),
                            style: context.texts.labelSmall?.copyWith(
                                color: c.primary,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
            if (delta != null) ...[
              AppSpacing.vGapSm,
              Text(l.whVsLast(delta),
                  style: context.texts.bodySmall?.copyWith(
                      color: deltaColor, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}
