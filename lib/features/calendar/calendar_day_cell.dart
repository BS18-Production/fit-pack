import 'package:flutter/material.dart';
import '../../core/i18n/formatting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import 'calendar_logic.dart';

/// Haftalık şerit ve ay görünümünün ortak gün hücresi (docs/24 §2).
///
/// Bugün = birincil renk dolgu · antrenman günü = tonlu dolgu + yeşil nokta ·
/// yalnız kayıt = gri nokta · seçili gün (bugün değilse) = birincil çerçeve ·
/// gelecek gün = soluk ve dokunulmaz. Boş geçmiş gün işaretsizdir —
/// kayıtsız gün "başarısız" değil, bilinmiyor.
class CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final DayMark mark;
  final bool isToday;
  final bool isSelected;
  final bool isFuture;
  final VoidCallback? onTap;

  /// Daire çapı. Nokta ve boşlukla birlikte dokunma hedefi ≥ 48.
  static const double circle = 38;
  static const double _dot = 5;

  const CalendarDayCell({
    super.key,
    required this.day,
    required this.mark,
    required this.isToday,
    required this.isSelected,
    required this.isFuture,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppL10n.of(context);

    final fill = isToday
        ? c.primary
        : (mark == DayMark.workout ? c.surfaceContainerHighest : null);
    final textColor = isToday
        ? c.onPrimary
        : (isFuture ? c.onSurfaceVariant.withValues(alpha: 0.45) : c.onSurface);
    final dotColor = switch (mark) {
      DayMark.workout => context.semantic.success,
      DayMark.record => recordDotColor(context),
      DayMark.none => Colors.transparent,
    };
    final markLabel = switch (mark) {
      DayMark.workout => l.navWorkout,
      DayMark.record => l.calLegendRecord,
      DayMark.none => null,
    };

    return Semantics(
      button: onTap != null,
      selected: isSelected,
      label: [
        context.dateFmt('d MMMM EEEE').format(day),
        ?markLabel,
      ].join(', '),
      excludeSemantics: true,
      child: InkResponse(
        onTap: isFuture ? null : onTap,
        radius: circle * 0.66,
        child: SizedBox(
          height: AppA11y.minTapTarget + AppSpacing.xs,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: circle,
                height: circle,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fill,
                  border: isSelected && !isToday
                      ? Border.all(color: c.primary, width: 2)
                      : null,
                ),
                child: Text(
                  '${day.day}',
                  style: context.texts.titleSmall?.copyWith(
                    color: textColor,
                    fontWeight: isToday || isSelected
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: _dot,
                height: _dot,
                decoration:
                    BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Kayıt var" noktasının rengi — hücre ve lejant aynı rengi kullansın.
/// `outline` açık temada fazla soluk kalıyordu (simülatörde görüldü).
Color recordDotColor(BuildContext context) =>
    context.colors.onSurfaceVariant.withValues(alpha: 0.6);

/// Gün başlıkları (P S Ç P C C P) — verilen günlerin dar adları; hafta
/// başı tercihi günlerin sırasından gelir.
class CalendarWeekdayRow extends StatelessWidget {
  final List<DateTime> days;
  const CalendarWeekdayRow({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final fmt = context.dateFmt('EEEEE');
    return Row(
      children: [
        for (final d in days)
          Expanded(
            child: Text(
              context.upper(fmt.format(d)),
              textAlign: TextAlign.center,
              style: context.texts.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
