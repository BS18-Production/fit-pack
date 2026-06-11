import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/providers.dart';
import '../../data/database/app_database.dart';
import '../../shared/widgets/app_state_views.dart';
import 'workout_plan_providers.dart';

/// Plandaki tek antrenman + geçen seansı (ghost önizleme için).
final _previewProvider = FutureProvider.autoDispose
    .family<_PreviewData?, String>((ref, type) async {
  final plan = await ref.watch(workoutPlanProvider.future);
  Map<String, dynamic>? workout;
  for (final phase in plan['phases'] as List<dynamic>) {
    for (final w in phase['workouts'] as List<dynamic>) {
      if (w['type'] == type) {
        workout = w as Map<String, dynamic>;
        break;
      }
    }
    if (workout != null) break;
  }
  if (workout == null) return null;

  final dao = ref.watch(workoutDaoProvider);
  Map<String, List<WorkoutSet>> lastSets = {};
  DateTime? lastDate;
  try {
    final last = await dao.getLastSessionWithSets(type);
    if (last != null) {
      lastDate = last.$1.date;
      final nameById = {
        for (final e in await dao.getAllExercises()) e.id: e.name
      };
      for (final s in last.$2) {
        final name = nameById[s.exerciseId];
        if (name != null) lastSets.putIfAbsent(name, () => []).add(s);
      }
    }
  } catch (_) {
    // Geçmişsiz devam.
  }
  return _PreviewData(
      workout: workout, lastSets: lastSets, lastDate: lastDate);
});

class _PreviewData {
  final Map<String, dynamic> workout;
  final Map<String, List<WorkoutSet>> lastSets;
  final DateTime? lastDate;
  _PreviewData(
      {required this.workout,
      required this.lastSets,
      required this.lastDate});
}

/// Seans öncesi ön izleme: hareketler + geçen seans değerleri + Başla.
/// Karta yanlış dokunuş artık kronometre başlatmaz.
class WorkoutPreviewScreen extends ConsumerWidget {
  final String workoutType;
  const WorkoutPreviewScreen({super.key, required this.workoutType});

  String _fmtSet(WorkoutSet s) {
    final w = s.weightKg;
    final wTxt = w == null
        ? '—'
        : (w == w.roundToDouble()
            ? w.round().toString()
            : w.toStringAsFixed(1));
    return '$wTxt×${s.reps ?? '—'}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_previewProvider(workoutType));

    return Scaffold(
      appBar: AppBar(
          title: Text(dataAsync.valueOrNull?.workout['name'] as String? ??
              'Antrenman')),
      body: dataAsync.when(
        loading: () => ListView(
          padding: AppSpacing.screen,
          children: [
            Skeleton.card(height: 72),
            AppSpacing.vGapMd,
            Skeleton.card(height: 72),
            AppSpacing.vGapMd,
            Skeleton.card(height: 72),
          ],
        ),
        error: (_, _) => ErrorState(
          message: 'Antrenman yüklenemedi',
          onRetry: () => ref.invalidate(_previewProvider(workoutType)),
        ),
        data: (data) {
          if (data == null) {
            return const EmptyState(
              icon: Icons.fitness_center_outlined,
              title: 'Antrenman bulunamadı',
              message: 'Bu antrenman tipi planda yok',
            );
          }
          final exercises = data.workout['exercises'] as List<dynamic>;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: AppSpacing.screen,
                  children: [
                    if (data.lastDate != null)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: Row(
                          children: [
                            Icon(Icons.history_rounded,
                                size: AppIconSize.sm,
                                color: context.colors.onSurfaceVariant),
                            AppSpacing.hGapSm,
                            Text(
                              'Son yapılış: ${DateFormat('d MMMM', 'tr_TR').format(data.lastDate!)}',
                              style: context.texts.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ...exercises.map((e) {
                      final name = e['name'] as String;
                      final last = data.lastSets[name] ?? const [];
                      return Card(
                        margin:
                            const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ListTile(
                          title: Text(name),
                          subtitle: Text(
                            last.isEmpty
                                ? '${e['sets']} set × ${e['repRange']} tekrar'
                                : '${e['sets']} set × ${e['repRange']} tekrar  ·  Geçen: ${last.map(_fmtSet).join(' · ')}',
                            style: context.texts.bodySmall?.copyWith(
                                color: last.isEmpty
                                    ? context.colors.onSurfaceVariant
                                    : context.colors.primary),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 88),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: () => context.pushReplacement(
                          '/workout/session/$workoutType'),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Antrenmanı Başlat'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
