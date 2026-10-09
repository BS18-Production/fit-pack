import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/formatting.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/glass.dart';
import 'providers/dashboard_providers.dart';
import 'workout_activity.dart';
import '../../shared/widgets/fitpack_icon.dart';

/// Gerçek seanslara dayanan günlük yakım. Grafik boş günleri kayıtlı
/// yakım 0, eksik tahmini boşluk olarak gösterir; canlı sensör verisi değildir.
class WorkoutActivityCard extends ConsumerStatefulWidget {
  const WorkoutActivityCard({super.key});
  @override
  ConsumerState<WorkoutActivityCard> createState() =>
      _WorkoutActivityCardState();
}

class _WorkoutActivityCardState extends ConsumerState<WorkoutActivityCard> {
  int _selected = 6;
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return ref
        .watch(recentWorkoutActivityProvider)
        .when(
          loading: () => Skeleton.card(height: 240),
          error: (_, _) => ErrorState(
            message: l.whLoadError,
            onRetry: () => ref.invalidate(recentWorkoutActivityProvider),
          ),
          data: (days) => _content(context, days),
        );
  }

  Widget _content(BuildContext context, List<WorkoutActivityDay> days) {
    final l = AppL10n.of(context);
    final c = context.colors;
    final selected = days[_selected];
    final anySessions = days.any((d) => d.sessions > 0);
    final sparseLabels =
        MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
        MediaQuery.sizeOf(context).width < 340;
    final max = days.fold<int>(0, (value, d) => math.max(value, d.kcal ?? 0));
    final maxY = math.max(100, (max / 100).ceil() * 100).toDouble();
    final segments = <List<FlSpot>>[];
    var segment = <FlSpot>[];
    for (var i = 0; i < days.length; i++) {
      if (days[i].kcal == null) {
        if (segment.isNotEmpty) segments.add(segment);
        segment = [];
      } else {
        segment.add(FlSpot(i.toDouble(), days[i].kcal!.toDouble()));
      }
    }
    if (segment.isNotEmpty) segments.add(segment);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.journalActivity, style: context.texts.titleMedium),
                    AppSpacing.vGapXs,
                    Text(
                      l.journalActivityPeriod,
                      style: context.texts.labelSmall?.copyWith(
                        color: c.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FitPackIcon.material(
                Icons.local_fire_department_rounded,
                color: c.secondary,
                size: AppIconSize.sm,
              ),
              AppSpacing.hGapXs,
              Text(
                selected.kcal == null
                    ? '—'
                    : context.numFmt.format(selected.kcal),
                style: context.texts.headlineSmall,
              ),
            ],
          ),
          if (!anySessions) ...[
            AppSpacing.vGapLg,
            Text(
              l.journalActivityEmpty,
              style: context.texts.bodyMedium?.copyWith(
                color: c.onSurfaceVariant,
              ),
            ),
          ] else ...[
            AppSpacing.vGapLg,
            Semantics(
              label: l.journalActivityPeriod,
              child: SizedBox(
                height: 164,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: 6,
                    minY: 0,
                    maxY: maxY,
                    clipData: const FlClipData.all(),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 2,
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: c.outlineVariant, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: maxY / 2,
                          getTitlesWidget: (v, meta) => Text(
                            context.numFmt.format(v.round()),
                            style: context.texts.labelSmall?.copyWith(
                              color: c.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: sparseLabels ? 40 : 28,
                          interval: sparseLabels ? 2 : 1,
                          getTitlesWidget: (v, meta) => Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Text(
                              context
                                  .dateFmt('EE')
                                  .format(days[v.round().clamp(0, 6)].date),
                              style: context.texts.labelSmall?.copyWith(
                                color: c.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    lineBarsData: segments
                        .map(
                          (spots) => LineChartBarData(
                            spots: spots,
                            color: c.primary,
                            barWidth: 2.5,
                            isCurved: true,
                            preventCurveOverShooting: true,
                            shadow: Shadow(
                              color: c.primary.withValues(alpha: .35),
                              blurRadius: 10,
                            ),
                            dotData: FlDotData(
                              show: true,
                              checkToShowDot: (spot, bar) =>
                                  spot.x.round() == _selected ||
                                  bar.spots.length == 1,
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  c.primary.withValues(alpha: .12),
                                  c.primary.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    lineTouchData: LineTouchData(
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions) return;
                        final spot = response?.lineBarSpots?.firstOrNull;
                        if (spot != null && spot.x.round() != _selected) {
                          setState(
                            () => _selected = spot.x.round().clamp(0, 6),
                          );
                        }
                      },
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => c.surfaceContainerHigh,
                        getTooltipItems: (spots) => spots
                            .map(
                              (spot) => LineTooltipItem(
                                '${context.dateFmt('d MMM').format(days[spot.x.round()].date)}\n${context.numFmt.format(spot.y.round())} kcal',
                                context.texts.labelSmall!.copyWith(
                                  color: c.onSurface,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          AppSpacing.vGapSm,
          LayoutBuilder(
            builder: (context, constraints) {
              final selector = PopupMenuButton<int>(
                tooltip: l.nutritionPickDate,
                initialValue: _selected,
                onSelected: (i) => setState(() => _selected = i),
                itemBuilder: (_) => [
                  for (var i = 0; i < days.length; i++)
                    PopupMenuItem(
                      value: i,
                      child: Text(
                        context.dateFmt('EEE · d MMM').format(days[i].date),
                      ),
                    ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          context.dateFmt('d MMM').format(selected.date),
                          style: context.texts.labelMedium,
                        ),
                      ),
                      FitPackIcon.material(
                        Icons.expand_more_rounded,
                        color: c.onSurfaceVariant,
                        size: AppIconSize.sm,
                      ),
                    ],
                  ),
                ),
              );
              final history = TextButton(
                onPressed: () => context.push(AppRoutes.workoutHistory),
                child: Text(l.workoutHistory),
              );
              if (constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    selector,
                    Align(alignment: Alignment.centerRight, child: history),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: selector),
                  history,
                ],
              );
            },
          ),
          Text(
            selected.kcal == null
                ? l.journalEstimateMissing
                : selected.sessions == 0
                ? l.journalNoWorkout
                : l.journalActivitySessions(selected.sessions),
            style: context.texts.labelSmall?.copyWith(
              color: c.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
