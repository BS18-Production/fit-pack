import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/providers.dart';
import '../../data/database/app_database.dart';
import '../../shared/widgets/app_state_views.dart';

class WorkoutSessionScreen extends ConsumerStatefulWidget {
  final String workoutType;

  const WorkoutSessionScreen({super.key, required this.workoutType});

  @override
  ConsumerState<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState
    extends ConsumerState<WorkoutSessionScreen> {
  List<dynamic> _exercises = [];
  final Map<int, List<_SetEntry>> _setLogs = {};
  DateTime? _startTime;
  int _energy = 5;
  int _rpe = 5;
  String _kneeStatus = 'normal';
  bool _loading = true;
  bool _saving = false;

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
    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/workout_plan.json');
      final plan = json.decode(jsonStr) as Map<String, dynamic>;
      final phases = plan['phases'] as List<dynamic>;
      for (final phase in phases) {
        for (final workout in phase['workouts'] as List<dynamic>) {
          if (workout['type'] == widget.workoutType) {
            if (!mounted) return;
            setState(() {
              _exercises = workout['exercises'] as List<dynamic>;
              for (var i = 0; i < _exercises.length; i++) {
                _setLogs[i] = List.generate(
                    _exercises[i]['sets'] as int, (_) => _SetEntry());
              }
              _loading = false;
            });
            return;
          }
        }
      }
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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

  bool get _hasAnyLoggedSet => _setLogs.values
      .any((sets) => sets.any((s) => s.weight != null || s.reps != null));

  Future<void> _finishWorkout() async {
    if (_exercises.isEmpty || _saving) return;

    if (!_hasAnyLoggedSet) {
      final ok = await confirmAction(
        context,
        title: 'Boş antrenman',
        message: 'Hiç set girilmedi. Yine de kaydedilsin mi?',
        confirmLabel: 'Kaydet',
        destructive: false,
      );
      if (!ok) return;
    }

    setState(() => _saving = true);
    try {
      final dao = ref.read(workoutDaoProvider);
      final profile = await ref.read(userProfileDaoProvider).getProfile();
      final duration =
          DateTime.now().difference(_startTime!).inMinutes;

      final sessionId = await dao.insertSession(WorkoutSessionsCompanion(
        date: Value(DateTime.now()),
        phase: Value(profile?.currentPhase ?? 1),
        workoutType: Value(widget.workoutType),
        durationMin: Value(duration),
        kneeStatus: Value(_kneeStatus),
        energy: Value(_energy),
        rpe: Value(_rpe),
      ));

      final allExercises = await dao.getAllExercises();
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
          SnackBar(content: Text('Antrenman kaydedildi · $duration dk')),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kaydedilemedi, tekrar dene'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workoutType),
        actions: [
          if (!_loading && _exercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: TextButton.icon(
                onPressed: _saving ? null : _finishWorkout,
                icon: _saving
                    ? SizedBox(
                        width: AppIconSize.sm,
                        height: AppIconSize.sm,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.colors.primary),
                      )
                    : const Icon(Icons.check_rounded),
                label: const Text('Bitir'),
              ),
            ),
        ],
      ),
      body: _loading
          ? ListView(
              padding: AppSpacing.screen,
              children: [
                Skeleton.card(height: 180),
                AppSpacing.vGapLg,
                Skeleton.card(height: 180),
              ],
            )
          : _exercises.isEmpty
              ? const EmptyState(
                  icon: Icons.fitness_center_outlined,
                  title: 'Antrenman bulunamadı',
                  message: 'Bu antrenman tipi için hareket yok',
                )
              : Column(
                  children: [
                    if (_isResting) _RestBar(
                      seconds: _restSecondsRemaining,
                      onSkip: _skipRest,
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: AppSpacing.screen,
                        itemCount: _exercises.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _exercises.length) {
                            return _SessionInfoCard(
                              energy: _energy,
                              rpe: _rpe,
                              kneeStatus: _kneeStatus,
                              onEnergyChanged: (v) =>
                                  setState(() => _energy = v),
                              onRpeChanged: (v) =>
                                  setState(() => _rpe = v),
                              onKneeChanged: (v) =>
                                  setState(() => _kneeStatus = v),
                            );
                          }
                          final exercise = _exercises[index];
                          final sets = _setLogs[index] ?? [];
                          final isCompound = exercise['rest'] != null &&
                              (exercise['rest'] as int) >= 90;
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppSpacing.lg),
                            child: _ExerciseCard(
                              name: exercise['name'] as String,
                              repRange: exercise['repRange'] as String,
                              sets: sets,
                              onSetComplete: () => _startRestTimer(
                                  isCompound ? 'compound' : 'isolation'),
                              onSetChanged: () => setState(() {}),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _RestBar extends StatelessWidget {
  final int seconds;
  final VoidCallback onSkip;
  const _RestBar({required this.seconds, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      color: context.colors.primary.withValues(alpha: 0.16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_rounded, color: context.colors.primary),
          AppSpacing.hGapSm,
          Text('Dinlenme  ${seconds}s',
              style: context.texts.titleMedium
                  ?.copyWith(color: context.colors.primary)),
          AppSpacing.hGapLg,
          TextButton(onPressed: onSkip, child: const Text('Atla')),
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
    final hintStyle = context.texts.labelMedium
        ?.copyWith(color: context.colors.onSurfaceVariant);
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: context.texts.titleMedium),
            AppSpacing.vGapXs,
            Text('Hedef: $repRange tekrar',
                style: context.texts.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
            AppSpacing.vGapMd,
            Row(
              children: [
                SizedBox(width: 36, child: Text('Set', style: hintStyle)),
                Expanded(
                    child: Text('Kg',
                        style: hintStyle, textAlign: TextAlign.center)),
                Expanded(
                    child: Text('Tekrar',
                        style: hintStyle, textAlign: TextAlign.center)),
                const SizedBox(width: 48),
              ],
            ),
            const Divider(),
            ...List.generate(
                sets.length,
                (i) => _SetRow(
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text('${index + 1}',
                style: context.texts.titleSmall?.copyWith(
                    color: isDone
                        ? context.semantic.success
                        : context.colors.onSurface)),
          ),
          Expanded(
            child: _NumField(
              hint: 'kg',
              decimal: true,
              onChanged: (v) {
                final parsed = double.tryParse(v.replaceAll(',', '.'));
                entry.weight = (parsed != null &&
                        parsed >= 0 &&
                        parsed <= 500)
                    ? parsed
                    : null;
                onChanged();
              },
            ),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: _NumField(
              hint: 'tekrar',
              decimal: false,
              onChanged: (v) {
                final parsed = int.tryParse(v);
                entry.reps =
                    (parsed != null && parsed >= 1 && parsed <= 100)
                        ? parsed
                        : null;
                onChanged();
              },
            ),
          ),
          AppSpacing.hGapSm,
          SizedBox(
            width: 48,
            child: IconButton(
              tooltip: 'Seti tamamla',
              icon: Icon(
                isDone
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
                color: isDone
                    ? context.semantic.success
                    : context.colors.onSurfaceVariant,
              ),
              onPressed: isDone ? onComplete : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final String hint;
  final bool decimal;
  final ValueChanged<String> onChanged;

  const _NumField({
    required this.hint,
    required this.decimal,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppA11y.minTapTarget,
      child: TextField(
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.allow(
              RegExp(decimal ? r'[0-9.,]' : r'[0-9]')),
        ],
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        ),
        onChanged: onChanged,
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
      margin: const EdgeInsets.only(bottom: 80),
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seans Bilgileri', style: context.texts.titleMedium),
            AppSpacing.vGapLg,
            Text('Enerji  $energy/10',
                style: context.texts.labelLarge),
            Slider(
              value: energy.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$energy',
              onChanged: (v) => onEnergyChanged(v.round()),
            ),
            Text('RPE (Zorluk)  $rpe/10',
                style: context.texts.labelLarge),
            Slider(
              value: rpe.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$rpe',
              onChanged: (v) => onRpeChanged(v.round()),
            ),
            AppSpacing.vGapSm,
            Text('Diz Durumu', style: context.texts.labelLarge),
            AppSpacing.vGapSm,
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
