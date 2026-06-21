import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/providers.dart';
import '../../shared/widgets/app_state_views.dart';
import 'routine_providers.dart';
import 'workout_ui.dart';

/// Rutin Önizleme (Claude Design reskin). Hareketler + hedef set×tekrar +
/// "Antrenmana Başla" + Düzenle/Arşivle. Hareket adları İngilizce.
class RoutinePreviewScreen extends ConsumerWidget {
  final int routineId;
  const RoutinePreviewScreen({super.key, required this.routineId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routine = ref
        .watch(activeRoutinesProvider)
        .valueOrNull
        ?.where((r) => r.id == routineId)
        .firstOrNull;
    final exAsync = ref.watch(routineExercisesProvider(routineId));

    return Scaffold(
      appBar: AppBar(
        title: Text(routine?.name ?? 'Rutin'),
        actions: [
          IconButton(
            tooltip: 'Düzenle',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/workout/routine/$routineId/edit'),
          ),
          IconButton(
            tooltip: 'Arşivle',
            icon: const Icon(Icons.archive_outlined),
            onPressed: () async {
              final ok = await confirmAction(
                context,
                title: 'Rutini arşivle',
                message:
                    'Bu rutin listeden kaldırılsın mı? Geçmiş antrenmanlar korunur.',
                confirmLabel: 'Arşivle',
              );
              if (!ok) return;
              await ref.read(workoutDaoProvider).archiveRoutine(routineId);
              ref.invalidate(activeRoutinesProvider);
              ref.invalidate(todayRoutineProvider);
              if (context.mounted) context.pop();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/workout/active/$routineId'),
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Antrenmana Başla'),
      ),
      body: exAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorState(
          message: 'Rutin yüklenemedi',
          onRetry: () => ref.invalidate(routineExercisesProvider(routineId)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.fitness_center_outlined,
              title: 'Bu rutin boş',
              message: 'Düzenle ile hareket ekle',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
            itemCount: items.length,
            separatorBuilder: (_, _) => AppSpacing.vGapMd,
            itemBuilder: (_, i) {
              final it = items[i];
              final re = it.routineExercise;
              final target = re.targetSets != null
                  ? '${re.targetSets}×${re.targetRepsMin ?? ''}'
                      '${re.targetRepsMax != null ? '-${re.targetRepsMax}' : ''}'
                  : '';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.md + 1),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 26,
                        child: Text('${i + 1}',
                            textAlign: TextAlign.center,
                            style: context.texts.titleSmall?.copyWith(
                              color: context.colors.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                              fontWeight: FontWeight.w800,
                            )),
                      ),
                      AppSpacing.hGapSm,
                      _EquipBadge(equipment: it.exercise.equipment),
                      AppSpacing.hGapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.exercise.name,
                                style: context.texts.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(
                              WorkoutUi.muscleEquip(it.exercise.primaryMuscle,
                                  it.exercise.equipment),
                              style: context.texts.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      if (target.isNotEmpty) ...[
                        AppSpacing.hGapSm,
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.colors.primary
                                .withValues(alpha: 0.12),
                            borderRadius: AppRadius.brSm,
                          ),
                          child: Text(target,
                              style: context.texts.labelMedium?.copyWith(
                                color: context.colors.primary,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EquipBadge extends StatelessWidget {
  final String? equipment;
  const _EquipBadge({required this.equipment});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: context.colors.onSurface.withValues(alpha: dark ? 0.06 : 0.05),
        borderRadius: AppRadius.brMd,
      ),
      child: Icon(WorkoutUi.equipmentIcon(equipment),
          color: context.colors.onSurfaceVariant, size: 19),
    );
  }
}
