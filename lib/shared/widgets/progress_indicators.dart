import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';

/// Modern beslenme/ilerleme görselleştirme bileşenleri.
///
/// KURAL (çökme önleme): tema okuması HER ZAMAN `build()` içinde yapılır,
/// animasyon `builder`'ının içinde DEĞİL. Aksi halde her tick'te
/// `Theme.of(context)` çağrılır → kısa ömürlü widget hızlı mount/unmount
/// olunca `InheritedElement` dangling dependent (çökme).

/// Kalori halkası — tüketilen vs hedef. Ortada "kalan" hero sayısı.
/// Hedef aşılırsa halka uyarı rengine döner.
class CalorieRing extends StatelessWidget {
  final double consumed;
  final int goal;
  final double size;
  final double? protein;
  final int? proteinGoal;

  const CalorieRing({
    super.key,
    required this.consumed,
    required this.goal,
    this.size = 168,
    this.protein,
    this.proteinGoal,
  });

  @override
  Widget build(BuildContext context) {
    // Tema build()'de okunur — animasyon builder'ında değil.
    final ringColor = context.semantic.macroCalories;
    final overColor = context.semantic.warning;
    final trackColor = context.colors.surfaceContainerHighest;
    final foreground = context.colors.onSurface;
    final glassColor = context.colors.surfaceContainerHigh;
    final proteinColor = context.semantic.macroProtein;
    final l = AppL10n.of(context);
    // Sayı boyutu halka boyutuyla orantılı: 204px halka → ~48px sayı (hero).
    final titleStyle = context.texts.displaySmall?.copyWith(
      fontSize: size * 0.235,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.03 * (size * 0.235),
      height: 1.0,
    );
    final subStyle = context.texts.labelMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    final pct = goal > 0 ? consumed / goal : 0.0;
    final over = consumed > goal;
    final remaining = (goal - consumed).round();
    final active = over ? overColor : ringColor;
    final proteinPct =
        proteinGoal != null && proteinGoal! > 0 && protein != null
        ? (protein! / proteinGoal!).clamp(0.0, 1.0)
        : null;
    final label = over ? l.nutritionKcalOver : l.nutritionKcalLeft;

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
        duration: AppDuration.slow,
        curve: Curves.easeOutCubic,
        builder: (_, animated, _) {
          return CustomPaint(
            painter: _RingPainter(
              progress: animated,
              color: active,
              track: trackColor,
              // Tasarım: 204px halkada ~14px iz → ~0.068 oran.
              stroke: size * 0.068,
              glass: glassColor,
              proteinProgress: proteinPct,
              proteinColor: proteinColor,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    over ? '+${remaining.abs()}' : '$remaining',
                    style: titleStyle?.copyWith(color: foreground),
                  ),
                  Text(label, style: subStyle),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;
  final double stroke;
  final Color glass;
  final double? proteinProgress;
  final Color proteinColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.stroke,
    required this.glass,
    required this.proteinProgress,
    required this.proteinColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;
    final face = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.35, -.65),
        colors: [glass, glass.withValues(alpha: .12)],
      ).createShader(rect);
    canvas.drawCircle(center, radius - stroke, face);

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, 2 * math.pi, false, trackPaint);

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    if (progress > 0) {
      final glow = Paint()
        ..color = color.withValues(alpha: .3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawArc(rect, start, 2 * math.pi * progress, false, glow);
      canvas.drawArc(rect, start, 2 * math.pi * progress, false, arcPaint);
    }
    if (proteinProgress != null) {
      final inner = Rect.fromCircle(
        center: center,
        radius: radius - stroke * 1.35,
      );
      final paint = Paint()
        ..color = track.withValues(alpha: .6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * .3
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(inner, start, 2 * math.pi, false, paint);
      if (proteinProgress! > 0) {
        paint.color = proteinColor.withValues(alpha: .55);
        canvas.drawArc(
          inner,
          start,
          2 * math.pi * proteinProgress!,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.track != track ||
      old.stroke != stroke ||
      old.glass != glass ||
      old.proteinProgress != proteinProgress ||
      old.proteinColor != proteinColor;
}

/// "P20 K28 Y45" satırı — kısaltmalar makro renkleriyle kodlu, böylece
/// P/K/Y'nin ne olduğu çubuklardaki renklerle eşleşerek anlaşılır.
class MacroInlineText extends StatelessWidget {
  final double protein;
  final double carb;
  final double fat;
  final String? prefix; // örn. "560 kcal · "
  final String? suffix; // örn. " /100g"

  const MacroInlineText({
    super.key,
    required this.protein,
    required this.carb,
    required this.fat,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final base = context.texts.labelSmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    TextSpan macro(String letter, double value, Color color) => TextSpan(
      text: '$letter${value.round()}',
      style: base?.copyWith(color: color, fontWeight: FontWeight.w700),
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          if (prefix != null) TextSpan(text: prefix),
          macro(l.macroProteinAbbr, protein, context.semantic.macroProtein),
          const TextSpan(text: ' '),
          macro(l.macroCarbsAbbr, carb, context.semantic.macroCarbs),
          const TextSpan(text: ' '),
          macro(l.macroFatAbbr, fat, context.semantic.macroFat),
          if (suffix != null) TextSpan(text: suffix),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Makro çubuğu — tüketilen vs hedef, kalan/aşım gösterir, animasyonlu.
class MacroBar extends StatelessWidget {
  final String label;
  final double current;
  final int? goal;
  final String unit;
  final Color color;

  const MacroBar({
    super.key,
    required this.label,
    required this.current,
    required this.goal,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final hasGoal = goal != null && goal! > 0;
    final pct = hasGoal ? (current / goal!) : 0.0;
    final over = hasGoal && current > goal!;
    final track = context.colors.surfaceContainerHighest;
    final labelStyle = context.texts.labelMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    final valueStyle = context.texts.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            AppSpacing.hGapSm,
            Text(label, style: labelStyle),
            const Spacer(),
            Text(
              hasGoal
                  ? '${current.round()} / $goal $unit'
                  : '${current.round()} $unit',
              style: valueStyle?.copyWith(
                color: over ? context.semantic.warning : null,
              ),
            ),
          ],
        ),
        AppSpacing.vGapXs,
        ClipRRect(
          borderRadius: AppRadius.brSm,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
            duration: AppDuration.slow,
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => LinearProgressIndicator(
              value: hasGoal ? v : 0,
              backgroundColor: track,
              valueColor: AlwaysStoppedAnimation<Color>(
                over ? context.semantic.warning : color,
              ),
              minHeight: 7,
            ),
          ),
        ),
      ],
    );
  }
}
