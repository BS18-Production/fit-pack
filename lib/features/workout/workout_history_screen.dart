import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/app_state_views.dart';
import 'history_card.dart';
import 'history_providers.dart';

/// Antrenman geçmişi (docs/31): seans başına özet kart, dokununca detay.
/// **Reaktif** (H-05): seans silinince/eklenince kendiliğinden tazelenir.
class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final historyAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.workoutHistory)),
      body: historyAsync.when(
        loading: () => ListView(
          padding: AppSpacing.screen,
          children: [
            Skeleton.card(height: 150),
            AppSpacing.vGapMd,
            Skeleton.card(height: 150),
            AppSpacing.vGapMd,
            Skeleton.card(height: 150),
          ],
        ),
        error: (_, _) => ErrorState(
          message: l.whLoadError,
          onRetry: () => ref.invalidate(workoutHistoryProvider),
        ),
        data: (h) {
          if (h.entries.isEmpty) {
            return EmptyState(
              icon: Icons.history_rounded,
              title: l.whEmptyTitle,
              message: l.whEmptyMsg,
            );
          }
          return ListView.builder(
            padding: AppSpacing.screen,
            itemCount: h.entries.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: HistoryCard(
                key: ValueKey(h.entries[i].session.id),
                entry: h.entries[i],
                exercisesById: h.exercisesById,
              ),
            ),
          );
        },
      ),
    );
  }
}
