import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/formatting.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/units/units.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/glass.dart';
import '../activity/activity_providers.dart';
import '../../shared/widgets/fitpack_icon.dart';

/// Bir günün kayıtları (docs/24): antrenman · beslenme · su. Ay görünümünün
/// altında ve haftalık şeritten açılan panelde aynı bileşen kullanılır.
///
/// Yalnız GERÇEKTEN olanı gösterir: kaydı olmayan başlık hiç çizilmez; hiç
/// kayıt yoksa tek cümle. Hedefe göre "başarısız" yorumu yapılmaz.
class DayRecords extends ConsumerWidget {
  final DayActivity? activity;

  /// "Aç"a basılınca, gezinmeden ÖNCE çağrılır (panel kendini kapatsın diye).
  final VoidCallback? beforeOpen;

  const DayRecords({super.key, required this.activity, this.beforeOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final a = activity;
    final c = context.colors;
    final s = context.semantic;

    if (a == null || a.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text(l.actNoEntry,
            style: context.texts.bodyMedium
                ?.copyWith(color: c.onSurfaceVariant)),
      );
    }

    final units = ref.watch(unitsProvider);
    final fmt = context.numFmt;
    final hasNutrition = a.kcal > 0 || a.protein > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (a.hasWorkout)
          GlassCard(
            radius: AppRadius.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Badge(icon: Icons.check_rounded, tint: c.primary),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: Text(l.navWorkout,
                          style: context.texts.titleSmall),
                    ),
                    TextButton(
                      onPressed: () {
                        beforeOpen?.call();
                        context.push(AppRoutes.workoutHistory);
                      },
                      child: Text('${l.calOpen} ›'),
                    ),
                  ],
                ),
                if (a.workoutName != null)
                  // Aynı gün birden çok seans: set ve hacim hepsinin toplamı,
                  // ad yalnız birinin — "+N" bunu gizlemesin diye.
                  Text(
                      a.sessionCount > 1
                          ? '${a.workoutName!} +${a.sessionCount - 1}'
                          : a.workoutName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  l.calWorkoutLine(
                    a.setCount,
                    '${fmt.format(units.weightFromKg(a.volumeKg).round())} '
                    '${units.weightUnit}',
                  ),
                  style: context.texts.bodySmall
                      ?.copyWith(color: c.onSurfaceVariant),
                ),
              ],
            ),
          ),
        if (hasNutrition) ...[
          if (a.hasWorkout) AppSpacing.vGapSm,
          _LineCard(
            icon: Icons.restaurant_rounded,
            tint: s.macroCalories,
            title: l.navNutrition,
            value: l.calNutritionLine(a.kcal.round(), a.protein.round()),
          ),
        ],
        if (a.waterMl > 0) ...[
          if (a.hasWorkout || hasNutrition) AppSpacing.vGapSm,
          _LineCard(
            icon: Icons.water_drop_outlined,
            tint: s.info,
            title: l.homeWaterTitle,
            value: l.calWaterLine((a.waterMl / 1000).toStringAsFixed(1)),
          ),
        ],
      ],
    );
  }
}

/// Şeritten bir güne dokununca açılan alt panel.
Future<void> showDayRecordsSheet(
  BuildContext context, {
  required DateTime day,
  required DayActivity? activity,
}) {
  final title = context.dateFmt('d MMMM EEEE').format(day);
  // Kök navigator (C-1): sekme içinden açılınca alt çubuğun arkasında kalmasın.
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: context.texts.titleLarge),
            AppSpacing.vGapMd,
            DayRecords(
              activity: activity,
              beforeOpen: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LineCard extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String value;
  const _LineCard({
    required this.icon,
    required this.tint,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.lg,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          _Badge(icon: icon, tint: tint),
          AppSpacing.hGapSm,
          Text(title, style: context.texts.titleSmall),
          AppSpacing.hGapSm,
          Expanded(
            child: Text(value,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final Color tint;
  const _Badge({required this.icon, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.16),
        borderRadius: AppRadius.brSm,
      ),
      child: FitPackIcon.material(icon, color: tint, size: AppIconSize.sm),
    );
  }
}
