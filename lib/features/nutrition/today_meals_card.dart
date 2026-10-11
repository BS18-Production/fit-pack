import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/formatting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/fitpack_icon.dart';
import '../../shared/widgets/glass.dart';
import '../home/providers/home_providers.dart';
import 'add_food_sheet.dart';
import 'meal_types.dart';
import 'nutrition_screen.dart' show selectedDateProvider;

/// Bugün öğün başına girilen kalori (öğün anahtarı → kcal). Reaktif;
/// gün dönümünde [todayNutritionProvider] ile birlikte tazelenir.
final todayMealKcalProvider = StreamProvider<Map<String, double>>((ref) {
  ref.watch(todayNutritionProvider); // gün dönümü tazelemesine bağlan
  final db = ref.watch(databaseProvider);
  return watchTables(db, [db.foodLogs, db.foods], () async {
    final logs =
        await ref.read(nutritionDaoProvider).getLogsWithFoodForDate(DateTime.now());
    final out = <String, double>{};
    for (final l in logs) {
      out[l.log.mealType] = (out[l.log.mealType] ?? 0) + l.log.computedKcal;
    }
    return out;
  });
});

/// Saate göre sıradaki öğün (girilmemişse vurgulanır): sabah kahvaltı,
/// öğlen öğle, akşam akşam yemeği, gece ara öğün.
String suggestedMeal(DateTime now) => switch (now.hour) {
      < 11 => 'breakfast',
      < 16 => 'lunch',
      < 22 => 'dinner',
      _ => 'snack',
    };

/// Ana Sayfa "Öğün günlüğün" kartı (docs/45 §5).
///
/// Eski kart sabit bir stok fotoğraf ("Somonlu salata") gösteriyordu —
/// kullanıcının verisiyle ilgisiz, kartın asıl işini (yemek eklemek)
/// gölgeliyordu. Yerine bugünün dört öğünü: girilen öğün kalorisiyle dolu,
/// boş öğün "+" ile; saate göre sıradaki boş öğün vurgulu. Dokununca o öğün
/// için ekleme paneli açılır. Görsel uygulamanın ikon-rozet dili (tonlu
/// daire + Rounded ikon), koyu/açık temada aynı rollerle.
class TodayMealsCard extends ConsumerWidget {
  /// Bu okunur genişliğin altında (pt ÷ yazı ölçeği) dört öğün 2×2 dizilir.
  static const _twoByTwoBelow = 300.0;

  /// Testler için "şimdi"; verilmezse gerçek saat.
  final DateTime? now;

  const TodayMealsCard({super.key, this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kcal = ref.watch(todayMealKcalProvider).valueOrNull ?? const {};
    final next = suggestedMeal(now ?? DateTime.now());
    return GlassCard(
      key: const ValueKey('journal.meals'),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final readable = constraints.maxWidth /
              MediaQuery.textScalerOf(context).scale(1);
          final tiles = [
            for (final m in mealTypes)
              _MealTile(
                mealType: m,
                kcal: kcal[m],
                highlighted: m == next && kcal[m] == null,
              ),
          ];
          // Dar ekran / büyük yazı: 2×2, metin kırpılmasın.
          if (readable < _twoByTwoBelow) {
            return Column(
              children: [
                Row(children: [
                  Expanded(child: tiles[0]),
                  Expanded(child: tiles[1]),
                ]),
                AppSpacing.vGapSm,
                Row(children: [
                  Expanded(child: tiles[2]),
                  Expanded(child: tiles[3]),
                ]),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final t in tiles) Expanded(child: t)],
          );
        },
      ),
    );
  }
}

class _MealTile extends ConsumerWidget {
  // Öğün rozeti ölçüleri (yalnız bu kart) — ikon AppIconSize.md.
  static const _badge = 48.0;
  static const _check = 14.0;
  static const _checkIcon = 10.0;
  static const _ringWidth = 1.5;
  static const _animation = Duration(milliseconds: 200);

  final String mealType;
  final double? kcal;
  final bool highlighted;

  const _MealTile({
    required this.mealType,
    required this.kcal,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.colors;
    final logged = kcal != null;
    final name = mealName(l, mealType);
    final tint = logged ? c.secondary : c.primary;
    final value = logged
        ? '${context.numFmt.format(kcal!.round())} kcal'
        : l.journalMealAdd;

    return Semantics(
      button: true,
      label: logged ? '$name, $value' : l.nutritionAddTo(name),
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('journal.meal.$mealType'),
        borderRadius: AppRadius.brMd,
        onTap: () {
          ref.read(selectedDateProvider.notifier).state = DateTime.now();
          showAddFoodSheet(context, mealType: mealType);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
          child: Column(
            children: [
              AnimatedContainer(
                duration: _animation,
                width: _badge,
                height: _badge,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: logged
                      ? tint.withValues(alpha: 0.16)
                      : c.surfaceContainerHighest.withValues(alpha: 0.6),
                  border: Border.all(
                    color: highlighted ? c.primary : Colors.transparent,
                    width: _ringWidth,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    FitPackIcon.material(
                      mealIcon(mealType),
                      size: AppIconSize.md,
                      color: logged ? tint : c.onSurfaceVariant,
                    ),
                    if (logged)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: _check,
                          height: _check,
                          decoration: BoxDecoration(
                              color: tint, shape: BoxShape.circle),
                          child: FitPackIcon.material(Icons.check_rounded,
                              size: _checkIcon, color: c.onSecondary),
                        ),
                      ),
                  ],
                ),
              ),
              AppSpacing.vGapSm,
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.texts.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.texts.labelSmall?.copyWith(
                  color: logged ? c.onSurfaceVariant : c.primary,
                  fontWeight: logged ? FontWeight.w600 : FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
