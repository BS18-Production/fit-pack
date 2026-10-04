import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/i18n/formatting.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_l10n.dart';
import 'rpe_scale.dart';

/// RPE seçici paneli (docs/27 F4). Klavye yerine 6–10 yarım adımlı şerit;
/// seçilen değerin efor etiketi ve kaç tekrar kaldığı canlı gösterilir.
///
/// Dönüş: `null` → vazgeçildi (değer değişmez); `(rpe: null)` → temizlendi;
/// `(rpe: x)` → seçildi.
Future<({double? rpe})?> showRpePicker(
  BuildContext context, {
  required int setNumber,
  required double? initial,
  String? setSummary,
}) {
  return showModalBottomSheet<({double? rpe})>(
    context: context,
    showDragHandle: true,
    builder: (_) => _RpePickerSheet(
        setNumber: setNumber, initial: initial, setSummary: setSummary),
  );
}

class _RpePickerSheet extends StatefulWidget {
  final int setNumber;
  final double? initial;
  final String? setSummary;
  const _RpePickerSheet(
      {required this.setNumber, required this.initial, this.setSummary});

  @override
  State<_RpePickerSheet> createState() => _RpePickerSheetState();
}

class _RpePickerSheetState extends State<_RpePickerSheet> {
  late double? _value = widget.initial;

  String _rirText(AppL10n l, double rpe) {
    final r = repsInReserve(rpe);
    if (r.max == null) return l.rpeRir_atLeast(r.min);
    if (r.max == 0) return l.rpeRir_none;
    if (r.min == r.max) return l.rpeRir_exact(r.min);
    return l.rpeRir_range(r.min, r.max!);
  }

  String _effortText(AppL10n l, RpeEffort e) => switch (e) {
        RpeEffort.light => l.rpeEffort_light,
        RpeEffort.moderate => l.rpeEffort_moderate,
        RpeEffort.vigorous => l.rpeEffort_vigorous,
        RpeEffort.veryHard => l.rpeEffort_veryHard,
        RpeEffort.extremelyHard => l.rpeEffort_extremelyHard,
        RpeEffort.max => l.rpeEffort_max,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.colors;
    final sep = context.numFmt.symbols.DECIMAL_SEP;
    final v = _value;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.rpePick_title(widget.setNumber),
                style: context.texts.titleMedium),
            if (widget.setSummary != null) ...[
              const SizedBox(height: 2),
              Text(widget.setSummary!,
                  style: context.texts.bodyMedium
                      ?.copyWith(color: c.onSurfaceVariant)),
            ],
            AppSpacing.vGapLg,
            Text(
              v == null ? '–' : formatRpe(v, decimalSep: sep),
              style: context.texts.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: v == null ? c.onSurfaceVariant : c.onSurface),
            ),
            AppSpacing.vGapXs,
            Text(v == null ? l.rpePick_select : _effortText(l, rpeEffort(v)),
                style: context.texts.titleSmall),
            const SizedBox(height: 2),
            // Yükseklik sabit: değer seçilince panel zıplamasın.
            SizedBox(
              height: 22,
              child: v == null
                  ? null
                  : Text(_rirText(l, v),
                      style: context.texts.bodyMedium
                          ?.copyWith(color: c.onSurfaceVariant)),
            ),
            AppSpacing.vGapLg,
            _RpeStrip(
              value: v,
              decimalSep: sep,
              onSelect: (x) {
                HapticFeedback.selectionClick();
                setState(() => _value = x);
              },
            ),
            AppSpacing.vGapLg,
            Row(
              children: [
                if (widget.initial != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, (rpe: null)),
                      child: Text(l.rpePick_clear),
                    ),
                  ),
                  AppSpacing.hGapMd,
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed:
                        v == null ? null : () => Navigator.pop(context, (rpe: v)),
                    icon: const Icon(Icons.check_rounded),
                    label: Text(l.rpePick_done),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 6–10 yarım adımlı seçim şeridi; seçili değer dolu daire.
class _RpeStrip extends StatelessWidget {
  final double? value;
  final String decimalSep;
  final ValueChanged<double> onSelect;
  const _RpeStrip(
      {required this.value, required this.decimalSep, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: c.surfaceContainerHighest,
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        children: [
          for (final x in rpeChoices)
            Expanded(
              child: Semantics(
                button: true,
                selected: x == value,
                child: InkWell(
                  key: ValueKey('rpe-choice-$x'),
                  customBorder: const CircleBorder(),
                  onTap: () => onSelect(x),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: x == value ? c.primary : Colors.transparent,
                      ),
                      child: Text(
                        formatRpe(x, decimalSep: decimalSep),
                        style: context.texts.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: x == value ? c.onPrimary : c.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
