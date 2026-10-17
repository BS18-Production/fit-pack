import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/formatting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/prefs/training_prefs.dart';
import '../../core/units/units.dart';
import '../../core/utils/format.dart';
import '../../l10n/app_l10n.dart';
import 'exercise_detail_screen.dart';
import 'progression.dart';
import 'rpe_picker_sheet.dart';
import 'rpe_scale.dart';
import 'session_progress.dart';
import 'set_prefill.dart';
import 'set_timer.dart';
import 'weight_step.dart';
import 'active_session_model.dart';
import 'workout_ui.dart';
import '../../shared/widgets/fitpack_icon.dart';

// Aktif seans ekranının gösterim bileşenleri (CR-018): ilerleme çubuğu,
// tarih çubuğu, mola şeridi, hareket bloğu ve set tablosu. Durum ve kayıt
// ekranda (`active_session_screen.dart`); bunlar yalnız gösterir ve geri
// çağırır.

const double sessionProgressBarHeight = 3;

/// Uygulama çubuğunun altında ince set ilerlemesi (C-16). Tümü bitince yeşil.
class SessionProgressBar extends StatelessWidget {
  final SessionProgress progress;
  const SessionProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final color = progress.isComplete
        ? context.semantic.success
        : context.colors.primary;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: progress.fraction),
      duration: AppDuration.normal,
      builder: (context, value, _) => LinearProgressIndicator(
        value: value,
        minHeight: sessionProgressBarHeight,
        color: color,
        backgroundColor: color.withValues(alpha: 0.12),
      ),
    );
  }
}

/// Seansın yazılacağı günü gösterir/değiştirir. Canlı modda ince bir bilgi
/// satırı (dokununca geçmişe çekilebilir), manuel modda vurgulu.
class SessionDateBar extends StatelessWidget {
  final DateTime date;
  final bool highlight;
  final VoidCallback? onTap;
  const SessionDateBar(
      {super.key,
      required this.date, required this.highlight, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final l = AppL10n.of(context);
    final label = isToday
        ? l.commonToday
        : context.dateFmt('EEEE, d MMMM').format(date);
    final bg = highlight
        ? context.colors.primaryContainer
        : context.colors.surfaceContainerHighest;
    final fg = highlight ? context.colors.onPrimaryContainer : context.colors.primary;
    return Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(
            children: [
              FitPackIcon.material(Icons.event_rounded, size: AppIconSize.sm, color: fg),
              AppSpacing.gapSm,
              Text(highlight ? l.nutritionPickDate : l.commonDate,
                  style: context.texts.labelLarge
                      ?.copyWith(color: context.colors.onSurfaceVariant)),
              const Spacer(),
              Text(label,
                  style: context.texts.labelLarge
                      ?.copyWith(color: fg, fontWeight: FontWeight.w700)),
              AppSpacing.gapXs,
              FitPackIcon.material(Icons.expand_more_rounded, size: AppIconSize.sm, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyActiveSession extends StatelessWidget {
  final VoidCallback onAdd;
  const EmptyActiveSession({super.key, required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FitPackIcon.material(Icons.bolt_rounded,
              size: AppIconSize.xxl, color: context.colors.primary),
          AppSpacing.vGapMd,
          Text(AppL10n.of(context).asEmptyWorkout,
              style: context.texts.titleMedium),
          AppSpacing.vGapSm,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Text(AppL10n.of(context).asStartFromLibrary,
                textAlign: TextAlign.center,
                style: context.texts.bodyMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
          ),
          AppSpacing.vGapLg,
          FilledButton.icon(
            onPressed: onAdd,
            icon: const FitPackIcon.material(Icons.add_rounded),
            label: Text(AppL10n.of(context).workoutAddExercise),
          ),
        ],
      ),
    );
  }
}

class RestBanner extends StatelessWidget {
  final int remaining;
  final String clock;
  final VoidCallback onMinus, onPlus, onSkip;
  const RestBanner(
      {super.key,
      required this.remaining,
      required this.clock,
      required this.onMinus,
      required this.onPlus,
      required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md + 2, vertical: AppSpacing.sm + 3),
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: AppRadius.brLg,
          boxShadow: [
            BoxShadow(
              color: c.primary.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            FitPackIcon.material(Icons.timer_rounded, color: c.onPrimary, size: AppIconSize.md),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppL10n.of(context).labelRest,
                      style: context.texts.labelSmall?.copyWith(
                          color: c.onPrimary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600)),
                  Text(clock,
                      style: context.texts.titleLarge?.copyWith(
                          color: c.onPrimary,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ),
            ),
            _MiniBtn('−15s', onMinus),
            AppSpacing.hGapXs,
            _MiniBtn('+15s', onPlus),
            AppSpacing.hGapXs,
            _MiniBtn(AppL10n.of(context).asSkip, onSkip, strong: true),
          ],
        ),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool strong;
  const _MiniBtn(this.label, this.onTap, {this.strong = false});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.onPrimary.withValues(alpha: strong ? 0.28 : 0.18),
      borderRadius: AppRadius.brSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(label,
              style: context.texts.labelMedium?.copyWith(
                  color: c.onPrimary, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class ExerciseBlock extends ConsumerWidget {
  final SessionExerciseEntry ex;
  final void Function(SessionSetEntry) onToggle;
  final void Function(SessionSetEntry) onCycleType;
  final VoidCallback onAddSet, onRemoveSet, onRemoveExercise, onChanged;
  final VoidCallback onToggleAdvance;
  // null = o yöne taşınamaz (ilk/son hareket).
  final VoidCallback? onMoveUp, onMoveDown;
  // null = geçmiş kayıt modu (dinlenme sayacı yok).
  final VoidCallback? onPickRest;
  final double stepKg; // ± düğmesinin adımı (kg)
  final void Function(SessionSetEntry set, int direction) onStep;
  final VoidCallback onPickStep;
  const ExerciseBlock(
      {super.key,
      required this.ex,
      required this.onMoveUp,
      required this.onMoveDown,
      required this.onPickRest,
      required this.stepKg,
      required this.onStep,
      required this.onPickStep,
      required this.onToggle,
      required this.onCycleType,
      required this.onAddSet,
      required this.onRemoveSet,
      required this.onRemoveExercise,
      required this.onChanged,
      required this.onToggleAdvance});

  /// Ölçüm tipine göre orta sütun başlıkları (SET ve ✓ arasındakiler).
  /// Ağırlık sütunu birim tercihine göre KG/LB yazar (docs/16 §3).
  static List<Widget> _headerCols(AppL10n l, String measure, Units units) {
    switch (measure) {
      case 'reps':
        return [
          Expanded(child: _H(l.hdrReps, center: true)),
          const SizedBox(width: 44, child: _RpeHeader()),
        ];
      case 'time':
        return [
          Expanded(child: _H(l.hdrTime, center: true)),
          const SizedBox(width: _timerColWidth),
        ];
      case 'distance':
        return [
          Expanded(child: _H(l.hdrDistance, center: true)),
          Expanded(child: _H(l.hdrTime, center: true)),
          const SizedBox(width: _timerColWidth),
        ];
      default:
        return [
          Expanded(
              child: _H(units.weightUnit.toUpperCase(), center: true)),
          Expanded(child: _H(l.hdrReps, center: true)),
          const SizedBox(width: 44, child: _RpeHeader()),
        ];
    }
  }

  /// Ağırlık girilen ölçüm tipi mi (± düğmesi yalnız bunlarda).
  static bool _weighted(String measure) =>
      measure != 'reps' && measure != 'time' && measure != 'distance';

  /// ✓'e basılınca kaydedilecek değerin metni ("55 kg × 10"); ✓ hiçbir
  /// alanı doldurmayacaksa (öneri yok ya da set zaten dolu) null.
  static String? _assistHint(
      SessionExerciseEntry ex, SessionSetEntry set, int index, Units units) {
    final sug = ex.suggestionAt(index);
    if (sug == null) return null;
    final v = fillMissing(set.values, sug, ex.measure);
    if (v == set.values) return null;
    return switch (ex.measure) {
      'reps' => v.reps == null ? null : '× ${v.reps}',
      'time' => v.durationSec == null ? null : fmtDuration(v.durationSec!),
      'distance' => [
          if (v.distanceM != null)
            '${units.distanceValue(v.distanceM!)} ${units.distanceUnit}',
          if (v.durationSec != null) fmtDuration(v.durationSec!),
        ].join(' · '),
      _ => [
          if (v.weightKg != null) units.lift(v.weightKg!),
          if (v.reps != null) '× ${v.reps}',
        ].join(' '),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final units = ref.watch(unitsProvider);
    final activeIndex = ex.sets.indexWhere((s) => !s.done);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: AppSpacing.cardCompact,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // hareket başlığı
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: dark ? 0.18 : 0.12),
                    borderRadius: AppRadius.brMd,
                  ),
                  child: FitPackIcon.material(WorkoutUi.equipmentIcon(ex.exercise.equipment),
                      color: c.primary, size: 18),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex.exercise.name,
                          style: context.texts.titleSmall
                              ?.copyWith(color: c.primary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                                WorkoutUi.equipmentLabel(ex.exercise.equipment),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.texts.bodySmall
                                    ?.copyWith(color: c.onSurfaceVariant)),
                          ),
                          if (onPickRest != null) ...[
                            AppSpacing.hGapSm,
                            _RestChip(restSec: ex.restSec, onTap: onPickRest!),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Nasıl yapılır (#2): talimat + kas haritası + demo görseli,
                // seanstan çıkmadan modal sheet'te.
                IconButton(
                  icon: FitPackIcon.material(Icons.help_outline_rounded,
                      color: c.onSurfaceVariant, size: AppIconSize.md),
                  tooltip: AppL10n.of(context).asHowTo,
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      showExerciseHowToSheet(context, ex.exercise),
                ),
                PopupMenuButton<String>(
                  icon: FitPackIcon.material(Icons.more_vert_rounded,
                      color: c.onSurfaceVariant, size: AppIconSize.md),
                  tooltip: AppL10n.of(context).asExerciseOptions,
                  onSelected: (v) {
                    switch (v) {
                      case 'up':
                        onMoveUp?.call();
                      case 'down':
                        onMoveDown?.call();
                      case 'remove':
                        onRemoveExercise();
                    }
                  },
                  itemBuilder: (_) => [
                    if (onMoveUp != null)
                      PopupMenuItem(
                        value: 'up',
                        child: _MenuRow(Icons.arrow_upward_rounded,
                            AppL10n.of(context).asMoveUp),
                      ),
                    if (onMoveDown != null)
                      PopupMenuItem(
                        value: 'down',
                        child: _MenuRow(Icons.arrow_downward_rounded,
                            AppL10n.of(context).asMoveDown),
                      ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          FitPackIcon.material(Icons.delete_outline_rounded,
                              color: c.error, size: AppIconSize.sm),
                          AppSpacing.hGapSm,
                          Text(AppL10n.of(context).asRemoveExercise,
                              style: TextStyle(color: c.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (ex.advice != null) ...[
              AppSpacing.vGapSm,
              _ProgressionLine(ex: ex, onToggle: onToggleAdvance),
            ],
            AppSpacing.vGapMd,
            // başlık satırı — ölçüm tipine göre sütunlar
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 2),
              child: Row(
                children: [
                  SizedBox(width: 30, child: _H(AppL10n.of(context).hdrSet)),
                  SizedBox(
                      width: 56,
                      child:
                          _H(AppL10n.of(context).hdrPrev, center: true)),
                  ..._headerCols(AppL10n.of(context), ex.measure, units),
                  const SizedBox(width: 42),
                ],
              ),
            ),
            // Set satırları da kimlikli — set silme/ekleme kaydırmasında
            // TextFormField durumu doğru sette kalsın (H-02).
            for (final (i, set) in ex.sets.indexed) ...[
              _SetRow(
                key: ObjectKey(set),
                index: i,
                set: set,
                measure: ex.measure,
                // "ÖNCEKİ": geçen seansın AYNI numaralı seti (G-2).
                previous: i < ex.lastSets.length
                    ? prevLabel(ex.lastSets[i], ex.measure, units)
                    : null,
                suggestion: set.done ? null : ex.suggestionAt(i),
                units: units,
                onToggle: () => onToggle(set),
                onCycleType: () => onCycleType(set),
                onChanged: onChanged,
              ),
              // Sıradaki set: ✓'in ne kaydedeceği + kilo ± (A4).
              if (i == activeIndex)
                _ActiveSetAssist(
                  key: ObjectKey((set, 'assist')),
                  hint: _assistHint(ex, set, i, units),
                  showStepper: _weighted(ex.measure),
                  stepLabel: units.lift(stepKg),
                  onMinus: () => onStep(set, -1),
                  onPlus: () => onStep(set, 1),
                  onPickStep: onPickStep,
                ),
            ],
            AppSpacing.vGapXs,
            Row(
              children: [
                TextButton.icon(
                  onPressed: onAddSet,
                  icon: const FitPackIcon.material(Icons.add_rounded, size: AppIconSize.sm),
                  label: Text(AppL10n.of(context).asAddSet),
                ),
                if (ex.sets.length > 1)
                  TextButton.icon(
                    onPressed: onRemoveSet,
                    icon: const FitPackIcon.material(Icons.remove_rounded, size: AppIconSize.sm),
                    label: Text(AppL10n.of(context).asRemoveSet),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Menü satırı: ikon + metin (hareket ⋯ menüsü).
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MenuRow(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          FitPackIcon.material(icon,
              color: context.colors.onSurfaceVariant, size: AppIconSize.sm),
          AppSpacing.hGapSm,
          Text(label),
        ],
      );
}

/// Hareket başlığında dinlenme süresi ("⏱ 1:30"); dokununca değişir (A2).
class _RestChip extends StatelessWidget {
  final int restSec;
  final VoidCallback onTap;
  const _RestChip({required this.restSec, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label =
        WorkoutUi.restLabel(restSec, none: AppL10n.of(context).commonNone);
    return Tooltip(
      message: AppL10n.of(context).asRestChange,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: 2),
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.10),
            borderRadius: AppRadius.brPill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FitPackIcon.material(Icons.timer_outlined, size: 13, color: c.primary),
              const SizedBox(width: 3),
              Text(label,
                  style: context.texts.labelSmall?.copyWith(
                      color: c.primary,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sıradaki (işaretlenmemiş ilk) setin altındaki yardım satırı (A4):
/// solda ✓'in tam olarak ne kaydedeceği, sağda kilo − adım + düğmeleri.
/// Önerinin soluk ipucu olarak kalıp anlaşılmaması sorununa cevap —
/// kural artık ekranda yazıyor.
class _ActiveSetAssist extends StatelessWidget {
  final String? hint;
  final bool showStepper;
  final String stepLabel;
  final VoidCallback onMinus, onPlus, onPickStep;
  const _ActiveSetAssist(
      {super.key,
      required this.hint,
      required this.showStepper,
      required this.stepLabel,
      required this.onMinus,
      required this.onPlus,
      required this.onPickStep});

  @override
  Widget build(BuildContext context) {
    final h = hint;
    if (h == null && !showStepper) return const SizedBox.shrink();
    final c = context.colors;
    final l = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 0, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: h == null
                ? const SizedBox.shrink()
                : Row(
                    children: [
                      FitPackIcon.material(Icons.subdirectory_arrow_right_rounded,
                          size: 14, color: c.primary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(l.asSuggestHint(h),
                            maxLines: 2,
                            style: context.texts.labelMedium?.copyWith(
                                color: c.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
          ),
          if (showStepper) ...[
            AppSpacing.hGapXs,
            _StepButton(
                icon: Icons.remove_rounded,
                tooltip: l.asStepDecrease(stepLabel),
                onTap: onMinus),
            Tooltip(
              message: l.asStepChange,
              child: InkWell(
                onTap: onPickStep,
                borderRadius: AppRadius.brSm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                  child: Text(stepLabel,
                      style: context.texts.labelMedium?.copyWith(
                          color: c.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.dotted,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ),
              ),
            ),
            _StepButton(
                icon: Icons.add_rounded,
                tooltip: l.asStepIncrease(stepLabel),
                onTap: onPlus),
          ],
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _StepButton(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: c.primary.withValues(alpha: 0.10),
        borderRadius: AppRadius.brSm,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brSm,
          child: SizedBox(
            width: 36,
            height: 30,
            child: FitPackIcon.material(icon, size: AppIconSize.sm, color: c.primary),
          ),
        ),
      ),
    );
  }
}

/// Dinlenme süresi seçici (A2). Seçilen süreyi (sn) döner.
class RestPickerSheet extends StatelessWidget {
  final int current;
  final bool savesToRoutine;
  const RestPickerSheet({super.key, required this.current, required this.savesToRoutine});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.asRestTitle, style: context.texts.titleMedium),
            AppSpacing.vGapXs,
            Text(savesToRoutine ? l.asRestRoutineNote : l.asRestSessionNote,
                style: context.texts.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
            AppSpacing.vGapLg,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final sec in {...WorkoutUi.restOptions, current}.toList()
                  ..sort())
                  ChoiceChip(
                    label: Text(WorkoutUi.restLabel(sec, none: l.commonNone)),
                    selected: sec == current,
                    onSelected: (_) => Navigator.pop(context, sec),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Kilo adımı seçici (A4). Seçilen adımı kg olarak döner.
class StepPickerSheet extends ConsumerWidget {
  final double currentKg;
  const StepPickerSheet({super.key, required this.currentKg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final units = ref.watch(unitsProvider);
    final options = units.imperial ? stepOptionsLb : stepOptionsKg;
    final currentLabel = units.lift(currentKg);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.asStepTitle, style: context.texts.titleMedium),
            AppSpacing.vGapXs,
            Text(l.asStepHelp,
                style: context.texts.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
            AppSpacing.vGapLg,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final o in options)
                  Builder(builder: (_) {
                    final kg = units.weightToKg(o);
                    final label = units.lift(kg);
                    return ChoiceChip(
                      label: Text(label),
                      selected: label == currentLabel,
                      onSelected: (_) => Navigator.pop(context, kg),
                    );
                  }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Hareket başlığının altında sonraki hedef satırı (docs/21 #3): gerekçe +
/// uygula/geri al. Metne dokununca kuralın açıklaması açılır.
class _ProgressionLine extends ConsumerWidget {
  final SessionExerciseEntry ex;
  final VoidCallback onToggle;
  const _ProgressionLine({required this.ex, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advice = ex.advice!;
    final l = AppL10n.of(context);
    final units = ref.watch(unitsProvider);
    final inc = ref.watch(effectiveIncrementKgProvider);
    final c = context.colors;
    // "15 kg × 10, 10, 10" ya da piramitte "100×10, 120×9, 140×7 kg".
    final sets = advice.uniformWeight
        ? '${units.lift(advice.lastTopWeightKg)} × ${advice.lastReps.join(', ')}'
        : '${[
            for (var i = 0; i < advice.lastReps.length; i++)
              '${units.liftValue(advice.lastWeightsKg[i])}×${advice.lastReps[i]}',
          ].join(', ')} ${units.weightUnit}';
    final applied = ex.appliedIncrementKg;
    final increase = advice.kind == ProgressionKind.increaseWeight;
    final decrease = advice.kind == ProgressionKind.decreaseWeight;
    // "+1.25 kg" satır sonunda "+1.25 / kg" diye bölünmesin: bölünmez boşluk.
    String amount(double kg) => units.lift(kg).replaceAll(' ', '\u00A0');

    final String text;
    if (applied != null) {
      text = increase
          ? l.progAppliedWeight(amount(applied), advice.repsMin)
          : decrease
              ? l.progAppliedDecrease(amount(applied), advice.repsMin)
              : l.progAppliedReps;
    } else {
      final rpe = advice.topRpe == null ? '' : _rpeText(advice.topRpe!);
      text = switch (advice.kind) {
        ProgressionKind.increaseWeight => advice.hardIncrease
            ? l.progIncreaseHard(sets, advice.repsMax, amount(inc), rpe)
            : l.progIncrease(sets, advice.repsMax, amount(inc)),
        ProgressionKind.addRep =>
          l.progAddRep(sets, advice.repsMin, advice.repsMax),
        ProgressionKind.repeat => l.progRepeat(sets, advice.repsMin),
        ProgressionKind.holdAtFailure => l.progHoldFailure(sets),
        ProgressionKind.decreaseWeight =>
          l.progDecrease(sets, advice.repsMin, amount(inc)),
      };
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.xs, AppSpacing.xs),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: applied != null ? 0.14 : 0.07),
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        children: [
          FitPackIcon.material(
              applied != null
                  ? Icons.check_circle_rounded
                  : decrease
                      ? Icons.trending_down_rounded
                      : Icons.trending_up_rounded,
              size: AppIconSize.sm,
              color: c.primary),
          AppSpacing.hGapSm,
          Expanded(
            child: InkWell(
              onTap: () => _showProgressionInfo(context, advice, units, inc),
              borderRadius: AppRadius.brSm,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Text(text,
                    style: context.texts.bodySmall
                        ?.copyWith(color: c.onSurface, height: 1.3)),
              ),
            ),
          ),
          if (advice.actionable) ...[
            AppSpacing.hGapXs,
            TextButton(
              onPressed: onToggle,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              child: Text(applied != null
                  ? l.commonUndo
                  : increase
                      ? l.progApplyWeight(amount(inc))
                      : decrease
                          ? l.progApplyDecrease(amount(inc))
                          : l.progApplyReps),
            ),
          ],
        ],
      ),
    );
  }
}

/// RPE 9.5 → "9,5" değil "9.5": seçicideki ve geçmişteki yazımla aynı.
String _rpeText(double v) =>
    v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);

void _showProgressionInfo(BuildContext context, ProgressionAdvice advice,
    Units units, double incrementKg) {
  final l = AppL10n.of(context);
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.progInfoTitle, style: ctx.texts.titleMedium),
            AppSpacing.vGapSm,
            Text(
                l.progInfoBody(advice.repsMin, advice.repsMax,
                    units.lift(incrementKg)),
                style: ctx.texts.bodyMedium),
            AppSpacing.vGapSm,
            Text(l.progInfoRpe, style: ctx.texts.bodyMedium),
            AppSpacing.vGapMd,
            Text(l.progInfoSettings,
                style: ctx.texts.bodySmall
                    ?.copyWith(color: ctx.colors.onSurfaceVariant)),
          ],
        ),
      ),
    ),
  );
}

class _H extends StatelessWidget {
  final String t;
  final bool center;
  const _H(this.t, {this.center = false});
  @override
  // C-15: salonda kol boyu mesafeden okunmalı — daha koyu + bir tık büyük.
  Widget build(BuildContext context) => Text(t,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: context.texts.labelSmall?.copyWith(
          color: context.colors.onSurfaceVariant,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3));
}

/// Süreli setlerde sayaç sütunu genişliği (başlık ve satır aynı).
const double _timerColWidth = 48;

/// "RPE" başlığı + dokunulabilir bilgi ipucu (ne olduğunu açıklar).
class _RpeHeader extends StatelessWidget {
  const _RpeHeader();

  @override
  Widget build(BuildContext context) {
    final color = context.colors.onSurfaceVariant;
    return InkWell(
      onTap: () => _showRpeInfo(context),
      borderRadius: AppRadius.brSm,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('RPE',
              style: context.texts.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3)),
          const SizedBox(width: 2),
          FitPackIcon.material(Icons.help_outline_rounded, size: 12, color: color),
        ],
      ),
    );
  }
}

void _showRpeInfo(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      Widget row(String level, String desc) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: ctx.colors.primary.withValues(alpha: 0.12),
                    borderRadius: AppRadius.brSm,
                  ),
                  child: Text(level,
                      style: ctx.texts.labelMedium?.copyWith(
                          color: ctx.colors.primary,
                          fontWeight: FontWeight.w800)),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(desc, style: ctx.texts.bodyMedium),
                  ),
                ),
              ],
            ),
          );

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppL10n.of(ctx).rpeTitle,
                  style: ctx.texts.titleMedium),
              AppSpacing.vGapSm,
              Text(
                AppL10n.of(ctx).rpeHelp,
                style: ctx.texts.bodyMedium
                    ?.copyWith(color: ctx.colors.onSurfaceVariant),
              ),
              AppSpacing.vGapLg,
              row('10', AppL10n.of(ctx).rpe10),
              row('9', AppL10n.of(ctx).rpe9),
              row('8', AppL10n.of(ctx).rpe8),
              row('7', AppL10n.of(ctx).rpe7),
              row('≤6', AppL10n.of(ctx).rpe6),
            ],
          ),
        ),
      );
    },
  );
}

class _SetRow extends StatelessWidget {
  final int index;
  final SessionSetEntry set;
  final String measure;
  final String? previous;
  // ✓'e basılınca boş alanlara yazılacak değerler — alanlarda soluk ipucu.
  final SetValues? suggestion;
  final Units units;
  final VoidCallback onToggle, onCycleType, onChanged;
  const _SetRow(
      {super.key,
      required this.index,
      required this.set,
      required this.measure,
      required this.previous,
      required this.suggestion,
      required this.units,
      required this.onToggle,
      required this.onCycleType,
      required this.onChanged});

  /// Ölçüm tipine göre orta giriş hücreleri (header ile aynı genişlik düzeni).
  /// Boş alanın ipucu = ✓ önerisi (G-2); öneri yoksa eski sabit ipucu.
  /// Panel başlığının altı: "80 kg × 8" (yalnız girilmiş alanlar).
  String? _setSummary() {
    final parts = [
      if (set.weight != null) units.lift(set.weight!),
      if (set.reps != null) '${set.reps}',
    ];
    return parts.isEmpty ? null : parts.join(' × ');
  }

  List<Widget> _inputCols(BuildContext context) {
    final sug = suggestion;
    // Koddan doldurulunca alan yeni değerle yeniden kurulsun (fillGen).
    Key k(String field) => ValueKey('$field-${set.fillGen}');
    final repsHint = sug?.reps?.toString();
    final timeHint =
        sug?.durationSec == null ? null : fmtDuration(sug!.durationSec!);
    // Süreli sette sayaç (docs/27 F3): hedef = girilen süre, yoksa geçen
    // seansın önerisi; sayaç süreyi yazar, seti tamamlamaz.
    Widget timerCell() => SizedBox(
        width: _timerColWidth,
        child: set.done
            ? null
            : SetTimerButton(
                // ValueKey: kayıt (record) her çizimde yeni nesne; ObjectKey
                // kimlikle karşılaştırır ve canlı saatin her tıkında sayacın
                // durumunu sıfırlardı. ValueKey alanları == ile karşılaştırır.
                key: ValueKey((set, 'timer')),
                targetSec: set.durationSec ?? sug?.durationSec,
                onDone: (sec) {
                  set.durationSec = sec;
                  set.fillGen++; // süre alanı yeni değerle kurulsun
                  onChanged();
                }));
    Widget rpeCell() => SizedBox(
        width: 44,
        child: _RpeCell(
            key: k('rpe'),
            value: set.rpe,
            onTap: () async {
              final picked = await showRpePicker(context,
                  setNumber: index + 1,
                  initial: set.rpe,
                  setSummary: _setSummary());
              if (picked == null) return;
              set.rpe = picked.rpe;
              onChanged();
            }));
    switch (measure) {
      case 'reps':
        return [
          Expanded(
              child: _NumCell(
                  key: k('reps'),
                  value: set.reps?.toDouble(),
                  decimal: false,
                  hint: repsHint,
                  onChanged: (v) {
                    set.reps = v?.round();
                    onChanged();
                  })),
          rpeCell(),
        ];
      case 'time':
        return [
          Expanded(
              child: _TimeCell(
                  key: k('time'),
                  value: set.durationSec,
                  hint: timeHint,
                  onChanged: (v) {
                    set.durationSec = v;
                    onChanged();
                  })),
          timerCell(),
        ];
      case 'distance':
        return [
          Expanded(
              child: _NumCell(
                  key: k('dist'),
                  value: set.distanceM == null
                      ? null
                      : units.distanceFromM(set.distanceM!),
                  decimal: true,
                  hint: sug?.distanceM == null
                      ? units.distanceUnit
                      : units.distanceValue(sug!.distanceM!),
                  onChanged: (v) {
                    set.distanceM =
                        v == null ? null : units.distanceToM(v);
                    onChanged();
                  })),
          Expanded(
              child: _TimeCell(
                  key: k('time'),
                  value: set.durationSec,
                  hint: timeHint,
                  onChanged: (v) {
                    set.durationSec = v;
                    onChanged();
                  })),
          timerCell(),
        ];
      default:
        return [
          // Görüntü/giriş birim tercihinde; state ve DB kg (docs/16 §3).
          Expanded(
              child: _NumCell(
                  key: k('kg'),
                  value: set.weight == null
                      ? null
                      // 1,25 kg'lık artış kaybolmasın: metrikte iki ondalık.
                      : double.parse(units.liftValue(set.weight!)),
                  decimal: true,
                  hint: sug?.weightKg == null
                      ? null
                      : units.liftValue(sug!.weightKg!),
                  onChanged: (v) {
                    set.weight = v == null ? null : units.weightToKg(v);
                    onChanged();
                  })),
          Expanded(
              child: _NumCell(
                  key: k('reps'),
                  value: set.reps?.toDouble(),
                  decimal: false,
                  hint: repsHint,
                  onChanged: (v) {
                    set.reps = v?.round();
                    onChanged();
                  })),
          rpeCell(),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final badge = sessionSetTypeLabel[set.type]!;
    final badgeColor = switch (set.type) {
      'warmup' => context.semantic.warning,
      'drop' => context.semantic.info,
      'failure' => c.error,
      _ => c.onSurfaceVariant,
    };
    // Rekor seti: sol rozet numara/tip yerine kupa — "kişisel rekor" bilgisi
    // set tipinden öncelikli.
    final showTrophy = set.done && set.isRecord;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      decoration: BoxDecoration(
        color: set.done
            ? context.semantic.success.withValues(alpha: 0.10)
            : null,
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: InkWell(
              onTap: onCycleType,
              borderRadius: AppRadius.brSm,
              child: Container(
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: showTrophy
                      ? context.semantic.warning.withValues(alpha: 0.14)
                      : badge.isEmpty
                          ? c.onSurface.withValues(alpha: 0.06)
                          : badgeColor.withValues(alpha: 0.14),
                  borderRadius: AppRadius.brSm,
                ),
                child: showTrophy
                    ? FitPackIcon.material(Icons.emoji_events_rounded,
                        size: 16,
                        color: context.semantic.warning,
                        semanticLabel: AppL10n.of(context).asNewRecord)
                    : Text(badge.isEmpty ? '${index + 1}' : badge,
                        style: context.texts.labelLarge?.copyWith(
                            color: badge.isEmpty ? c.onSurface : badgeColor,
                            fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          SizedBox(
            width: 56,
            // C-15: referans bilgi — girilen değerden (tam koyu) ve öneriden
            // (%40) ayrışacak kadar okunur.
            child: Text(previous ?? '—',
                textAlign: TextAlign.center,
                style: context.texts.bodySmall?.copyWith(
                    color: c.onSurfaceVariant.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ),
          ..._inputCols(context),
          SizedBox(
            width: 42,
            child: Center(
              child: Material(
                color: set.done
                    ? context.semantic.success
                    : c.onSurface.withValues(alpha: 0.08),
                borderRadius: AppRadius.brSm,
                child: InkWell(
                  key: ValueKey('set.complete.$index'),
                  onTap: onToggle,
                  borderRadius: AppRadius.brSm,
                  child: SizedBox(
                    width: 38,
                    height: 34,
                    child: FitPackIcon.material(Icons.check_rounded,
                        size: 18,
                        color: set.done
                            ? context.semantic.onSuccess
                            : c.onSurfaceVariant),
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

class _NumCell extends StatelessWidget {
  final double? value;
  final bool decimal;
  final String? hint;
  final ValueChanged<double?> onChanged;
  const _NumCell(
      {super.key,
      required this.value,
      required this.decimal,
      required this.onChanged,
      this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TextFormField(
        initialValue: value == null
            ? null
            : (decimal
                ? (value == value!.roundToDouble()
                    ? value!.round().toString()
                    : value.toString())
                : value!.round().toString()),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
              RegExp(decimal ? r'[0-9.,]' : r'[0-9]')),
        ],
        decoration: InputDecoration(
          hintText: hint ?? '0',
          // Öneri (G-2) girilmiş değerle karışmasın — belirgin soluk.
          hintStyle: _hintStyle(context),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
        onChanged: (v) =>
            onChanged(double.tryParse(v.replaceAll(',', '.'))),
      ),
    );
  }
}

/// RPE hücresi — klavye açmaz, dokununca seçici paneli açılır (docs/27 F4).
/// Görünüm diğer giriş hücreleriyle aynı (tema giriş dekorasyonu).
class _RpeCell extends StatelessWidget {
  final double? value;
  final VoidCallback onTap;
  const _RpeCell({super.key, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final v = value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brSm,
        child: InputDecorator(
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          ),
          textAlign: TextAlign.center,
          child: Text(
            v == null
                ? '–'
                : formatRpe(v, decimalSep: context.numFmt.symbols.DECIMAL_SEP),
            textAlign: TextAlign.center,
            style: v == null
                ? _hintStyle(context)
                : context.texts.bodyLarge,
          ),
        ),
      ),
    );
  }
}

/// Boş giriş alanı ipucu: girilmiş değerden (onSurface) açıkça soluk.
TextStyle _hintStyle(BuildContext context) => TextStyle(
    color: context.colors.onSurfaceVariant.withValues(alpha: 0.4));

/// Süre giriş hücresi — dk:sn formatı ("12:30"). Kullanıcı ":" ile saniye
/// girer; sadece sayı yazarsa dakika kabul edilir (bkz. [parseDuration]).
class _TimeCell extends StatelessWidget {
  final int? value;
  final String? hint; // ✓ önerisi (G-2); yoksa "0:00"
  final ValueChanged<int?> onChanged;
  const _TimeCell(
      {super.key, required this.value, required this.onChanged, this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TextFormField(
        initialValue: value == null ? null : fmtDuration(value!),
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9:.,]')),
        ],
        decoration: InputDecoration(
          hintText: hint ?? '0:00',
          hintStyle: _hintStyle(context),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
        onChanged: (v) => onChanged(parseDuration(v)),
      ),
    );
  }
}
