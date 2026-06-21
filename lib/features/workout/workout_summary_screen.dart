import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/database/app_database.dart';
import '../../data/providers.dart';

/// Antrenman Özeti (Antrenman V2 Faz C). Süre, toplam hacim, set sayısı,
/// hareket bazlı döküm. Seans zaten kaydedildi; bu ekran recap.
class WorkoutSummaryScreen extends ConsumerWidget {
  final int sessionId;
  const WorkoutSummaryScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_summaryProvider(sessionId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/workout');
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Antrenman Özeti'),
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('Özet yüklenemedi')),
          data: (s) => ListView(
            padding: AppSpacing.screen,
            children: [
              AppSpacing.vGapMd,
              Icon(Icons.check_circle_rounded,
                  size: AppIconSize.xxl, color: context.semantic.success),
              AppSpacing.vGapMd,
              Center(
                child: Text(s.title,
                    style: context.texts.headlineSmall,
                    textAlign: TextAlign.center),
              ),
              AppSpacing.vGapxl_,
              Row(
                children: [
                  Expanded(child: _Metric('Süre', '${s.durationMin} dk')),
                  AppSpacing.hGapMd,
                  Expanded(child: _Metric('Toplam Hacim', '${s.volume} kg')),
                ],
              ),
              AppSpacing.vGapMd,
              Row(
                children: [
                  Expanded(child: _Metric('Set', '${s.totalSets}')),
                  AppSpacing.hGapMd,
                  Expanded(child: _Metric('Hareket', '${s.perExercise.length}')),
                ],
              ),
              AppSpacing.vGapxl_,
              Text('Hareketler', style: context.texts.titleMedium),
              AppSpacing.vGapSm,
              ...s.perExercise.map((e) => Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Padding(
                      padding: AppSpacing.cardCompact,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(e.name,
                                style: context.texts.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text(
                              '${e.sets} set · ${e.volume} kg',
                              style: context.texts.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  )),
              AppSpacing.vGapLg,
              FilledButton(
                onPressed: () => context.go('/workout'),
                child: const Text('Bitti'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label, value;
  const _Metric(this.label, this.value);
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
                    letterSpacing: 1.0)),
            AppSpacing.vGapSm,
            Text(value, style: context.texts.headlineSmall),
          ],
        ),
      ),
    );
  }
}

// ───────── özet hesabı ─────────

class _ExerciseRecap {
  final String name;
  final int sets;
  final int volume;
  _ExerciseRecap(this.name, this.sets, this.volume);
}

class _Summary {
  final String title;
  final int durationMin;
  final int volume;
  final int totalSets;
  final List<_ExerciseRecap> perExercise;
  _Summary(this.title, this.durationMin, this.volume, this.totalSets,
      this.perExercise);
}

final _summaryProvider =
    FutureProvider.family<_Summary, int>((ref, sessionId) async {
  final dao = ref.watch(workoutDaoProvider);
  final sessions = await dao.getAllSessions();
  final session = sessions.firstWhere((s) => s.id == sessionId);
  final sets = await dao.getSetsForSession(sessionId);
  final allEx = {for (final e in await dao.getAllExercises()) e.id: e.name};

  int volume = 0;
  final byEx = <int, List<WorkoutSet>>{};
  for (final s in sets) {
    volume += ((s.weightKg ?? 0) * (s.reps ?? 0)).round();
    byEx.putIfAbsent(s.exerciseId, () => []).add(s);
  }
  final recaps = byEx.entries.map((e) {
    final v = e.value
        .fold<int>(0, (a, s) => a + ((s.weightKg ?? 0) * (s.reps ?? 0)).round());
    return _ExerciseRecap(allEx[e.key] ?? 'Hareket', e.value.length, v);
  }).toList();

  return _Summary(
    session.workoutType,
    session.durationMin ?? 0,
    volume,
    sets.length,
    recaps,
  );
});
