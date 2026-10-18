import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/formatting.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/units/units.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/fitpack_icon.dart';
import '../../shared/widgets/glass.dart';
import 'training_progress.dart';
import 'training_progress_providers.dart';

/// İlerleme → Antrenman parçası (docs/56 §1): ana hareketlerin günlük en iyi
/// tahmini 1RM eğrisi, son 30 günün rekorları, 8 haftalık hacim.
class TrainingProgressView extends ConsumerWidget {
  final EdgeInsets padding;
  const TrainingProgressView({super.key, required this.padding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final async = ref.watch(trainingProgressProvider);
    return async.when(
      loading: () => ListView(padding: padding, children: [
        Skeleton.card(height: 140),
        AppSpacing.vGapMd,
        Skeleton.card(height: 140),
      ]),
      error: (_, _) => ErrorState(
        message: l.whLoadError,
        onRetry: () => ref.invalidate(trainingProgressProvider),
      ),
      data: (p) {
        // Karşılaştırma iki farklı gün ister (tek seans gelişim değil).
        if (p.trainingDays < 2) {
          return ListView(padding: padding, children: [
            EmptyState(
              icon: Icons.trending_up_rounded,
              title: l.prog3cEmptyTitle(2 - p.trainingDays),
              message: l.prog3cEmptyMsg,
              actionLabel: l.prog3cStartWorkout,
              onAction: () => context.go(AppRoutes.workout),
            ),
          ]);
        }
        return ListView(padding: padding, children: [
          _SectionHeader(title: l.prog3cTopTitle, note: l.prog3cTopNote),
          for (final t in p.top) ...[
            _TopExerciseCard(top: t),
            AppSpacing.vGapSm,
          ],
          AppSpacing.vGapMd,
          _SectionHeader(title: l.prog3cRecordsTitle),
          _RecordsCard(records: p.records),
          AppSpacing.vGapLg,
          _SectionHeader(title: l.prog3cVolumeTitle, note: l.prog3cVolumeNote),
          _VolumeCard(weeks: p.weeklyVolume),
        ]);
      },
    );
  }
}

/// Units "62.5" yazar; ekranda yerel ondalık ("62,5").
String _loc(BuildContext context, String s) =>
    s.replaceAll('.', context.numFmt.symbols.DECIMAL_SEP);

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? note;
  const _SectionHeader({required this.title, this.note});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.texts.titleMedium),
            if (note != null)
              Text(note!,
                  style: context.texts.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ),
      );
}

class _TopExerciseCard extends ConsumerWidget {
  final TopExercise top;
  const _TopExerciseCard({required this.top});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.colors;
    final units = ref.watch(unitsProvider);
    final latest = _loc(context, units.weight(top.latest));
    final d = top.delta4w;
    final delta = d == null
        ? null
        : '${d >= 0 ? '+' : '−'}${_loc(context, units.weight(d.abs()))}';
    return GlassCard(
      key: ValueKey('progress.top.${top.exerciseId}'),
      onTap: () => context.push(AppRoutes.exerciseDetail(top.exerciseId)),
      child: Semantics(
        label: [
          top.name,
          l.prog3cLatest(latest),
          if (delta != null) l.prog3cDelta(delta),
        ].join(', '),
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(top.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.titleSmall),
                ),
                FitPackIcon.material(Icons.chevron_right_rounded,
                    color: c.onSurfaceVariant),
              ],
            ),
            AppSpacing.vGapXs,
            Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(latest,
                    style: context.texts.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(l.prog3cE1rm,
                    style: context.texts.bodySmall
                        ?.copyWith(color: c.onSurfaceVariant)),
                if (delta != null)
                  Text(l.prog3cDelta(delta),
                      style: context.texts.labelLarge?.copyWith(
                          color: c.primary, fontWeight: FontWeight.w700)),
              ],
            ),
            AppSpacing.vGapSm,
            if (top.hasCurve)
              SizedBox(height: 56, child: _Sparkline(top: top))
            else
              Text(l.prog3cNoCurve,
                  style: context.texts.bodySmall
                      ?.copyWith(color: c.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final TopExercise top;
  const _Sparkline({required this.top});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final spots = [
      for (final d in top.daily)
        FlSpot(d.date.millisecondsSinceEpoch / Duration.millisecondsPerDay,
            d.e1rm),
    ];
    final ys = spots.map((s) => s.y);
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY) * 0.15).clamp(1.0, double.infinity);
    return ExcludeSemantics(
      child: LineChart(LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: c.primary,
            barWidth: 2.5,
            isCurved: false,
            dotData: FlDotData(
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                  radius: 2.5, color: c.primary, strokeWidth: 0),
            ),
          ),
        ],
      )),
    );
  }
}

class _RecordsCard extends ConsumerWidget {
  final List<RecordEvent> records;
  const _RecordsCard({required this.records});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.colors;
    final units = ref.watch(unitsProvider);
    return GlassCard(
      child: records.isEmpty
          ? Text(l.prog3cNoRecords,
              style: context.texts.bodyMedium
                  ?.copyWith(color: c.onSurfaceVariant))
          : Column(
              children: [
                for (final r in records)
                  InkWell(
                    onTap: () =>
                        context.push(AppRoutes.exerciseDetail(r.exerciseId)),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                          minHeight: AppA11y.minTapTarget),
                      child: Row(
                        children: [
                          FitPackIcon.material(Icons.emoji_events_rounded,
                              size: AppIconSize.sm,
                              color: context.semantic.warning),
                          AppSpacing.hGapSm,
                          Expanded(
                            child: Text(r.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.texts.bodyMedium),
                          ),
                          AppSpacing.hGapSm,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_loc(context, units.weight(r.e1rm)),
                                  style: context.texts.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700)),
                              Text(context.dateFmt('d MMM').format(r.date),
                                  style: context.texts.bodySmall?.copyWith(
                                      color: c.onSurfaceVariant)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _VolumeCard extends ConsumerWidget {
  final List<({DateTime weekStart, double? volumeKg})> weeks;
  const _VolumeCard({required this.weeks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final units = ref.watch(unitsProvider);
    final values = [for (final w in weeks) w.volumeKg ?? 0];
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final l = AppL10n.of(context);
    // Ekran okuyucu: hafta hafta değer; kayıtsız hafta "kayıt yok".
    final label = [
      for (final w in weeks)
        '${context.dateFmt('d MMM').format(w.weekStart)}: '
            '${w.volumeKg == null ? l.prog3cNoData : '${context.numFmt.format(units.weightFromKg(w.volumeKg!).round())} ${units.weightUnit}'}',
    ].join('; ');
    return GlassCard(
      child: Semantics(
        label: label,
        excludeSemantics: true,
        child: SizedBox(
          height: 140,
          child: BarChart(BarChartData(
            maxY: maxV <= 0 ? 1 : maxV * 1.1,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (v, meta) {
                    final i = v.toInt();
                    // Yalnız ilk ve son hafta etiketli — tekrar etmesin.
                    if (i != 0 && i != weeks.length - 1) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                          context.dateFmt('d MMM').format(weeks[i].weekStart),
                          style: context.texts.labelSmall
                              ?.copyWith(color: c.onSurfaceVariant)),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (final (i, w) in weeks.indexed)
                BarChartGroupData(x: i, barRods: [
                  // Kayıtsız hafta: çubuk yok (boşluk, 0 değil).
                  if (w.volumeKg != null)
                    BarChartRodData(
                      toY: w.volumeKg!,
                      color: c.primary,
                      width: 14,
                      borderRadius: AppRadius.brSm,
                    ),
                ]),
            ],
          )),
        ),
      ),
    );
  }
}
