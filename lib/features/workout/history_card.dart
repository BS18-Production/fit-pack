import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/formatting.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/units/units.dart';
import '../../core/utils/format.dart';
import '../../data/database/app_database.dart';
import '../../l10n/app_l10n.dart';
import 'history_providers.dart';
import 'history_summary.dart';
import '../../shared/widgets/fitpack_icon.dart';

/// Kartta gösterilen en fazla hareket satırı; fazlası "+N hareket daha".
const historyCardExercises = 3;

/// Bir setin kısa değer metni — "80 kg × 8", "12 tekrar", "5 km · 25:00".
/// Görüntü birim tercihinde; DB metrik (docs/16 §3).
String historySetValue(AppL10n l, WorkoutSet s, Units units) {
  if (s.durationSec != null || s.distanceM != null) {
    return [
      if (s.distanceM != null)
        '${units.distanceValue(s.distanceM!)} ${units.distanceUnit}',
      if (s.durationSec != null) fmtDuration(s.durationSec!),
    ].join(' · ');
  }
  if (s.weightKg == null && s.reps != null) return '${s.reps} ${l.unitReps}';
  final w = s.weightKg == null ? '—' : units.weightValue(s.weightKg!);
  return '$w ${units.weightUnit} × ${s.reps ?? '—'}';
}

/// Geçmiş özet kartı (docs/31): ad · tarih · süre; hacim · set · rekor;
/// hareketler en iyi setleriyle. Dokununca seans detayı açılır.
class HistoryCard extends ConsumerWidget {
  final HistoryEntry entry;
  final Map<int, Exercise> exercisesById;

  const HistoryCard(
      {super.key, required this.entry, required this.exercisesById});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final units = ref.watch(unitsProvider);
    final s = entry.session;
    final muted = context.colors.onSurfaceVariant;
    final date =
        context.dateFmt(historyDatePattern(s.date, DateTime.now())).format(s.date);
    final meta = [
      date,
      if ((s.durationMin ?? 0) > 0) '${s.durationMin} ${l.unitMinShort}',
    ].join('  ·  ');
    final shown = entry.exercises.take(historyCardExercises).toList();
    final more = entry.exercises.length - shown.length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.workoutSession(s.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.workoutType,
                            style: context.texts.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(meta,
                            style:
                                context.texts.bodySmall?.copyWith(color: muted)),
                      ],
                    ),
                  ),
                  FitPackIcon.material(Icons.chevron_right_rounded, color: muted),
                ],
              ),
              AppSpacing.vGapMd,
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.xs,
                children: [
                  if (entry.totals.volumeKg > 0)
                    _Stat(Icons.fitness_center_rounded,
                        units.weight(entry.totals.volumeKg, frac: 0)),
                  _Stat(Icons.format_list_numbered_rounded,
                      l.workoutSetCount(entry.totals.sets)),
                  if (entry.records > 0)
                    _Stat(Icons.emoji_events_rounded,
                        l.whRecordCount(entry.records),
                        color: context.semantic.warning),
                ],
              ),
              if (shown.isNotEmpty) ...[
                AppSpacing.vGapMd,
                const Divider(height: 1),
                AppSpacing.vGapSm,
                for (final b in shown)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child: Text('${b.sets} ×',
                              style: context.texts.bodySmall?.copyWith(
                                  color: muted, fontWeight: FontWeight.w700)),
                        ),
                        Expanded(
                          child: Text(
                              exercisesById[b.exerciseId]?.name ?? '?',
                              style: context.texts.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (b.best != null) ...[
                          AppSpacing.hGapSm,
                          Text(historySetValue(l, b.best!, units),
                              style: context.texts.bodySmall?.copyWith(
                                  color: muted,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ])),
                        ],
                      ],
                    ),
                  ),
                if (more > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(l.whMoreExercises(more),
                        style: context.texts.bodySmall?.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _Stat(this.icon, this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FitPackIcon.material(icon, size: AppIconSize.sm, color: c),
        AppSpacing.hGapXs,
        Text(text,
            style: context.texts.labelLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
