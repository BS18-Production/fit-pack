import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/formatting.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/units/units.dart';
import '../../data/providers.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/glass.dart';
import '../home/providers/home_providers.dart';
import '../workout/workout_ui.dart';
import 'weekly_review.dart';
import 'weekly_review_providers.dart';

/// **Haftalık değerlendirme ekranı** (docs/22 §4, görsel yenileme §10).
///
/// **Bir bakışta okunur** (Samet, 2026-09-30: "çok yazı okutmadan, net"):
/// 1. Üstte 4 metrik kutusu — büyük sayı + geçen haftaya göre değişim.
/// 2. Hemen altında tek aksiyon: "Gelecek hafta".
/// 3. Ayrıntı (ilerleme, kas dağılımı, hedef yönü) aşağıda, kısa satırlarla.
/// 4. "Nereden hesaplandı" (A3) kaybolmadı — her bölüm başlığındaki ⓘ'de.
///
/// docs/22 kuralları aynen geçerli: verisi olmayan bölüm gizlenmez ("Kayıt
/// yok" der); kayıtsız günden yargı çıkmaz; düşüş "kötü" diye boyanmaz;
/// puan yok, hareketler toplanmaz.
class WeeklyReviewScreen extends ConsumerStatefulWidget {
  const WeeklyReviewScreen({super.key});

  @override
  ConsumerState<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends ConsumerState<WeeklyReviewScreen> {
  /// Kaç hafta geriye bakılıyor — geçici ekran durumu (CONVENTIONS §2).
  int _offset = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final async = ref.watch(weeklyReviewProvider(_offset));

    return Scaffold(
      appBar: AppBar(title: Text(l.wrTitle)),
      body: async.when(
        loading: () => ListView(
          padding: AppSpacing.screen,
          children: [
            Skeleton.card(height: 72),
            AppSpacing.vGapMd,
            Skeleton.card(height: 220),
            AppSpacing.vGapMd,
            Skeleton.card(height: 100),
          ],
        ),
        error: (_, _) => ErrorState(
          message: l.whLoadError,
          onRetry: () => ref.invalidate(weeklyReviewProvider(_offset)),
        ),
        data: (r) => ListView(
          padding: AppSpacing.screen,
          children: [
            _WeekHeader(
              period: r.period,
              onPrev: () => setState(() => _offset++),
              onNext: _offset == 0 ? null : () => setState(() => _offset--),
            ),
            AppSpacing.vGapMd,
            _SectionTitle(
              title: l.wrThisWeek,
              info: [
                l.wrWorkoutSource(r.workout.sessions),
                l.wrNutritionSource,
                l.wrWeightSource,
              ],
            ),
            _KpiGrid(review: r),
            AppSpacing.vGapLg,
            _FocusCard(review: r),
            AppSpacing.vGapLg,
            _SectionTitle(
                title: l.wrProgressTitle, info: [l.wrProgressSource]),
            _ProgressCard(review: r),
            AppSpacing.vGapLg,
            _SectionTitle(title: l.wrMuscleTitle, info: [l.wrMuscleSource]),
            _MuscleCard(review: r),
            AppSpacing.vGapLg,
            _SectionTitle(
                title: l.wrDirectionLabel, info: [l.wrWeightSource]),
            const _DirectionCard(),
            AppSpacing.vGapXl,
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── Başlık ─────────────────────────────

class _WeekHeader extends StatelessWidget {
  final ReviewPeriod period;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  const _WeekHeader({
    required this.period,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final locale = Localizations.localeOf(context).toString();
    final f = DateFormat.MMMd(locale);
    // Bitiş hariç → ekranda son gün gösterilir.
    final son = period.end.subtract(const Duration(days: 1));
    return Row(
      children: [
        IconButton(
          tooltip: l.wrPrevWeek,
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: onPrev,
        ),
        Expanded(
          child: Column(
            children: [
              Text('${f.format(period.start)} – ${f.format(son)}',
                  style: context.texts.titleMedium),
              if (!period.isComplete)
                Text(
                  l.wrInProgress(period.daysElapsed),
                  style: context.texts.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: l.wrNextWeek,
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: onNext,
        ),
      ],
    );
  }
}

// ───────────────────────────── Bölüm başlığı ─────────────────────────────

/// Bölüm başlığı + ⓘ: "nereden hesaplandı" metni (A3) alt sayfada açılır —
/// ekranda sürekli okunacak yazı olmaktan çıktı, kaybolmadı.
class _SectionTitle extends StatelessWidget {
  final String title;
  final List<String> info;
  const _SectionTitle({required this.title, required this.info});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: context.texts.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ),
          IconButton(
            tooltip: l.wrHowCalculated,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.info_outline_rounded,
                size: AppIconSize.sm, color: context.colors.onSurfaceVariant),
            onPressed: () => showModalBottomSheet<void>(
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
                      Text(l.wrHowCalculated, style: ctx.texts.titleMedium),
                      AppSpacing.vGapMd,
                      for (final t in info) ...[
                        Text(t, style: ctx.texts.bodyMedium),
                        AppSpacing.vGapSm,
                      ],
                    ],
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

/// "+0,4 kg" / "−1,0 kg" — işaretli, birimle.
String _signed(Units u, double kg) {
  final s = u.weight(kg.abs());
  if (kg > 0) return '+$s';
  if (kg < 0) return '−$s';
  return s;
}

// ───────────────────────────── Metrik kutuları ─────────────────────────────

/// Değişim satırı: ok ikonu + işaretli metin + ton rengi. Renk hiçbir zaman
/// tek başına bilgi taşımaz (ok + metin var).
class _Delta {
  final String text;
  final int sign; // −1, 0, 1
  final DeltaTone tone;
  const _Delta(this.text, this.sign, this.tone);
}

class _KpiTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final _Delta? delta;
  final List<String> notes;
  const _KpiTile({
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    this.delta,
    this.notes = const [],
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = delta;
    final toneColor = switch (d?.tone) {
      DeltaTone.good => context.semantic.success,
      DeltaTone.caution => context.semantic.warning,
      _ => c.onSurfaceVariant,
    };
    return GlassCard(
      padding: AppSpacing.cardCompact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: c.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.labelMedium?.copyWith(
                        color: c.onSurfaceVariant,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: value,
                    style: context.texts.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800, height: 1.1)),
                if (unit != null)
                  TextSpan(
                      text: ' $unit',
                      style: context.texts.titleSmall?.copyWith(
                          color: c.onSurfaceVariant,
                          fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          if (d != null) ...[
            AppSpacing.vGapXs,
            Row(
              children: [
                Icon(
                    d.sign > 0
                        ? Icons.arrow_upward_rounded
                        : d.sign < 0
                            ? Icons.arrow_downward_rounded
                            : Icons.remove_rounded,
                    size: 14,
                    color: toneColor),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(d.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.labelMedium?.copyWith(
                          color: toneColor, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ],
          for (final n in notes) ...[
            const SizedBox(height: 2),
            Text(n,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.texts.bodySmall
                    ?.copyWith(color: c.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class _KpiGrid extends ConsumerWidget {
  final WeeklyReview review;
  const _KpiGrid({required this.review});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final u = ref.watch(unitsProvider);
    final nf = context.numFmt;
    final w = review.workout;
    final n = review.nutrition;
    final kg = review.weight;
    // Hafta sürüyorsa tam haftayla kıyas yanıltır: değişim oku yok, yalnız
    // "Geçen hafta: X" (W-2).
    final complete = review.period.isComplete;

    final sessionsDelta = w.sessions - w.prevSessions;
    final workouts = _KpiTile(
      icon: Icons.fitness_center_rounded,
      label: l.wrKpiWorkouts,
      value: '${w.sessions}',
      unit: w.planned != null ? '/ ${w.planned}' : null,
      delta: complete && sessionsDelta != 0
          ? _Delta('${sessionsDelta > 0 ? '+' : '−'}${sessionsDelta.abs()}',
              sessionsDelta.sign, countTone(sessionsDelta))
          : null,
      notes: [l.wrPrevValue('${w.prevSessions}')],
    );

    final pct = percentChange(w.volumeKg, w.prevVolumeKg);
    final volume = _KpiTile(
      icon: Icons.stacked_bar_chart_rounded,
      label: l.wrKpiVolume,
      value: w.volumeKg == 0 ? '0' : nf.format(u.weightFromKg(w.volumeKg).round()),
      unit: u.weightUnit,
      delta: complete && pct != null && pct != 0
          ? _Delta('${pct > 0 ? '+' : '−'}${pct.abs()}%', pct.sign,
              countTone(pct))
          : null,
      notes: [
        l.wrPrevValue(w.prevVolumeKg == 0
            ? '0'
            : u.weight(w.prevVolumeKg, frac: 0)),
      ],
    );

    // Beslenme: kayıtsız günden yargı yok → değişim oku/renk hiç yok.
    final food = _KpiTile(
      icon: Icons.restaurant_rounded,
      label: l.wrKpiKcal,
      value: n.avgKcal == null ? '—' : nf.format(n.avgKcal),
      unit: n.avgKcal == null ? null : 'kcal',
      notes: n.loggedDays == 0
          ? [l.wrNoRecord]
          : [
              l.wrLoggedOf(n.loggedDays, review.period.daysElapsed),
              [
                l.wrProteinAvg(n.avgProtein!),
                if (n.kcalGoal > 0) l.wrGoalShort(n.kcalGoal),
              ].join(' · '),
            ],
    );

    final weight = _KpiTile(
      icon: Icons.monitor_weight_rounded,
      label: l.wrKpiWeight,
      value: kg.weekAvg == null ? '—' : u.weightValue(kg.weekAvg!),
      unit: kg.weekAvg == null ? null : u.weightUnit,
      delta: kg.delta == null || kg.singleMeasurement
          ? null
          : _Delta(_signed(u, kg.delta!), kg.delta!.sign.toInt(),
              weightTone(kg.meaning)),
      notes: kg.count == 0
          ? [l.wrNoRecord]
          : [
              kg.singleMeasurement
                  ? l.wrSingleShort
                  : kg.delta == null
                      ? l.wrNoPrevShort
                      : l.wrMeasureCount(kg.count),
            ],
    );

    Widget row(Widget a, Widget b) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: a),
              AppSpacing.hGapMd,
              Expanded(child: b),
            ],
          ),
        );

    return Column(
      children: [
        row(workouts, volume),
        AppSpacing.vGapMd,
        row(food, weight),
      ],
    );
  }
}

// ───────────────────────────── Odak ─────────────────────────────

/// Tek aksiyon — metrik kutularının hemen altında, vurgulu.
class _FocusCard extends StatelessWidget {
  final WeeklyReview review;
  const _FocusCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.colors;
    final f = review.focus;
    final metin = switch (f.kind) {
      FocusKind.completePlan => l.wrFocusCompletePlan(f.planned!, f.done!),
      FocusKind.increaseWeight => l.wrFocusIncrease(f.exerciseName!),
      FocusKind.loggingHabit => l.wrFocusLogging(f.done!),
      FocusKind.reviewCalories => l.wrFocusCalories,
      FocusKind.keepRhythm => l.wrFocusKeep,
    };
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.10),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: c.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.16),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(Icons.flag_rounded, color: c.primary, size: 20),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(l.wrFocusTitle,
                          style: context.texts.labelLarge?.copyWith(
                              color: c.primary, fontWeight: FontWeight.w800)),
                    ),
                    _InfoButton(info: [l.wrFocusSource]),
                  ],
                ),
                Text(metin,
                    style: context.texts.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Odak kartı içindeki küçük ⓘ (başlık satırı olmayan yerler için).
class _InfoButton extends StatelessWidget {
  final List<String> info;
  const _InfoButton({required this.info});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return InkWell(
      borderRadius: AppRadius.brPill,
      onTap: () => showModalBottomSheet<void>(
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
                Text(l.wrHowCalculated, style: ctx.texts.titleMedium),
                AppSpacing.vGapMd,
                for (final t in info) Text(t, style: ctx.texts.bodyMedium),
              ],
            ),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Icon(Icons.info_outline_rounded,
            size: AppIconSize.sm, color: context.colors.onSurfaceVariant),
      ),
    );
  }
}

// ───────────────────────────── Ayrıntı ─────────────────────────────

class _EmptyLine extends StatelessWidget {
  final String text;
  const _EmptyLine(this.text);

  // Tam genişlik: boş kart, dolu kartlarla aynı hizada dursun.
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: Text(text,
            style: context.texts.bodyMedium
                ?.copyWith(color: context.colors.onSurfaceVariant)),
      );
}

/// En çok ilerleyen hareketler: ad | en iyi set | 1TM farkı. Her hareket ayrı.
class _ProgressCard extends ConsumerWidget {
  final WeeklyReview review;
  const _ProgressCard({required this.review});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final u = ref.watch(unitsProvider);
    final c = context.colors;
    return GlassCard(
      child: review.progress.isEmpty
          ? _EmptyLine(l.wrProgressNone)
          : Column(
              children: [
                for (final (i, p) in review.progress.indexed) ...[
                  if (i > 0) Divider(height: AppSpacing.lg, color: c.outlineVariant),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.texts.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            Text('${u.lift(p.bestWeightKg)} × ${p.bestReps}',
                                style: context.texts.bodySmall
                                    ?.copyWith(color: c.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_upward_rounded,
                          size: 14, color: context.semantic.success),
                      const SizedBox(width: 2),
                      Text(l.wrProgressDelta(u.lift(p.deltaE1rm)),
                          style: context.texts.labelLarge?.copyWith(
                              color: context.semantic.success,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

/// Kas grubu dağılımı — yatay çubuklar (tek renk; büyüklük = set sayısı).
/// Yalnız sayım: "az çalıştın" gibi yargı yok.
class _MuscleCard extends StatelessWidget {
  final WeeklyReview review;
  const _MuscleCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.colors;
    final rows = review.muscleSets.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = rows.isEmpty ? 1 : rows.first.value;
    return GlassCard(
      child: rows.isEmpty
          ? _EmptyLine(l.wrMuscleNone)
          : Column(
              children: [
                for (final e in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 92,
                          child: Text(WorkoutUi.muscleLabel(e.key),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.texts.bodySmall),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: AppRadius.brPill,
                            child: Stack(
                              children: [
                                Container(
                                    height: 8,
                                    color: c.primary.withValues(alpha: 0.12)),
                                FractionallySizedBox(
                                  widthFactor: e.value / max,
                                  child: Container(height: 8, color: c.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 56,
                          child: Text(l.wrMuscleRow(e.value),
                              textAlign: TextAlign.end,
                              style: context.texts.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Kilo hedefi yönü + çelişki notu (docs/22 §9). Metrik kutusundaki kilo
/// renginin kaynağı burası.
class _DirectionCard extends ConsumerWidget {
  const _DirectionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final dir = GoalDirection.tryParse(profile?.goalDirection);
    final conflict = ref.watch(goalConflictProvider).valueOrNull ?? false;
    final muted = context.texts.bodySmall
        ?.copyWith(color: context.colors.onSurfaceVariant);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<GoalDirection>(
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                    value: GoalDirection.lose, label: Text(l.wrDirLose)),
                ButtonSegment(
                    value: GoalDirection.maintain,
                    label: Text(l.wrDirMaintain)),
                ButtonSegment(
                    value: GoalDirection.gain, label: Text(l.wrDirGain)),
              ],
              selected: {?dir},
              onSelectionChanged: (s) => ref
                  .read(userProfileDaoProvider)
                  .setGoalDirection(s.isEmpty ? null : s.first.name),
            ),
          ),
          if (dir == null) ...[
            AppSpacing.vGapSm,
            Text(l.wrDirectionUnset, style: muted),
          ],
          if (conflict) ...[
            AppSpacing.vGapSm,
            Text(l.wrGoalConflict, style: context.texts.bodyMedium),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => context.push(AppRoutes.profile),
                child: Text(l.wrGoalConflictAction),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
