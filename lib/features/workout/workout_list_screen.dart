import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../shared/widgets/app_state_views.dart';
import '../home/providers/home_providers.dart';
import 'workout_plan_providers.dart';

class WorkoutListScreen extends ConsumerWidget {
  const WorkoutListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(workoutPlanProvider);
    final profileAsync = ref.watch(userProfileProvider);

    Widget skeleton() => ListView(
          padding: AppSpacing.screen,
          children: [
            const Skeleton(width: 180, height: 24),
            AppSpacing.vGapLg,
            Skeleton.card(height: 110),
            AppSpacing.vGapMd,
            Skeleton.card(height: 110),
          ],
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Antrenman')),
      body: planAsync.when(
        loading: skeleton,
        error: (_, _) => ErrorState(
          message: 'Antrenman planı yüklenemedi',
          onRetry: () => ref.invalidate(workoutPlanProvider),
        ),
        data: (plan) => profileAsync.when(
          loading: skeleton,
          error: (_, _) => ErrorState(
            message: 'Profil yüklenemedi',
            onRetry: () => ref.invalidate(userProfileProvider),
          ),
          data: (profile) {
            final currentPhase = profile?.currentPhase ?? 1;
            final phases = plan['phases'] as List<dynamic>;
            final phase = phases.firstWhere(
              (p) => p['phase'] == currentPhase,
              orElse: () => phases.first,
            );
            final workouts = phase['workouts'] as List<dynamic>;

            if (workouts.isEmpty) {
              return const EmptyState(
                icon: Icons.fitness_center_outlined,
                title: 'Bu fazda antrenman yok',
                message: 'Ayarlardan fazı kontrol et',
              );
            }

            return ListView(
              padding: AppSpacing.screen,
              children: [
                Text(phase['name'] as String,
                    style: context.texts.headlineSmall),
                AppSpacing.vGapXs,
                Text('Hafta ${profile?.currentWeek ?? 1}',
                    style: context.texts.bodyMedium
                        ?.copyWith(color: context.colors.onSurfaceVariant)),
                AppSpacing.vGapXl,
                ...workouts.map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _WorkoutCard(workout: w),
                    )),
                AppSpacing.vGapMd,
                OutlinedButton.icon(
                  onPressed: () => context.push('/workout/history'),
                  icon: const Icon(Icons.history_rounded,
                      size: AppIconSize.sm),
                  label: const Text('Antrenman Geçmişi'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final dynamic workout;
  const _WorkoutCard({required this.workout});

  IconData _iconForType(String type) {
    if (type == 'Cardio') return Icons.directions_run_rounded;
    if (type.startsWith('Upper')) return Icons.sports_gymnastics_rounded;
    if (type.startsWith('Lower')) return Icons.directions_walk_rounded;
    return Icons.fitness_center_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final type = workout['type'] as String;
    final name = workout['name'] as String;
    final day = workout['day'] as String;
    final exercises = workout['exercises'] as List<dynamic>;

    return Card(
      child: InkWell(
        onTap: () => context.push('/workout/preview/$type'),
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color:
                          context.colors.primary.withValues(alpha: 0.14),
                      borderRadius: AppRadius.brMd,
                    ),
                    child: Icon(_iconForType(type),
                        color: context.colors.primary,
                        size: AppIconSize.md),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: context.texts.titleMedium),
                        Text(day,
                            style: context.texts.bodySmall?.copyWith(
                                color: context.colors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Text('${exercises.length} hareket',
                      style: context.texts.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant)),
                  AppSpacing.hGapSm,
                  Icon(Icons.chevron_right_rounded,
                      color: context.colors.onSurfaceVariant),
                ],
              ),
              AppSpacing.vGapMd,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: exercises.take(4).map<Widget>((e) {
                  return Chip(
                    label: Text(e['name'] as String),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
