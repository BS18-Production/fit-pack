import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/database/daos/nutrition_dao.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/progress_indicators.dart';
import '../home/providers/home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final lastSessionAsync = ref.watch(lastWorkoutSessionProvider);
    final todayNutritionAsync = ref.watch(todayNutritionProvider);
    final latestWeightAsync = ref.watch(latestWeightProvider);
    final streakAsync = ref.watch(workoutStreakProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fit Pack'),
        actions: [
          IconButton(
            tooltip: 'Veri dışa aktar',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => context.push('/export'),
          ),
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider);
          ref.invalidate(lastWorkoutSessionProvider);
          ref.invalidate(todayNutritionProvider);
          ref.invalidate(latestWeightProvider);
          ref.invalidate(workoutStreakProvider);
        },
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            profileAsync.when(
              data: (profile) => profile == null
                  ? const SizedBox.shrink()
                  : _PhaseCard(
                      phase: profile.currentPhase,
                      week: profile.currentWeek),
              loading: () => Skeleton.card(height: 80),
              error: (_, _) => const SizedBox.shrink(),
            ),
            AppSpacing.vGapLg,
            lastSessionAsync.when(
              data: (lastSession) => _StartWorkoutCard(
                daysSince: lastSession != null
                    ? DateTime.now().difference(lastSession.date).inDays
                    : null,
              ),
              loading: () => Skeleton.card(height: 88),
              error: (_, _) => const _StartWorkoutCard(daysSince: null),
            ),
            AppSpacing.vGapLg,
            todayNutritionAsync.when(
              data: (nutrition) => profileAsync.maybeWhen(
                data: (profile) => _NutritionCard(
                  nutrition: nutrition,
                  kcalGoal: profile?.kcalGoal ?? 2200,
                  proteinGoal: profile?.proteinGoal ?? 180,
                ),
                orElse: () => Skeleton.card(height: 130),
              ),
              loading: () => Skeleton.card(height: 130),
              error: (_, _) => const SizedBox.shrink(),
            ),
            AppSpacing.vGapLg,
            Row(
              children: [
                Expanded(
                  child: streakAsync.when(
                    data: (streak) => _StatCard(
                      icon: Icons.local_fire_department_rounded,
                      tone: _StatTone.warning,
                      label: 'Seri',
                      value: '$streak gün',
                    ),
                    loading: () => Skeleton.card(height: 104),
                    error: (_, _) => const _StatCard(
                      icon: Icons.local_fire_department_rounded,
                      tone: _StatTone.warning,
                      label: 'Seri',
                      value: '0 gün',
                    ),
                  ),
                ),
                AppSpacing.hGapLg,
                Expanded(
                  child: latestWeightAsync.when(
                    data: (m) => _StatCard(
                      icon: Icons.monitor_weight_outlined,
                      tone: _StatTone.primary,
                      label: 'Son Kilo',
                      value: m?.weightKg != null
                          ? '${m!.weightKg!.toStringAsFixed(1)} kg'
                          : '— kg',
                    ),
                    loading: () => Skeleton.card(height: 104),
                    error: (_, _) => const _StatCard(
                      icon: Icons.monitor_weight_outlined,
                      tone: _StatTone.primary,
                      label: 'Son Kilo',
                      value: '— kg',
                    ),
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

class _PhaseCard extends StatelessWidget {
  final int phase;
  final int week;
  const _PhaseCard({required this.phase, required this.week});

  String _phaseName() => switch (phase) {
        1 => 'Full Body (Faz 1)',
        2 => 'Upper/Lower Split (Faz 2)',
        3 => 'İleri Upper/Lower (Faz 3)',
        _ => 'Faz $phase',
      };

  @override
  Widget build(BuildContext context) {
    final today =
        DateFormat('EEEE, d MMMM', 'tr_TR').format(DateTime.now());
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.14),
                borderRadius: AppRadius.brMd,
              ),
              child: Icon(Icons.calendar_today_rounded,
                  color: context.colors.primary, size: AppIconSize.md),
            ),
            AppSpacing.hGapLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(today,
                      style: context.texts.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant)),
                  AppSpacing.vGapXs,
                  Text('${_phaseName()} · Hafta $week',
                      style: context.texts.titleMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartWorkoutCard extends StatelessWidget {
  final int? daysSince;
  const _StartWorkoutCard({required this.daysSince});

  @override
  Widget build(BuildContext context) {
    final subtitle = daysSince == null
        ? 'Programını aç ve başla'
        : daysSince == 0
            ? 'Bugün antrenman yaptın 💪'
            : 'Son antrenman: $daysSince gün önce';
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.brLg,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.indigoBright, AppColors.indigoDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.brLg,
        child: InkWell(
          onTap: () => context.go('/workout'),
          borderRadius: AppRadius.brLg,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: AppRadius.brMd,
                  ),
                  child: const Icon(Icons.fitness_center_rounded,
                      size: AppIconSize.md, color: Colors.white),
                ),
                AppSpacing.hGapLg,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Antrenmanı Başlat',
                          style: context.texts.titleMedium
                              ?.copyWith(color: Colors.white)),
                      AppSpacing.vGapXs,
                      Text(subtitle,
                          style: context.texts.bodySmall?.copyWith(
                              color:
                                  Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final DailyNutrition nutrition;
  final int kcalGoal;
  final int proteinGoal;

  const _NutritionCard({
    required this.nutrition,
    required this.kcalGoal,
    required this.proteinGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go('/nutrition'),
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Bugünkü Beslenme',
                      style: context.texts.titleSmall),
                  Icon(Icons.chevron_right_rounded,
                      color: context.colors.onSurfaceVariant,
                      size: AppIconSize.md),
                ],
              ),
              AppSpacing.vGapLg,
              Row(
                children: [
                  CalorieRing(
                      consumed: nutrition.kcal,
                      goal: kcalGoal,
                      size: 104),
                  AppSpacing.hGapXl,
                  Expanded(
                    child: Column(
                      children: [
                        MacroBar(
                          label: 'Protein',
                          current: nutrition.protein,
                          goal: proteinGoal,
                          unit: 'g',
                          color: context.semantic.macroProtein,
                        ),
                        AppSpacing.vGapMd,
                        MacroBar(
                          label: 'Karbonhidrat',
                          current: nutrition.carb,
                          goal: null,
                          unit: 'g',
                          color: context.semantic.macroCarbs,
                        ),
                        AppSpacing.vGapMd,
                        MacroBar(
                          label: 'Yağ',
                          current: nutrition.fat,
                          goal: null,
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

enum _StatTone { primary, warning }

class _StatCard extends StatelessWidget {
  final IconData icon;
  final _StatTone tone;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.tone,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _StatTone.primary => context.colors.primary,
      _StatTone.warning => context.semantic.warning,
    };
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: AppRadius.brMd,
              ),
              child: Icon(icon, color: color, size: AppIconSize.md),
            ),
            AppSpacing.vGapMd,
            Text(value,
                style: context.texts.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            AppSpacing.vGapXs,
            Text(label,
                style: context.texts.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
