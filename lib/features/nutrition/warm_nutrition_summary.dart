import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/i18n/formatting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/nutrition_theme.dart';
import '../../l10n/app_l10n.dart';
import '../../data/database/daos/nutrition_dao.dart';
import 'macro_goals.dart';

/// Beslenmeye özgü tek enerji halkası; hedef hesapları mevcut saf mantıktan.
class WarmNutritionSummary extends StatelessWidget {
  final DailyNutrition totals;
  final int kcalGoal, proteinGoal;
  final VoidCallback onGoals;
  const WarmNutritionSummary({
    super.key,
    required this.totals,
    required this.kcalGoal,
    required this.proteinGoal,
    required this.onGoals,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.colors;
    final dark = c.brightness == Brightness.dark;
    final goals = deriveMacroGoals(
      kcalGoal: kcalGoal,
      proteinGoal: proteinGoal,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: NutritionTheme.summaryRadius,
        border: Border.all(color: c.outlineVariant),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            dark
                ? NutritionTheme.darkSummaryStart
                : NutritionTheme.lightSummaryStart,
            c.surface,
          ],
        ),
      ),
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.nutritionDailyEnergy,
                    style: context.texts.titleSmall,
                  ),
                ),
                TextButton(
                  onPressed: onGoals,
                  child: Text(l.settingsSectionGoals),
                ),
              ],
            ),
            AppSpacing.vGapSm,
            LayoutBuilder(
              builder: (context, constraints) {
                final large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
                final stacked = large || constraints.maxWidth < 285;
                final ring = WarmEnergyRing(
                  consumed: totals.kcal,
                  goal: kcalGoal,
                  size: stacked
                      ? NutritionTheme.largeRingSize
                      : NutritionTheme.ringSize,
                );
                final readings = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Reading(
                      label: l.journalEnergyLogged,
                      value: totals.kcal.round(),
                      primary: true,
                    ),
                    AppSpacing.vGapLg,
                    _Reading(label: l.journalEnergyGoal, value: kcalGoal),
                  ],
                );
                return stacked
                    ? Column(
                        children: [
                          ring,
                          AppSpacing.vGapLg,
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _Reading(
                                  label: l.journalEnergyLogged,
                                  value: totals.kcal.round(),
                                  primary: true,
                                ),
                              ),
                              AppSpacing.hGapLg,
                              Expanded(
                                child: _Reading(
                                  label: l.journalEnergyGoal,
                                  value: kcalGoal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          ring,
                          AppSpacing.hGapLg,
                          Expanded(child: readings),
                        ],
                      );
              },
            ),
            AppSpacing.vGapXl,
            LayoutBuilder(
              builder: (context, constraints) {
                final rows =
                    MediaQuery.textScalerOf(context).scale(1) > 1.15 ||
                    constraints.maxWidth < 285;
                final macros = [
                  (
                    l.macroProtein,
                    totals.protein,
                    proteinGoal,
                    context.semantic.macroProtein,
                  ),
                  (
                    l.macroCarbs,
                    totals.carb,
                    goals.carb,
                    context.semantic.macroCarbs,
                  ),
                  (
                    l.macroFat,
                    totals.fat,
                    goals.fat,
                    context.semantic.macroFat,
                  ),
                ];
                return rows
                    ? Column(
                        children: [
                          for (final m in macros)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: _Macro(
                                label: m.$1,
                                value: m.$2,
                                goal: m.$3,
                                color: m.$4,
                                row: true,
                              ),
                            ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < macros.length; i++) ...[
                            if (i > 0) AppSpacing.hGapMd,
                            Expanded(
                              child: _Macro(
                                label: macros[i].$1,
                                value: macros[i].$2,
                                goal: macros[i].$3,
                                color: macros[i].$4,
                              ),
                            ),
                          ],
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Reading extends StatelessWidget {
  final String label;
  final int value;
  final bool primary;
  const _Reading({
    required this.label,
    required this.value,
    this.primary = false,
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
      AppSpacing.vGapXs,
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: context.numFmt.format(value),
              style:
                  (primary
                          ? context.texts.headlineSmall
                          : context.texts.titleMedium)
                      ?.copyWith(
                        fontWeight: primary ? FontWeight.w800 : FontWeight.w600,
                      ),
            ),
            TextSpan(
              text: ' kcal',
              style: context.texts.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _Macro extends StatelessWidget {
  final String label;
  final double value;
  final int goal;
  final Color color;
  final bool row;
  const _Macro({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
    this.row = false,
  });
  @override
  Widget build(BuildContext context) {
    final title = Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        AppSpacing.hGapXs,
        Flexible(
          child: Text(
            label,
            style: context.texts.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
    final valueText = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: context.numFmt.format(value.round()),
            style: context.texts.titleMedium?.copyWith(fontSize: 18),
          ),
          TextSpan(
            text: row
                ? ' / ${context.numFmt.format(goal)} g'
                : '\n/ ${context.numFmt.format(goal)} g',
            style: context.texts.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
    return Semantics(
      label:
          '$label: ${context.numFmt.format(value.round())} / ${context.numFmt.format(goal)} g',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (row)
              Row(
                children: [
                  Expanded(child: title),
                  AppSpacing.hGapMd,
                  valueText,
                ],
              )
            else ...[
              title,
              AppSpacing.vGapSm,
              valueText,
            ],
            AppSpacing.vGapSm,
            ClipRRect(
              borderRadius: AppRadius.brPill,
              child: LinearProgressIndicator(
                minHeight: AppSpacing.xs,
                value: goal > 0 ? (value / goal).clamp(0, 1) : 0,
                color: color,
                backgroundColor: context.colors.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WarmEnergyRing extends StatefulWidget {
  final double consumed, size;
  final int goal;
  const WarmEnergyRing({
    super.key,
    required this.consumed,
    required this.goal,
    this.size = NutritionTheme.ringSize,
  });
  @override
  State<WarmEnergyRing> createState() => _WarmEnergyRingState();
}

class _WarmEnergyRingState extends State<WarmEnergyRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late double _from, _to;
  double get _ratio =>
      widget.goal > 0 ? (widget.consumed / widget.goal).clamp(0, 1) : 0;
  double get _value =>
      _from + (_to - _from) * Curves.easeOutCubic.transform(_controller.value);
  @override
  void initState() {
    super.initState();
    _from = _to = _ratio;
    _controller = AnimationController(
      vsync: this,
      duration: NutritionTheme.ringDuration,
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant WarmEnergyRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.consumed == widget.consumed &&
        oldWidget.goal == widget.goal) {
      return;
    }
    _from = _value;
    _to = _ratio;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final difference = widget.goal - widget.consumed.round();
    final label = difference < 0
        ? l.nutritionKcalAboveGoal
        : difference == 0
        ? l.nutritionKcalAtGoal
        : l.nutritionKcalRemaining;
    final c = context.colors;
    final dark = c.brightness == Brightness.dark;
    return Semantics(
      label:
          '${l.nutritionDailyEnergy}. ${context.numFmt.format(difference.abs())} $label. ${l.journalEnergyLogged}: ${context.numFmt.format(widget.consumed.round())} kcal. ${l.journalEnergyGoal}: ${context.numFmt.format(widget.goal)} kcal.',
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, _) => CustomPaint(
                    painter: _EnergyPainter(
                      value: _value,
                      start: c.primary,
                      end: dark
                          ? NutritionTheme.darkRingEnd
                          : NutritionTheme.lightRingEnd,
                      track: c.surfaceContainerHighest,
                      surface: c.surface,
                      outline: c.outlineVariant,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        context.numFmt.format(difference.abs()),
                        style: context.texts.displaySmall?.copyWith(
                          fontSize: 33,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ),
                    AppSpacing.vGapXs,
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: context.texts.labelSmall?.copyWith(
                        color: c.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnergyPainter extends CustomPainter {
  final double value;
  final Color start, end, track, surface, outline;
  const _EnergyPainter({
    required this.value,
    required this.start,
    required this.end,
    required this.track,
    required this.surface,
    required this.outline,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 176;
    final center = size.center(Offset.zero);
    final radius = 72 * scale;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      62 * scale,
      Paint()
        ..shader = RadialGradient(
          colors: [surface, surface.withValues(alpha: .15)],
        ).createShader(rect),
    );
    canvas.drawCircle(
      center,
      62 * scale,
      Paint()
        ..color = outline.withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = scale,
    );
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = NutritionTheme.ringStroke * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, p..color = track);
    if (value <= 0) return;
    p.shader = SweepGradient(
      colors: [start, end],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, p);
    // Sweep sınırındaki renk dikişi yuvarlak başlangıç ucunda görünmesin.
    canvas.drawCircle(
      center - Offset(0, radius),
      NutritionTheme.ringStroke * scale / 2,
      Paint()..color = start,
    );
    final angle = -math.pi / 2 + math.pi * 2 * value;
    final tip = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawCircle(
      tip,
      3 * scale,
      Paint()..color = Color.lerp(start, end, value)!,
    );
    canvas.drawCircle(tip, 1.7 * scale, Paint()..color = surface);
  }

  @override
  bool shouldRepaint(covariant _EnergyPainter old) =>
      old.value != value ||
      old.start != start ||
      old.end != end ||
      old.track != track ||
      old.surface != surface ||
      old.outline != outline;
}
