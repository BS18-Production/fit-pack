import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/providers.dart';
import '../../data/database/app_database.dart';

class WorkoutSessionScreen extends ConsumerStatefulWidget {
  final String workoutType;

  const WorkoutSessionScreen({super.key, required this.workoutType});

  @override
  ConsumerState<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  List<dynamic> _exercises = [];
  final Map<int, List<_SetEntry>> _setLogs = {};
  DateTime? _startTime;
  int _energy = 5;
  int _rpe = 5;
  String _kneeStatus = 'normal';

  // Rest timer
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isResting = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _loadWorkoutPlan();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWorkoutPlan() async {
    final jsonStr = await rootBundle.loadString('assets/data/workout_plan.json');
    final plan = json.decode(jsonStr) as Map<String, dynamic>;
    final phases = plan['phases'] as List<dynamic>;

    for (final phase in phases) {
      final workouts = phase['workouts'] as List<dynamic>;
      for (final workout in workouts) {
        if (workout['type'] == widget.workoutType) {
          setState(() {
            _exercises = workout['exercises'] as List<dynamic>;
            for (var i = 0; i < _exercises.length; i++) {
              final sets = _exercises[i]['sets'] as int;
              _setLogs[i] = List.generate(
                sets,
                (_) => _SetEntry(),
              );
            }
          });
          return;
        }
      }
    }
  }

  void _startRestTimer(String category) {
    _restTimer?.cancel();
    final seconds = category == 'compound'
        ? AppConstants.compoundRestSeconds
        : AppConstants.isolationRestSeconds;

    setState(() {
      _restSecondsRemaining = seconds;
      _isResting = true;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _restSecondsRemaining--;
        if (_restSecondsRemaining <= 0) {
          _isResting = false;
          timer.cancel();
          // Haptic feedback
          HapticFeedback.heavyImpact();
        }
      });
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restSecondsRemaining = 0;
    });
  }

  Future<void> _finishWorkout() async {
    if (_exercises.isEmpty) return;

    final dao = ref.read(workoutDaoProvider);
    final profileDao = ref.read(userProfileDaoProvider);
    final profile = await profileDao.getProfile();
    final duration = DateTime.now().difference(_startTime!).inMinutes;

    // Create session
    final sessionId = await dao.insertSession(WorkoutSessionsCompanion(
      date: Value(DateTime.now()),
      phase: Value(profile?.currentPhase ?? 1),
      workoutType: Value(widget.workoutType),
      durationMin: Value(duration),
      kneeStatus: Value(_kneeStatus),
      energy: Value(_energy),
      rpe: Value(_rpe),
    ));

    // Get all exercises from DB to map names to IDs
    final allExercises = await dao.getAllExercises();

    // Save sets
    for (var exIdx = 0; exIdx < _exercises.length; exIdx++) {
      final exerciseName = _exercises[exIdx]['name'] as String;
      final dbExercise = allExercises.firstWhere(
        (e) => e.name == exerciseName,
        orElse: () => allExercises.first,
      );

      final sets = _setLogs[exIdx] ?? [];
      for (var setIdx = 0; setIdx < sets.length; setIdx++) {
        final set = sets[setIdx];
        if (set.weight != null || set.reps != null) {
          await dao.insertSet(WorkoutSetsCompanion(
            sessionId: Value(sessionId),
            exerciseId: Value(dbExercise.id),
            setNumber: Value(setIdx + 1),
            weightKg: Value(set.weight),
            reps: Value(set.reps),
            isWarmup: Value(set.isWarmup),
            restSeconds: Value(_exercises[exIdx]['rest'] as int?),
          ));
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Antrenman kaydedildi! ($duration dk)'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workoutType),
        actions: [
          TextButton.icon(
            onPressed: _finishWorkout,
            icon: const Icon(Icons.check, color: Colors.green),
            label: const Text('Bitir', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
      body: _exercises.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Rest timer bar
                if (_isResting)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Colors.blue.withValues(alpha: 0.2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Dinlenme: $_restSecondsRemaining sn',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: _skipRest,
                          child: const Text('Atla'),
                        ),
                      ],
                    ),
                  ),

                // Exercise list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _exercises.length + 1, // +1 for session info
                    itemBuilder: (context, index) {
                      if (index == _exercises.length) {
                        return _SessionInfoCard(
                          energy: _energy,
                          rpe: _rpe,
                          kneeStatus: _kneeStatus,
                          onEnergyChanged: (v) => setState(() => _energy = v),
                          onRpeChanged: (v) => setState(() => _rpe = v),
                          onKneeChanged: (v) => setState(() => _kneeStatus = v),
                        );
                      }

                      final exercise = _exercises[index];
                      final sets = _setLogs[index] ?? [];
                      final isCompound = exercise['rest'] != null && (exercise['rest'] as int) >= 90;

                      return _ExerciseCard(
                        name: exercise['name'] as String,
                        repRange: exercise['repRange'] as String,
                        sets: sets,
                        onSetComplete: () => _startRestTimer(isCompound ? 'compound' : 'isolation'),
                        onSetChanged: () => setState(() {}),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _SetEntry {
  double? weight;
  int? reps;
  bool isWarmup = false;
}

class _ExerciseCard extends StatelessWidget {
  final String name;
  final String repRange;
  final List<_SetEntry> sets;
  final VoidCallback onSetComplete;
  final VoidCallback onSetChanged;

  const _ExerciseCard({
    required this.name,
    required this.repRange,
    required this.sets,
    required this.onSetComplete,
    required this.onSetChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
              'Hedef: $repRange tekrar',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 12),

            // Header row
            const Row(
              children: [
                SizedBox(width: 40, child: Text('Set', style: TextStyle(color: Colors.grey, fontSize: 12))),
                Expanded(child: Text('Kg', style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center)),
                Expanded(child: Text('Tekrar', style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center)),
                SizedBox(width: 48),
              ],
            ),
            const Divider(height: 8),

            // Set rows
            ...List.generate(sets.length, (i) => _SetRow(
              index: i,
              entry: sets[i],
              onComplete: onSetComplete,
              onChanged: onSetChanged,
            )),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final int index;
  final _SetEntry entry;
  final VoidCallback onComplete;
  final VoidCallback onChanged;

  const _SetRow({
    required this.index,
    required this.entry,
    required this.onComplete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = entry.weight != null && entry.reps != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDone ? Colors.green : Colors.white,
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (v) {
                  entry.weight = double.tryParse(v);
                  onChanged();
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (v) {
                  entry.reps = int.tryParse(v);
                  onChanged();
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: Icon(
                isDone ? Icons.check_circle : Icons.check_circle_outline,
                color: isDone ? Colors.green : Colors.grey,
              ),
              onPressed: () {
                if (isDone) onComplete();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionInfoCard extends StatelessWidget {
  final int energy;
  final int rpe;
  final String kneeStatus;
  final ValueChanged<int> onEnergyChanged;
  final ValueChanged<int> onRpeChanged;
  final ValueChanged<String> onKneeChanged;

  const _SessionInfoCard({
    required this.energy,
    required this.rpe,
    required this.kneeStatus,
    required this.onEnergyChanged,
    required this.onRpeChanged,
    required this.onKneeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8, bottom: 32),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seans Bilgileri',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Energy
            Text('Enerji: $energy/10'),
            Slider(
              value: energy.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => onEnergyChanged(v.round()),
            ),

            // RPE
            Text('RPE (Zorluk): $rpe/10'),
            Slider(
              value: rpe.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => onRpeChanged(v.round()),
            ),

            // Knee status
            const Text('Diz Durumu:'),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'normal', label: Text('Normal')),
                ButtonSegment(value: 'sore', label: Text('Hassas')),
                ButtonSegment(value: 'pain', label: Text('Ağrılı')),
              ],
              selected: {kneeStatus},
              onSelectionChanged: (v) => onKneeChanged(v.first),
            ),
          ],
        ),
      ),
    );
  }
}
