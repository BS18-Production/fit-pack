import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/i18n/formatting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/glass.dart';
import '../../shared/widgets/progress_indicators.dart';
import 'macro_goals.dart';
import '../../shared/widgets/fitpack_icon.dart';

/// Ana Sayfa ve Beslenme aynı enerji/makro kompozisyonunu kullanır.
/// Sayılar mevcut sağlayıcılardan gelir; widget veri yazmaz.
class NutritionSummaryCard extends StatelessWidget {
  final double kcal, protein, carb, fat;
  final int kcalGoal, proteinGoal;
  final VoidCallback? onTap;

  const NutritionSummaryCard({
    super.key,
    required this.kcal,
    required this.protein,
    required this.carb,
    required this.fat,
    required this.kcalGoal,
    required this.proteinGoal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final goals = deriveMacroGoals(
      kcalGoal: kcalGoal,
      proteinGoal: proteinGoal,
    );
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.journalEnergyMacros,
                  style: context.texts.titleMedium,
                ),
              ),
              if (onTap != null)
                FitPackIcon.material(
                  Icons.arrow_outward_rounded,
                  size: AppIconSize.sm,
                  color: context.colors.onSurfaceVariant,
                ),
            ],
          ),
          AppSpacing.vGapLg,
          LayoutBuilder(
            builder: (context, constraints) {
              final ring = CalorieRing(
                consumed: kcal,
                goal: kcalGoal,
                protein: protein,
                proteinGoal: proteinGoal,
                size: largeText
                    ? 190
                    : math.min(168, constraints.maxWidth * .54),
              );
              final readings = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EnergyReading(
                    label: l.journalEnergyLogged,
                    value: kcal.round(),
                  ),
                  AppSpacing.vGapLg,
                  _EnergyReading(label: l.journalEnergyGoal, value: kcalGoal),
                ],
              );
              if (largeText) {
                return Column(children: [ring, AppSpacing.vGapLg, readings]);
              }
              return Row(
                children: [
                  ring,
                  AppSpacing.hGapMd,
                  Expanded(child: readings),
                ],
              );
            },
          ),
          AppSpacing.vGapSm,
          Text(
            l.journalProteinRing,
            style: context.texts.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGapLg,
          const Divider(),
          AppSpacing.vGapLg,
          if (largeText) ...[
            MacroBar(
              label: l.macroProtein,
              current: protein,
              goal: proteinGoal,
              unit: 'g',
              color: context.semantic.macroProtein,
            ),
            AppSpacing.vGapMd,
            MacroBar(
              label: l.macroCarbs,
              current: carb,
              goal: goals.carb,
              unit: 'g',
              color: context.semantic.macroCarbs,
            ),
            AppSpacing.vGapMd,
            MacroBar(
              label: l.macroFat,
              current: fat,
              goal: goals.fat,
              unit: 'g',
              color: context.semantic.macroFat,
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _MacroTile(
                    label: l.macroProtein,
                    value: protein,
                    goal: proteinGoal,
                    color: context.semantic.macroProtein,
                  ),
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: _MacroTile(
                    label: l.macroCarbs,
                    value: carb,
                    goal: goals.carb,
                    color: context.semantic.macroCarbs,
                  ),
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: _MacroTile(
                    label: l.macroFat,
                    value: fat,
                    goal: goals.fat,
                    color: context.semantic.macroFat,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EnergyReading extends StatelessWidget {
  final String label;
  final int value;
  const _EnergyReading({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: context.texts.labelSmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      AppSpacing.vGapXs,
      Text(context.numFmt.format(value), style: context.texts.titleLarge),
      Text(
        'kcal',
        style: context.texts.labelSmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class _MacroTile extends StatelessWidget {
  final String label;
  final double value;
  final int goal;
  final Color color;
  const _MacroTile({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: context.texts.labelSmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      AppSpacing.vGapSm,
      Text(
        context.numFmt.format(value.round()),
        style: context.texts.titleMedium,
      ),
      Text(
        '/ ${context.numFmt.format(goal)} g',
        style: context.texts.labelSmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      AppSpacing.vGapSm,
      ClipRRect(
        borderRadius: AppRadius.brPill,
        child: LinearProgressIndicator(
          value: goal > 0 ? (value / goal).clamp(0, 1) : 0,
          color: color,
          backgroundColor: context.colors.surfaceContainerHighest,
          minHeight: AppSpacing.xs,
          semanticsLabel: label,
        ),
      ),
    ],
  );
}
