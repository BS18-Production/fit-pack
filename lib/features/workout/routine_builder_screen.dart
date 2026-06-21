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
import 'routine_providers.dart';

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
  _BuilderItem(this.exercise,
      {this.sets = 3, this.repsMin = 8, this.repsMax = 12});
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
            )));
      _loading = false;
    });
  }

  Future<void> _addExercise() async {
    final ex = await context.push<Exercise>('/exercises/select');
    if (ex == null) return;
    if (_items.any((i) => i.exercise.id == ex.id)) return; // tekrar ekleme
    setState(() => _items.add(_BuilderItem(ex)));
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
    final companion = RoutinesCompanion(
      name: Value(name),
      scheduledWeekday: Value(_weekday),
    );

    int routineId;
    if (_isEdit) {
      routineId = widget.routineId!;
      final existing = await dao.getRoutine(routineId);
      await dao.updateRoutine(companion.copyWith(
        id: Value(routineId),
        createdAt: Value(existing!.createdAt),
        orderIndex: Value(existing.orderIndex),
        isArchived: Value(existing.isArchived),
      ));
      await dao.clearRoutineExercises(routineId);
    } else {
      routineId = await dao.createRoutine(companion);
    }

    for (var i = 0; i < _items.length; i++) {
      final it = _items[i];
      await dao.addRoutineExercise(RoutineExercisesCompanion(
        routineId: Value(routineId),
        exerciseId: Value(it.exercise.id),
        orderIndex: Value(i),
        targetSets: Value(it.sets),
        targetRepsMin: Value(it.repsMin),
        targetRepsMax: Value(it.repsMax),
      ));
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
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Kaydet'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: AppSpacing.screen,
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(40)
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Rutin adı (örn. Push Day)',
                        ),
                      ),
                      AppSpacing.vGapMd,
                      _WeekdayPicker(
                        value: _weekday,
                        onChanged: (v) => setState(() => _weekday = v),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _items.isEmpty
                      ? EmptyState(
                          icon: Icons.add_task_rounded,
                          title: 'Hareket ekle',
                          message:
                              'Kütüphaneden hareket seçerek rutini doldur',
                          actionLabel: 'Hareket Ekle',
                          onAction: _addExercise,
                          compact: true,
                        )
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg),
                          itemCount: _items.length,
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
      floatingActionButton: _items.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _addExercise,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Hareket Ekle'),
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
                    color: context.colors.onSurfaceVariant,
                    size: AppIconSize.sm),
                AppSpacing.hGapSm,
                Expanded(
                  child: Text(item.exercise.name,
                      style: context.texts.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
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
