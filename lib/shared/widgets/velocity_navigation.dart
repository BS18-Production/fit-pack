import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import 'fitpack_icon.dart';

/// Velocity: ikon ve etiket aynı dolu lime kapsülde.
/// Büyük metinde görsel etiket saklanır; Semantics/Tooltip daima korunur.
class VelocityNavigation extends StatelessWidget {
  const VelocityNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  }) : assert(selectedIndex >= 0 && selectedIndex < 4);
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final labels = [l.navHome, l.navWorkout, l.navNutrition, l.navProgress];
    const glyphs = [
      FitPackGlyph.home,
      FitPackGlyph.workout,
      FitPackGlyph.nutrition,
      FitPackGlyph.progress,
    ];
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scaler = MediaQuery.textScalerOf(context);
    final hideLabels =
        scaler.scale(1) > 1.3 ||
        (MediaQuery.sizeOf(context).width < 360 && scaler.scale(1) > 1.15);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppDuration.control;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? AppGlass.darkNavFill : AppGlass.lightNavFill,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadow.withValues(alpha: dark ? .2 : .08),
            blurRadius: AppSpacing.xl,
            offset: const Offset(0, AppSpacing.sm),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: List.generate(labels.length, (index) {
            final selected = index == selectedIndex;
            final ink = selected
                ? context.colors.onPrimary
                : context.colors.onSurfaceVariant;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : AppSpacing.xs),
                child: Semantics(
                  label: labels[index],
                  button: true,
                  selected: selected,
                  onTap: () => onSelected(index),
                  child: Tooltip(
                    message: labels[index],
                    excludeFromSemantics: true,
                    child: AnimatedContainer(
                      key: ValueKey('velocity-tab-$index'),
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: selected
                            ? context.colors.primary
                            : Colors.transparent,
                        borderRadius: AppRadius.brControl,
                        boxShadow: selected && dark
                            ? [
                                BoxShadow(
                                  color: context.colors.primary.withValues(
                                    alpha: .10,
                                  ),
                                  blurRadius: AppSpacing.md,
                                ),
                              ]
                            : const [],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: AppRadius.brControl,
                        child: InkWell(
                          excludeFromSemantics: true,
                          borderRadius: AppRadius.brControl,
                          onTap: () => onSelected(index),
                          child: ExcludeSemantics(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: AppSpacing.sm,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: hideLabels
                                      ? AppA11y.minTapTarget
                                      : AppNavigation.itemHeight,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FitPackIcon(
                                      glyphs[index],
                                      size: AppIconSize.navigation,
                                      color: ink,
                                    ),
                                    if (!hideLabels) ...[
                                      AppSpacing.vGapXs,
                                      Text(
                                        labels[index],
                                        maxLines: 1,
                                        style: context.texts.labelSmall
                                            ?.copyWith(
                                              color: ink,
                                              fontWeight: selected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
