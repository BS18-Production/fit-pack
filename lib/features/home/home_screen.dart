import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/database/daos/nutrition_dao.dart';
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
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => context.push('/export'),
          ),
          IconButton(
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
          padding: const EdgeInsets.all(16),
          children: [
            // Phase & Week info
            profileAsync.when(
              data: (profile) {
                if (profile == null) return const SizedBox.shrink();
                return _PhaseCard(
                  phase: profile.currentPhase,
                  week: profile.currentWeek,
                );
              },
              loading: () => const _ShimmerCard(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Start Workout
            lastSessionAsync.when(
              data: (lastSession) {
                final daysSince = lastSession != null
                    ? DateTime.now().difference(lastSession.date).inDays
                    : null;
                return _StartWorkoutCard(daysSince: daysSince);
              },
              loading: () => const _ShimmerCard(),
              error: (_, _) => const _StartWorkoutCard(daysSince: null),
            ),
            const SizedBox(height: 16),

            // Nutrition
            todayNutritionAsync.when(
              data: (nutrition) => profileAsync.when(
                data: (profile) => _NutritionCard(
                  nutrition: nutrition,
                  kcalGoal: profile?.kcalGoal ?? 2200,
                  proteinGoal: profile?.proteinGoal ?? 180,
                ),
                loading: () => const _ShimmerCard(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              loading: () => const _ShimmerCard(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Streak & Weight row
            Row(
              children: [
                Expanded(
                  child: streakAsync.when(
                    data: (streak) => _StatCard(
                      icon: Icons.local_fire_department,
                      iconColor: Colors.orange,
                      label: 'Seri',
                      value: '$streak gün',
                    ),
                    loading: () => const _ShimmerCard(),
                    error: (_, _) => const _StatCard(
                      icon: Icons.local_fire_department,
                      iconColor: Colors.orange,
                      label: 'Seri',
                      value: '0 gün',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: latestWeightAsync.when(
                    data: (measurement) => _StatCard(
                      icon: Icons.monitor_weight_outlined,
                      iconColor: Colors.blue,
                      label: 'Son Kilo',
                      value: measurement?.weightKg != null
                          ? '${measurement!.weightKg!.toStringAsFixed(1)} kg'
                          : '-- kg',
                    ),
                    loading: () => const _ShimmerCard(),
                    error: (_, _) => const _StatCard(
                      icon: Icons.monitor_weight_outlined,
                      iconColor: Colors.blue,
                      label: 'Son Kilo',
                      value: '-- kg',
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

  String _phaseName() {
    switch (phase) {
      case 1:
        return 'Full Body (Faz 1)';
      case 2:
        return 'Upper/Lower Split (Faz 2)';
      case 3:
        return 'İleri Upper/Lower (Faz 3)';
      default:
        return 'Faz $phase';
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d MMMM', 'tr_TR').format(DateTime.now());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              today,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_phaseName()}, Hafta $week',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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
    return Card(
      child: InkWell(
        onTap: () => context.go('/workout'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.fitness_center, size: 40, color: Colors.blue),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Antrenmanı Başlat',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (daysSince != null)
                      Text(
                        daysSince == 0
                            ? 'Bugün antrenman yaptın'
                            : 'Son antrenman: $daysSince gün önce',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
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
    final kcalPct = kcalGoal > 0 ? nutrition.kcal / kcalGoal : 0.0;
    final proteinPct = proteinGoal > 0 ? nutrition.protein / proteinGoal : 0.0;

    return Card(
      child: InkWell(
        onTap: () => context.go('/nutrition'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bugünkü Beslenme',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Icon(Icons.add_circle_outline, color: Colors.green),
                ],
              ),
              const SizedBox(height: 12),
              _ProgressRow(
                label: 'Kalori',
                current: nutrition.kcal.round(),
                goal: kcalGoal,
                unit: 'kcal',
                progress: kcalPct.clamp(0.0, 1.0),
                color: Colors.orange,
              ),
              const SizedBox(height: 8),
              _ProgressRow(
                label: 'Protein',
                current: nutrition.protein.round(),
                goal: proteinGoal,
                unit: 'g',
                progress: proteinPct.clamp(0.0, 1.0),
                color: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int current;
  final int goal;
  final String unit;
  final double progress;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.current,
    required this.goal,
    required this.unit,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(
              '$current / $goal $unit',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 8),
            Text(value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    )),
          ],
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: 60,
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
