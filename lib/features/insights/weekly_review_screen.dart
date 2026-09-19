import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

/// **Haftalık değerlendirme ekranı** (docs/22 §4).
///
/// Bölümler motorun sırasıyla kart olarak dizilir. İki ilke:
/// 1. **Verisi olmayan bölüm gizlenmez** — "bu hafta kayıt yok" der;
///    eksikliğin kendisi bilgi.
/// 2. **Her kartta "nereden hesaplandı"** (A3) — sayıya itiraz eden kullanıcı
///    kaynağı görebilmeli; güven için şart.
///
/// Metinler yargısız: "kaçırdın" yok, "tersine" yazılsa bile "tek hafta tek
/// başına sonuç değildir" ile birlikte.
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
            Skeleton.card(height: 140),
            AppSpacing.vGapMd,
            Skeleton.card(height: 140),
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
            _SummaryCard(review: r),
            AppSpacing.vGapMd,
            _WorkoutCard(review: r),
            AppSpacing.vGapMd,
            _ProgressCard(review: r),
            AppSpacing.vGapMd,
            _NutritionCard(review: r),
            AppSpacing.vGapMd,
            _WeightCard(review: r),
            AppSpacing.vGapMd,
            _MuscleCard(review: r),
            AppSpacing.vGapMd,
            _FocusCard(review: r),
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

// ───────────────────────────── Kart iskeleti ─────────────────────────────

/// Başlık + içerik + "nereden hesaplandı" satırı. Her bölüm bunu kullanır ki
/// kaynak satırı hiçbir kartta unutulmasın.
class _ReviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  final String source;

  const _ReviewCard({
    required this.icon,
    required this.title,
    required this.children,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppIconSize.md, color: c.primary),
              AppSpacing.hGapSm,
              Text(title, style: context.texts.titleSmall),
            ],
          ),
          AppSpacing.vGapSm,
          ...children,
          AppSpacing.vGapSm,
          Text(
            source,
            style: context.texts.bodySmall?.copyWith(color: c.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String text;
  final bool muted;
  const _Line(this.text, {this.muted = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Text(
          text,
          style: context.texts.bodyMedium?.copyWith(
            color: muted ? context.colors.onSurfaceVariant : null,
          ),
        ),
      );
}

/// "+0,4" / "−1,0" — işaretli, birimle.
String _signed(Units u, double kg) {
  final s = u.weight(kg.abs());
  if (kg > 0) return '+$s';
  if (kg < 0) return '−$s';
  return s;
}

// ───────────────────────────── Bölümler ─────────────────────────────

class _SummaryCard extends ConsumerWidget {
  final WeeklyReview review;
  const _SummaryCard({required this.review});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final u = ref.watch(unitsProvider);
    final n = review.nutrition;
    final w = review.weight;
    final facts = <String>[
      l.wrFactWorkouts(review.workout.sessions),
      n.loggedDays == 0 ? l.wrFactNoFood : l.wrFactFoodDays(n.loggedDays),
      if (w.delta != null)
        l.wrFactWeightDelta(_signed(u, w.delta!))
      else if (w.count > 0)
        l.wrFactNoPrevWeight
      else
        l.wrFactNoWeight,
    ];
    final metin = facts.join(' · ');
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.wrSummaryTitle, style: context.texts.titleSmall),
          AppSpacing.vGapSm,
          Text(metin[0].toUpperCase() + metin.substring(1),
              style: context.texts.bodyLarge),
        ],
      ),
    );
  }
}

class _WorkoutCard extends ConsumerWidget {
  final WeeklyReview review;
  const _WorkoutCard({required this.review});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final u = ref.watch(unitsProvider);
    final w = review.workout;
    return _ReviewCard(
      icon: Icons.fitness_center_rounded,
      title: l.wrWorkoutTitle,
      source: l.wrWorkoutSource(w.sessions),
      children: [
        if (w.sessions == 0 && w.planned == null)
          _Line(l.wrWorkoutNone, muted: true)
        else ...[
          _Line(w.planned != null
              ? l.wrWorkoutPlanned(w.sessions, w.planned!)
              : l.wrWorkoutDone(w.sessions)),
          if (w.sessions > 0)
            _Line(l.wrWorkoutDetail(
              w.completedSets,
              w.totalMinutes,
              u.weight(w.volumeKg, frac: 0),
            )),
        ],
        _Line(l.wrWorkoutPrev(w.prevSessions), muted: true),
      ],
    );
  }
}

class _ProgressCard extends ConsumerWidget {
  final WeeklyReview review;
  const _ProgressCard({required this.review});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final u = ref.watch(unitsProvider);
    return _ReviewCard(
      icon: Icons.trending_up_rounded,
      title: l.wrProgressTitle,
      source: l.wrProgressSource,
      children: [
        if (review.progress.isEmpty)
          _Line(l.wrProgressNone, muted: true)
        else
          for (final p in review.progress)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: context.texts.bodyMedium),
                  Text(
                    l.wrProgressRow(
                        u.lift(p.bestWeightKg), p.bestReps, u.lift(p.deltaE1rm)),
                    style: context.texts.bodySmall
                        ?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final WeeklyReview review;
  const _NutritionCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final n = review.nutrition;
    return _ReviewCard(
      icon: Icons.restaurant_rounded,
      title: l.wrNutritionTitle,
      source: l.wrNutritionSource,
      children: [
        // Kayıt yoksa hiçbir hedef yargısı yok (Samet kuralı).
        if (n.loggedDays == 0)
          _Line(l.wrNutritionNone, muted: true)
        else ...[
          _Line(l.wrNutritionLogged(n.loggedDays)),
          _Line(l.wrNutritionAvg(n.avgKcal!, n.avgProtein!)),
          if (n.kcalGoal > 0)
            _Line(l.wrNutritionGoal(n.kcalGoal, n.proteinGoal), muted: true),
        ],
      ],
    );
  }
}

class _WeightCard extends ConsumerWidget {
  final WeeklyReview review;
  const _WeightCard({required this.review});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final u = ref.watch(unitsProvider);
    final w = review.weight;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final dir = GoalDirection.tryParse(profile?.goalDirection);
    final conflict = ref.watch(goalConflictProvider).valueOrNull ?? false;

    final meaning = switch (w.meaning) {
      WeightMeaning.onTrack => l.wrMeaningOnTrack,
      WeightMeaning.against => l.wrMeaningAgainst,
      WeightMeaning.flat => l.wrMeaningFlat,
      WeightMeaning.unknown => null,
    };

    return _ReviewCard(
      icon: Icons.monitor_weight_rounded,
      title: l.wrWeightTitle,
      source: l.wrWeightSource,
      children: [
        if (w.count == 0)
          _Line(l.wrWeightNone, muted: true)
        else ...[
          _Line(l.wrWeightAvg(u.weight(w.weekAvg!), w.count)),
          if (w.singleMeasurement)
            _Line(l.wrWeightSingle, muted: true)
          else if (w.delta != null)
            _Line(l.wrWeightDelta(_signed(u, w.delta!)))
          else
            _Line(l.wrWeightNoPrev, muted: true),
          if (meaning != null) _Line(meaning),
        ],
        AppSpacing.vGapSm,
        Text(l.wrDirectionLabel, style: context.texts.labelMedium),
        AppSpacing.vGapXs,
        SegmentedButton<GoalDirection>(
          emptySelectionAllowed: true,
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: GoalDirection.lose, label: Text(l.wrDirLose)),
            ButtonSegment(
                value: GoalDirection.maintain, label: Text(l.wrDirMaintain)),
            ButtonSegment(value: GoalDirection.gain, label: Text(l.wrDirGain)),
          ],
          selected: {?dir},
          onSelectionChanged: (s) => ref
              .read(userProfileDaoProvider)
              .setGoalDirection(s.isEmpty ? null : s.first.name),
        ),
        if (dir == null) ...[
          AppSpacing.vGapXs,
          _Line(l.wrDirectionUnset, muted: true),
        ],
        if (conflict) ...[
          AppSpacing.vGapSm,
          _Line(l.wrGoalConflict),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push(AppRoutes.profile),
              child: Text(l.wrGoalConflictAction),
            ),
          ),
        ],
      ],
    );
  }
}

class _MuscleCard extends StatelessWidget {
  final WeeklyReview review;
  const _MuscleCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final rows = review.muscleSets.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return _ReviewCard(
      icon: Icons.accessibility_new_rounded,
      title: l.wrMuscleTitle,
      source: l.wrMuscleSource,
      children: [
        if (rows.isEmpty)
          _Line(l.wrMuscleNone, muted: true)
        else
          for (final e in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(WorkoutUi.muscleLabel(e.key),
                        style: context.texts.bodyMedium),
                  ),
                  Text(l.wrMuscleRow(e.value),
                      style: context.texts.bodyMedium),
                ],
              ),
            ),
      ],
    );
  }
}

class _FocusCard extends StatelessWidget {
  final WeeklyReview review;
  const _FocusCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final f = review.focus;
    final metin = switch (f.kind) {
      FocusKind.completePlan => l.wrFocusCompletePlan(f.planned!, f.done!),
      FocusKind.increaseWeight => l.wrFocusIncrease(f.exerciseName!),
      FocusKind.loggingHabit => l.wrFocusLogging(f.done!),
      FocusKind.reviewCalories => l.wrFocusCalories,
      FocusKind.keepRhythm => l.wrFocusKeep,
    };
    return _ReviewCard(
      icon: Icons.flag_rounded,
      title: l.wrFocusTitle,
      source: l.wrFocusSource,
      children: [
        Text(metin, style: context.texts.bodyLarge),
      ],
    );
  }
}
