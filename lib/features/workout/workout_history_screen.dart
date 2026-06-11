import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/providers.dart';
import '../../data/database/app_database.dart';
import '../../shared/widgets/app_state_views.dart';
import 'workout_plan_providers.dart';

final _allSessionsProvider = FutureProvider<List<WorkoutSession>>((ref) {
  return ref.watch(workoutDaoProvider).getAllSessions();
});

/// Seansın setleri (genişletilince yüklenir) — hareket adıyla gruplu.
final _sessionSetsProvider = FutureProvider.autoDispose
    .family<Map<String, List<WorkoutSet>>, int>((ref, sessionId) async {
  final dao = ref.watch(workoutDaoProvider);
  final sets = await dao.getSetsForSession(sessionId);
  final nameById = {for (final e in await dao.getAllExercises()) e.id: e.name};
  final grouped = <String, List<WorkoutSet>>{};
  for (final s in sets) {
    grouped.putIfAbsent(nameById[s.exerciseId] ?? '?', () => []).add(s);
  }
  return grouped;
});

class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(_allSessionsProvider);
    final namesAsync = ref.watch(workoutDisplayNamesProvider);
    final names = namesAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Antrenman Geçmişi')),
      body: sessionsAsync.when(
        loading: () => ListView(
          padding: AppSpacing.screen,
          children: [
            Skeleton.card(height: 84),
            AppSpacing.vGapMd,
            Skeleton.card(height: 84),
            AppSpacing.vGapMd,
            Skeleton.card(height: 84),
          ],
        ),
        error: (_, _) => ErrorState(
          message: 'Geçmiş yüklenemedi',
          onRetry: () => ref.invalidate(_allSessionsProvider),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const EmptyState(
              icon: Icons.history_rounded,
              title: 'Henüz antrenman yok',
              message:
                  'İlk antrenmanını tamamladığında burada görünecek',
            );
          }
          return ListView.builder(
            padding: AppSpacing.screen,
            itemCount: sessions.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _SessionCard(
                session: sessions[i],
                displayName:
                    workoutDisplayName(names, sessions[i].workoutType),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SessionCard extends ConsumerWidget {
  final WorkoutSession session;
  final String displayName;

  const _SessionCard({required this.session, required this.displayName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateTxt =
        DateFormat('d MMMM EEEE', 'tr_TR').format(session.date);
    final meta = <String>[
      dateTxt,
      if (session.durationMin != null && session.durationMin! > 0)
        '${session.durationMin} dk',
      'RPE ${session.rpe}',
    ].join('  ·  ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: context.colors.primary.withValues(alpha: 0.14),
            borderRadius: AppRadius.brMd,
          ),
          child: Icon(
            session.workoutType == 'Cardio'
                ? Icons.directions_run_rounded
                : Icons.fitness_center_rounded,
            color: context.colors.primary,
            size: AppIconSize.md,
          ),
        ),
        title: Text(displayName, style: context.texts.titleSmall),
        subtitle: Text(meta,
            style: context.texts.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant)),
        children: [_SessionDetail(sessionId: session.id)],
      ),
    );
  }
}

class _SessionDetail extends ConsumerWidget {
  final int sessionId;
  const _SessionDetail({required this.sessionId});

  String _fmtSet(WorkoutSet s) {
    final w = s.weightKg;
    final wTxt = w == null
        ? '—'
        : (w == w.roundToDouble()
            ? w.round().toString()
            : w.toStringAsFixed(1));
    return '$wTxt kg × ${s.reps ?? '—'}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(_sessionSetsProvider(sessionId));
    return setsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (_, _) => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text('Setler yüklenemedi'),
      ),
      data: (grouped) {
        if (grouped.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('Set kaydı yok',
                style: context.texts.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
          );
        }
        // Toplam hacim = Σ kg × tekrar — seansın "iş" özeti.
        double volume = 0;
        for (final sets in grouped.values) {
          for (final s in sets) {
            volume += (s.weightKg ?? 0) * (s.reps ?? 0);
          }
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (volume > 0) ...[
                Text('Toplam hacim: ${volume.round()} kg',
                    style: context.texts.labelMedium?.copyWith(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w700)),
                AppSpacing.vGapMd,
              ],
              ...grouped.entries.map((e) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: Text(e.key,
                                style: context.texts.bodyMedium)),
                        AppSpacing.hGapMd,
                        Text(
                          e.value.map(_fmtSet).join('  ·  '),
                          style: context.texts.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}
