import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/format.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/workout_dao.dart';
import '../../data/providers.dart';
import '../../shared/widgets/app_state_views.dart';
import 'exercise_library_screen.dart' show libraryExercisesProvider;
import 'workout_ui.dart';

/// Hareket Detayı (Antrenman V2 Faz D). Geçmiş / Grafik (e1RM) / Rekorlar.

final _exerciseProvider =
    FutureProvider.family<Exercise?, int>((ref, id) =>
        ref.watch(workoutDaoProvider).getExerciseById(id));

final _historyProvider =
    FutureProvider.family<List<ExerciseSetPoint>, int>((ref, id) =>
        ref.watch(workoutDaoProvider).getExerciseHistory(id));

class ExerciseDetailScreen extends ConsumerWidget {
  final int exerciseId;
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ex = ref.watch(_exerciseProvider(exerciseId)).valueOrNull;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(ex?.name ?? 'Hareket'),
          actions: [
            if (ex?.isCustom == true)
              IconButton(
                tooltip: 'Arşivle',
                icon: const Icon(Icons.archive_outlined),
                onPressed: () async {
                  final ok = await confirmAction(
                    context,
                    title: 'Hareketi arşivle',
                    message:
                        '${ex!.name} kütüphaneden kaldırılsın mı? Geçmiş kayıtlar korunur.',
                    confirmLabel: 'Arşivle',
                  );
                  if (!ok) return;
                  await ref.read(workoutDaoProvider).archiveExercise(ex.id);
                  ref.invalidate(libraryExercisesProvider);
                  if (context.mounted) context.pop();
                },
              ),
          ],
          bottom: const TabBar(tabs: [
            Tab(text: 'Geçmiş'),
            Tab(text: 'Grafik'),
            Tab(text: 'Rekorlar'),
          ]),
        ),
        body: TabBarView(children: [
          _HistoryTab(exerciseId: exerciseId, exercise: ex),
          _ChartTab(exerciseId: exerciseId),
          _RecordsTab(exerciseId: exerciseId),
        ]),
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  final int exerciseId;
  final Exercise? exercise;
  const _HistoryTab({required this.exerciseId, this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_historyProvider(exerciseId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Yüklenemedi')),
      data: (points) {
        final df = DateFormat('d MMM yyyy', 'tr_TR');
        return ListView(
          padding: AppSpacing.screen,
          children: [
            if (exercise != null) _InfoCard(exercise!),
            AppSpacing.vGapLg,
            if (points.isEmpty)
              const EmptyState(
                icon: Icons.history_rounded,
                title: 'Henüz kayıt yok',
                message: 'Bu hareketi bir antrenmanda kullanınca burada görünür',
                compact: true,
              )
            else ...[
              Text('Set geçmişi', style: context.texts.titleSmall),
              AppSpacing.vGapSm,
              ...points.reversed.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(df.format(p.date),
                            style: context.texts.bodyMedium?.copyWith(
                                color: context.colors.onSurfaceVariant)),
                        Text(
                          p.weightKg != null
                              ? '${fmtNum(p.weightKg!)} kg × ${p.reps ?? '-'}'
                              : '${p.reps ?? '-'} tekrar',
                          style: context.texts.titleSmall,
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Exercise ex;
  const _InfoCard(this.ex);
  @override
  Widget build(BuildContext context) {
    final catColor = WorkoutUi.categoryColor(context, ex.category);
    final subtitle = WorkoutUi.muscleEquip(ex.primaryMuscle, ex.equipment);
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.13),
                borderRadius: AppRadius.brLg,
              ),
              child: Icon(WorkoutUi.equipmentIcon(ex.equipment),
                  color: catColor, size: 26),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(WorkoutUi.categoryLabel(ex.category),
                      style: context.texts.titleSmall),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: context.texts.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartTab extends ConsumerWidget {
  final int exerciseId;
  const _ChartTab({required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_historyProvider(exerciseId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Yüklenemedi')),
      data: (points) {
        final e1rms = points
            .where((p) => p.e1rm != null)
            .map((p) => p.e1rm!)
            .toList();
        if (e1rms.length < 2) {
          return const EmptyState(
            icon: Icons.show_chart_rounded,
            title: 'Grafik için yeterli veri yok',
            message: 'En az iki kez kg×tekrar girince ilerleme grafiği çıkar',
            compact: true,
          );
        }
        final spots = [
          for (var i = 0; i < e1rms.length; i++)
            FlSpot(i.toDouble(), e1rms[i])
        ];
        final minY = e1rms.reduce((a, b) => a < b ? a : b);
        final maxY = e1rms.reduce((a, b) => a > b ? a : b);
        final pad = ((maxY - minY) * 0.15).clamp(2.0, 50.0);
        return Padding(
          padding: AppSpacing.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tahmini 1RM gelişimi',
                  style: context.texts.titleSmall),
              Text('Epley: kg × (1 + tekrar/30)',
                  style: context.texts.labelSmall
                      ?.copyWith(color: context.colors.onSurfaceVariant)),
              AppSpacing.vGapLg,
              Expanded(
                child: LineChart(LineChartData(
                  minY: minY - pad,
                  maxY: maxY + pad,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                        color: context.colors.outlineVariant, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, _) => Text('${v.round()}',
                            style: context.texts.labelSmall),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      color: context.colors.primary,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: context.colors.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                )),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecordsTab extends ConsumerWidget {
  final int exerciseId;
  const _RecordsTab({required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_historyProvider(exerciseId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Yüklenemedi')),
      data: (points) {
        final withData = points.where((p) => p.e1rm != null).toList();
        if (withData.isEmpty) {
          return const EmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'Henüz rekor yok',
            message: 'kg×tekrar girince kişisel rekorların burada toplanır',
            compact: true,
          );
        }
        ExerciseSetPoint bestE1rm = withData.first;
        ExerciseSetPoint maxWeight = withData.first;
        for (final p in withData) {
          if (p.e1rm! > bestE1rm.e1rm!) bestE1rm = p;
          if ((p.weightKg ?? 0) > (maxWeight.weightKg ?? 0)) maxWeight = p;
        }
        return ListView(
          padding: AppSpacing.screen,
          children: [
            _Record('🏆', 'Tahmini 1RM',
                '${bestE1rm.e1rm!.round()} kg',
                '${fmtNum(bestE1rm.weightKg!)} kg × ${bestE1rm.reps}'),
            _Record('🏋️', 'En ağır set',
                '${fmtNum(maxWeight.weightKg!)} kg',
                '${maxWeight.reps} tekrar'),
            _Record('📈', 'Toplam kayıt', '${points.length} set', ''),
          ],
        );
      },
    );
  }
}

class _Record extends StatelessWidget {
  final String emoji, label, value, sub;
  const _Record(this.emoji, this.label, this.value, this.sub);
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: AppSpacing.card,
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            AppSpacing.hGapLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: context.texts.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant)),
                  Text(value, style: context.texts.titleMedium),
                  if (sub.isNotEmpty)
                    Text(sub,
                        style: context.texts.labelSmall?.copyWith(
                            color: context.colors.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
