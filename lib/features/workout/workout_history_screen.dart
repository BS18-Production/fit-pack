import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/formatting.dart';
import '../../core/units/units.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/format.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';
import '../../data/database/app_database.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/app_state_views.dart';
import '../home/providers/home_providers.dart';
import 'calorie_estimate.dart';

/// **Reaktif** (H-05): seans silinince/eklenince kendiliğinden tazelenir.
final _allSessionsProvider = StreamProvider<List<WorkoutSession>>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [db.workoutSessions],
      () => ref.read(workoutDaoProvider).getAllSessions());
});

/// Seansın setleri (genişletilince yüklenir) — hareket adıyla gruplu.
final _sessionSetsProvider = FutureProvider.autoDispose
    .family<Map<String, List<WorkoutSet>>, int>((ref, sessionId) async {
  final dao = ref.watch(workoutDaoProvider);
  final sets = await dao.getSetsForSession(sessionId);
  final nameById = {for (final e in await dao.getAllExercises()) e.id: e.name};
  final grouped = <String, List<WorkoutSet>>{};
  for (final s in sets) {
    grouped.putIfAbsent(nameById[s.exerciseId] ?? '?', () => []).add(s);
  }
  return grouped;
});

class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(_allSessionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppL10n.of(context).workoutHistory)),
      body: sessionsAsync.when(
        loading: () => ListView(
          padding: AppSpacing.screen,
          children: [
            Skeleton.card(height: 84),
            AppSpacing.vGapMd,
            Skeleton.card(height: 84),
            AppSpacing.vGapMd,
            Skeleton.card(height: 84),
          ],
        ),
        error: (_, _) => ErrorState(
          message: AppL10n.of(context).whLoadError,
          onRetry: () => ref.invalidate(_allSessionsProvider),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            final l = AppL10n.of(context);
            return EmptyState(
              icon: Icons.history_rounded,
              title: l.whEmptyTitle,
              message: l.whEmptyMsg,
            );
          }
          return ListView.builder(
            padding: AppSpacing.screen,
            itemCount: sessions.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _SessionCard(session: sessions[i]),
            ),
          );
        },
      ),
    );
  }
}

class _SessionCard extends ConsumerWidget {
  final WorkoutSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final dateTxt =
        context.dateFmt('d MMMM EEEE').format(session.date);
    final meta = <String>[
      dateTxt,
      if (session.durationMin != null && session.durationMin! > 0)
        '${session.durationMin} ${l.unitMinShort}',
      if (session.rpe != null) 'RPE ${session.rpe}',
    ].join('  ·  ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: context.colors.primary.withValues(alpha: 0.14),
            borderRadius: AppRadius.brMd,
          ),
          child: Icon(
            session.workoutType == 'Cardio'
                ? Icons.directions_run_rounded
                : Icons.fitness_center_rounded,
            color: context.colors.primary,
            size: AppIconSize.md,
          ),
        ),
        title: Text(session.workoutType, style: context.texts.titleSmall),
        subtitle: Text(meta,
            style: context.texts.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant)),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded,
              color: context.colors.onSurfaceVariant),
          onSelected: (v) {
            if (v == 'date') _editDate(context, ref);
            if (v == 'delete') _delete(context, ref);
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
        children: [_SessionDetail(session: session)],
      ),
    );
  }

  Future<void> _editDate(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: session.date,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked == null) return;
    // Günü değiştir, mevcut saat dilimini koru → istatistikler doğru güne kayar.
    final newDate = DateTime(picked.year, picked.month, picked.day,
        session.date.hour, session.date.minute);
    final dao = ref.read(workoutDaoProvider);
    await dao.updateSession(session.copyWith(
      date: newDate,
      startedAt: Value(session.startedAt == null
          ? null
          : DateTime(picked.year, picked.month, picked.day,
              session.startedAt!.hour, session.startedAt!.minute)),
    ));
    // Liste + istatistikler reaktif (H-05) → tarih değişimi kendiliğinden yansır.
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: AppL10n.of(context).whDeleteTitle,
      message: AppL10n.of(context).whDeleteMsg,
      confirmLabel: AppL10n.of(context).commonDelete,
      destructive: true,
    );
    if (!ok) return;
    await ref.read(workoutDaoProvider).deleteSessionWithSets(session.id);
    // Liste + haftalık istatistik + seri reaktif (H-05) → silme kendiliğinden
    // yansır.
  }
}

class _SessionDetail extends ConsumerWidget {
  final WorkoutSession session;
  const _SessionDetail({required this.session});

  /// Bir set'in değer metni — ölçüm tipini dolu alandan çıkarır (kayıtta yok).
  /// Görüntü birim tercihinde; DB metrik (docs/16 §3).
  String _fmtSet(BuildContext context, WorkoutSet s, Units units) {
    if (s.durationSec != null || s.distanceM != null) {
      final parts = <String>[
        if (s.distanceM != null)
          '${units.distanceValue(s.distanceM!)} ${units.distanceUnit}',
        if (s.durationSec != null) fmtDuration(s.durationSec!),
      ];
      return parts.join(' · ');
    }
    if (s.weightKg == null && s.reps != null) {
      return '${s.reps} ${AppL10n.of(context).unitReps}';
    }
    final wTxt = s.weightKg == null ? '—' : units.weightValue(s.weightKg!);
    return '$wTxt ${units.weightUnit} × ${s.reps ?? '—'}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(_sessionSetsProvider(session.id));
    final bodyWeight = ref.watch(latestWeightProvider).valueOrNull?.weightKg;
    final units = ref.watch(unitsProvider);
    return setsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(AppL10n.of(context).whSetsLoadError),
      ),
      data: (grouped) {
        if (grouped.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(AppL10n.of(context).whNoSets,
                style: context.texts.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
          );
        }
        // Seans özeti: toplam hacim, set sayısı, yoğunluk → kalori tahmini.
        double volume = 0;
        var setCount = 0;
        final allSets = <WorkoutSet>[];
        for (final sets in grouped.values) {
          for (final s in sets) {
            volume += (s.weightKg ?? 0) * (s.reps ?? 0);
            setCount++;
            allSets.add(s);
          }
        }
        final intensity = sessionIntensity(allSets);
        final kcal = estimateWorkoutKcal(
          bodyWeightKg: bodyWeight,
          durationMin: session.durationMin,
          avgRpe: intensity.avgRpe,
          isCardio:
              intensity.isCardio || session.workoutType == 'Cardio',
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── üst istatistik şeridi ──
              _StatStrip(
                duration: session.durationMin,
                volume:
                    volume > 0 ? units.weightFromKg(volume).round() : null,
                volumeUnit: units.weightUnit,
                setCount: setCount,
                kcal: kcal?.round(),
              ),
              AppSpacing.vGapMd,
              const Divider(height: 1),
              AppSpacing.vGapMd,
              // ── hareket blokları (ad üstte, setler altında numaralı) ──
              ...grouped.entries.map((e) => _ExerciseLog(
                    name: e.key,
                    lines: [
                      for (var i = 0; i < e.value.length; i++)
                        (
                          no: i + 1,
                          type: e.value[i].setType,
                          value: _fmtSet(context, e.value[i], units),
                        ),
                    ],
                  )),
              if (kcal != null) ...[
                AppSpacing.vGapSm,
                Text(
                  AppL10n.of(context).whCalorieNote,
                  style: context.texts.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant
                          .withValues(alpha: 0.7)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Seans üst istatistik şeridi: süre · hacim · set · ~kcal.
class _StatStrip extends StatelessWidget {
  final int? duration;
  final int? volume; // görüntü biriminde
  final String volumeUnit;
  final int setCount;
  final int? kcal;
  const _StatStrip(
      {required this.duration,
      required this.volume,
      required this.volumeUnit,
      required this.setCount,
      required this.kcal});

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[
      if (duration != null && duration! > 0)
        (
          Icons.schedule_rounded,
          '$duration ${AppL10n.of(context).unitMinShort}',
          AppL10n.of(context).labelDuration
        ),
      if (volume != null)
        (
          Icons.fitness_center_rounded,
          '$volume $volumeUnit',
          AppL10n.of(context).labelVolume
        ),
      (
        Icons.format_list_numbered_rounded,
        '$setCount',
        AppL10n.of(context).labelSets
      ),
      if (kcal != null)
        (Icons.local_fire_department_rounded, '~$kcal', 'kcal'),
    ];
    return Row(
      children: [
        for (final it in items)
          Expanded(
            child: Column(
              children: [
                Icon(it.$1, size: AppIconSize.sm, color: context.colors.primary),
                const SizedBox(height: 4),
                Text(it.$2,
                    style: context.texts.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()])),
                Text(it.$3,
                    style: context.texts.labelSmall?.copyWith(
                        color: context.colors.onSurfaceVariant)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Tek hareketin günlüğü: ad (tam genişlik başlık) + altında numaralı set
/// satırları. Sıkışma yok — her set kendi satırında, değer hizalı.
class _ExerciseLog extends StatelessWidget {
  final String name;
  final List<({int no, String type, String value})> lines;
  const _ExerciseLog({required this.name, required this.lines});

  static const _typeBadge = {'warmup': 'I', 'drop': 'D', 'failure': 'F'};

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: context.texts.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          AppSpacing.vGapXs,
          ...lines.map((l) {
            final badge = _typeBadge[l.type];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  // set numarası / tip rozeti
                  Container(
                    width: 26,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.onSurface.withValues(alpha: 0.06),
                      borderRadius: AppRadius.brSm,
                    ),
                    child: Text(badge ?? '${l.no}',
                        style: context.texts.labelMedium?.copyWith(
                            color: badge != null
                                ? c.primary
                                : c.onSurfaceVariant,
                            fontWeight: FontWeight.w700)),
                  ),
                  AppSpacing.hGapMd,
                  Text(l.value,
                      style: context.texts.bodyMedium?.copyWith(
                          fontFeatures: const [
                            FontFeature.tabularFigures()
                          ])),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
