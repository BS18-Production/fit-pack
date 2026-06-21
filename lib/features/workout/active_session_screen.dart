import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/database/app_database.dart';
import '../../data/providers.dart';
import '../home/providers/home_providers.dart';
import 'routine_providers.dart';

/// Aktif Antrenman Seansı (Antrenman V2 Faz C — docs/09-workout-v2.md).
/// Set tablosu (KG/tekrar/RPE/✓), set tipleri, dinlenme sayacı, canlı süre,
/// +set / +hareket. Bitir → seans + setler kaydedilir → özet.

const _setTypes = ['normal', 'warmup', 'drop', 'failure'];
const _setTypeLabel = {
  'normal': '',
  'warmup': 'I',
  'drop': 'D',
  'failure': 'F'
};

class _SetEntry {
  double? weight;
  int? reps;
  double? rpe;
  String type = 'normal';
  bool done = false;
}

class _SessionExercise {
  final Exercise exercise;
  final String? previous; // geçen seans ipucu "60×8"
  final List<_SetEntry> sets;
  _SessionExercise(this.exercise, this.previous, this.sets);
}

class ActiveSessionScreen extends ConsumerStatefulWidget {
  final int? routineId;
  const ActiveSessionScreen({super.key, this.routineId});

  @override
  ConsumerState<ActiveSessionScreen> createState() =>
      _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen> {
  final List<_SessionExercise> _exercises = [];
  String _title = 'Boş Antrenman';
  late final DateTime _startedAt;
  bool _loading = true;
  bool _saving = false;

  Timer? _ticker; // canlı süre
  Duration _elapsed = Duration.zero;

  Timer? _restTimer;
  int _restRemaining = 0;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = DateTime.now().difference(_startedAt));
    });
    _load();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final dao = ref.read(workoutDaoProvider);
    if (widget.routineId != null) {
      final routine = await dao.getRoutine(widget.routineId!);
      final exs = await dao.getRoutineExercises(widget.routineId!);
      _title = routine?.name ?? 'Antrenman';
      for (final it in exs) {
        final last = await dao.getLastSetForExercise(it.exercise.id);
        final prev = last != null && last.weightKg != null && last.reps != null
            ? '${_fmt(last.weightKg!)}×${last.reps}'
            : null;
        final count = it.routineExercise.targetSets ?? 3;
        _exercises.add(_SessionExercise(
          it.exercise,
          prev,
          List.generate(count, (_) => _SetEntry()),
        ));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  String _clock(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get _hasData =>
      _exercises.any((e) => e.sets.any((s) => s.weight != null || s.reps != null || s.done));

  // ───────── set işlemleri ─────────

  void _toggleDone(_SessionExercise ex, _SetEntry set) {
    setState(() => set.done = !set.done);
    if (set.done) {
      HapticFeedback.lightImpact();
      _startRest(90);
    }
  }

  void _cycleType(_SetEntry set) {
    final i = _setTypes.indexOf(set.type);
    setState(() => set.type = _setTypes[(i + 1) % _setTypes.length]);
  }

  void _addSet(_SessionExercise ex) => setState(() => ex.sets.add(_SetEntry()));
  void _removeSet(_SessionExercise ex) {
    if (ex.sets.length > 1) setState(() => ex.sets.removeLast());
  }

  Future<void> _addExercise() async {
    final ex = await context.push<Exercise>('/exercises/select');
    if (ex == null) return;
    final last = await ref.read(workoutDaoProvider).getLastSetForExercise(ex.id);
    final prev = last != null && last.weightKg != null && last.reps != null
        ? '${_fmt(last.weightKg!)}×${last.reps}'
        : null;
    setState(() => _exercises
        .add(_SessionExercise(ex, prev, List.generate(1, (_) => _SetEntry()))));
  }

  // ───────── dinlenme sayacı ─────────

  void _startRest(int seconds) {
    _restTimer?.cancel();
    setState(() => _restRemaining = seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _restRemaining--);
      if (_restRemaining <= 0) {
        t.cancel();
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _bumpRest(int delta) =>
      setState(() => _restRemaining = (_restRemaining + delta).clamp(0, 999));
  void _skipRest() {
    _restTimer?.cancel();
    setState(() => _restRemaining = 0);
  }

  // ───────── bitir / kaydet ─────────

  Future<void> _finish() async {
    if (_saving) return;
    if (!_hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Önce en az bir set gir')));
      return;
    }
    setState(() => _saving = true);
    final dao = ref.read(workoutDaoProvider);
    final ended = DateTime.now();
    final sessionId = await dao.insertSession(WorkoutSessionsCompanion(
      date: Value(_startedAt),
      phase: const Value(0),
      workoutType: Value(_title),
      routineId: Value(widget.routineId),
      startedAt: Value(_startedAt),
      endedAt: Value(ended),
      durationMin: Value(ended.difference(_startedAt).inMinutes),
    ));

    for (final ex in _exercises) {
      var n = 1;
      for (final s in ex.sets) {
        if (s.weight == null && s.reps == null && !s.done) continue;
        await dao.insertSet(WorkoutSetsCompanion(
          sessionId: Value(sessionId),
          exerciseId: Value(ex.exercise.id),
          setNumber: Value(n++),
          weightKg: Value(s.weight),
          reps: Value(s.reps),
          rpe: Value(s.rpe),
          setType: Value(s.type),
          isComplete: Value(s.done),
          isWarmup: Value(s.type == 'warmup'),
        ));
      }
    }

    ref.invalidate(weekWorkoutStatsProvider);
    ref.invalidate(lastWorkoutSessionProvider);
    ref.invalidate(workoutStreakProvider);
    if (mounted) context.pushReplacement('/workout/summary/$sessionId');
  }

  Future<bool> _confirmExit() async {
    if (!_hasData) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Antrenmandan çık?'),
        content: const Text('Girdiğin setler kaydedilmeyecek.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Devam et')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Çık')),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final go = GoRouter.of(context);
        if (await _confirmExit() && mounted) go.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_title, style: context.texts.titleMedium),
              Text(_clock(_elapsed),
                  style: context.texts.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                      fontFeatures: const [])),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : _finish,
              child: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Bitir'),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_restRemaining > 0) _RestBanner(
                    remaining: _restRemaining,
                    clock: _clock(Duration(seconds: _restRemaining)),
                    onMinus: () => _bumpRest(-15),
                    onPlus: () => _bumpRest(15),
                    onSkip: _skipRest,
                  ),
                  Expanded(
                    child: _exercises.isEmpty
                        ? _EmptyActive(onAdd: _addExercise)
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 96),
                            children: [
                              ..._exercises.map((e) => _ExerciseBlock(
                                    ex: e,
                                    fmt: _fmt,
                                    onToggle: (s) => _toggleDone(e, s),
                                    onCycleType: _cycleType,
                                    onAddSet: () => _addSet(e),
                                    onRemoveSet: () => _removeSet(e),
                                    onChanged: () => setState(() {}),
                                  )),
                              AppSpacing.vGapMd,
                              OutlinedButton.icon(
                                onPressed: _addExercise,
                                icon: const Icon(Icons.add_rounded,
                                    size: AppIconSize.sm),
                                label: const Text('Hareket Ekle'),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EmptyActive extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyActive({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded,
              size: AppIconSize.xxl, color: context.colors.primary),
          AppSpacing.vGapMd,
          Text('Boş antrenman', style: context.texts.titleMedium),
          AppSpacing.vGapSm,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Text('Kütüphaneden hareket ekleyerek başla',
                textAlign: TextAlign.center,
                style: context.texts.bodyMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
          ),
          AppSpacing.vGapLg,
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Hareket Ekle'),
          ),
        ],
      ),
    );
  }
}

class _RestBanner extends StatelessWidget {
  final int remaining;
  final String clock;
  final VoidCallback onMinus, onPlus, onSkip;
  const _RestBanner(
      {required this.remaining,
      required this.clock,
      required this.onMinus,
      required this.onPlus,
      required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      color: c.primary,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: c.onPrimary, size: AppIconSize.sm),
          AppSpacing.hGapSm,
          Text('Dinlenme', style: context.texts.labelLarge?.copyWith(color: c.onPrimary)),
          AppSpacing.hGapMd,
          Text(clock,
              style: context.texts.titleMedium?.copyWith(
                  color: c.onPrimary, fontWeight: FontWeight.w800)),
          const Spacer(),
          _MiniBtn('−15', onMinus, c),
          _MiniBtn('+15', onPlus, c),
          TextButton(
            onPressed: onSkip,
            child: Text('Atla', style: TextStyle(color: c.onPrimary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final ColorScheme c;
  const _MiniBtn(this.label, this.onTap, this.c);
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(label,
          style: TextStyle(color: c.onPrimary, fontWeight: FontWeight.w700)),
    );
  }
}

class _ExerciseBlock extends StatelessWidget {
  final _SessionExercise ex;
  final String Function(double) fmt;
  final void Function(_SetEntry) onToggle;
  final void Function(_SetEntry) onCycleType;
  final VoidCallback onAddSet, onRemoveSet, onChanged;
  const _ExerciseBlock(
      {required this.ex,
      required this.fmt,
      required this.onToggle,
      required this.onCycleType,
      required this.onAddSet,
      required this.onRemoveSet,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: AppSpacing.cardCompact,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ex.exercise.name, style: context.texts.titleSmall),
            if (ex.previous != null) ...[
              const SizedBox(height: 2),
              Text('Geçen seans: ${ex.previous}',
                  style: context.texts.labelSmall
                      ?.copyWith(color: c.onSurfaceVariant)),
            ],
            AppSpacing.vGapSm,
            // başlık satırı
            Row(
              children: [
                const SizedBox(width: 34, child: _H('SET')),
                Expanded(child: _H('KG', center: true)),
                Expanded(child: _H('TEKRAR', center: true)),
                const SizedBox(width: 52, child: _H('RPE', center: true)),
                const SizedBox(width: 44),
              ],
            ),
            ...ex.sets.asMap().entries.map((e) => _SetRow(
                  index: e.key,
                  set: e.value,
                  onToggle: () => onToggle(e.value),
                  onCycleType: () => onCycleType(e.value),
                  onChanged: onChanged,
                )),
            AppSpacing.vGapXs,
            Row(
              children: [
                TextButton.icon(
                  onPressed: onAddSet,
                  icon: const Icon(Icons.add_rounded, size: AppIconSize.sm),
                  label: const Text('Set Ekle'),
                ),
                if (ex.sets.length > 1)
                  TextButton.icon(
                    onPressed: onRemoveSet,
                    icon: const Icon(Icons.remove_rounded, size: AppIconSize.sm),
                    label: const Text('Çıkar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _H extends StatelessWidget {
  final String t;
  final bool center;
  const _H(this.t, {this.center = false});
  @override
  Widget build(BuildContext context) => Text(t,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: context.texts.labelSmall?.copyWith(
          color: context.colors.onSurfaceVariant,
          fontWeight: FontWeight.w700));
}

class _SetRow extends StatelessWidget {
  final int index;
  final _SetEntry set;
  final VoidCallback onToggle, onCycleType, onChanged;
  const _SetRow(
      {required this.index,
      required this.set,
      required this.onToggle,
      required this.onCycleType,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final badge = _setTypeLabel[set.type]!;
    final badgeColor = switch (set.type) {
      'warmup' => context.semantic.warning,
      'drop' => context.semantic.info,
      'failure' => c.error,
      _ => c.onSurfaceVariant,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: InkWell(
              onTap: onCycleType,
              borderRadius: AppRadius.brSm,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(badge.isEmpty ? '${index + 1}' : badge,
                    style: context.texts.labelLarge?.copyWith(
                        color: badge.isEmpty ? c.onSurface : badgeColor,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          Expanded(child: _NumCell(
            value: set.weight,
            decimal: true,
            onChanged: (v) { set.weight = v; onChanged(); },
          )),
          Expanded(child: _NumCell(
            value: set.reps?.toDouble(),
            decimal: false,
            onChanged: (v) { set.reps = v?.round(); onChanged(); },
          )),
          SizedBox(width: 52, child: _NumCell(
            value: set.rpe,
            decimal: true,
            hint: '–',
            onChanged: (v) { set.rpe = v; onChanged(); },
          )),
          SizedBox(
            width: 44,
            child: IconButton(
              icon: Icon(set.done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded),
              color: set.done ? context.semantic.success : c.outline,
              onPressed: onToggle,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumCell extends StatelessWidget {
  final double? value;
  final bool decimal;
  final String? hint;
  final ValueChanged<double?> onChanged;
  const _NumCell(
      {required this.value,
      required this.decimal,
      required this.onChanged,
      this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TextFormField(
        initialValue: value == null
            ? null
            : (decimal
                ? (value == value!.roundToDouble()
                    ? value!.round().toString()
                    : value.toString())
                : value!.round().toString()),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
              RegExp(decimal ? r'[0-9.,]' : r'[0-9]')),
        ],
        decoration: InputDecoration(
          hintText: hint ?? '0',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
        onChanged: (v) =>
            onChanged(double.tryParse(v.replaceAll(',', '.'))),
      ),
    );
  }
}
