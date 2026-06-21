import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/database/app_database.dart';
import '../../shared/widgets/app_state_views.dart';
import 'routine_providers.dart';

/// Antrenman ana ekranı (Antrenman V2 Faz B — docs/09-workout-v2.md).
/// Boş antrenman başlat + Rutinlerim + Yeni Rutin + Geçmiş. Sabit program yok.
class WorkoutListScreen extends ConsumerWidget {
  const WorkoutListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(activeRoutinesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrenman'),
        actions: [
          IconButton(
            tooltip: 'Hareket Kütüphanesi',
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: () => context.push('/exercises'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeRoutinesProvider);
          ref.invalidate(weekWorkoutStatsProvider);
        },
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            const _WeekStatsBar(),
            AppSpacing.vGapLg,
            _EmptyWorkoutButton(),
            AppSpacing.vGapxl_,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rutinlerim', style: context.texts.titleMedium),
                TextButton.icon(
                  onPressed: () => context.push('/workout/routine/new'),
                  icon: const Icon(Icons.add_rounded, size: AppIconSize.sm),
                  label: const Text('Yeni Rutin'),
                ),
              ],
            ),
            AppSpacing.vGapSm,
            routinesAsync.when(
              loading: () => Column(children: [
                Skeleton.card(height: 84),
                AppSpacing.vGapMd,
                Skeleton.card(height: 84),
              ]),
              error: (_, _) => ErrorState(
                message: 'Rutinler yüklenemedi',
                onRetry: () => ref.invalidate(activeRoutinesProvider),
              ),
              data: (routines) {
                if (routines.isEmpty) {
                  return _NoRoutines(
                    onCreate: () => context.push('/workout/routine/new'),
                  );
                }
                return Column(
                  children: routines
                      .map((r) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _RoutineCard(routine: r),
                          ))
                      .toList(),
                );
              },
            ),
            AppSpacing.vGapMd,
            OutlinedButton.icon(
              onPressed: () => context.push('/workout/history'),
              icon: const Icon(Icons.history_rounded, size: AppIconSize.sm),
              label: const Text('Antrenman Geçmişi'),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _WeekStatsBar extends ConsumerWidget {
  const _WeekStatsBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(weekWorkoutStatsProvider).valueOrNull;
    final sessions = stats?.sessions ?? 0;
    final volume = stats?.volumeKg ?? 0;
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            label: 'BU HAFTA',
            value: '$sessions',
            unit: 'antrenman',
          ),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: _StatBox(
            label: 'TOPLAM HACİM',
            value: volume >= 1000
                ? '${(volume / 1000).toStringAsFixed(1)}k'
                : '$volume',
            unit: 'kg',
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value, unit;
  const _StatBox(
      {required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: context.texts.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                )),
            AppSpacing.vGapSm,
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: context.texts.headlineSmall),
                AppSpacing.hGapXs,
                Text(unit,
                    style: context.texts.bodySmall
                        ?.copyWith(color: context.colors.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWorkoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.brXl,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.indigo, AppColors.indigoDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigoDeep.withValues(alpha: 0.24),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.brXl,
        child: InkWell(
          onTap: () => context.push('/workout/active'),
          borderRadius: AppRadius.brXl,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.lg + 2),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.white),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Boş Antrenman Başlat',
                          style: context.texts.titleMedium
                              ?.copyWith(color: Colors.white)),
                      Text('Rutin olmadan hızlıca başla',
                          style: context.texts.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.82))),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoRoutines extends StatelessWidget {
  final VoidCallback onCreate;
  const _NoRoutines({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.list_alt_rounded,
      title: 'Henüz rutin yok',
      message: 'Kendi antrenman rutinini oluştur — hareketleri seç, '
          'hedef set ve tekrarları belirle.',
      actionLabel: 'İlk Rutinini Oluştur',
      onAction: onCreate,
      compact: true,
    );
  }
}

class _RoutineCard extends ConsumerWidget {
  final Routine routine;
  const _RoutineCard({required this.routine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exAsync = ref.watch(routineExercisesProvider(routine.id));
    final exercises = exAsync.valueOrNull ?? [];
    final day = routine.scheduledWeekday != null
        ? kWeekdayTr[routine.scheduledWeekday]
        : null;

    return Card(
      child: InkWell(
        onTap: () => context.push('/workout/routine/${routine.id}/preview'),
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.12),
                      borderRadius: AppRadius.brMd,
                    ),
                    child: Icon(Icons.fitness_center_rounded,
                        color: context.colors.primary, size: AppIconSize.md),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(routine.name, style: context.texts.titleSmall),
                        const SizedBox(height: 2),
                        Text(
                          [
                            '${exercises.length} hareket',
                            ?day,
                          ].join(' · '),
                          style: context.texts.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: context.colors.onSurfaceVariant),
                ],
              ),
              if (exercises.isNotEmpty) ...[
                AppSpacing.vGapMd,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: exercises
                      .take(4)
                      .map((e) => _Tag(e.exercise.name))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: AppRadius.brSm,
      ),
      child: Text(label,
          style: context.texts.labelSmall
              ?.copyWith(color: context.colors.onSurfaceVariant)),
    );
  }
}
