import 'dart:convert';
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
import 'workout_ui.dart';
import '../../core/router/app_routes.dart';

/// Antrenman V2 — Hareket Kütüphanesi (Claude Design reskin).
/// Hareket/ekipman/kas adları İngilizce (salon standardı), arayüz Türkçe.
/// Kategoriye göre gruplu liste, arama + kategori/kas filtreleri, özel hareket.

final libraryExercisesProvider = FutureProvider<List<Exercise>>((ref) {
  return ref.watch(workoutDaoProvider).getLibraryExercises();
});

/// Filtre + gruplama için kategori sırası.
const _categoryOrder = [
  'compound',
  'isolation',
  'calisthenics',
  'cardio',
  'flexibility',
];

const _muscleKeys = [
  'chest',
  'back',
  'shoulders',
  'biceps',
  'triceps',
  'legs',
  'glutes',
  'core',
  'calves',
  'full_body',
];

const kMeasurementTr = {
  'weight_reps': 'kg × tekrar',
  'reps': 'tekrar',
  'time': 'süre',
  'distance': 'mesafe',
};

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  /// Çoklu seçim modu (rutin oluşturucu / aktif seanstan açılınca).
  final bool selectionMode;
  const ExerciseLibraryScreen({super.key, this.selectionMode = false});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState
    extends ConsumerState<ExerciseLibraryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _category;
  String? _muscle;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Exercise> _filter(List<Exercise> all) {
    final q = _query.trim();
    return all.where((e) {
      if (_category != null && e.category != _category) return false;
      if (_muscle != null && e.primaryMuscle != _muscle) return false;
      if (q.isNotEmpty) {
        // İngilizce ad + İngilizce/Türkçe kas + ekipman + kategori üzerinde
        // ara — kullanıcı "bacak", "arka kol", "makine" ile de bulabilsin.
        final haystack = WorkoutUi.searchHaystack(
          name: e.name,
          category: e.category,
          primaryMuscle: e.primaryMuscle,
          equipment: e.equipment,
          muscles: _parseMuscles(e.muscleGroups),
        );
        if (!WorkoutUi.matchesQuery(haystack, q)) return false;
      }
      return true;
    }).toList();
  }

  List<String> _parseMuscles(String json) {
    try {
      final list = jsonDecode(json);
      if (list is List) return list.cast<String>();
    } catch (_) {}
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(libraryExercisesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectionMode ? 'Hareket Seç' : 'Hareket Kütüphanesi'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Hareket ara…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        }),
              ),
            ),
          ),
          _FilterRow(
            keys: _categoryOrder,
            selected: _category,
            colored: true,
            labelFn: WorkoutUi.categoryLabel,
            onChanged: (c) => setState(() => _category = c),
          ),
          _FilterRow(
            keys: _muscleKeys,
            selected: _muscle,
            small: true,
            labelFn: WorkoutUi.muscleLabel,
            onChanged: (m) => setState(() => _muscle = m),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => ErrorState(
                message: 'Hareketler yüklenemedi',
                onRetry: () => ref.invalidate(libraryExercisesProvider),
              ),
              data: (all) {
                final list = _filter(all);
                return Column(
                  children: [
                    _CountRow(count: list.length, onNew: _addCustom),
                    Expanded(
                      child: list.isEmpty
                          ? EmptyState(
                              icon: Icons.search_off_rounded,
                              title: _query.isEmpty
                                  ? 'Hareket bulunamadı'
                                  : '"$_query" bulunamadı',
                              message: 'Filtreyi değiştir ya da yeni hareket ekle',
                              actionLabel: 'Yeni Hareket',
                              onAction: _addCustom,
                              compact: true,
                            )
                          : _GroupedList(
                              exercises: list,
                              onTap: (e) => widget.selectionMode
                                  ? Navigator.pop(context, e)
                                  : context.push(AppRoutes.exerciseDetail(e.id)),
                              selectionMode: widget.selectionMode,
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addCustom() async {
    final result = await showDialog<ExercisesCompanion>(
      context: context,
      builder: (_) => const _CustomExerciseDialog(),
    );
    if (result == null) return;
    await ref.read(workoutDaoProvider).insertCustomExercise(result);
    ref.invalidate(libraryExercisesProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hareket eklendi')),
      );
    }
  }
}

// ───────────────────────────────────────────── Sayı + Yeni Hareket satırı

class _CountRow extends StatelessWidget {
  final int count;
  final VoidCallback onNew;
  const _CountRow({required this.count, required this.onNew});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colors.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$count hareket',
              style: context.texts.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              )),
          TextButton.icon(
            onPressed: onNew,
            icon: const Icon(Icons.add_rounded, size: AppIconSize.sm),
            label: const Text('Yeni Hareket'),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────── Filtre çipleri (outline)

class _FilterRow extends StatelessWidget {
  final List<String> keys;
  final String? selected;
  final bool small;
  final bool colored;
  final String Function(String) labelFn;
  final ValueChanged<String?> onChanged;
  const _FilterRow({
    required this.keys,
    required this.selected,
    required this.labelFn,
    required this.onChanged,
    this.small = false,
    this.colored = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: small ? 42 : 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: keys.map((k) {
          final isSel = selected == k;
          final accent =
              colored ? WorkoutUi.categoryColor(context, k) : context.colors.primary;
          return Padding(
            padding: const EdgeInsets.only(right: 7),
            child: _OutlineChip(
              label: labelFn(k),
              selected: isSel,
              accent: accent,
              onTap: () => onChanged(isSel ? null : k),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OutlineChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _OutlineChip(
      {required this.label,
      required this.selected,
      required this.accent,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: AppRadius.brPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brPill,
            border: Border.all(
              color: selected ? accent : context.colors.outlineVariant,
              width: 1,
            ),
          ),
          child: Text(label,
              style: context.texts.labelMedium?.copyWith(
                color: selected ? accent : context.colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              )),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────── Gruplu liste

class _GroupedList extends StatelessWidget {
  final List<Exercise> exercises;
  final void Function(Exercise) onTap;
  final bool selectionMode;
  const _GroupedList({
    required this.exercises,
    required this.onTap,
    required this.selectionMode,
  });

  @override
  Widget build(BuildContext context) {
    // Kategoriye göre grupla, sabit sırada.
    final groups = <String, List<Exercise>>{};
    for (final e in exercises) {
      groups.putIfAbsent(e.category, () => []).add(e);
    }
    final orderedCats = _categoryOrder.where(groups.containsKey).toList()
      ..addAll(groups.keys.where((c) => !_categoryOrder.contains(c)));

    final children = <Widget>[];
    for (final cat in orderedCats) {
      final items = groups[cat]!;
      children.add(_CategoryHeader(category: cat, count: items.length));
      for (final e in items) {
        children.add(_ExerciseRow(
          exercise: e,
          selectionMode: selectionMode,
          onTap: () => onTap(e),
        ));
      }
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxxl),
      children: children,
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String category;
  final int count;
  const _CategoryHeader({required this.category, required this.count});

  @override
  Widget build(BuildContext context) {
    final color = WorkoutUi.categoryColor(context, category);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, AppSpacing.lg, 2, AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2)),
          ),
          AppSpacing.hGapSm,
          Text(WorkoutUi.categoryLabel(category),
              style: context.texts.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              )),
          AppSpacing.hGapSm,
          Text('$count',
              style: context.texts.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final Exercise exercise;
  final bool selectionMode;
  final VoidCallback onTap;
  const _ExerciseRow({
    required this.exercise,
    required this.selectionMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final catColor = WorkoutUi.categoryColor(context, exercise.category);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sub = WorkoutUi.muscleEquip(exercise.primaryMuscle, exercise.equipment);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: c.outlineVariant, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: c.onSurface.withValues(alpha: dark ? 0.06 : 0.05),
                borderRadius: AppRadius.brMd,
              ),
              child: Icon(WorkoutUi.equipmentIcon(exercise.equipment),
                  color: c.onSurfaceVariant, size: 20),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(exercise.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.texts.titleSmall),
                      ),
                      AppSpacing.hGapSm,
                      _CatTag(label: WorkoutUi.categoryLabel(exercise.category),
                          color: catColor),
                      if (exercise.isCustom) ...[
                        AppSpacing.hGapXs,
                        Icon(Icons.person_rounded,
                            size: 14, color: c.secondary),
                      ],
                    ],
                  ),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(sub,
                        style: context.texts.bodySmall
                            ?.copyWith(color: c.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
            AppSpacing.hGapSm,
            if (selectionMode)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius: AppRadius.brMd,
                ),
                child: Icon(Icons.add_rounded, color: c.onPrimary, size: 18),
              )
            else
              Icon(Icons.chevron_right_rounded, color: c.outline),
          ],
        ),
      ),
    );
  }
}

class _CatTag extends StatelessWidget {
  final String label;
  final Color color;
  const _CatTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: AppRadius.brSm,
      ),
      child: Text(label,
          style: context.texts.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 9.5,
            letterSpacing: 0.2,
          )),
    );
  }
}

// ───────────────────────────────────────────── Özel hareket dialog

const _categoryItemsEn = {
  'compound': 'Compound',
  'isolation': 'Isolation',
  'calisthenics': 'Calisthenics',
  'cardio': 'Cardio',
  'flexibility': 'Flexibility',
};

const _muscleItemsEn = {
  'chest': 'Chest',
  'back': 'Back',
  'shoulders': 'Shoulders',
  'biceps': 'Biceps',
  'triceps': 'Triceps',
  'legs': 'Legs',
  'glutes': 'Glutes',
  'core': 'Core',
  'calves': 'Calves',
  'full_body': 'Full Body',
};

const _equipmentItemsEn = {
  'barbell': 'Barbell',
  'dumbbell': 'Dumbbell',
  'machine': 'Machine',
  'cable': 'Cable',
  'smith': 'Smith Machine',
  'kettlebell': 'Kettlebell',
  'bodyweight': 'Bodyweight',
  'cardio': 'Cardio Machine',
  'none': 'None',
};

class _CustomExerciseDialog extends StatefulWidget {
  const _CustomExerciseDialog();

  @override
  State<_CustomExerciseDialog> createState() => _CustomExerciseDialogState();
}

class _CustomExerciseDialogState extends State<_CustomExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _category = 'compound';
  String _muscle = 'chest';
  String _equipment = 'barbell';
  String _measurement = 'weight_reps';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ExercisesCompanion(
        name: Value(_name.text.trim()),
        category: Value(_category),
        primaryMuscle: Value(_muscle),
        equipment: Value(_equipment),
        measurementType: Value(_measurement),
        muscleGroups: Value(jsonEncode([_muscle])),
        isCustom: const Value(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Hareket'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                inputFormatters: [LengthLimitingTextInputFormatter(50)],
                decoration: const InputDecoration(
                    labelText: 'Hareket adı (örn. Cable Row)'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ad gir' : null,
              ),
              AppSpacing.vGapMd,
              _Dropdown(
                label: 'Kategori',
                value: _category,
                items: _categoryItemsEn,
                onChanged: (v) => setState(() => _category = v),
              ),
              AppSpacing.vGapMd,
              _Dropdown(
                label: 'Ana kas',
                value: _muscle,
                items: _muscleItemsEn,
                onChanged: (v) => setState(() => _muscle = v),
              ),
              AppSpacing.vGapMd,
              _Dropdown(
                label: 'Ekipman',
                value: _equipment,
                items: _equipmentItemsEn,
                onChanged: (v) => setState(() => _equipment = v),
              ),
              AppSpacing.vGapMd,
              _Dropdown(
                label: 'Ölçüm tipi',
                value: _measurement,
                items: kMeasurementTr,
                onChanged: (v) => setState(() => _measurement = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç')),
        FilledButton(onPressed: _save, child: const Text('Ekle')),
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;
  const _Dropdown(
      {required this.label,
      required this.value,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (v) => v == null ? null : onChanged(v),
    );
  }
}
