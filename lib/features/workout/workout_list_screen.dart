import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../home/providers/home_providers.dart';

/// Loaded workout plan from JSON
final workoutPlanProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final jsonStr = await rootBundle.loadString('assets/data/workout_plan.json');
  return json.decode(jsonStr) as Map<String, dynamic>;
});

class WorkoutListScreen extends ConsumerWidget {
  const WorkoutListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(workoutPlanProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Antrenman')),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (plan) => profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Hata: $e')),
          data: (profile) {
            final currentPhase = profile?.currentPhase ?? 1;
            final phases = plan['phases'] as List<dynamic>;
            final phase = phases.firstWhere(
              (p) => p['phase'] == currentPhase,
              orElse: () => phases.first,
            );
            final workouts = phase['workouts'] as List<dynamic>;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Phase header
                Text(
                  phase['name'] as String,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hafta ${profile?.currentWeek ?? 1}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 20),

                // Workout cards
                ...workouts.map((w) => _WorkoutCard(workout: w)),

                const SizedBox(height: 20),

                // History button
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to workout history
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('Antrenman Geçmişi'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final dynamic workout;

  const _WorkoutCard({required this.workout});

  IconData _iconForType(String type) {
    if (type == 'Cardio') return Icons.directions_run;
    if (type.startsWith('Upper')) return Icons.accessibility_new;
    if (type.startsWith('Lower')) return Icons.directions_walk;
    return Icons.fitness_center;
  }

  @override
  Widget build(BuildContext context) {
    final type = workout['type'] as String;
    final name = workout['name'] as String;
    final day = workout['day'] as String;
    final exercises = workout['exercises'] as List<dynamic>;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/workout/session/$type'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_iconForType(type), color: Colors.blue, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          day,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${exercises.length} hareket',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: exercises.take(4).map<Widget>((e) {
                  return Chip(
                    label: Text(
                      e['name'] as String,
                      style: const TextStyle(fontSize: 11),
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
