import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/nutrition_dao.dart';
import '../../data/providers.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/progress_indicators.dart';
import '../workout/routine_providers.dart';
import '../nutrition/macro_goals.dart';
import 'providers/home_providers.dart';

/// Ana Sayfa — Claude Design (2026-06-21) tasarımına göre yeniden kuruldu.
/// Özel header (BUGÜN + tarih + ikonlar), durum-duyarlı birincil kart
/// (antrenman günü gradient CTA / dinlenme günü sakin kart), beslenme hero
/// halkası, su takibi, sessiz seri+kilo satırı.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider);
          ref.invalidate(todayNutritionProvider);
          ref.invalidate(weightTrendProvider);
          ref.invalidate(workoutStreakProvider);
          ref.invalidate(todayWaterProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
          children: [
            const _Header(),
            AppSpacing.vGapxl_,
            // Birincil aksiyon — durum-duyarlı (bugünkü rutin / dinlenme)
            const _PrimaryActionCard(),
            AppSpacing.vGapxl_,
            // Beslenme HERO
            ref.watch(todayNutritionProvider).when(
                  data: (nutrition) => profileAsync.maybeWhen(
                    data: (profile) => _NutritionHeroCard(
                      nutrition: nutrition,
                      kcalGoal: profile?.kcalGoal ?? 2200,
                      proteinGoal: profile?.proteinGoal ?? 180,
                    ),
                    orElse: () => Skeleton.card(height: 360),
                  ),
                  loading: () => Skeleton.card(height: 360),
                  error: (_, _) => const SizedBox.shrink(),
                ),
            AppSpacing.vGapxl_,
            // Su takibi
            const _WaterCard(),
            AppSpacing.vGapxl_,
            // Seri + Kilo (sessiz)
            const _StatRow(),
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
    final today =
        DateFormat('EEEE, d MMMM', 'tr_TR').format(DateTime.now());
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
                  Text('BUGÜN',
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
              tooltip: 'Veri dışa aktar',
              icon: const Icon(Icons.ios_share_rounded),
              color: context.colors.onSurfaceVariant,
              onPressed: () => context.push('/export'),
            ),
            IconButton(
              tooltip: 'Ayarlar',
              icon: const Icon(Icons.tune_rounded),
              color: context.colors.onSurfaceVariant,
              onPressed: () => context.push('/settings'),
            ),
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
          onTap: () => context.push('/workout/routine/${routine.id}/preview'),
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
                      Text('Bugün: ${routine.name}',
                          style: context.texts.titleLarge
                              ?.copyWith(color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                          exCount != null
                              ? 'Antrenmanı başlat · $exCount hareket'
                              : 'Antrenmanı başlat',
                          style: context.texts.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.82))),
                    ],
                  ),
                ),
                AppSpacing.hGapMd,
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: AppRadius.brMd,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white),
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
    return Card(
      child: InkWell(
        onTap: () => context.go('/workout'),
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
                    Text('Antrenmana başla', style: context.texts.titleMedium),
                    const SizedBox(height: 2),
                    Text('Rutin oluştur ya da boş antrenman başlat',
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
    final muted = context.colors.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
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
                      Text('Bugün dinlenme günü',
                          style: context.texts.titleMedium),
                      if (nextName != null) ...[
                        const SizedBox(height: 3),
                        Text('Sıradaki: $nextName',
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
              onTap: () => context.go('/workout'),
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
                      child: Text('Yine de antrenman yap',
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
      ),
    );
  }
}

// ──────────────────────────────────────────────────────── Beslenme HERO

class _NutritionHeroCard extends StatelessWidget {
  final DailyNutrition nutrition;
  final int kcalGoal;
  final int proteinGoal;

  const _NutritionHeroCard({
    required this.nutrition,
    required this.kcalGoal,
    required this.proteinGoal,
  });

  @override
  Widget build(BuildContext context) {
    final derived =
        deriveMacroGoals(kcalGoal: kcalGoal, proteinGoal: proteinGoal);
    return Card(
      child: InkWell(
        onTap: () => context.go('/nutrition'),
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl,
              AppSpacing.xl, AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Bugünkü Beslenme', style: context.texts.titleMedium),
                  Text('Düzenle',
                      style: context.texts.labelMedium?.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              AppSpacing.vGapLg,
              Center(
                child: CalorieRing(
                  consumed: nutrition.kcal,
                  goal: kcalGoal,
                  size: 196,
                ),
              ),
              AppSpacing.vGapxl_,
              MacroBar(
                label: 'Protein',
                current: nutrition.protein,
                goal: proteinGoal,
                unit: 'g',
                color: context.semantic.macroProtein,
              ),
              AppSpacing.vGapLg,
              MacroBar(
                label: 'Karbonhidrat',
                current: nutrition.carb,
                goal: derived.carb,
                unit: 'g',
                color: context.semantic.macroCarbs,
              ),
              AppSpacing.vGapLg,
              MacroBar(
                label: 'Yağ',
                current: nutrition.fat,
                goal: derived.fat,
                unit: 'g',
                color: context.semantic.macroFat,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────── Su takibi

class _WaterCard extends ConsumerWidget {
  const _WaterCard();

  Future<void> _add(WidgetRef ref, int ml) async {
    await ref.read(nutritionDaoProvider).addWater(DateTime.now(), ml);
    ref.invalidate(todayWaterProvider);
  }

  Future<void> _reset(WidgetRef ref) async {
    await ref.read(nutritionDaoProvider).resetWater(DateTime.now());
    ref.invalidate(todayWaterProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = context.semantic.info;
    final goalMl =
        ref.watch(userProfileProvider).valueOrNull?.waterGoalMl ?? 2500;
    final ml = ref.watch(todayWaterProvider).valueOrNull ?? 0;
    final pct = (ml / goalMl).clamp(0.0, 1.0);
    final liters = (ml / 1000).toStringAsFixed(1);
    final goalL = (goalMl / 1000).toStringAsFixed(1);

    return Card(
      child: InkWell(
        onLongPress: () => _reset(ref),
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: AppRadius.brSm,
                    ),
                    child: Icon(Icons.water_drop_outlined,
                        color: accent, size: AppIconSize.sm),
                  ),
                  AppSpacing.hGapMd,
                  Text('Su', style: context.texts.titleSmall),
                  const Spacer(),
                  Text.rich(TextSpan(children: [
                    TextSpan(
                        text: '$liters ',
                        style: context.texts.titleSmall),
                    TextSpan(
                        text: '/ $goalL L',
                        style: context.texts.labelMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600)),
                  ])),
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
              Row(
                children: [
                  Expanded(
                    child: _WaterChip(
                      label: '+250 ml',
                      accent: accent,
                      onTap: () => _add(ref, 250),
                    ),
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: _WaterChip(
                      label: '+1 bardak',
                      accent: accent,
                      onTap: () => _add(ref, 200),
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

class _WaterChip extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback onTap;
  const _WaterChip(
      {required this.label, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent.withValues(alpha: 0.10),
      borderRadius: AppRadius.brPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: Container(
          height: AppA11y.minTapTarget - 8,
          alignment: Alignment.center,
          child: Text(label,
              style: context.texts.labelMedium
                  ?.copyWith(color: accent, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────── Seri + Kilo

class _StatRow extends ConsumerWidget {
  const _StatRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(workoutStreakProvider).valueOrNull ?? 0;
    final trend = ref.watch(weightTrendProvider).valueOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _StatColumn(
                label: 'SERİ',
                onTap: streak > 0 ? null : () => context.go('/workout'),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 18)),
                    AppSpacing.hGapSm,
                    Text(streak > 0 ? '$streak' : '0',
                        style: context.texts.headlineSmall),
                    AppSpacing.hGapXs,
                    Text('gün',
                        style: context.texts.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            VerticalDivider(
                width: 1, color: context.colors.outlineVariant),
            Expanded(
              child: _StatColumn(
                label: 'SON KİLO',
                onTap: () => context.go('/progress'),
                child: trend?.latest == null
                    ? Text('İlk kilonu gir',
                        style: context.texts.titleSmall?.copyWith(
                            color: context.colors.primary))
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(trend!.latest!.toStringAsFixed(1),
                              style: context.texts.headlineSmall),
                          AppSpacing.hGapXs,
                          Text('kg',
                              style: context.texts.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant)),
                          if (trend.delta != null && trend.delta != 0) ...[
                            AppSpacing.hGapSm,
                            _DeltaChip(delta: trend.delta!),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final Widget child;
  final VoidCallback? onTap;
  const _StatColumn(
      {required this.label, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: context.texts.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                )),
            AppSpacing.vGapSm,
            child,
          ],
        ),
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  final double delta;
  const _DeltaChip({required this.delta});

  @override
  Widget build(BuildContext context) {
    // Cut bağlamı: kilo düşüşü olumlu (yeşil). Artış nötr/uyarı tonu.
    final down = delta < 0;
    final color =
        down ? context.semantic.success : context.colors.onSurfaceVariant;
    return Text(
      '${down ? '↓' : '↑'} ${delta.abs().toStringAsFixed(1)}',
      style: context.texts.labelMedium
          ?.copyWith(color: color, fontWeight: FontWeight.w700),
    );
  }
}
