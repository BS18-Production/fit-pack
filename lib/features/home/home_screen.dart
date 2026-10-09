import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/formatting.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/units/units.dart';
import '../../core/utils/weight_goal.dart';
import '../../l10n/app_l10n.dart';
import '../../data/database/app_database.dart';
import '../../data/providers.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/glass.dart';
import '../calendar/week_strip.dart';
import '../workout/routine_providers.dart';
import '../workout/workout_draft.dart';
import '../nutrition/nutrition_summary_card.dart';
import '../nutrition/meal_idea_card.dart';
import '../nutrition/nutrition_screen.dart' show selectedDateProvider;
import 'workout_activity_card.dart';
import 'providers/dashboard_providers.dart';
import 'providers/home_providers.dart';
import '../../core/prefs/week_start_provider.dart';
import '../nutrition/nutrition_habit_widgets.dart';
import 'rhythm_state.dart';
import 'streak_calc.dart';
import '../../shared/widgets/fitpack_icon.dart';

/// Ana Sayfa (docs/24). Sıra: başlık → haftalık şerit → bugünün eylemi →
/// ritim (seri + bu hafta + son 30 gün) → günün kaydı → içgörü, su + kilo.
/// Tüm sayılar gerçek veriden gelir (sahte veri yok — kaynak yoksa öğe gizlenir).
///
/// Şeritteki gezinme bugünün eylemine DOKUNMAZ: eylem kartı yalnız bugüne
/// bakan sağlayıcıları izler, şeridin seçili haftasını bilmez.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Zemin (GlassBackground) app.dart'ta TÜM ekranlara bir kez verilir;
    // burada tekrar kurulmaz. Alt boşluk: içerik buzlu çubuğun altından
    // aktığı için bottomScrollInset.
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider);
          ref.invalidate(todayNutritionProvider);
          ref.invalidate(weightTrendProvider);
          ref.invalidate(weeklyStreakProvider);
          ref.invalidate(todayWaterProvider);
          ref.invalidate(todayRoutineProvider);
          ref.invalidate(activeDraftProvider);
          ref.invalidate(last30WorkoutStatsProvider);
          ref.invalidate(recentWorkoutActivityProvider);
          ref.invalidate(topProgressProvider);
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            context.bottomScrollInset,
          ),
          children: const [
            _Header(),
            AppSpacing.vGapLg,
            WeekStrip(),
            AppSpacing.vGapXl,
            _CompactNutrition(),
            AppSpacing.vGapLg,
            _PrimaryActionCard(),
            AppSpacing.vGapXl,
            _DayLogHeader(),
            AppSpacing.vGapMd,
            MealIdeaCard(),
            AppSpacing.vGapMd,
            UsualMealCard(),
            AppSpacing.vGapXl,
            WorkoutActivityCard(),
            AppSpacing.vGapXl,
            _RhythmCard(),
            AppSpacing.vGapXl,
            _InsightCard(),
            _CompactHealthRow(),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────── Header

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.colors;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'FIT'),
                            TextSpan(
                              text: 'PACK',
                              style: TextStyle(color: c.primary),
                            ),
                          ],
                        ),
                        style: context.texts.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.8,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        context.upper(l.journalSubtitle),
                        style: context.texts.labelSmall?.copyWith(
                          color: c.onSurfaceVariant,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: c.surfaceContainer,
                    foregroundColor: c.onSurface,
                    minimumSize: const Size.square(AppA11y.minTapTarget),
                  ),
                  tooltip: l.homeProfileTooltip,
                  icon: const FitPackIcon.material(Icons.person_outline_rounded),
                  onPressed: () => context.push(AppRoutes.profile),
                ),
              ],
            ),
            AppSpacing.vGapXl,
            Text(l.journalTitle, style: context.texts.headlineMedium),
            AppSpacing.vGapXs,
            Text(
              context.dateFmt('d MMMM, EEEE').format(DateTime.now()),
              style: context.texts.bodySmall?.copyWith(
                color: c.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────── Birincil aksiyon (durum)

/// Bugünün eylemi — öncelik sırası (docs/24 §2): devam eden seans →
/// planlı rutin → dinlenme günü → plan yok. Yalnız BUGÜNE bakar.
class _PrimaryActionCard extends ConsumerWidget {
  const _PrimaryActionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Devam eden seans varken "yeni antrenman başlat" yarışmaz (docs/23 §3.2).
    final draft = ref.watch(activeDraftProvider).valueOrNull;
    if (draft != null) return _ResumeCard(draft: draft);

    return ref
        .watch(todayRoutineProvider)
        .when(
          loading: () => Skeleton.card(height: 150),
          error: (_, _) => const _StartWorkoutCard(),
          data: (tr) {
            if (tr.today != null) return _TrainingDayCard(routine: tr.today!);
            if (tr.next == null) return const _StartWorkoutCard();
            return _RestDayCard(nextName: tr.next!.name);
          },
        );
  }
}

/// Mor gradyanlı eylem kartı: üst etiket, başlık, alt satır, beyaz düğme.
/// Antrenman günü ve devam eden seans aynı kalıbı kullanır.
class _GradientActionCard extends StatelessWidget {
  final String kicker, title, subtitle, action;
  final IconData actionIcon;
  final VoidCallback onTap;
  const _GradientActionCard({
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.actionIcon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  kicker,
                  style: context.texts.labelSmall?.copyWith(
                    color: c.onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: .09),
                  borderRadius: AppRadius.brMd,
                ),
                child: FitPackIcon.material(
                  Icons.fitness_center_rounded,
                  color: c.primary,
                  size: AppIconSize.sm,
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.texts.headlineMedium,
          ),
          if (subtitle.isNotEmpty) ...[
            AppSpacing.vGapXs,
            Text(
              subtitle,
              style: context.texts.bodySmall?.copyWith(
                color: c.onSurfaceVariant,
              ),
            ),
          ],
          AppSpacing.vGapLg,
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onTap,
              child: Row(
                children: [
                  FitPackIcon.material(actionIcon, size: AppIconSize.sm),
                  AppSpacing.hGapSm,
                  Expanded(child: Text(action)),
                  AppSpacing.hGapSm,
                  const FitPackIcon.material(Icons.arrow_outward_rounded, size: AppIconSize.sm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeCard extends ConsumerWidget {
  final WorkoutDraft draft;
  const _ResumeCard({required this.draft});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final setCount = draft.exercises.fold<int>(
      0,
      (n, e) => n + e.sets.where((s) => s.done).length,
    );
    final mins = DateTime.now().difference(draft.startedAt).inMinutes;
    final sub =
        l.workoutResumeSub(draft.exercises.length, setCount) +
        (mins > 0 && mins < 600 ? ' · $mins ${l.unitMinShort}' : '');
    return _GradientActionCard(
      kicker: l.homeInProgress,
      title: draft.title,
      subtitle: sub,
      action: l.homeResumeAction,
      actionIcon: Icons.play_arrow_rounded,
      onTap: () => context
          .push(AppRoutes.workoutActiveResume)
          .then((_) => ref.invalidate(activeDraftProvider)),
    );
  }
}

class _TrainingDayCard extends ConsumerWidget {
  final Routine routine;
  const _TrainingDayCard({required this.routine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final exCount = ref
        .watch(routineExercisesProvider(routine.id))
        .valueOrNull
        ?.length;
    return _GradientActionCard(
      kicker: l.homeTodayPlan,
      title: routine.name,
      subtitle: exCount != null ? l.homePlanSubtitle(exCount) : '',
      action: l.homeStart,
      actionIcon: Icons.play_arrow_rounded,
      onTap: () => context.push(AppRoutes.routinePreview(routine.id)),
    );
  }
}

class _StartWorkoutCard extends StatelessWidget {
  const _StartWorkoutCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.go(AppRoutes.workout),
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.brMd,
                ),
                child: FitPackIcon.material(
                  Icons.fitness_center_rounded,
                  color: context.colors.primary,
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppL10n.of(context).homeStartTitle,
                      style: context.texts.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppL10n.of(context).homeStartSubtitle,
                      style: context.texts.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FitPackIcon.material(Icons.chevron_right_rounded, color: context.colors.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestDayCard extends StatelessWidget {
  final String? nextName;
  const _RestDayCard({required this.nextName});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final muted = context.colors.onSurfaceVariant;
    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: muted.withValues(alpha: 0.10),
                  borderRadius: AppRadius.brMd,
                ),
                child: FitPackIcon.material(Icons.bedtime_outlined, color: muted),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.homeRestTitle, style: context.texts.titleMedium),
                    if (nextName != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        l.homeRestNext(nextName!),
                        style: context.texts.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          InkWell(
            onTap: () => context.go(AppRoutes.workout),
            borderRadius: AppRadius.brMd,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: muted.withValues(alpha: 0.07),
                borderRadius: AppRadius.brMd,
              ),
              child: Row(
                children: [
                  FitPackIcon.material(Icons.bolt_rounded, color: muted, size: AppIconSize.sm),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Text(
                      l.homeWorkoutAnyway,
                      style: context.texts.labelLarge?.copyWith(
                        color: muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FitPackIcon.material(
                    Icons.chevron_right_rounded,
                    color: context.colors.outline,
                    size: AppIconSize.sm,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── Ritim kartı

/// Ritim başlığının metni — seçim `rhythmHeadline`'da (birim testli).
String _rhythmTitle(AppL10n l, RhythmHeadline h) {
  final n = h.n, next = h.n + 1;
  return switch (h.line) {
    RhythmLine.start => l.rhythmStart,
    RhythmLine.firstWeek => l.rhythmFirstWeek,
    RhythmLine.firstWeekLastOne => l.rhythmFirstWeekLastOne,
    RhythmLine.week1 => l.rhythmWeek1,
    RhythmLine.week2 => l.rhythmWeek2,
    RhythmLine.week3 => l.rhythmWeek3,
    RhythmLine.month1 => l.rhythmMonth1,
    RhythmLine.month2 => l.rhythmMonth2,
    RhythmLine.month3 => l.rhythmMonth3,
    RhythmLine.halfYear => l.rhythmHalfYear,
    RhythmLine.year1 => l.rhythmYear1,
    RhythmLine.doneA => l.rhythmDoneA(n),
    RhythmLine.doneB => l.rhythmDoneB(n),
    RhythmLine.doneC => l.rhythmDoneC(n),
    RhythmLine.doneD => l.rhythmDoneD(n),
    RhythmLine.ongoingA => l.rhythmOngoingA(n),
    RhythmLine.ongoingB => l.rhythmOngoingB(next),
    RhythmLine.ongoingC => l.rhythmOngoingC(n),
    RhythmLine.ongoingLastOne => l.rhythmOngoingLastOne(next),
    RhythmLine.restartA => l.rhythmRestartA,
    RhythmLine.restartB => l.rhythmRestartB,
    RhythmLine.restartC => l.rhythmRestartC,
  };
}

/// Seri + bu haftanın ilerlemesi + son 30 günün özeti (docs/24 §2).
/// Seri [weeklyStreakProvider]'dan: haftalık hedef bazlı — dinlenme günü ya da
/// uygulamayı açmamak seriyi kırmaz; devam eden hafta seriyi sıfırlamaz.
class _RhythmCard extends ConsumerWidget {
  const _RhythmCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.colors;
    final streak =
        ref.watch(weeklyStreakProvider).valueOrNull ??
        const WeeklyStreak(weeks: 0, thisWeekDone: 0, weeklyGoal: 1);
    final month = ref.watch(last30WorkoutStatsProvider).valueOrNull;
    final units = ref.watch(unitsProvider);
    final fmt = context.numFmt;

    final state = rhythmStateOf(streak);
    final done = streak.thisWeekDone, goal = streak.weeklyGoal;
    // Haftanın sırası: seri 0 iken başlığın haftadan haftaya dönmesi için.
    final weekStart = startOfWeek(DateTime.now(), ref.watch(weekStartProvider));
    final weekIndex =
        DateTime.utc(
          weekStart.year,
          weekStart.month,
          weekStart.day,
        ).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay ~/
        7;
    final title = _rhythmTitle(l, rhythmHeadline(streak, weekIndex: weekIndex));
    final subtitle = switch (state) {
      RhythmState.empty => l.homeRhythmEmptySub(goal),
      RhythmState.restart => l.homeRhythmRestartSub(done, goal),
      RhythmState.weekDone => l.homeRhythmDone(done, goal),
      RhythmState.firstWeek ||
      RhythmState.ongoing => l.homeRhythmLeft(done, goal, streak.remaining),
    };
    final barColor = streak.thisWeekComplete
        ? context.semantic.success
        : c.primary;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.homeRhythmKicker,
            style: context.texts.labelSmall?.copyWith(
              color: c.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: title),
                // Emoji yerine temalı ikon (CONVENTIONS §5b).
                if (streak.weeks > 0)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: FitPackIcon.material(
                        Icons.local_fire_department_rounded,
                        size: 24,
                        color: context.semantic.warning,
                      ),
                    ),
                  ),
              ],
            ),
            style: context.texts.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: context.texts.bodySmall?.copyWith(color: c.onSurfaceVariant),
          ),
          AppSpacing.vGapMd,
          ClipRRect(
            borderRadius: AppRadius.brPill,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (done / goal).clamp(0.0, 1.0)),
              duration: AppDuration.normal,
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: c.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
          AppSpacing.vGapLg,
          Text(
            l.homeLast30,
            style: context.texts.labelSmall?.copyWith(
              color: c.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          AppSpacing.vGapSm,
          IntrinsicHeight(
            child: Row(
              children: [
                _RhythmStat(
                  value: fmt.format(month?.sessions ?? 0),
                  label: l.homeStatWorkouts,
                ),
                VerticalDivider(color: c.outlineVariant, width: AppSpacing.xl),
                _RhythmStat(
                  value: fmt.format(
                    units.weightFromKg(month?.volumeKg ?? 0).round(),
                  ),
                  label: l.homeStatVolume(units.weightUnit),
                ),
                VerticalDivider(color: c.outlineVariant, width: AppSpacing.xl),
                _RhythmStat(
                  value: fmt.format(month?.kcalBurned ?? 0),
                  label: l.homeStatKcalEstimated,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.push(AppRoutes.weeklyReview),
              icon: const FitPackIcon.material(Icons.insights_rounded, size: AppIconSize.sm),
              label: Text(l.wrOpen),
            ),
          ),
        ],
      ),
    );
  }
}

class _RhythmStat extends StatelessWidget {
  final String value;
  final String label;
  const _RhythmStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────── Günün kaydı başlığı

class _DayLogHeader extends ConsumerWidget {
  const _DayLogHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l.journalMeals, style: context.texts.titleLarge),
            ),
            TextButton(
              onPressed: () {
                ref.read(selectedDateProvider.notifier).state = DateTime.now();
                context.go(AppRoutes.nutrition);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.navNutrition),
                  const FitPackIcon.material(Icons.arrow_outward_rounded, size: AppIconSize.sm),
                ],
              ),
            ),
          ],
        ),
        // Haftalık kayıt hedefi — günlük seri değil (docs/26).
        const LogWeekLineText(),
      ],
    );
  }
}

// ──────────────────────────────────────────────────── Kompakt beslenme

class _CompactNutrition extends ConsumerWidget {
  const _CompactNutrition();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    return ref
        .watch(todayNutritionProvider)
        .when(
          loading: () => Skeleton.card(height: 320),
          error: (_, _) => ErrorState(
            message: AppL10n.of(context).nutritionLoadError,
            onRetry: () => ref.invalidate(todayNutritionProvider),
          ),
          data: (nutrition) => NutritionSummaryCard(
            kcal: nutrition.kcal,
            protein: nutrition.protein,
            carb: nutrition.carb,
            fat: nutrition.fat,
            kcalGoal: profile?.kcalGoal ?? 2200,
            proteinGoal: profile?.proteinGoal ?? 180,
            onTap: () {
              ref.read(selectedDateProvider.notifier).state = DateTime.now();
              context.go(AppRoutes.nutrition);
            },
          ),
        );
  }
}

// ─────────────────────────────────────────────────────────── İçgörü kartı

/// En çok gelişen hareket (e1RM artışı). Yeterli veri yoksa hiç gösterilmez.
class _InsightCard extends ConsumerWidget {
  const _InsightCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final top = ref.watch(topProgressProvider).valueOrNull;
    if (top == null) return const SizedBox.shrink();
    final units = ref.watch(unitsProvider);
    final c = context.colors;
    final success = context.semantic.success;

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: _Card(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: success.withValues(alpha: 0.16),
                borderRadius: AppRadius.brMd,
              ),
              child: FitPackIcon.material(Icons.trending_up_rounded, color: success),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.homeInsightLabel,
                    style: context.texts.labelSmall?.copyWith(
                      color: success,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.homeInsightMostImproved(top.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.homeInsightSubtitle,
                    style: context.texts.bodySmall?.copyWith(
                      color: c.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.hGapSm,
            Text(
              '+${units.weight(top.deltaE1rm)}',
              style: context.texts.titleMedium?.copyWith(
                color: success,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────── Su + Kilo mini satır

class _CompactHealthRow extends ConsumerWidget {
  const _CompactHealthRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _WaterMini()),
          SizedBox(width: AppSpacing.md),
          Expanded(child: _WeightMini()),
        ],
      ),
    );
  }
}

class _WaterMini extends ConsumerWidget {
  const _WaterMini();

  // todayWaterProvider reaktif (H-05) → su ekleme/sıfırlama kendiliğinden yansır.
  Future<void> _add(WidgetRef ref, int ml) async {
    await ref.read(nutritionDaoProvider).addWater(DateTime.now(), ml);
  }

  Future<void> _reset(WidgetRef ref) async {
    await ref.read(nutritionDaoProvider).resetWater(DateTime.now());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final accent = context.semantic.info;
    final goalMl =
        ref.watch(userProfileProvider).valueOrNull?.waterGoalMl ?? 2500;
    final ml = ref.watch(todayWaterProvider).valueOrNull ?? 0;
    final pct = (ml / goalMl).clamp(0.0, 1.0);
    final liters = (ml / 1000).toStringAsFixed(1);
    final goalL = (goalMl / 1000).toStringAsFixed(1);

    return _Card(
      child: GestureDetector(
        onLongPress: () => _reset(ref),
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: AppRadius.brSm,
                  ),
                  child: FitPackIcon.material(
                    Icons.water_drop_outlined,
                    color: accent,
                    size: AppIconSize.sm,
                  ),
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.homeWaterTitle, style: context.texts.titleSmall),
                      Text(
                        l.homeWaterAmount(liters, goalL),
                        style: context.texts.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.vGapMd,
            ClipRRect(
              borderRadius: AppRadius.brSm,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct),
                duration: AppDuration.normal,
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 6,
                  backgroundColor: context.colors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ),
            AppSpacing.vGapMd,
            SizedBox(
              width: double.infinity,
              child: _MiniAction(
                label: l.homeWaterAdd,
                accent: accent,
                onTap: () => _add(ref, 250),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback onTap;
  const _MiniAction({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent.withValues(alpha: 0.12),
      borderRadius: AppRadius.brPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: Container(
          height: 34,
          alignment: Alignment.center,
          child: Text(
            label,
            style: context.texts.labelMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _WeightMini extends ConsumerWidget {
  const _WeightMini();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final trend = ref.watch(weightTrendProvider).valueOrNull;
    final goalKg = ref.watch(userProfileProvider).valueOrNull?.goalWeightKg;
    final units = ref.watch(unitsProvider);
    final c = context.colors;
    final success = context.semantic.success;

    return _Card(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.go(AppRoutes.progress),
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: success.withValues(alpha: 0.16),
                      borderRadius: AppRadius.brSm,
                    ),
                    child: FitPackIcon.material(
                      Icons.monitor_weight_outlined,
                      color: success,
                      size: AppIconSize.sm,
                    ),
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Text(
                      l.homeWeightTitle,
                      style: context.texts.titleSmall,
                    ),
                  ),
                ],
              ),
              AppSpacing.vGapMd,
              if (trend?.latest == null)
                Text(
                  l.homeWeightEmpty,
                  style: context.texts.titleSmall?.copyWith(color: c.primary),
                )
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      units.weightValue(trend!.latest!),
                      style: context.texts.headlineSmall,
                    ),
                    AppSpacing.hGapXs,
                    Text(
                      units.weightUnit,
                      style: context.texts.bodySmall?.copyWith(
                        color: c.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (trend.delta != null && trend.delta != 0) ...[
                  const SizedBox(height: 4),
                  _DeltaChip(
                    delta: trend.delta!,
                    units: units,
                    tone: weightChangeTone(
                      fromKg: trend.latest! - trend.delta!,
                      toKg: trend.latest!,
                      goalKg: goalKg,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  final double delta; // kg (DB kanonik)
  final Units units;
  final WeightChangeTone tone;
  const _DeltaChip({
    required this.delta,
    required this.units,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    // C-31: yön hedef kiloya göre yorumlanır (kilo alan için artış olumlu);
    // hedef yoksa nötr. Eskiden "düşüş = iyi" sabitti.
    final down = delta < 0;
    final color = tone == WeightChangeTone.good
        ? context.semantic.success
        : context.colors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FitPackIcon.material(
            down ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            units.weight(delta.abs()),
            style: context.texts.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────── Ortak kart

/// Dashboard kartı — artık "liquid glass" (yarı saydam + arka bulanıklık).
/// Tek yerden [GlassCard]'a delege eder; böylece tüm Ana Sayfa kartları
/// tutarlı cam yüzey alır (açık/koyu temaya göre otomatik).
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(radius: AppRadius.xl, padding: padding, child: child);
  }
}
