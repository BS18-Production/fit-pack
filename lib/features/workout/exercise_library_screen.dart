import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/database/app_database.dart';
import '../../data/providers.dart';
import '../../shared/widgets/app_state_views.dart';

/// Antrenman V2 — Hareket Kütüphanesi (docs/09-workout-v2.md, Faz A).
/// İngilizce hareket adları, Türkçe arayüz. Kategori + kas + arama filtreleri,
/// özel hareket ekleme, hareket detay sayfası.

final libraryExercisesProvider = FutureProvider<List<Exercise>>((ref) {
  return ref.watch(workoutDaoProvider).getLibraryExercises();
});

// ───────── İngilizce iç değer → Türkçe etiket eşlemeleri ─────────

const kCategoryTr = {
  'compound': 'Bileşik',
  'isolation': 'İzolasyon',
  'calisthenics': 'Vücut Ağırlığı',
  'cardio': 'Kardiyo',
  'flexibility': 'Esneklik',
};

const kEquipmentTr = {
  'barbell': 'Halter',
  'dumbbell': 'Dambıl',
  'machine': 'Makine',
  'cable': 'Kablo',
  'smith': 'Smith',
  'bodyweight': 'Vücut Ağırlığı',
  'cardio': 'Kardiyo',
  'none': 'Ekipmansız',
};

const kMuscleTr = {
  'chest': 'Göğüs',
  'back': 'Sırt',
  'shoulders': 'Omuz',
  'biceps': 'Biceps',
  'triceps': 'Triceps',
  'legs': 'Bacak',
  'glutes': 'Kalça',
  'core': 'Karın',
  'calves': 'Baldır',
  'full_body': 'Tüm Vücut',
};

const kMeasurementTr = {
  'weight_reps': 'kg × tekrar',
  'reps': 'tekrar',
  'time': 'süre',
  'distance': 'mesafe',
};

IconData _categoryIcon(String c) => switch (c) {
      'calisthenics' => Icons.accessibility_new_rounded,
      'cardio' => Icons.directions_run_rounded,
      'flexibility' => Icons.self_improvement_rounded,
      _ => Icons.fitness_center_rounded,
    };

String _trCat(String c) => kCategoryTr[c] ?? c;
String _trMuscle(String? m) => m == null ? '' : (kMuscleTr[m] ?? m);
String _trEquip(String? e) => e == null ? '' : (kEquipmentTr[e] ?? e);

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  /// Çoklu seçim modu (rutin oluşturucudan açılınca) — Faz B kullanır.
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
  String? _category; // null = tümü
  String? _muscle; // null = tümü

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Exercise> _filter(List<Exercise> all) {
    final q = _query.trim().toLowerCase();
    return all.where((e) {
      if (_category != null && e.category != _category) return false;
      if (_muscle != null && e.primaryMuscle != _muscle) return false;
      if (q.isNotEmpty && !e.name.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(libraryExercisesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Hareket Kütüphanesi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustom,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yeni Hareket'),
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
                hintText: 'Hareket ara',
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
          _CategoryChips(
            selected: _category,
            onChanged: (c) => setState(() => _category = c),
          ),
          _MuscleChips(
            selected: _muscle,
            onChanged: (m) => setState(() => _muscle = m),
          ),
          AppSpacing.vGapSm,
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => ErrorState(
                message: 'Hareketler yüklenemedi',
                onRetry: () => ref.invalidate(libraryExercisesProvider),
              ),
              data: (all) {
                final list = _filter(all);
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off_rounded,
                    title: _query.isEmpty
                        ? 'Hareket bulunamadı'
                        : '"$_query" bulunamadı',
                    message: 'Filtreyi değiştir ya da yeni hareket ekle',
                    actionLabel: 'Yeni Hareket',
                    onAction: _addCustom,
                    compact: true,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, 96),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => AppSpacing.vGapSm,
                  itemBuilder: (_, i) => _ExerciseTile(
                    exercise: list[i],
                    onTap: () => _openDetail(list[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(Exercise e) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ExerciseDetailSheet(
        exercise: e,
        onArchived: () {
          ref.invalidate(libraryExercisesProvider);
        },
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

// ───────────────────────────────────────────── Filtre çipleri

class _CategoryChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;
  const _CategoryChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final entries = kCategoryTr.entries.toList();
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          _Chip(
            label: 'Tümü',
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          ...entries.map((e) => _Chip(
                label: e.value,
                selected: selected == e.key,
                onTap: () => onChanged(selected == e.key ? null : e.key),
              )),
        ],
      ),
    );
  }
}

class _MuscleChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;
  const _MuscleChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: kMuscleTr.entries
            .map((e) => _Chip(
                  label: e.value,
                  small: true,
                  selected: selected == e.key,
                  onTap: () => onChanged(selected == e.key ? null : e.key),
                ))
            .toList(),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool small;
  final VoidCallback onTap;
  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap,
      this.small = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: selected ? c.primary : c.surfaceContainerHigh,
        borderRadius: AppRadius.brPill,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brPill,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: small ? AppSpacing.md : AppSpacing.lg,
                vertical: AppSpacing.sm),
            child: Text(label,
                style: (small ? context.texts.labelMedium : context.texts.labelLarge)
                    ?.copyWith(
                  color: selected ? c.onPrimary : c.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────── Liste satırı

class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;
  const _ExerciseTile({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sub = [
      _trMuscle(exercise.primaryMuscle),
      _trEquip(exercise.equipment),
    ].where((s) => s.isNotEmpty).join(' · ');

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: AppSpacing.cardCompact,
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.brMd,
                ),
                child: Icon(_categoryIcon(exercise.category),
                    color: c.primary, size: AppIconSize.sm + 2),
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
                              style: context.texts.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (exercise.isCustom) ...[
                          AppSpacing.hGapSm,
                          Icon(Icons.person_rounded,
                              size: AppIconSize.sm, color: c.secondary),
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
              Icon(Icons.chevron_right_rounded, color: c.outline),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────── Detay sheet

class _ExerciseDetailSheet extends ConsumerWidget {
  final Exercise exercise;
  final VoidCallback onArchived;
  const _ExerciseDetailSheet(
      {required this.exercise, required this.onArchived});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muscles = (() {
      try {
        return (jsonDecode(exercise.muscleGroups) as List)
            .map((m) => _trMuscle(m as String))
            .where((s) => s.isNotEmpty)
            .join(', ');
      } catch (_) {
        return '';
      }
    })();

    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(title: exercise.name),
          AppSpacing.vGapMd,
          _DetailRow('Kategori', _trCat(exercise.category)),
          _DetailRow('Ana kas', _trMuscle(exercise.primaryMuscle)),
          if (muscles.isNotEmpty) _DetailRow('Çalışan kaslar', muscles),
          _DetailRow('Ekipman', _trEquip(exercise.equipment)),
          _DetailRow('Ölçüm', kMeasurementTr[exercise.measurementType] ?? '—'),
          AppSpacing.vGapLg,
          Text('Geçmiş, ilerleme grafiği ve rekorlar yakında (Antrenman V2 Faz D).',
              style: context.texts.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant)),
          if (exercise.isCustom) ...[
            AppSpacing.vGapLg,
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final ok = await confirmAction(
                    context,
                    title: 'Hareketi arşivle',
                    message:
                        '${exercise.name} kütüphaneden kaldırılsın mı? Geçmiş kayıtlar korunur.',
                    confirmLabel: 'Arşivle',
                  );
                  if (!ok) return;
                  await ref.read(workoutDaoProvider).archiveExercise(exercise.id);
                  onArchived();
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Arşivle'),
              ),
            ),
          ],
          AppSpacing.vGapMd,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: context.texts.bodyMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
          ),
          Expanded(child: Text(value, style: context.texts.bodyMedium)),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────── Özel hareket dialog

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
                items: kCategoryTr,
                onChanged: (v) => setState(() => _category = v),
              ),
              AppSpacing.vGapMd,
              _Dropdown(
                label: 'Ana kas',
                value: _muscle,
                items: kMuscleTr,
                onChanged: (v) => setState(() => _muscle = v),
              ),
              AppSpacing.vGapMd,
              _Dropdown(
                label: 'Ekipman',
                value: _equipment,
                items: kEquipmentTr,
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
