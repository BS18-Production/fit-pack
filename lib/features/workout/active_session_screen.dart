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
import '../../shared/widgets/app_state_views.dart';
import '../home/providers/home_providers.dart';
import 'routine_providers.dart';
import 'workout_ui.dart';

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
  int? durationSec; // süre ölçümlü hareket (plank, kardiyo)
  double? distanceM; // mesafe ölçümlü hareket (koşu, yüzme)
  String type = 'normal';
  bool done = false;

  /// Ölçüm tipine göre set'te anlamlı bir veri girilmiş mi.
  bool hasInput(String measure) {
    switch (measure) {
      case 'reps':
        return reps != null;
      case 'time':
        return durationSec != null;
      case 'distance':
        return distanceM != null || durationSec != null;
      default:
        return weight != null || reps != null;
    }
  }
}

class _SessionExercise {
  final Exercise exercise;
  final String? previous; // geçen seans ipucu (tipe göre format)
  final List<_SetEntry> sets;
  final int restSec; // setler arası dinlenme (rutinden ya da kategoriye göre)
  _SessionExercise(this.exercise, this.previous, this.sets,
      {required this.restSec});

  String get measure => exercise.measurementType;
}

/// dk:sn biçimi ("12:30", "0:45").
String mmss(int totalSec) {
  final m = totalSec ~/ 60;
  final s = (totalSec % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// "12:30" / "1.30" / "90" → saniye. Boş/geçersiz → null.
int? parseDuration(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  if (t.contains(':')) {
    final parts = t.split(':');
    final m = int.tryParse(parts[0]) ?? 0;
    final s = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return m * 60 + s;
  }
  // saf sayı → dakika kabul et
  final mins = double.tryParse(t.replaceAll(',', '.'));
  return mins == null ? null : (mins * 60).round();
}

/// Geçen seansın değerini ölçüm tipine göre formatlar ("60×8", "12", "12:30", "5.2 km").
String? prevLabel(WorkoutSet? s, String measure) {
  if (s == null) return null;
  String fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();
  switch (measure) {
    case 'reps':
      return s.reps != null ? '${s.reps}' : null;
    case 'time':
      return s.durationSec != null ? mmss(s.durationSec!) : null;
    case 'distance':
      if (s.distanceM == null) return null;
      return '${fmt(s.distanceM! / 1000)} km';
    default:
      return (s.weightKg != null && s.reps != null)
          ? '${fmt(s.weightKg!)}×${s.reps}'
          : null;
  }
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
        final prev = prevLabel(last, it.exercise.measurementType);
        // Kardiyo/süre/mesafe hareketleri tek "set" ile başlar; ağırlık
        // hareketleri rutin hedefi kadar (varsayılan 3).
        final isCardioLike = it.exercise.measurementType == 'time' ||
            it.exercise.measurementType == 'distance';
        final count = isCardioLike ? 1 : (it.routineExercise.targetSets ?? 3);
        _exercises.add(_SessionExercise(
          it.exercise,
          prev,
          List.generate(count, (_) => _SetEntry()),
          restSec: it.routineExercise.targetRestSec ??
              WorkoutUi.defaultRestSec(it.exercise.category),
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

  bool get _hasData => _exercises
      .any((e) => e.sets.any((s) => s.hasInput(e.measure) || s.done));

  // ───────── set işlemleri ─────────

  void _toggleDone(_SessionExercise ex, _SetEntry set) {
    setState(() => set.done = !set.done);
    if (set.done) {
      HapticFeedback.lightImpact();
      // Hareketin kullanıcı tarafından belirlenen dinlenme süresi (0 = yok).
      if (ex.restSec > 0) _startRest(ex.restSec);
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

  /// Hareketi seanstan kaldır. Veri girilmişse önce onay sor.
  Future<void> _removeExercise(_SessionExercise ex) async {
    final hasData = ex.sets.any((s) => s.hasInput(ex.measure) || s.done);
    if (hasData) {
      final ok = await confirmAction(
        context,
        title: 'Hareketi kaldır',
        message: '${ex.exercise.name} ve girdiğin setler silinecek.',
        confirmLabel: 'Kaldır',
        destructive: true,
      );
      if (!ok) return;
    }
    setState(() => _exercises.remove(ex));
  }

  Future<void> _addExercise() async {
    final ex = await context.push<Exercise>('/exercises/select');
    if (ex == null) return;
    final last = await ref.read(workoutDaoProvider).getLastSetForExercise(ex.id);
    final prev = prevLabel(last, ex.measurementType);
    setState(() => _exercises.add(_SessionExercise(
          ex,
          prev,
          List.generate(1, (_) => _SetEntry()),
          restSec: WorkoutUi.defaultRestSec(ex.category),
        )));
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
        if (!s.hasInput(ex.measure) && !s.done) continue;
        await dao.insertSet(WorkoutSetsCompanion(
          sessionId: Value(sessionId),
          exerciseId: Value(ex.exercise.id),
          setNumber: Value(n++),
          weightKg: Value(s.weight),
          reps: Value(s.reps),
          rpe: Value(s.rpe),
          durationSec: Value(s.durationSec),
          distanceM: Value(s.distanceM),
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
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_title,
                  style: context.texts.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 13, color: context.colors.primary),
                  const SizedBox(width: 4),
                  Text(_clock(_elapsed),
                      style: context.texts.labelMedium?.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: FilledButton(
                onPressed: _saving ? null : _finish,
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.secondary,
                  foregroundColor: context.colors.onSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  visualDensity: VisualDensity.compact,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Bitir'),
              ),
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
                                    onRemoveExercise: () => _removeExercise(e),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md + 2, vertical: AppSpacing.sm + 3),
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: AppRadius.brLg,
          boxShadow: [
            BoxShadow(
              color: c.primary.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.timer_rounded, color: c.onPrimary, size: AppIconSize.md),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dinlenme',
                      style: context.texts.labelSmall?.copyWith(
                          color: c.onPrimary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600)),
                  Text(clock,
                      style: context.texts.titleLarge?.copyWith(
                          color: c.onPrimary,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ),
            ),
            _MiniBtn('−15s', onMinus),
            AppSpacing.hGapXs,
            _MiniBtn('+15s', onPlus),
            AppSpacing.hGapXs,
            _MiniBtn('Atla', onSkip, strong: true),
          ],
        ),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool strong;
  const _MiniBtn(this.label, this.onTap, {this.strong = false});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.onPrimary.withValues(alpha: strong ? 0.28 : 0.18),
      borderRadius: AppRadius.brSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(label,
              style: context.texts.labelMedium?.copyWith(
                  color: c.onPrimary, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _ExerciseBlock extends StatelessWidget {
  final _SessionExercise ex;
  final String Function(double) fmt;
  final void Function(_SetEntry) onToggle;
  final void Function(_SetEntry) onCycleType;
  final VoidCallback onAddSet, onRemoveSet, onRemoveExercise, onChanged;
  const _ExerciseBlock(
      {required this.ex,
      required this.fmt,
      required this.onToggle,
      required this.onCycleType,
      required this.onAddSet,
      required this.onRemoveSet,
      required this.onRemoveExercise,
      required this.onChanged});

  /// Ölçüm tipine göre orta sütun başlıkları (SET ve ✓ arasındakiler).
  static List<Widget> _headerCols(String measure) {
    switch (measure) {
      case 'reps':
        return const [
          Expanded(child: _H('TEKRAR', center: true)),
          SizedBox(width: 44, child: _RpeHeader()),
        ];
      case 'time':
        return const [Expanded(child: _H('SÜRE', center: true))];
      case 'distance':
        return const [
          Expanded(child: _H('MESAFE', center: true)),
          Expanded(child: _H('SÜRE', center: true)),
        ];
      default:
        return const [
          Expanded(child: _H('KG', center: true)),
          Expanded(child: _H('TEKRAR', center: true)),
          SizedBox(width: 44, child: _RpeHeader()),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: AppSpacing.cardCompact,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // hareket başlığı
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: dark ? 0.18 : 0.12),
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Icon(WorkoutUi.equipmentIcon(ex.exercise.equipment),
                      color: c.primary, size: 18),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex.exercise.name,
                          style: context.texts.titleSmall
                              ?.copyWith(color: c.primary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(WorkoutUi.equipmentLabel(ex.exercise.equipment),
                          style: context.texts.bodySmall
                              ?.copyWith(color: c.onSurfaceVariant)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      color: c.onSurfaceVariant, size: AppIconSize.md),
                  tooltip: 'Hareket seçenekleri',
                  onSelected: (v) {
                    if (v == 'remove') onRemoveExercise();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              color: c.error, size: AppIconSize.sm),
                          AppSpacing.hGapSm,
                          Text('Hareketi kaldır',
                              style: TextStyle(color: c.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            AppSpacing.vGapMd,
            // başlık satırı — ölçüm tipine göre sütunlar
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 2),
              child: Row(
                children: [
                  const SizedBox(width: 30, child: _H('SET')),
                  const SizedBox(width: 56, child: _H('ÖNCEKİ', center: true)),
                  ..._headerCols(ex.measure),
                  const SizedBox(width: 42),
                ],
              ),
            ),
            ...ex.sets.asMap().entries.map((e) => _SetRow(
                  index: e.key,
                  set: e.value,
                  measure: ex.measure,
                  previous: ex.previous,
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
          color: context.colors.onSurfaceVariant.withValues(alpha: 0.7),
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
          letterSpacing: 0.3));
}

/// "RPE" başlığı + dokunulabilir bilgi ipucu (ne olduğunu açıklar).
class _RpeHeader extends StatelessWidget {
  const _RpeHeader();

  @override
  Widget build(BuildContext context) {
    final color = context.colors.onSurfaceVariant.withValues(alpha: 0.7);
    return InkWell(
      onTap: () => _showRpeInfo(context),
      borderRadius: AppRadius.brSm,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('RPE',
              style: context.texts.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                  letterSpacing: 0.3)),
          const SizedBox(width: 2),
          Icon(Icons.help_outline_rounded, size: 12, color: color),
        ],
      ),
    );
  }
}

void _showRpeInfo(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      Widget row(String level, String desc) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: ctx.colors.primary.withValues(alpha: 0.12),
                    borderRadius: AppRadius.brSm,
                  ),
                  child: Text(level,
                      style: ctx.texts.labelMedium?.copyWith(
                          color: ctx.colors.primary,
                          fontWeight: FontWeight.w800)),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(desc, style: ctx.texts.bodyMedium),
                  ),
                ),
              ],
            ),
          );

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RPE — Algılanan Zorluk',
                  style: ctx.texts.titleMedium),
              AppSpacing.vGapSm,
              Text(
                'Seti yaparken ne kadar zorlandığını 1-10 arası kendin '
                'puanlarsın. "Kaç tekrar daha yapabilirdin?" sorusuna dayanır. '
                'Opsiyoneldir — boş bırakabilirsin.',
                style: ctx.texts.bodyMedium
                    ?.copyWith(color: ctx.colors.onSurfaceVariant),
              ),
              AppSpacing.vGapLg,
              row('10', 'Son tekrar — bir tane daha yapamazdın'),
              row('9', '1 tekrar daha yapabilirdin'),
              row('8', '2 tekrar rezervde kaldı'),
              row('7', '3-4 tekrar rezerv'),
              row('≤6', 'Rahat / ısınma seti'),
            ],
          ),
        ),
      );
    },
  );
}

class _SetRow extends StatelessWidget {
  final int index;
  final _SetEntry set;
  final String measure;
  final String? previous;
  final VoidCallback onToggle, onCycleType, onChanged;
  const _SetRow(
      {required this.index,
      required this.set,
      required this.measure,
      required this.previous,
      required this.onToggle,
      required this.onCycleType,
      required this.onChanged});

  /// Ölçüm tipine göre orta giriş hücreleri (header ile aynı genişlik düzeni).
  List<Widget> _inputCols() {
    switch (measure) {
      case 'reps':
        return [
          Expanded(
              child: _NumCell(
                  value: set.reps?.toDouble(),
                  decimal: false,
                  onChanged: (v) {
                    set.reps = v?.round();
                    onChanged();
                  })),
          SizedBox(
              width: 44,
              child: _NumCell(
                  value: set.rpe,
                  decimal: true,
                  hint: '–',
                  onChanged: (v) {
                    set.rpe = v;
                    onChanged();
                  })),
        ];
      case 'time':
        return [
          Expanded(
              child: _TimeCell(
                  value: set.durationSec,
                  onChanged: (v) {
                    set.durationSec = v;
                    onChanged();
                  })),
        ];
      case 'distance':
        return [
          Expanded(
              child: _NumCell(
                  value: set.distanceM == null ? null : set.distanceM! / 1000,
                  decimal: true,
                  hint: 'km',
                  onChanged: (v) {
                    set.distanceM = v == null ? null : v * 1000;
                    onChanged();
                  })),
          Expanded(
              child: _TimeCell(
                  value: set.durationSec,
                  onChanged: (v) {
                    set.durationSec = v;
                    onChanged();
                  })),
        ];
      default:
        return [
          Expanded(
              child: _NumCell(
                  value: set.weight,
                  decimal: true,
                  onChanged: (v) {
                    set.weight = v;
                    onChanged();
                  })),
          Expanded(
              child: _NumCell(
                  value: set.reps?.toDouble(),
                  decimal: false,
                  onChanged: (v) {
                    set.reps = v?.round();
                    onChanged();
                  })),
          SizedBox(
              width: 44,
              child: _NumCell(
                  value: set.rpe,
                  decimal: true,
                  hint: '–',
                  onChanged: (v) {
                    set.rpe = v;
                    onChanged();
                  })),
        ];
    }
  }

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
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      decoration: BoxDecoration(
        color: set.done
            ? context.semantic.success.withValues(alpha: 0.10)
            : null,
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: InkWell(
              onTap: onCycleType,
              borderRadius: AppRadius.brSm,
              child: Container(
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badge.isEmpty
                      ? c.onSurface.withValues(alpha: 0.06)
                      : badgeColor.withValues(alpha: 0.14),
                  borderRadius: AppRadius.brSm,
                ),
                child: Text(badge.isEmpty ? '${index + 1}' : badge,
                    style: context.texts.labelLarge?.copyWith(
                        color: badge.isEmpty ? c.onSurface : badgeColor,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(previous ?? '—',
                textAlign: TextAlign.center,
                style: context.texts.bodySmall?.copyWith(
                    color: c.onSurfaceVariant.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ),
          ..._inputCols(),
          SizedBox(
            width: 42,
            child: Center(
              child: Material(
                color: set.done
                    ? context.semantic.success
                    : c.onSurface.withValues(alpha: 0.06),
                borderRadius: AppRadius.brSm,
                child: InkWell(
                  onTap: onToggle,
                  borderRadius: AppRadius.brSm,
                  child: SizedBox(
                    width: 38,
                    height: 34,
                    child: Icon(Icons.check_rounded,
                        size: 18,
                        color: set.done
                            ? context.semantic.onSuccess
                            : c.onSurfaceVariant.withValues(alpha: 0.6)),
                  ),
                ),
              ),
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

/// Süre giriş hücresi — dk:sn formatı ("12:30"). Kullanıcı ":" ile saniye
/// girer; sadece sayı yazarsa dakika kabul edilir (bkz. [parseDuration]).
class _TimeCell extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  const _TimeCell({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TextFormField(
        initialValue: value == null ? null : mmss(value!),
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9:.,]')),
        ],
        decoration: const InputDecoration(
          hintText: '0:00',
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
        onChanged: (v) => onChanged(parseDuration(v)),
      ),
    );
  }
}
