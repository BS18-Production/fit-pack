import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/formatting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/motion.dart';
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
      duration: motionDuration(context, AppDuration.normal),
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

/// Mola çubuğu — ekranın altında (A5): listeyi itmez, satırlar yerinde kalır.
/// Düğmeler en az 48×48 (A1/A2: eski şeritte 49×31). Dar ekranda ya da
/// büyük yazıda iki satır: süre üstte, düğmeler altta eşit genişlikte.
class RestBar extends StatelessWidget {
  final int remaining;
  final String clock;
  final VoidCallback onMinus, onPlus, onSkip;
  const RestBar(
      {super.key,
      required this.remaining,
      required this.clock,
      required this.onMinus,
      required this.onPlus,
      required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppL10n.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(10) > 11.5;
    final info = Semantics(
      label: '${l.labelRest} $clock',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FitPackIcon.material(Icons.timer_rounded,
              color: c.primary, size: AppIconSize.md),
          AppSpacing.hGapSm,
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.labelRest,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.labelSmall?.copyWith(
                        color: c.onSurfaceVariant,
                        fontWeight: FontWeight.w600)),
                Text(clock,
                    maxLines: 1,
                    style: context.texts.titleLarge?.copyWith(
                        color: c.onSurface,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ],
            ),
          ),
        ],
      ),
    );
    final buttons = [
      _RestBtn(
          key: const ValueKey('rest.minus'),
          label: l.asRestMinus,
          tooltip: l.asRestMinusHint,
          onTap: onMinus),
      _RestBtn(
          key: const ValueKey('rest.plus'),
          label: l.asRestPlus,
          tooltip: l.asRestPlusHint,
          onTap: onPlus),
      _RestBtn(
          key: const ValueKey('rest.skip'),
          label: l.asSkip,
          onTap: onSkip,
          strong: true),
    ];
    return Material(
      color: c.surfaceContainerHigh,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.primary, width: 2)),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: narrow
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    info,
                    AppSpacing.vGapSm,
                    Row(children: [
                      for (final (i, b) in buttons.indexed) ...[
                        if (i > 0) AppSpacing.hGapSm,
                        Expanded(child: b),
                      ],
                    ]),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                        child: Align(
                            alignment: Alignment.centerLeft,
                            heightFactor: 1,
                            child: info)),
                    for (final b in buttons) ...[AppSpacing.hGapSm, b],
                  ],
                ),
        ),
      ),
    );
  }
}

class _RestBtn extends StatelessWidget {
  final String label;
  final String? tooltip;
  final VoidCallback onTap;
  final bool strong;
  const _RestBtn(
      {super.key,
      required this.label,
      required this.onTap,
      this.tooltip,
      this.strong = false});

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(56, 48)),
      padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.md)),
      tapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
    );
    final text = Text(label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.fade,
        style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()]));
    final btn = strong
        ? FilledButton(onPressed: onTap, style: style, child: text)
        : OutlinedButton(onPressed: onTap, style: style, child: text);
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// iOS sayı klavyesinde "Bitti" tuşu yok (A5): set alanı odaktayken
/// klavyenin hemen üstünde Sonraki / Bitti. Diğer platformlarda klavyenin
/// kendi eylem tuşu var — çubuk çizilmez.
class SessionKeyboardBar extends StatelessWidget {
  const SessionKeyboardBar({super.key});

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS ||
        MediaQuery.viewInsetsOf(context).bottom == 0) {
      return const SizedBox.shrink();
    }
    final l = AppL10n.of(context);
    return Material(
      color: context.colors.surfaceContainerHigh,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            const Spacer(),
            TextButton(
                key: const ValueKey('kb.next'),
                onPressed: () =>
                    FocusManager.instance.primaryFocus?.nextFocus(),
                child: Text(l.asKbNext)),
            TextButton(
                key: const ValueKey('kb.done'),
                onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Text(l.asKbDone,
                    style: const TextStyle(fontWeight: FontWeight.w800))),
            AppSpacing.hGapSm,
          ],
        ),
      ),
    );
  }
}

class ExerciseBlock extends ConsumerWidget {
  final SessionExerciseEntry ex;
  final void Function(SessionSetEntry) onToggle;
  final void Function(SessionSetEntry set, String type) onSetType;
  final VoidCallback onAddSet, onRemoveSet, onRemoveExercise, onChanged;
  final VoidCallback onToggleAdvance;
  final VoidCallback? onReplaceExercise;
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
      required this.onSetType,
      required this.onAddSet,
      required this.onRemoveSet,
      required this.onRemoveExercise,
      required this.onChanged,
      required this.onToggleAdvance,
      this.onReplaceExercise});

  /// Ölçüm tipine göre orta sütun başlıkları (SET ve ✓ arasındakiler).
  /// Ağırlık sütunu birim tercihine göre KG/LB yazar (docs/16 §3). Dar
  /// düzende RPE sütunu yok (set seçenekleri ve yardım satırında).
  static List<Widget> _headerCols(
      AppL10n l, String measure, Units units, bool compact) {
    switch (measure) {
      case 'reps':
        return [
          Expanded(child: _H(l.hdrReps, center: true)),
          if (!compact) const SizedBox(width: setTargetSize, child: _RpeHeader()),
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
          if (!compact) const SizedBox(width: setTargetSize, child: _RpeHeader()),
        ];
    }
  }

  /// Dar düzen (K4 Seçenek 1b): 300'den dar satır ya da büyük yazıda
  /// "ÖNCEKİ" ve RPE sütunları satırdan çıkar — 48'lik hedeflerle kg/tekrar
  /// alanlarına yer kalsın (review/A6 §3, A7, Codex R4).
  static bool compactFor(BuildContext context, double rowWidth) =>
      rowWidth < 300 || MediaQuery.textScalerOf(context).scale(10) > 11.5;

  /// Setin ✓'te kaydedeceği değerlerin metni ("60 kg × 10"); boşsa null.
  static String? _valuesText(SetValues v, String measure, Units units) {
    final t = switch (measure) {
      'reps' => v.reps == null ? '' : '× ${v.reps}',
      'time' => v.durationSec == null ? '' : fmtDuration(v.durationSec!),
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
    return t.isEmpty ? null : t;
  }

  /// RPE girilen ölçüm tipi mi (süre/mesafede yok).
  static bool _hasRpe(String measure) =>
      measure != 'time' && measure != 'distance';

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
    return _valuesText(v, ex.measure, units);
  }

  /// K6: öneri bu seansın üstteki setinden geliyor ve geçen seansın aynı
  /// setinden farklıysa yardım satırı "geçen sefer"i de yazar — piramitte
  /// farkında olmadan düşük kayıt olmasın (A2 #4).
  static bool _suggestionDiffersFromLast(SessionExerciseEntry ex, int index) {
    final sug = ex.suggestionAt(index);
    final last = ex.lastValues;
    if (sug == null ||
        index >= last.length ||
        !last[index].hasAny(ex.measure)) {
      return false;
    }
    return sug != last[index];
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
                      // Dar ekranda ekipman adı kesilmesin: çip alt satıra
                      // iner (A4 R4).
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.sm,
                        children: [
                          Text(WorkoutUi.equipmentLabel(ex.exercise.equipment),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.texts.bodySmall
                                  ?.copyWith(color: c.onSurfaceVariant)),
                          if (onPickRest != null)
                            _RestChip(restSec: ex.restSec, onTap: onPickRest!),
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
                      case 'replace':
                        onReplaceExercise?.call();
                      case 'remove':
                        onRemoveExercise();
                    }
                  },
                  itemBuilder: (_) => [
                    if (onReplaceExercise != null)
                      PopupMenuItem(
                        value: 'replace',
                        child: _MenuRow(Icons.swap_horiz_rounded,
                            AppL10n.of(context).asReplaceExercise),
                      ),
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
            LayoutBuilder(builder: (context, box) {
              final compact = compactFor(context, box.maxWidth);
              final l = AppL10n.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // başlık satırı — ölçüm tipine göre sütunlar
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      children: [
                        SizedBox(
                            width: setTargetSize,
                            child: _H(l.hdrSet, center: true)),
                        if (!compact)
                          SizedBox(
                              width: _prevColWidth,
                              child: _H(l.hdrPrev, center: true)),
                        ..._headerCols(l, ex.measure, units, compact),
                        const SizedBox(width: setTargetSize),
                      ],
                    ),
                  ),
                  // Set satırları da kimlikli — set silme/ekleme kaydırmasında
                  // TextFormField durumu doğru sette kalsın (H-02).
                  for (final (i, set) in ex.sets.indexed) ...[
                    // Sıradaki set — etkin set kartı (K4): ✓'in ne
                    // kaydedeceği + kilo ± 48×48; dar düzende ÖNCEKİ ve RPE de
                    // burada. Setin ÜSTÜNDE: set tamamlanınca satır bir
                    // sonrakine geçer ama sıradaki ✓ yerinden oynamaz (A5).
                    if (i == activeIndex)
                      _ActiveSetAssist(
                        key: ObjectKey((set, 'assist')),
                        compact: compact,
                        hint: _assistHint(ex, set, i, units),
                        previous: i < ex.lastSets.length
                            ? prevLabel(ex.lastSets[i], ex.measure, units)
                            : null,
                        showPrevious:
                            compact || _suggestionDiffersFromLast(ex, i),
                        showStepper: _weighted(ex.measure),
                        stepLabel: units.lift(stepKg),
                        onMinus: () => onStep(set, -1),
                        onPlus: () => onStep(set, 1),
                        onPickStep: onPickStep,
                        rpeCell: compact && _hasRpe(ex.measure)
                            ? SizedBox(
                                width: setTargetSize,
                                child: _RpeCell(
                                    key: ValueKey('rpe-assist-${set.fillGen}'),
                                    value: set.rpe,
                                    label: l.asSemField(i + 1, 'RPE'),
                                    onTap: () => pickSetRpe(
                                        context, set, i, units, onChanged)),
                              )
                            : null,
                      ),
                    _SetRow(
                      key: ObjectKey(set),
                      index: i,
                      set: set,
                      measure: ex.measure,
                      compact: compact,
                      // "ÖNCEKİ": geçen seansın AYNI numaralı seti (G-2).
                      previous: i < ex.lastSets.length
                          ? prevLabel(ex.lastSets[i], ex.measure, units)
                          : null,
                      suggestion: set.done ? null : ex.suggestionAt(i),
                      valuesText: _valuesText(
                          set.done || ex.suggestionAt(i) == null
                              ? set.values
                              : fillMissing(
                                  set.values, ex.suggestionAt(i)!, ex.measure),
                          ex.measure,
                          units),
                      units: units,
                      onToggle: () => onToggle(set),
                      onSetType: (t) => onSetType(set, t),
                      onChanged: onChanged,
                    ),
                  ],
                ],
              );
            }),
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
    // Görünür çip küçük kalır; dokunma alanı 48 yüksek (U04, A7).
    return Tooltip(
      message: AppL10n.of(context).asRestChange,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: setTargetSize),
          child: Center(
          widthFactor: 1,
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
        ),
      ),
    );
  }
}

/// Sıradaki (işaretlenmemiş ilk) setin altındaki yardım satırı — etkin set
/// kartı (A4, K4): solda ✓'in tam olarak ne kaydedeceği, sağda kilo − adım +
/// (48×48). Dar düzende metin üstte, düğmeler altta; ÖNCEKİ ve RPE de bu
/// satıra iner (satırdan çıkan sütunlar).
class _ActiveSetAssist extends StatelessWidget {
  final bool compact;
  final String? hint;
  final String? previous;
  final bool showPrevious;
  final bool showStepper;
  final String stepLabel;
  final VoidCallback onMinus, onPlus, onPickStep;
  final Widget? rpeCell;
  const _ActiveSetAssist(
      {super.key,
      required this.compact,
      required this.hint,
      required this.previous,
      required this.showPrevious,
      required this.showStepper,
      required this.stepLabel,
      required this.onMinus,
      required this.onPlus,
      required this.onPickStep,
      this.rpeCell});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppL10n.of(context);
    final h = hint;
    final prev = showPrevious ? previous : null;
    final raw = h != null
        ? (prev != null ? l.asSuggestWithPrev(h, prev) : l.asSuggestHint(h))
        : prev != null
            ? l.asPrevOnly(prev)
            : null;
    // Yerel ondalık: alanlar "42,5" yazarken satır "42.5" demesin.
    final text = raw == null ? null : _localNum(context, raw);
    final controls = [
      ?rpeCell,
      if (showStepper) ...[
        _StepButton(
            key: const ValueKey('step.minus'),
            icon: Icons.remove_rounded,
            tooltip: l.asStepDecrease(stepLabel),
            onTap: onMinus),
        Tooltip(
          message: l.asStepChange,
          child: InkWell(
            onTap: onPickStep,
            borderRadius: AppRadius.brSm,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                  minWidth: setTargetSize, minHeight: setTargetSize),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Text(stepLabel,
                      maxLines: 1,
                      style: context.texts.labelMedium?.copyWith(
                          color: c.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.dotted,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ),
              ),
            ),
          ),
        ),
        _StepButton(
            key: const ValueKey('step.plus'),
            icon: Icons.add_rounded,
            tooltip: l.asStepIncrease(stepLabel),
            onTap: onPlus),
      ],
    ];
    if (text == null && controls.isEmpty) return const SizedBox.shrink();
    final style = context.texts.labelMedium
        ?.copyWith(color: c.primary, fontWeight: FontWeight.w600, height: 1.3);
    // Sabit satır yüksekliği (geniş 2, dar 3 satır): metin setten sete
    // kısalıp uzasa da satır boyu değişmez — ✓ sonrası sıradaki set yerinde
    // kalır (A5).
    final lines = compact ? 3 : 2;
    final label = SizedBox(
      height: MediaQuery.textScalerOf(context).scale(style?.fontSize ?? 12) *
          1.3 *
          lines,
      child: text == null
          ? null
          : Row(
              children: [
                FitPackIcon.material(Icons.subdirectory_arrow_right_rounded,
                    size: 14, color: c.primary),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(text,
                      maxLines: lines,
                      overflow: TextOverflow.ellipsis,
                      style: style),
                ),
              ],
            ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(setTargetSize, AppSpacing.xs, 0, 2),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                label,
                if (controls.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: controls,
                  ),
              ],
            )
          : Row(
              children: [
                Expanded(child: label),
                if (controls.isNotEmpty) AppSpacing.hGapXs,
                ...controls,
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
      {super.key,
      required this.icon,
      required this.tooltip,
      required this.onTap});

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
            width: setTargetSize,
            height: setTargetSize,
            child: FitPackIcon.material(icon, size: AppIconSize.md, color: c.primary),
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
              child: Container(
                constraints: const BoxConstraints(minHeight: setTargetSize),
                alignment: Alignment.centerLeft,
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
                minimumSize: const Size(setTargetSize, setTargetSize),
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
  // Tek satır, sığmazsa küçülür: büyük yazıda "ÖNCE/Kİ" diye bölünmesin (A2).
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: center ? Alignment.center : Alignment.centerLeft,
        child: Text(t,
            maxLines: 1,
            softWrap: false,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: context.texts.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3)),
      );
}

/// Set satırındaki dokunma hedefleri (rozet, RPE, ✓, ±): Android/Material
/// önerisi 48×48 (deneyim araştırması U04).
const double setTargetSize = 48;

/// Geniş düzende "ÖNCEKİ" sütunu.
const double _prevColWidth = 56;

/// Süreli setlerde sayaç sütunu genişliği (başlık ve satır aynı).
const double _timerColWidth = setTargetSize;

/// "RPE" başlığı + dokunulabilir bilgi ipucu (ne olduğunu açıklar). Büyük
/// yazıda sütuna sığacak kadar küçülür (A6: 1,6×'te 5,9 pt taşıyordu).
class _RpeHeader extends StatelessWidget {
  const _RpeHeader();

  @override
  Widget build(BuildContext context) {
    final color = context.colors.onSurfaceVariant;
    // Başlık dokunulmaz (48'lik hedef başlığı büyütürdü); "RPE nedir?" set
    // seçenekleri panelinde.
    return Semantics(
      label: AppL10n.of(context).rpeTitle,
      excludeSemantics: true,
      child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('RPE',
                  maxLines: 1,
                  style: context.texts.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3)),
              const SizedBox(width: 2),
            ],
          ),
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

/// Set seçenekleri paneli (A5 #10): set türü + RPE. Rozete dokunuş türü
/// döngüyle sessizce değiştiriyordu; artık seçim açık ve geri alınabilir.
/// Dönüş: seçilen tür, `'rpe'` (RPE seçici açılsın) ya da `'rpeInfo'`
/// (RPE açıklaması); `null` = vazgeçildi.
Future<String?> _showSetOptions(BuildContext context,
    {required int setNumber, required String type, required double? rpe}) {
  final l = AppL10n.of(context);
  String typeName(String t) => switch (t) {
        'warmup' => l.asTypeWarmup,
        'drop' => l.asTypeDrop,
        'failure' => l.asTypeFailure,
        _ => l.asTypeNormal,
      };
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.asSetOptionsTitle(setNumber), style: ctx.texts.titleMedium),
            AppSpacing.vGapMd,
            Text(l.asSetType,
                style: ctx.texts.labelLarge
                    ?.copyWith(color: ctx.colors.onSurfaceVariant)),
            AppSpacing.vGapSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final t in sessionSetTypes)
                  ChoiceChip(
                    key: ValueKey('settype.$t'),
                    label: Text(typeName(t)),
                    selected: t == type,
                    onSelected: (_) => Navigator.pop(ctx, t),
                  ),
              ],
            ),
            AppSpacing.vGapMd,
            ListTile(
              key: const ValueKey('setoptions.rpe'),
              contentPadding: EdgeInsets.zero,
              title: Text(l.rpeTitle),
              trailing: Text(
                  rpe == null
                      ? '–'
                      : formatRpe(rpe,
                          decimalSep: ctx.numFmt.symbols.DECIMAL_SEP),
                  style: ctx.texts.titleMedium),
              onTap: () => Navigator.pop(ctx, 'rpe'),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('setoptions.rpeInfo'),
                onPressed: () => Navigator.pop(ctx, 'rpeInfo'),
                icon: const FitPackIcon.material(Icons.help_outline_rounded,
                    size: AppIconSize.sm),
                label: Text(l.rpeTitle),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// RPE seçici → sete yaz (satır, yardım satırı ve set seçenekleri ortak).
Future<void> pickSetRpe(BuildContext context, SessionSetEntry set, int index,
    Units units, VoidCallback onChanged) async {
  final parts = [
    if (set.weight != null) units.lift(set.weight!),
    if (set.reps != null) '${set.reps}',
  ];
  final picked = await showRpePicker(context,
      setNumber: index + 1,
      initial: set.rpe,
      setSummary: parts.isEmpty ? null : parts.join(' × '));
  if (picked == null) return;
  set.rpe = picked.rpe;
  set.fillGen++; // RPE hücresi yeni değerle kurulsun
  onChanged();
}

class _SetRow extends StatelessWidget {
  final int index;
  final SessionSetEntry set;
  final String measure;
  final bool compact;
  final String? previous;
  // ✓'e basılınca boş alanlara yazılacak değerler — alanlarda soluk ipucu.
  final SetValues? suggestion;
  // ✓'in kaydedeceği değer metni — ekran okuyucu adı için.
  final String? valuesText;
  final Units units;
  final VoidCallback onToggle, onChanged;
  final ValueChanged<String> onSetType;
  const _SetRow(
      {super.key,
      required this.index,
      required this.set,
      required this.measure,
      required this.compact,
      required this.previous,
      required this.suggestion,
      required this.valuesText,
      required this.units,
      required this.onToggle,
      required this.onSetType,
      required this.onChanged});

  String _typeName(AppL10n l) => switch (set.type) {
        'warmup' => l.asTypeWarmup,
        'drop' => l.asTypeDrop,
        'failure' => l.asTypeFailure,
        _ => l.asTypeNormal,
      };

  /// Ölçüm tipine göre orta giriş hücreleri (header ile aynı genişlik düzeni).
  /// Boş alanın ipucu = ✓ önerisi (G-2); öneri yoksa eski sabit ipucu.
  List<Widget> _inputCols(BuildContext context) {
    final l = AppL10n.of(context);
    final n = index + 1;
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
        width: setTargetSize,
        child: _RpeCell(
            key: k('rpe'),
            value: set.rpe,
            label: l.asSemField(n, 'RPE'),
            onTap: () => pickSetRpe(context, set, index, units, onChanged)));
    Widget reps() => Expanded(
        child: _NumCell(
            key: k('reps'),
            label: l.asSemField(n, l.unitReps),
            value: set.reps?.toDouble(),
            decimal: false,
            hint: repsHint,
            onChanged: (v) {
              set.reps = v?.round();
              onChanged();
            }));
    Widget time() => Expanded(
        child: _TimeCell(
            key: k('time'),
            label: l.asSemField(n, l.hdrTime.toLowerCase()),
            value: set.durationSec,
            hint: timeHint,
            onChanged: (v) {
              set.durationSec = v;
              onChanged();
            }));
    switch (measure) {
      case 'reps':
        return [reps(), if (!compact) rpeCell()];
      case 'time':
        return [time(), timerCell()];
      case 'distance':
        return [
          Expanded(
              child: _NumCell(
                  key: k('dist'),
                  label: l.asSemField(n, units.distanceUnit),
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
          time(),
          timerCell(),
        ];
      default:
        return [
          // Görüntü/giriş birim tercihinde; state ve DB kg (docs/16 §3).
          Expanded(
              child: _NumCell(
                  key: k('kg'),
                  label: l.asSemField(n, units.weightUnit),
                  value: set.weight == null
                      ? null
                      // 1,25 kg'lık artış kaybolmasın: metrikte iki ondalık.
                      : double.parse(
                          units.liftValue(set.weight!).replaceAll(',', '.')),
                  decimal: true,
                  hint: sug?.weightKg == null
                      ? null
                      : units.liftValue(sug!.weightKg!),
                  onChanged: (v) {
                    set.weight = v == null ? null : units.weightToKg(v);
                    onChanged();
                  })),
          reps(),
          if (!compact) rpeCell(),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppL10n.of(context);
    final n = index + 1;
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
    // Dar düzende RPE sütunu yok: girilmiş RPE rozetin altında küçük yazılır.
    final rpe = set.rpe;
    final rpeTag = compact && rpe != null
        ? '@${formatRpe(rpe, decimalSep: context.numFmt.symbols.DECIMAL_SEP)}'
        : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: set.done
            ? context.semantic.success.withValues(alpha: 0.10)
            : null,
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: l.asSemSetOptions(n, _typeName(l)),
            excludeSemantics: true,
            child: InkWell(
              key: ValueKey('set.badge.$index'),
              onTap: () async {
                final r = await _showSetOptions(context,
                    setNumber: n, type: set.type, rpe: set.rpe);
                if (r == null || !context.mounted) return;
                if (r == 'rpe') {
                  await pickSetRpe(context, set, index, units, onChanged);
                } else if (r == 'rpeInfo') {
                  _showRpeInfo(context);
                } else {
                  onSetType(r);
                }
              },
              borderRadius: AppRadius.brSm,
              child: SizedBox(
                width: setTargetSize,
                height: setTargetSize,
                child: Center(
                  child: Container(
                    width: 34,
                    height: 34,
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
                            semanticLabel: l.asNewRecord)
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(badge.isEmpty ? '$n' : badge,
                                    style: context.texts.labelLarge?.copyWith(
                                        color: badge.isEmpty
                                            ? c.onSurface
                                            : badgeColor,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1)),
                                if (rpeTag != null)
                                  Text(rpeTag,
                                      style: context.texts.labelSmall?.copyWith(
                                          color: c.onSurfaceVariant,
                                          height: 1.0)),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          if (!compact)
            SizedBox(
              width: _prevColWidth,
              // C-15: referans bilgi — girilen değerden ve öneriden
              // ayrışacak kadar okunur; kontrast ≥4,5:1 (A1: açıkta 4,28 idi).
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(previous ?? '—',
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: context.texts.bodySmall?.copyWith(
                        color: c.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ),
            ),
          ..._inputCols(context),
          Semantics(
            button: true,
            label: set.done
                ? l.asSemUndoSet(n)
                : valuesText == null
                    ? l.asSemCompleteSetEmpty(n)
                    : l.asSemCompleteSet(n, valuesText!),
            excludeSemantics: true,
            child: SizedBox(
              width: setTargetSize,
              height: setTargetSize,
              child: Material(
                color: set.done
                    ? context.semantic.success
                    : c.onSurface.withValues(alpha: 0.08),
                borderRadius: AppRadius.brSm,
                child: InkWell(
                  key: ValueKey('set.complete.$index'),
                  onTap: onToggle,
                  borderRadius: AppRadius.brSm,
                  child: FitPackIcon.material(Icons.check_rounded,
                      size: AppIconSize.md,
                      color: set.done
                          ? context.semantic.onSuccess
                          : c.onSurfaceVariant),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Giriş alanı iç boşluğu: alan en az 48 yüksek olsun (U04).
const _fieldPadding = EdgeInsets.symmetric(vertical: 13, horizontal: 4);

/// Sayıyı yerel ondalık ayırıcıyla yazar ("62,5" — A1: "62.5" görünüyordu).
String _localNum(BuildContext context, String raw) =>
    raw.replaceAll('.', context.numFmt.symbols.DECIMAL_SEP);

class _NumCell extends StatelessWidget {
  final double? value;
  final bool decimal;
  final String? hint;
  final String label; // ekran okuyucu: "Set 2 kg"
  final ValueChanged<double?> onChanged;
  const _NumCell(
      {super.key,
      required this.value,
      required this.decimal,
      required this.label,
      required this.onChanged,
      this.hint});

  @override
  Widget build(BuildContext context) {
    final h = hint == null ? null : _localNum(context, hint!);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      // Ad + öneri tek düğümde (A6): okuyucu "Set 2 kg, öneri 60" der;
      // öneri girilmiş değerle karışmaz.
      child: MergeSemantics(
        child: Semantics(
          label: label,
          hint: h == null ? null : AppL10n.of(context).asSemSuggestion(h),
          child: TextFormField(
            initialValue: value == null
                ? null
                : _localNum(
                    context,
                    decimal
                        ? (value == value!.roundToDouble()
                            ? value!.round().toString()
                            : value.toString())
                        : value!.round().toString()),
            textAlign: TextAlign.center,
            style: _enteredStyle(context),
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(decimal ? r'[0-9.,]' : r'[0-9]')),
            ],
            decoration: InputDecoration(
              hintText: h ?? '0',
              // Öneri (G-2) girilmiş değerle karışmasın — soluk ama okunur.
              hintStyle: _hintStyle(context),
              isDense: true,
              contentPadding: _fieldPadding,
            ),
            onChanged: (v) =>
                onChanged(double.tryParse(v.replaceAll(',', '.'))),
          ),
        ),
      ),
    );
  }
}

/// RPE hücresi — klavye açmaz, dokununca seçici paneli açılır (docs/27 F4).
/// Görünüm diğer giriş hücreleriyle aynı (tema giriş dekorasyonu).
class _RpeCell extends StatelessWidget {
  final double? value;
  final String label;
  final VoidCallback onTap;
  const _RpeCell(
      {super.key, required this.value, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final v = value;
    final text = v == null
        ? '–'
        : formatRpe(v, decimalSep: context.numFmt.symbols.DECIMAL_SEP);
    return Semantics(
      button: true,
      label: v == null ? label : '$label $text',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brSm,
          child: InputDecorator(
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: _fieldPadding,
            ),
            textAlign: TextAlign.center,
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: v == null ? _hintStyle(context) : _enteredStyle(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// Boş giriş alanı ipucu: girilmiş değerden (onSurface, kalın) ayrışır ama
/// okunur — eski %40 alfa koyuda 2,1:1, açıkta 1,7:1 idi (A1); şimdi tam
/// onSurfaceVariant (≥4,5:1) + ince yazı.
TextStyle _hintStyle(BuildContext context) => TextStyle(
    color: context.colors.onSurfaceVariant, fontWeight: FontWeight.w400);

/// Girilmiş değer: tam renk + kalın — öneriden (ince, soluk) ilk bakışta ayrışır.
TextStyle? _enteredStyle(BuildContext context) => context.texts.bodyLarge
    ?.copyWith(color: context.colors.onSurface, fontWeight: FontWeight.w800);

/// Süre giriş hücresi — dk:sn formatı ("12:30"). Kullanıcı ":" ile saniye
/// girer; sadece sayı yazarsa dakika kabul edilir (bkz. [parseDuration]).
class _TimeCell extends StatelessWidget {
  final int? value;
  final String? hint; // ✓ önerisi (G-2); yoksa "0:00"
  final String label; // ekran okuyucu: "Set 1 süre"
  final ValueChanged<int?> onChanged;
  const _TimeCell(
      {super.key,
      required this.value,
      required this.label,
      required this.onChanged,
      this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: MergeSemantics(
        child: Semantics(
        label: label,
        child: TextFormField(
        initialValue: value == null ? null : fmtDuration(value!),
        textAlign: TextAlign.center,
        style: _enteredStyle(context),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9:.,]')),
        ],
        decoration: InputDecoration(
          hintText: hint ?? '0:00',
          hintStyle: _hintStyle(context),
          isDense: true,
          contentPadding: _fieldPadding,
        ),
        textInputAction: TextInputAction.next,
        onChanged: (v) => onChanged(parseDuration(v)),
      ),
      ),
      ),
    );
  }
}
