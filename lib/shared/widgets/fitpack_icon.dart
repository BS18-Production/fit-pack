import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_dimens.dart';

/// FitPack'in 24 birimlik, dolu/eğimli vektör ailesi.
/// Seçili ve pasif durumlarda siluet aynıdır; renk IconTheme'den gelir.
enum FitPackGlyph {
  home,
  workout,
  nutrition,
  progress,
  plus,
  play,
  arrowRight,
  arrowUpRight,
  edit,
  history,
  settings,
  check,
  close,
  scan,
  copy,
  trash,
  calendar,
  library,
  profile,
  weight,
  water,
  chevronRight,
  chevronLeft;

  String get asset =>
      'assets/icons/fitpack/${switch (this) {
        arrowRight => 'arrow_right',
        arrowUpRight => 'arrow_up_right',
        chevronRight => 'chevron_right',
        chevronLeft => 'chevron_left',
        _ => name,
      }}.svg';
}

class FitPackIcon extends StatelessWidget {
  const FitPackIcon(
    this.glyph, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  }) : materialIcon = null;

  /// Mevcut IconData kabul eden eylem/kart API'lerini korur.
  /// Ailede karşılığı olmayan özel simgeler Material'da kalır.
  const FitPackIcon.material(
    this.materialIcon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  }) : glyph = null;
  final FitPackGlyph? glyph;
  final IconData? materialIcon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final resolvedGlyph = glyph ?? _materialGlyphs[materialIcon];
    if (resolvedGlyph == null) {
      return Icon(
        materialIcon,
        size: size,
        color: color,
        semanticLabel: semanticLabel,
      );
    }
    final theme = IconTheme.of(context);
    final resolvedSize = size ?? theme.size ?? AppIconSize.md;
    final resolvedColor =
        color ?? theme.color ?? Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(
      resolvedGlyph.asset,
      width: resolvedSize,
      height: resolvedSize,
      colorFilter: ColorFilter.mode(
        (theme.opacity == null || theme.opacity == 1)
            ? resolvedColor
            : resolvedColor.withValues(alpha: resolvedColor.a * theme.opacity!),
        BlendMode.srcIn,
      ),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}

final _materialGlyphs = <IconData, FitPackGlyph>{
  Icons.home_rounded: FitPackGlyph.home,
  Icons.home_outlined: FitPackGlyph.home,
  Icons.fitness_center_rounded: FitPackGlyph.workout,
  Icons.fitness_center_outlined: FitPackGlyph.workout,
  Icons.restaurant_rounded: FitPackGlyph.nutrition,
  Icons.restaurant_menu_rounded: FitPackGlyph.nutrition,
  Icons.insights_rounded: FitPackGlyph.progress,
  Icons.trending_up_rounded: FitPackGlyph.progress,
  Icons.add_rounded: FitPackGlyph.plus,
  Icons.add: FitPackGlyph.plus,
  Icons.play_arrow_rounded: FitPackGlyph.play,
  Icons.arrow_forward_rounded: FitPackGlyph.arrowRight,
  Icons.arrow_forward: FitPackGlyph.arrowRight,
  Icons.arrow_outward_rounded: FitPackGlyph.arrowUpRight,
  Icons.edit_rounded: FitPackGlyph.edit,
  Icons.edit_outlined: FitPackGlyph.edit,
  Icons.edit: FitPackGlyph.edit,
  Icons.history_rounded: FitPackGlyph.history,
  Icons.tune_rounded: FitPackGlyph.settings,
  Icons.settings_rounded: FitPackGlyph.settings,
  Icons.check_rounded: FitPackGlyph.check,
  Icons.check: FitPackGlyph.check,
  Icons.close_rounded: FitPackGlyph.close,
  Icons.close: FitPackGlyph.close,
  Icons.qr_code_rounded: FitPackGlyph.scan,
  Icons.qr_code_scanner_rounded: FitPackGlyph.scan,
  Icons.content_copy_rounded: FitPackGlyph.copy,
  Icons.copy_all_rounded: FitPackGlyph.copy,
  Icons.delete_rounded: FitPackGlyph.trash,
  Icons.delete_outline_rounded: FitPackGlyph.trash,
  Icons.calendar_today_rounded: FitPackGlyph.calendar,
  Icons.edit_calendar_rounded: FitPackGlyph.calendar,
  Icons.calendar_month_rounded: FitPackGlyph.calendar,
  Icons.menu_book_rounded: FitPackGlyph.library,
  Icons.person_outline_rounded: FitPackGlyph.profile,
  Icons.person_rounded: FitPackGlyph.profile,
  Icons.monitor_weight_outlined: FitPackGlyph.weight,
  Icons.water_drop_outlined: FitPackGlyph.water,
  Icons.water_drop_rounded: FitPackGlyph.water,
  Icons.chevron_right_rounded: FitPackGlyph.chevronRight,
  Icons.chevron_left_rounded: FitPackGlyph.chevronLeft,
};
