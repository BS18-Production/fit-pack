import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/database/app_database.dart';
import '../../data/providers.dart';
import 'routine_providers.dart';
import 'workout_ui.dart';

/// Rutin Oluşturucu (Antrenman V2 Faz B — docs/09-workout-v2.md).
/// Ad + opsiyonel haftalık gün + hareketler (kütüphaneden) + hedef set×tekrar
/// + sürükle sırala. routineId verilirse düzenleme modu.
class RoutineBuilderScreen extends ConsumerStatefulWidget {
  final int? routineId;
  const RoutineBuilderScreen({super.key, this.routineId});

  @override
  ConsumerState<RoutineBuilderScreen> createState() =>
      _RoutineBuilderScreenState();
}

class _BuilderItem {
  final Exercise exercise;
  int sets;
  int repsMin;
  int repsMax;
  int restSec; // setler arası dinlenme (saniye) — kullanıcı belirler
  _BuilderItem(this.exercise,
      {this.sets = 3,
      this.repsMin = 8,
      this.repsMax = 12,
      required this.restSec});
}

class _RoutineBuilderScreenState extends ConsumerState<RoutineBuilderScreen> {
  final _nameCtrl = TextEditingController();
  int? _weekday;
  final List<_BuilderItem> _items = [];
  bool _loading = false;
  bool _saving = false;

  bool get _isEdit => widget.routineId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final dao = ref.read(workoutDaoProvider);
    final routine = await dao.getRoutine(widget.routineId!);
    final exs = await dao.getRoutineExercises(widget.routineId!);
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = routine?.name ?? '';
      _weekday = routine?.scheduledWeekday;
      _items
        ..clear()
        ..addAll(exs.map((e) => _BuilderItem(
              e.exercise,
              sets: e.routineExercise.targetSets ?? 3,
              repsMin: e.routineExercise.targetRepsMin ?? 8,
              repsMax: e.routineExercise.targetRepsMax ?? 12,
              restSec: e.routineExercise.targetRestSec ??
                  WorkoutUi.defaultRestSec(e.exercise.category),
            )));
      _loading = false;
    });
  }

  Future<void> _addExercise() async {
    final ex = await context.push<Exercise>('/exercises/select');
    if (ex == null) return;
    if (_items.any((i) => i.exercise.id == ex.id)) return; // tekrar ekleme
    setState(() => _items.add(_BuilderItem(
          ex,
          restSec: WorkoutUi.defaultRestSec(ex.category),
        )));
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rutine bir ad ver')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('En az bir hareket ekle')));
      return;
    }
    setState(() => _saving = true);
    final dao = ref.read(workoutDaoProvider);
    var companion = RoutinesCompanion(
      name: Value(name),
      scheduledWeekday: Value(_weekday),
    );

    final int routineId;
    try {
      if (_isEdit) {
        final existing = await dao.getRoutine(widget.routineId!);
        companion = companion.copyWith(
          id: Value(widget.routineId!),
          createdAt: Value(existing!.createdAt),
          orderIndex: Value(existing.orderIndex),
          isArchived: Value(existing.isArchived),
        );
      }
      // Rutin + hareketler tek transaction'da: düzenlemede "sil + yeniden
      // yaz" adımları atomik — ortada hata olsa mevcut liste kaybolmaz.
      routineId = await dao.saveRoutineWithExercises(
        routine: companion,
        isNew: !_isEdit,
        buildExercises: (id) => [
          for (var i = 0; i < _items.length; i++)
            RoutineExercisesCompanion(
              routineId: Value(id),
              exerciseId: Value(_items[i].exercise.id),
              orderIndex: Value(i),
              targetSets: Value(_items[i].sets),
              targetRepsMin: Value(_items[i].repsMin),
              targetRepsMax: Value(_items[i].repsMax),
              targetRestSec: Value(_items[i].restSec),
            ),
        ],
      );
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Rutin kaydedilemedi — tekrar dene')));
      }
      return;
    }

    ref.invalidate(activeRoutinesProvider);
    ref.invalidate(routineExercisesProvider(routineId));
    ref.invalidate(todayRoutineProvider);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Rutini Düzenle' : 'Yeni Rutin'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RUTİN ADI',
                          style: context.texts.labelSmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          )),
                      AppSpacing.vGapSm,
                      TextField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(40)
                        ],
                        decoration: const InputDecoration(
                          hintText: 'örn. Push Day',
                        ),
                      ),
                      AppSpacing.vGapMd,
                      _WeekdayPicker(
                        value: _weekday,
                        onChanged: (v) => setState(() => _weekday = v),
                      ),
                      AppSpacing.vGapLg,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_items.length} hareket',
                              style: context.texts.titleSmall),
                          Text('hedef set×tekrar',
                              style: context.texts.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant
                                      .withValues(alpha: 0.7))),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _items.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0,
                              AppSpacing.lg, AppSpacing.lg),
                          children: [
                            DottedBorderBox(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.xxl),
                                child: Center(
                                  child: Text('Henüz hareket yok',
                                      style: context.texts.bodyMedium?.copyWith(
                                          color: context
                                              .colors.onSurfaceVariant
                                              .withValues(alpha: 0.7))),
                                ),
                              ),
                            ),
                            AppSpacing.vGapMd,
                            _AddExerciseButton(onTap: _addExercise),
                          ],
                        )
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                          itemCount: _items.length,
                          footer: Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: _AddExerciseButton(onTap: _addExercise),
                          ),
                          onReorder: (oldI, newI) {
                            setState(() {
                              if (newI > oldI) newI--;
                              final it = _items.removeAt(oldI);
                              _items.insert(newI, it);
                            });
                          },
                          itemBuilder: (_, i) => _ItemCard(
                            key: ValueKey(_items[i].exercise.id),
                            item: _items[i],
                            onChanged: () => setState(() {}),
                            onRemove: () =>
                                setState(() => _items.removeAt(i)),
                          ),
                        ),
                ),
              ],
            ),
      bottomNavigationBar: _loading
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
              child: GradientButton(
                label: 'Rutini Kaydet',
                busy: _saving,
                onTap: _save,
              ),
            ),
    );
  }
}

class _AddExerciseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddExerciseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.brLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brLg,
        child: DottedBorderBox(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded,
                    color: context.colors.primary, size: AppIconSize.sm),
                AppSpacing.hGapSm,
                Text('Hareket Ekle',
                    style: context.texts.labelLarge?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekdayPicker extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  const _WeekdayPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Haftalık gün (opsiyonel)',
        helperText: 'Atarsan ana sayfa o gün bu rutini önerir',
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Gün atama')),
        ...kWeekdayTr.entries.map(
            (e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
      ],
      onChanged: onChanged,
    );
  }
}

class _ItemCard extends StatelessWidget {
  final _BuilderItem item;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  const _ItemCard(
      {super.key,
      required this.item,
      required this.onChanged,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: AppSpacing.cardCompact,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.drag_handle_rounded,
                    color: context.colors.onSurfaceVariant
                        .withValues(alpha: 0.6),
                    size: AppIconSize.sm),
                AppSpacing.hGapSm,
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.colors.onSurface.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.06
                            : 0.05),
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Icon(WorkoutUi.equipmentIcon(item.exercise.equipment),
                      color: context.colors.onSurfaceVariant, size: 18),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.exercise.name,
                          style: context.texts.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(
                          WorkoutUi.muscleLabel(item.exercise.primaryMuscle),
                          style: context.texts.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  visualDensity: VisualDensity.compact,
                  color: context.colors.onSurfaceVariant,
                  onPressed: onRemove,
                ),
              ],
            ),
            Row(
              children: [
                _Stepper(
                  label: 'Set',
                  value: item.sets,
                  min: 1,
                  max: 10,
                  onChanged: (v) {
                    item.sets = v;
                    onChanged();
                  },
                ),
                AppSpacing.hGapLg,
                Expanded(
                  child: _RepRange(
                    min: item.repsMin,
                    max: item.repsMax,
                    onChanged: (lo, hi) {
                      item.repsMin = lo;
                      item.repsMax = hi;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            AppSpacing.vGapSm,
            _RestRow(
              restSec: item.restSec,
              onPick: (v) {
                item.restSec = v;
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Hareketin setler arası dinlenme süresi — dokununca süre seçici açılır.
class _RestRow extends StatelessWidget {
  final int restSec;
  final ValueChanged<int> onPick;
  const _RestRow({required this.restSec, required this.onPick});

  Future<void> _pick(BuildContext context) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
              child: Text('Setler arası dinlenme',
                  style: ctx.texts.titleMedium),
            ),
            ...WorkoutUi.restOptions.map((sec) {
              final selected = sec == restSec;
              return ListTile(
                title: Text(WorkoutUi.restLabel(sec)),
                trailing: selected
                    ? Icon(Icons.check_rounded, color: ctx.colors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, sec),
              );
            }),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (picked != null) onPick(picked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: AppRadius.brSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(Icons.timer_outlined,
                size: AppIconSize.sm, color: context.colors.onSurfaceVariant),
            AppSpacing.hGapSm,
            Text('Dinlenme',
                style: context.texts.labelLarge?.copyWith(
                    color: context.colors.onSurfaceVariant)),
            const Spacer(),
            Text(WorkoutUi.restLabel(restSec),
                style: context.texts.labelLarge?.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w700)),
            Icon(Icons.expand_more_rounded,
                size: AppIconSize.sm, color: context.colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final int value, min, max;
  final ValueChanged<int> onChanged;
  const _Stepper(
      {required this.label,
      required this.value,
      required this.min,
      required this.max,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline_rounded),
          visualDensity: VisualDensity.compact,
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        Text('$value $label',
            style: context.texts.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded),
          visualDensity: VisualDensity.compact,
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _RepRange extends StatelessWidget {
  final int min, max;
  final void Function(int lo, int hi) onChanged;
  const _RepRange(
      {required this.min, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Tekrar',
            style: context.texts.labelMedium
                ?.copyWith(color: context.colors.onSurfaceVariant)),
        AppSpacing.hGapSm,
        _MiniField(
          value: min,
          onChanged: (v) => onChanged(v, max < v ? v : max),
        ),
        Text(' – ', style: context.texts.bodyMedium),
        _MiniField(
          value: max,
          onChanged: (v) => onChanged(min > v ? v : min, v),
        ),
      ],
    );
  }
}

class _MiniField extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _MiniField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: TextFormField(
        initialValue: '$value',
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        decoration: const InputDecoration(
            isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
        onChanged: (v) {
          final n = int.tryParse(v);
          if (n != null && n > 0) onChanged(n);
        },
      ),
    );
  }
}
