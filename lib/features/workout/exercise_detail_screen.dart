import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/formatting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/units/units.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/workout_dao.dart';
import '../../data/providers.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/app_state_views.dart';
import 'muscle_map.dart';
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
    final l = AppL10n.of(context);
    final ex = ref.watch(_exerciseProvider(exerciseId)).valueOrNull;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(ex?.name ?? l.edFallbackTitle),
          actions: [
            if (ex?.isCustom == true)
              IconButton(
                tooltip: l.commonArchive,
                icon: const Icon(Icons.archive_outlined),
                onPressed: () async {
                  final ok = await confirmAction(
                    context,
                    title: l.edArchiveTitle,
                    message: l.edArchiveMsg(ex!.name),
                    confirmLabel: l.commonArchive,
                  );
                  if (!ok) return;
                  await ref.read(workoutDaoProvider).archiveExercise(ex.id);
                  // Kütüphane reaktif (H-05) → arşivleme kendiliğinden yansır.
                  if (context.mounted) context.pop();
                },
              ),
          ],
          bottom: TabBar(isScrollable: true, tabs: [
            Tab(text: l.edTabHow),
            Tab(text: l.edTabHistory),
            Tab(text: l.edTabChart),
            Tab(text: l.edTabRecords),
          ]),
        ),
        // TabBarView yerine IndexedStack: sekmeye dokununca içerik yatay
        // KAYMADAN anlık değişir (Samet "slayt gibi kaymasın" dedi). Tüm
        // sekmeler canlı kalır → durum/scroll korunur, tekrar fetch yok.
        // Başlık altı çizgi göstergesi TabBar'da normal şekilde kayar.
        body: Builder(
          builder: (context) {
            final controller = DefaultTabController.of(context);
            return AnimatedBuilder(
              animation: controller,
              builder: (context, _) => IndexedStack(
                index: controller.index,
                children: [
                  ExerciseHowToContent(exercise: ex),
                  _HistoryTab(exerciseId: exerciseId, exercise: ex),
                  _ChartTab(exerciseId: exerciseId),
                  _RecordsTab(exerciseId: exerciseId),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Aktif seans sırasında hareketin "nasıl yapılır" bilgisini modal sheet'te
/// gösterir (#2 — talimat + kas haritası + demo görseli). Detay ekranına gitmeye
/// gerek kalmadan seans akışı bozulmaz.
void showExerciseHowToSheet(BuildContext context, Exercise exercise) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
            child: Text(exercise.name,
                style: ctx.texts.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: ExerciseHowToContent(
                exercise: exercise, scrollController: scrollController),
          ),
        ],
      ),
    ),
  );
}

/// Hareketin "Nasıl Yapılır" içeriği (İçerik Zenginleştirme — docs/11): form
/// görseli + adım adım talimat + meta (kas/ekipman/seviye). free-exercise-db.
/// Hem hareket detayı sekmesinde hem aktif seans sheet'inde kullanılır (#2).
class ExerciseHowToContent extends StatelessWidget {
  final Exercise? exercise;
  final ScrollController? scrollController; // sheet içinde kaydırma için
  const ExerciseHowToContent({super.key, this.exercise, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final ex = exercise;
    if (ex == null) return const SizedBox.shrink();
    final steps = <String>[];
    if (ex.instructions != null && ex.instructions!.isNotEmpty) {
      try {
        steps.addAll((jsonDecode(ex.instructions!) as List).cast<String>());
      } catch (_) {}
    }
    final muscles = <String>[];
    if (ex.muscleGroups.isNotEmpty) {
      try {
        muscles.addAll((jsonDecode(ex.muscleGroups) as List).cast<String>());
      } catch (_) {}
    }
    return ListView(
      controller: scrollController,
      padding: AppSpacing.screen,
      children: [
        // Demo fotoğrafı (free-exercise-db, public domain) — CDN'den lazy-load
        // + cache. Yoksa/internetsizse ekipman ikonu yer tutucu.
        if (_demoImageUrl(ex.imagePath) != null)
          ClipRRect(
            borderRadius: AppRadius.brLg,
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: CachedNetworkImage(
                imageUrl: _demoImageUrl(ex.imagePath)!,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  color: context.colors.surfaceContainerHighest,
                  child: const Center(
                      child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2))),
                ),
                errorWidget: (_, _, _) => Container(
                  color: context.colors.surfaceContainerHighest,
                  child: Icon(WorkoutUi.equipmentIcon(ex.equipment),
                      size: AppIconSize.xxl,
                      color: context.colors.onSurfaceVariant),
                ),
              ),
            ),
          ),
        // Çalışan kaslar — vücut diyagramı (veriden renklenir).
        if (ex.primaryMuscle != null || muscles.isNotEmpty) ...[
          AppSpacing.vGapLg,
          Text(AppL10n.of(context).edMusclesWorked,
              style: context.texts.titleSmall),
          AppSpacing.vGapSm,
          Center(
              child: MuscleMap(
                  primaryMuscle: ex.primaryMuscle, muscles: muscles)),
          AppSpacing.vGapXs,
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legendDot(context, context.colors.primary,
                AppL10n.of(context).edPrimary),
            AppSpacing.hGapLg,
            _legendDot(context,
                context.colors.primary.withValues(alpha: 0.4),
                AppL10n.of(context).edSecondary),
          ]),
        ],
        AppSpacing.vGapLg,
        _InfoCard(ex),
        if (ex.level != null) ...[
          AppSpacing.vGapMd,
          Wrap(spacing: AppSpacing.sm, children: [
            _Chip(_levelLabel(AppL10n.of(context), ex.level!)),
            if (ex.force != null)
              _Chip(_forceLabel(AppL10n.of(context), ex.force!)),
          ]),
        ],
        AppSpacing.vGapLg,
        if (steps.isEmpty)
          EmptyState(
            icon: Icons.menu_book_rounded,
            title: AppL10n.of(context).edNoInstructions,
            message: AppL10n.of(context).edNoInstructionsMsg,
            compact: true,
          )
        else ...[
          Text(AppL10n.of(context).edHowTo,
              style: context.texts.titleSmall),
          AppSpacing.vGapMd,
          ...steps.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.colors.primary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Text('${e.key + 1}',
                          style: context.texts.labelMedium?.copyWith(
                              color: context.colors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                    AppSpacing.hGapMd,
                    Expanded(
                        child: Text(e.value,
                            style: context.texts.bodyMedium)),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  /// imagePath 'assets/exercise_img/...' → free-exercise-db jsDelivr CDN URL'i
  /// (public domain). Sadece bu önekli yollar için; değilse null.
  static String? _demoImageUrl(String? imagePath) {
    const prefix = 'assets/exercise_img/';
    if (imagePath == null || !imagePath.startsWith(prefix)) return null;
    final rel = imagePath.substring(prefix.length);
    return 'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/$rel';
  }

  Widget _legendDot(BuildContext context, Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      AppSpacing.hGapXs,
      Text(label,
          style: context.texts.labelMedium
              ?.copyWith(color: context.colors.onSurfaceVariant)),
    ]);
  }

  static String _levelLabel(AppL10n l, String level) => switch (level) {
        'beginner' => l.edLevelBeginner,
        'intermediate' => l.edLevelIntermediate,
        'expert' => l.edLevelExpert,
        _ => level,
      };
  static String _forceLabel(AppL10n l, String force) => switch (force) {
        'push' => l.edForcePush,
        'pull' => l.edForcePull,
        'static' => l.edForceStatic,
        _ => force,
      };
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: AppRadius.brPill,
      ),
      child: Text(label,
          style: context.texts.labelMedium
              ?.copyWith(color: context.colors.onSurfaceVariant)),
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
    final units = ref.watch(unitsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          Center(child: Text(AppL10n.of(context).edLoadError)),
      data: (points) {
        final df = context.dateFmt('d MMM yyyy');
        return ListView(
          padding: AppSpacing.screen,
          children: [
            if (exercise != null) _InfoCard(exercise!),
            AppSpacing.vGapLg,
            if (points.isEmpty)
              EmptyState(
                icon: Icons.history_rounded,
                title: AppL10n.of(context).nutritionNoEntries,
                message: AppL10n.of(context).edAppearsHere,
                compact: true,
              )
            else ...[
              Text(AppL10n.of(context).edSetHistory,
                  style: context.texts.titleSmall),
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
                              ? '${units.weight(p.weightKg!)} × ${p.reps ?? '-'}'
                              : '${p.reps ?? '-'} ${AppL10n.of(context).unitReps}',
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
      error: (_, _) =>
          Center(child: Text(AppL10n.of(context).edLoadError)),
      data: (points) {
        final units = ref.watch(unitsProvider);
        // Grafik görüntü biriminde çizilir (hesap kg — docs/16 §3).
        final e1rms = points
            .where((p) => p.e1rm != null)
            .map((p) => units.weightFromKg(p.e1rm!))
            .toList();
        if (e1rms.length < 2) {
          return EmptyState(
            icon: Icons.show_chart_rounded,
            title: AppL10n.of(context).edChartEmpty,
            message: AppL10n.of(context).edChartEmptyMsg,
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
              Text(AppL10n.of(context).edE1rmTitle,
                  style: context.texts.titleSmall),
              Text(AppL10n.of(context).edEpley,
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
      error: (_, _) =>
          Center(child: Text(AppL10n.of(context).edLoadError)),
      data: (points) {
        final units = ref.watch(unitsProvider);
        final withData = points.where((p) => p.e1rm != null).toList();
        if (withData.isEmpty) {
          return EmptyState(
            icon: Icons.emoji_events_outlined,
            title: AppL10n.of(context).edNoPr,
            message: AppL10n.of(context).edNoPrMsg,
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
            _Record(
                Icons.emoji_events_rounded,
                context.semantic.warning,
                AppL10n.of(context).edBestE1rm,
                units.weight(bestE1rm.e1rm!, frac: 0),
                '${units.weight(bestE1rm.weightKg!)} × ${bestE1rm.reps}'),
            _Record(
                Icons.fitness_center_rounded,
                context.colors.primary,
                AppL10n.of(context).edHeaviest,
                units.weight(maxWeight.weightKg!),
                '${maxWeight.reps} ${AppL10n.of(context).unitReps}'),
            _Record(
                Icons.insights_rounded,
                context.colors.secondary,
                AppL10n.of(context).edTotalLogs,
                '${points.length} set',
                ''),
          ],
        );
      },
    );
  }
}

class _Record extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String label, value, sub;
  const _Record(this.icon, this.tint, this.label, this.value, this.sub);
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: AppSpacing.card,
        child: Row(
          children: [
            // Emoji yerine temanın ikon-rozet dili (emoji denetimi).
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.16),
                borderRadius: AppRadius.brMd,
              ),
              child: Icon(icon, color: tint),
            ),
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
