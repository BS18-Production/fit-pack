import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/glass.dart';
import 'add_food_sheet.dart';
import 'nutrition_screen.dart' show selectedDateProvider;
import '../../shared/widgets/fitpack_icon.dart';

/// Temsili fotoğraf bir yemek kaydı değildir; CTA mevcut giriş panelini açar.
class MealIdeaCard extends ConsumerWidget {
  const MealIdeaCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadius.brXl,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 2.12,
              child: Image.asset(
                'assets/images/salmon_salad.jpg',
                fit: BoxFit.cover,
                semanticLabel: l.journalMealPhoto,
              ),
            ),
            Padding(
              padding: AppSpacing.card,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final heading = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.journalMealIdea,
                        style: context.texts.labelSmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        l.journalSalmonSalad,
                        style: context.texts.titleMedium,
                      ),
                    ],
                  );
                  final action = TextButton.icon(
                    key: const ValueKey('journal.addMeal'),
                    onPressed: () {
                      ref.read(selectedDateProvider.notifier).state =
                          DateTime.now();
                      showAddFoodSheet(context);
                    },
                    icon: const FitPackIcon.material(Icons.add_rounded, size: AppIconSize.sm),
                    label: Text(l.nutritionAddFood),
                  );
                  if (constraints.maxWidth < 280 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [heading, AppSpacing.vGapSm, action],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: heading),
                      AppSpacing.hGapSm,
                      action,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
