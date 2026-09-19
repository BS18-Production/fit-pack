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
import '../../shared/widgets/progress_indicators.dart';
import '../workout/routine_providers.dart';
import '../nutrition/macro_goals.dart';
import 'providers/dashboard_providers.dart';
import 'providers/home_providers.dart';
import 'streak_calc.dart';

/// Ana Sayfa — dashboard reskin (2026-07-04). Momentum hero (seri + son 30 gün),
/// durum-duyarlı antrenman CTA, "Bu Hafta" metrik grid, kompakt beslenme,
/// en çok gelişen hareket içgörüsü, Su + Kilo mini kartları. Tüm sayılar
/// gerçek veriden gelir (sahte veri yok — kaynak yoksa öğe gizlenir).
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
          ref.invalidate(last30WorkoutStatsProvider);
          ref.invalidate(weekDashboardProvider);
          ref.invalidate(topProgressProvider);
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm,
              AppSpacing.xl, context.bottomScrollInset),
          children: const [
            _Header(),
            SizedBox(height: 26),
            _MomentumHero(),
            SizedBox(height: 26),
            _PrimaryActionCard(),
            SizedBox(height: 26),
            _WeekDashboard(),
            SizedBox(height: 26),
            _CompactNutrition(),
            SizedBox(height: 26),
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
    final today = context.dateFmt('EEEE, d MMMM').format(DateTime.now());
    final dateLabel = today[0].toUpperCase() + today.substring(1);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.homeToday,
                      style: context.texts.labelSmall?.copyWith(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      )),
                  const SizedBox(height: 5),
                  Text(dateLabel, style: context.texts.headlineMedium),
                ],
              ),
            ),
            IconButton(
              tooltip: l.homeProfileTooltip,
              icon: const Icon(Icons.person_outline_rounded),
              color: context.colors.onSurfaceVariant,
              onPressed: () => context.push(AppRoutes.profile),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── Momentum hero

/// Seri + son 30 günün özeti (antrenman / hacim / kcal). Seri verisi
/// [weeklyStreakProvider] (haftalık hedef bazlı — dinlenme günü seriyi
/// kırmaz), özet [last30WorkoutStatsProvider].
class _MomentumHero extends ConsumerWidget {
  const _MomentumHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final streak = ref.watch(weeklyStreakProvider).valueOrNull ??
        const WeeklyStreak(weeks: 0, thisWeekDone: 0, weeklyGoal: 1);
    final month = ref.watch(last30WorkoutStatsProvider).valueOrNull;
    final units = ref.watch(unitsProvider);
    final c = context.colors;
    final fmt = context.numFmt;

    // Üç durum: seri var (hafta sayısı + bu haftanın ilerlemesi) · seri yok
    // ama bu hafta başlandı (ilk haftayı tamamla) · hiç yok (başlat).
    final hasWeeks = streak.weeks > 0;
    final started = streak.thisWeekDone > 0;
    final kicker = (hasWeeks || started)
        ? l.homeStreakWeekProgress(streak.thisWeekDone, streak.weeklyGoal)
        : l.homeStreakKickerZero;
    final title = hasWeeks
        ? l.homeStreakTitle(streak.weeks)
        : (started ? l.homeStreakTitleFirstWeek : l.homeStreakTitleZero);
    // Emoji yerine temalı ikon (docs/08 + emoji denetimi): sistem emojisi
    // premium glass dile yabancı ve platforma göre değişken görünüyor.
    final titleIcon = hasWeeks
        ? Icon(Icons.local_fire_department_rounded,
            size: 30, color: context.semantic.warning)
        : Icon(Icons.bolt_rounded, size: 30, color: c.primary);

    return _Card(
      child: Stack(
        children: [
          // Köşe ışıması — kenarı şeffafa eriyen yumuşak bloom (keskin disk
          // değil). Kart onu kırpsa da belirgin dairesel kenar oluşmaz.
          Positioned(
            right: -70,
            top: -70,
            child: IgnorePointer(
              child: Container(
                width: 184,
                height: 184,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    stops: const [0.0, 0.5, 1.0],
                    colors: [
                      c.primary.withValues(alpha: 0.20),
                      c.primary.withValues(alpha: 0.06),
                      c.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kicker,
                  style: context.texts.bodySmall
                      ?.copyWith(color: c.onSurfaceVariant)),
              const SizedBox(height: 3),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: title),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: titleIcon,
                    ),
                  ),
                ]),
                style: context.texts.displaySmall?.copyWith(height: 1.05),
              ),
              AppSpacing.vGapLg,
              Row(
                children: [
                  _MomentumStat(
                      value: '${month?.sessions ?? 0}',
                      label: l.homeStatWorkouts),
                  AppSpacing.hGapSm,
                  _MomentumStat(
                      value: fmt.format(
                          units.weightFromKg(month?.volumeKg ?? 0).round()),
                      label: l.homeStatVolume(units.weightUnit)),
                  AppSpacing.hGapSm,
                  _MomentumStat(
                      value: fmt.format(month?.kcalBurned ?? 0),
                      label: l.homeStatKcal),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MomentumStat extends StatelessWidget {
  final String value;
  final String label;
  const _MomentumStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md - 2),
        decoration: BoxDecoration(
          color: c.surfaceContainerHighest,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: c.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: context.texts.labelSmall
                    ?.copyWith(color: c.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────── Birincil aksiyon (durum)

/// Bugünkü rutine göre: planlı rutin varsa gradient CTA, yoksa dinlenme/başlat.
class _PrimaryActionCard extends ConsumerWidget {
  const _PrimaryActionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(todayRoutineProvider).when(
          loading: () => Skeleton.card(height: 84),
          error: (_, _) => const _StartWorkoutCard(),
          data: (tr) {
            if (tr.today != null) return _TrainingDayCard(routine: tr.today!);
            if (tr.next == null) return const _StartWorkoutCard();
            return _RestDayCard(nextName: tr.next!.name);
          },
        );
  }
}

class _TrainingDayCard extends ConsumerWidget {
  final Routine routine;
  const _TrainingDayCard({required this.routine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final exCount =
        ref.watch(routineExercisesProvider(routine.id)).valueOrNull?.length;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.brXl,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.indigo, AppColors.indigoDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigoDeep.withValues(alpha: 0.24),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.brXl,
        child: InkWell(
          onTap: () => context.push(AppRoutes.routinePreview(routine.id)),
          borderRadius: AppRadius.brXl,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.lg + 3),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.homeTodayRoutine(routine.name),
                          style: context.texts.titleLarge
                              ?.copyWith(color: AppColors.onGradient)),
                      const SizedBox(height: 4),
                      Text(
                          exCount != null
                              ? l.homeStartWithCount(exCount)
                              : l.homeStart,
                          style: context.texts.bodySmall?.copyWith(
                              color: AppColors.onGradient
                                  .withValues(alpha: 0.82))),
                    ],
                  ),
                ),
                AppSpacing.hGapMd,
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.onGradient.withValues(alpha: 0.20),
                    borderRadius: AppRadius.brMd,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: AppColors.onGradient),
                ),
              ],
            ),
          ),
        ),
      ),
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
              horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.brMd,
                ),
                child: Icon(Icons.fitness_center_rounded,
                    color: context.colors.primary),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppL10n.of(context).homeStartTitle,
                        style: context.texts.titleMedium),
                    const SizedBox(height: 2),
                    Text(AppL10n.of(context).homeStartSubtitle,
                        style: context.texts.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.colors.outline),
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
                child: Icon(Icons.bedtime_outlined, color: muted),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.homeRestTitle,
                        style: context.texts.titleMedium),
                    if (nextName != null) ...[
                      const SizedBox(height: 3),
                      Text(l.homeRestNext(nextName!),
                          style: context.texts.bodySmall
                              ?.copyWith(color: muted)),
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
                  horizontal: AppSpacing.md, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: muted.withValues(alpha: 0.07),
                borderRadius: AppRadius.brMd,
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, color: muted, size: AppIconSize.sm),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Text(l.homeWorkoutAnyway,
                        style: context.texts.labelLarge?.copyWith(
                            color: muted, fontWeight: FontWeight.w600)),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: context.colors.outline, size: AppIconSize.sm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── Bu Hafta grid

class _WeekDashboard extends ConsumerWidget {
  const _WeekDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final async = ref.watch(weekDashboardProvider);
    final data = async.valueOrNull;
    final units = ref.watch(unitsProvider);
    final fmt = context.numFmt;

    final goalText = data == null
        ? ''
        : (data.scheduledDays != null
            ? l.homeWeekGoalDone(data.workouts, data.scheduledDays!)
            : l.homeWeekGoalCount(data.workouts));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l.homeThisWeek, style: context.texts.headlineSmall),
            if (goalText.isNotEmpty)
              Flexible(
                child: Text(goalText,
                    textAlign: TextAlign.end,
                    style: context.texts.bodySmall
                        ?.copyWith(color: context.colors.onSurfaceVariant)),
              ),
          ],
        ),
        AppSpacing.vGapMd,
        if (async.isLoading && data == null)
          Skeleton.card(height: 260)
        else
          GridView.count(
            // Padding AÇIKÇA sıfır (C-7): verilmezse iç ızgara MediaQuery'nin
            // güvenli alanını (çentik + buzlu çubuk) kendine ekliyor → başlıkla
            // kartlar ve kartlarla Beslenme arasında büyük boşluk oluşuyordu.
            padding: EdgeInsets.zero,
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.35,
            children: [
              _MetricCard(
                icon: Icons.fitness_center_rounded,
                value:
                    '${fmt.format(units.weightFromKg(data?.volumeKg ?? 0).round())} ${units.weightUnit}',
                caption: l.homeMetricVolume,
                change: data?.volumeDeltaPct == null
                    ? null
                    : '${data!.volumeDeltaPct! >= 0 ? '+' : ''}${data.volumeDeltaPct}%',
                changePositive: (data?.volumeDeltaPct ?? 0) >= 0,
              ),
              _MetricCard(
                icon: Icons.local_fire_department_rounded,
                tint: context.semantic.warning,
                value: fmt.format(data?.kcalBurned ?? 0),
                caption: l.homeMetricKcal,
              ),
              _MetricCard(
                icon: Icons.event_available_rounded,
                tint: context.semantic.info,
                value: data?.scheduledDays != null
                    ? '${data?.workouts ?? 0}/${data!.scheduledDays}'
                    : '${data?.workouts ?? 0}',
                caption: l.homeMetricWorkouts,
              ),
              _MetricCard(
                icon: Icons.egg_alt_outlined,
                tint: context.semantic.macroProtein,
                value: data?.proteinAvgPct != null
                    ? '%${data!.proteinAvgPct}'
                    : '—',
                caption: l.homeMetricProtein,
              ),
            ],
          ),
        // Haftalık değerlendirme (docs/22): aynı sayıların yorumlanmış hâli.
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => context.push(AppRoutes.weeklyReview),
            icon: const Icon(Icons.insights_rounded, size: AppIconSize.sm),
            label: Text(l.wrOpen),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color? tint;
  final String value;
  final String caption;
  final String? change;
  final bool changePositive;

  const _MetricCard({
    required this.icon,
    required this.value,
    required this.caption,
    this.tint,
    this.change,
    this.changePositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = tint ?? c.primary;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: AppRadius.brMd,
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: (changePositive
                            ? context.semantic.success
                            : c.onSurfaceVariant)
                        .withValues(alpha: 0.16),
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Text(change!,
                      style: context.texts.labelMedium?.copyWith(
                        color: changePositive
                            ? context.semantic.success
                            : c.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      )),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.headlineSmall
                      ?.copyWith(letterSpacing: -0.5)),
              const SizedBox(height: 2),
              Text(caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall
                      ?.copyWith(color: c.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────── Kompakt beslenme

class _CompactNutrition extends ConsumerWidget {
  const _CompactNutrition();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final nutrition = ref.watch(todayNutritionProvider).valueOrNull;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    if (nutrition == null) return Skeleton.card(height: 190);

    final kcalGoal = profile?.kcalGoal ?? 2200;
    final proteinGoal = profile?.proteinGoal ?? 180;
    final derived =
        deriveMacroGoals(kcalGoal: kcalGoal, proteinGoal: proteinGoal);

    return _Card(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.go(AppRoutes.nutrition),
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.homeNutritionTitle, style: context.texts.titleLarge),
                  Text(l.commonEdit,
                      style: context.texts.labelMedium?.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              AppSpacing.vGapLg,
              Row(
                children: [
                  CalorieRing(
                      consumed: nutrition.kcal, goal: kcalGoal, size: 118),
                  AppSpacing.hGapLg,
                  Expanded(
                    child: Column(
                      children: [
                        MacroBar(
                          label: l.macroProtein,
                          current: nutrition.protein,
                          goal: proteinGoal,
                          unit: 'g',
                          color: context.semantic.macroProtein,
                        ),
                        AppSpacing.vGapMd,
                        MacroBar(
                          label: l.macroCarbs,
                          current: nutrition.carb,
                          goal: derived.carb,
                          unit: 'g',
                          color: context.semantic.macroCarbs,
                        ),
                        AppSpacing.vGapMd,
                        MacroBar(
                          label: l.macroFat,
                          current: nutrition.fat,
                          goal: derived.fat,
                          unit: 'g',
                          color: context.semantic.macroFat,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
              child: Icon(Icons.trending_up_rounded, color: success),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.homeInsightLabel,
                      style: context.texts.labelSmall?.copyWith(
                        color: success,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      )),
                  const SizedBox(height: 2),
                  Text(l.homeInsightMostImproved(top.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.titleSmall),
                  const SizedBox(height: 2),
                  Text(l.homeInsightSubtitle,
                      style: context.texts.bodySmall
                          ?.copyWith(color: c.onSurfaceVariant)),
                ],
              ),
            ),
            AppSpacing.hGapSm,
            Text('+${units.weight(top.deltaE1rm)}',
                style: context.texts.titleMedium?.copyWith(
                    color: success, fontWeight: FontWeight.w800)),
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
                  child: Icon(Icons.water_drop_outlined,
                      color: accent, size: AppIconSize.sm),
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.homeWaterTitle, style: context.texts.titleSmall),
                      Text(l.homeWaterAmount(liters, goalL),
                          style: context.texts.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant)),
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
  const _MiniAction(
      {required this.label, required this.accent, required this.onTap});

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
          child: Text(label,
              style: context.texts.labelMedium
                  ?.copyWith(color: accent, fontWeight: FontWeight.w700)),
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
                    child: Icon(Icons.monitor_weight_outlined,
                        color: success, size: AppIconSize.sm),
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    child:
                        Text(l.homeWeightTitle, style: context.texts.titleSmall),
                  ),
                ],
              ),
              AppSpacing.vGapMd,
              if (trend?.latest == null)
                Text(l.homeWeightEmpty,
                    style:
                        context.texts.titleSmall?.copyWith(color: c.primary))
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(units.weightValue(trend!.latest!),
                        style: context.texts.headlineSmall),
                    AppSpacing.hGapXs,
                    Text(units.weightUnit,
                        style: context.texts.bodySmall
                            ?.copyWith(color: c.onSurfaceVariant)),
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
  const _DeltaChip(
      {required this.delta, required this.units, required this.tone});

  @override
  Widget build(BuildContext context) {
    // C-31: yön hedef kiloya göre yorumlanır (kilo alan için artış olumlu);
    // hedef yoksa nötr. Eskiden "düşüş = iyi" sabitti.
    final down = delta < 0;
    final color = tone == WeightChangeTone.good
        ? context.semantic.success
        : context.colors.onSurfaceVariant;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            down
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            units.weight(delta.abs()),
            style: context.texts.labelMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
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
  const _Card(
      {required this.child,
      this.padding = const EdgeInsets.all(AppSpacing.lg)});

  @override
  Widget build(BuildContext context) {
    return GlassCard(radius: AppRadius.lg, padding: padding, child: child);
  }
}
