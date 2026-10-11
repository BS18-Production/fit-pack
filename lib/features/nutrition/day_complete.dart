import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/fitpack_icon.dart';
import 'nutrition_screen.dart' show selectedDateProvider;

/// Seçili günün "kaydım tamamlandı" durumu (docs/37 §1).
typedef DayCompletion = ({bool complete, bool changedAfter});

/// Reaktif: gün işaretlenince ya da o güne kayıt eklenince/değişince yeniden
/// hesaplanır (gün tablosu + öğün kayıtları izlenir; elle invalidate gerekmez).
final dayCompletionProvider = StreamProvider<DayCompletion>((ref) {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedDateProvider);
  final dao = ref.read(nutritionDaoProvider);
  return watchTables(db, [db.nutritionDays, db.foodLogs], () async {
    final row = await (db.select(db.nutritionDays)
          ..where((n) => n.day.equals(_key(date))))
        .getSingleOrNull();
    final complete = row?.status == 'complete';
    return (
      complete: complete,
      changedAfter: complete && await dao.changedAfterComplete(date),
    );
  });
});

String _key(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Beslenme ekranının altında: "Bugünkü kaydım tamamlandı" düğmesi ya da
/// ✓ durumu + geri al. Geçmiş günü sonradan işaretlemek serbest (docs/21 #8).
class DayCompleteCard extends ConsumerWidget {
  const DayCompleteCard({super.key, required this.date, required this.isToday});

  final DateTime date;
  final bool isToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final state = ref.watch(dayCompletionProvider);
    final dao = ref.read(nutritionDaoProvider);
    final s = state.valueOrNull;
    if (s == null) return const SizedBox.shrink();

    if (!s.complete) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kenarlıklı: "Yemek Ekle" ana eylem kalır, bu ikincil (görsel
          // kontrol 2026-10-11 — iki parlak birincil düğme yarışıyordu).
          OutlinedButton.icon(
            key: const ValueKey('nutrition.dayComplete'),
            onPressed: () => dao.markDayComplete(date),
            icon: const FitPackIcon.material(Icons.task_alt_rounded),
            label: Text(isToday
                ? l.nutritionDayCompleteToday
                : l.nutritionDayCompletePast),
          ),
          AppSpacing.vGapXs,
          Text(
            l.nutritionDayCompleteHint,
            textAlign: TextAlign.center,
            style: context.texts.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      );
    }
    return Container(
      key: const ValueKey('nutrition.dayCompleted'),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.secondaryContainer,
        borderRadius: AppRadius.brControl,
      ),
      child: Row(
        children: [
          FitPackIcon.material(Icons.task_alt_rounded,
              color: context.colors.secondary),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.nutritionDayCompleted,
                    style: context.texts.titleSmall),
                if (s.changedAfter)
                  Text(
                    l.nutritionDayChangedAfter,
                    style: context.texts.bodySmall
                        ?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          TextButton(
            key: const ValueKey('nutrition.dayReopen'),
            onPressed: () => dao.reopenDay(date),
            child: Text(l.nutritionDayReopen),
          ),
        ],
      ),
    );
  }
}
