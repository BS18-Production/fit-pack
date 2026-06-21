import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/providers.dart';
import '../../shared/widgets/app_state_views.dart';
import 'exercise_library_screen.dart' show kEquipmentTr;
import 'routine_providers.dart';

/// Rutin Önizleme (Antrenman V2 Faz B). Hareketler + hedef set×tekrar +
/// "Antrenmana Başla" + Düzenle/Arşivle.
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
            onPressed: () =>
                context.push('/workout/routine/$routineId/edit'),
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
            separatorBuilder: (_, _) => AppSpacing.vGapSm,
            itemBuilder: (_, i) {
              final it = items[i];
              final re = it.routineExercise;
              final target = re.targetSets != null
                  ? '${re.targetSets} × ${re.targetRepsMin ?? ''}'
                      '${re.targetRepsMax != null ? '-${re.targetRepsMax}' : ''}'
                  : '';
              return Card(
                child: Padding(
                  padding: AppSpacing.cardCompact,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            context.colors.primary.withValues(alpha: 0.12),
                        child: Text('${i + 1}',
                            style: context.texts.labelMedium?.copyWith(
                                color: context.colors.primary,
                                fontWeight: FontWeight.w800)),
                      ),
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
                              [
                                kEquipmentTr[it.exercise.equipment] ?? '',
                                if (target.isNotEmpty) 'Hedef: $target',
                              ].where((s) => s.isNotEmpty).join(' · '),
                              style: context.texts.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
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
