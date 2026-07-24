import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';
import '../../data/database/app_database.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/progress_indicators.dart';
import 'barcode_flow.dart';
import 'nutrition_screen.dart' show unitOptionsWith;

/// Besin veritabanı (P-1 + P-2, docs/07-nutrition-v2.md).
/// "Yemekler frontend'de değil" → buradan görünür/yönetilir: lokal SQLite
/// `foods` tablosu. Değerleri gör, custom yemekleri düzenle/sil.
/// **Reaktif** (H-05): yemek eklenince/düzenlenince/silinince tazelenir.
final allFoodsProvider = StreamProvider<List<Food>>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(
      db, [db.foods], () => ref.read(nutritionDaoProvider).getAllFoods());
});

class FoodsScreen extends ConsumerStatefulWidget {
  const FoodsScreen({super.key});

  @override
  ConsumerState<FoodsScreen> createState() => _FoodsScreenState();
}

class _FoodsScreenState extends ConsumerState<FoodsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Food> _filtered(List<Food> all) {
    final q = _query.trim().toLowerCase();
    final list = q.isEmpty
        ? [...all]
        : all.where((f) => f.name.toLowerCase().contains(q)).toList();
    list.sort((a, b) {
      if (a.isCustom != b.isCustom) return a.isCustom ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  Future<void> _scan() async {
    final food = await scanBarcodeToFood(context, ref);
    if (food == null || !mounted) return;
    // allFoodsProvider reaktif (H-05) → tarama sonrası liste kendiliğinden güncel.
    _searchController.text = food.name;
    setState(() => _query = food.name);
  }

  Future<void> _create() async {
    final form = await showDialog<_FoodForm>(
      context: context,
      builder: (_) => const _FoodFormDialog(),
    );
    if (form == null) return;
    await ref.read(nutritionDaoProvider).insertFood(FoodsCompanion(
          name: Value(form.name),
          kcalPer100g: Value(form.kcal),
          proteinPer100g: Value(form.protein),
          carbPer100g: Value(form.carb),
          fatPer100g: Value(form.fat),
          source: const Value('custom'),
          isCustom: const Value(true),
          isRecipe: const Value(false),
          defaultPortionGrams: Value(form.portionG),
          unitLabel: Value(form.unitLabel),
        ));
    // allFoodsProvider reaktif (H-05) → yeni yemek kendiliğinden görünür.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppL10n.of(context).foodsAdded(form.name))));
    }
  }

  Future<void> _edit(Food food) async {
    final form = await showDialog<_FoodForm>(
      context: context,
      builder: (_) => _FoodFormDialog(initial: food),
    );
    if (form == null) return;
    await ref.read(nutritionDaoProvider).updateFood(
          food.id,
          FoodsCompanion(
            name: Value(form.name),
            kcalPer100g: Value(form.kcal),
            proteinPer100g: Value(form.protein),
            carbPer100g: Value(form.carb),
            fatPer100g: Value(form.fat),
            defaultPortionGrams: Value(form.portionG),
            unitLabel: Value(form.unitLabel),
          ),
        );
    // allFoodsProvider reaktif (H-05) → düzenleme kendiliğinden yansır.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppL10n.of(context).foodsUpdated)));
    }
  }

  Future<void> _delete(Food food) async {
    final l = AppL10n.of(context);
    final dao = ref.read(nutritionDaoProvider);
    final logCount = await dao.foodLogCount(food.id);
    if (!mounted) return;
    if (logCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.foodsHasLogs(food.name, logCount)),
      ));
      return;
    }
    final ok = await confirmAction(
      context,
      title: l.foodsDeleteTitle,
      message: l.foodsDeleteMessage(food.name),
    );
    if (!ok) return;
    await dao.deleteFood(food.id);
    // allFoodsProvider reaktif (H-05) → silme kendiliğinden yansır.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.foodsDeleted(food.name))));
    }
  }

  void _showReadOnly(Food food) {
    final l = AppL10n.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(food.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv(context, l.foodsPer100g, ''),
            _kv(context, l.macroCalories,
                '${food.kcalPer100g.round()} kcal'),
            _kv(context, l.macroProtein,
                '${food.proteinPer100g.round()} g'),
            _kv(context, l.macroCarbs, '${food.carbPer100g.round()} g'),
            _kv(context, l.macroFat, '${food.fatPer100g.round()} g'),
            if (food.unitLabel != null &&
                (food.defaultPortionGrams ?? 0) > 0) ...[
              const Divider(),
              _kv(
                  context,
                  l.nutritionUnit,
                  l.nutritionUnitApprox(food.unitLabel!,
                      food.defaultPortionGrams!.round())),
            ],
            AppSpacing.vGapSm,
            Text(l.foodsReadOnlyNote,
                style: context.texts.labelSmall
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.commonClose)),
        ],
      ),
    );
  }

  static Widget _kv(BuildContext context, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k,
                style: context.texts.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant)),
            Text(v, style: context.texts.bodyMedium),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final foodsAsync = ref.watch(allFoodsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.settingsFoods),
        actions: [
          IconButton(
            tooltip: l.nutritionScanBarcode,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: _scan,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: Text(l.foodsNew),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l.nutritionSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: foodsAsync.when(
              loading: () => ListView(
                padding: AppSpacing.screen,
                children: [
                  Skeleton.card(height: 72),
                  AppSpacing.vGapMd,
                  Skeleton.card(height: 72),
                  AppSpacing.vGapMd,
                  Skeleton.card(height: 72),
                ],
              ),
              error: (_, _) => ErrorState(
                message: l.foodsLoadError,
                onRetry: () => ref.invalidate(allFoodsProvider),
              ),
              data: (all) {
                final list = _filtered(all);
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.no_food_rounded,
                    title: _query.isEmpty
                        ? l.nutritionNoFoods
                        : l.nutritionNotFound(_query),
                    message: l.foodsEmptyHint,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(
                      bottom: 88,
                      left: AppSpacing.lg,
                      right: AppSpacing.lg),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _FoodRow(
                    food: list[i],
                    onTap: () => list[i].isCustom
                        ? _edit(list[i])
                        : _showReadOnly(list[i]),
                    onDelete: list[i].isCustom
                        ? () => _delete(list[i])
                        : null,
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

class _FoodRow extends StatelessWidget {
  final Food food;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _FoodRow(
      {required this.food, required this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final hasUnit =
        food.unitLabel != null && (food.defaultPortionGrams ?? 0) > 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Row(
        children: [
          Flexible(
              child: Text(food.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (food.isCustom) ...[
            AppSpacing.hGapSm,
            Icon(Icons.person_rounded,
                size: AppIconSize.sm, color: context.colors.secondary),
          ] else if (food.source == 'openfoodfacts') ...[
            AppSpacing.hGapSm,
            Icon(Icons.qr_code_rounded,
                size: AppIconSize.sm, color: context.colors.tertiary),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MacroInlineText(
            protein: food.proteinPer100g,
            carb: food.carbPer100g,
            fat: food.fatPer100g,
            prefix: '${food.kcalPer100g.round()} kcal · ',
            suffix: ' /100g',
          ),
          if (hasUnit)
            Text(
              AppL10n.of(context).nutritionUnitApprox(
                  food.unitLabel!, food.defaultPortionGrams!.round()),
              style: context.texts.labelSmall
                  ?.copyWith(color: context.colors.secondary),
            ),
        ],
      ),
      trailing: onDelete == null
          ? Icon(Icons.chevron_right_rounded,
              color: context.colors.onSurfaceVariant)
          : IconButton(
              tooltip: AppL10n.of(context).commonDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: context.colors.onSurfaceVariant,
              onPressed: onDelete,
            ),
    );
  }
}

/// Custom yemek oluştur/düzenle. Değerler **doğrudan /100g** girilir
/// (kullanıcı "değerleri takip edeyim" dedi — gizli dönüşüm yok).
class _FoodForm {
  final String name;
  final double kcal, protein, carb, fat;
  final double? portionG;
  final String? unitLabel;
  _FoodForm(this.name, this.kcal, this.protein, this.carb, this.fat,
      this.portionG, this.unitLabel);
}

class _FoodFormDialog extends StatefulWidget {
  final Food? initial;
  const _FoodFormDialog({this.initial});

  @override
  State<_FoodFormDialog> createState() => _FoodFormDialogState();
}

class _FoodFormDialogState extends State<_FoodFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _kcal;
  late final TextEditingController _protein;
  late final TextEditingController _carb;
  late final TextEditingController _fat;
  late final TextEditingController _portion;
  String? _unit;

  bool _unitInitialized = false;

  @override
  void initState() {
    super.initState();
    final f = widget.initial;
    String s(num? v) => v == null ? '' : _trim(v.toDouble());
    _name = TextEditingController(text: f?.name ?? '');
    _kcal = TextEditingController(text: s(f?.kcalPer100g));
    _protein = TextEditingController(text: s(f?.proteinPer100g));
    _carb = TextEditingController(text: s(f?.carbPer100g));
    _fat = TextEditingController(text: s(f?.fatPer100g));
    _portion = TextEditingController(text: s(f?.defaultPortionGrams));
    _unit = f?.unitLabel; // yeni kayıtta varsayılan ilk build'de (locale)
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_unitInitialized) {
      _unitInitialized = true;
      if (widget.initial == null) {
        _unit = AppL10n.of(context).unitPortion;
      }
    }
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  @override
  void dispose() {
    for (final c in [_name, _kcal, _protein, _carb, _fat, _portion]) {
      c.dispose();
    }
    super.dispose();
  }

  double _n(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final portion = _unit == null ? null : _n(_portion);
    Navigator.pop(
      context,
      _FoodForm(_name.text.trim(), _n(_kcal), _n(_protein), _n(_carb),
          _n(_fat), portion, _unit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final editing = widget.initial != null;
    return AlertDialog(
      title: Text(editing ? l.foodsEditTitle : l.foodsNew),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.foodsFormHelp,
                style: context.texts.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant),
              ),
              AppSpacing.vGapMd,
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration:
                    InputDecoration(labelText: l.nutritionFoodName),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l.commonEnterName
                    : null,
              ),
              AppSpacing.vGapMd,
              _Num(_kcal, l.foodsKcalPer100, req: true),
              AppSpacing.vGapMd,
              _Num(_protein, l.foodsProteinPer100),
              AppSpacing.vGapMd,
              _Num(_carb, l.foodsCarbPer100),
              AppSpacing.vGapMd,
              _Num(_fat, l.foodsFatPer100),
              AppSpacing.vGapMd,
              DropdownButtonFormField<String?>(
                initialValue: _unit,
                decoration: InputDecoration(labelText: l.nutritionUnit),
                items: [
                  DropdownMenuItem(
                      value: null, child: Text(l.nutritionNoUnitOption)),
                  ...unitOptionsWith(l, _unit).map((u) => DropdownMenuItem(
                      value: u, child: Text(l.nutritionOneUnit(u)))),
                ],
                onChanged: (v) => setState(() => _unit = v),
              ),
              if (_unit != null) ...[
                AppSpacing.vGapMd,
                _Num(_portion, l.nutritionUnitGramsQuestion(_unit!),
                    req: true),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.commonCancel)),
        FilledButton(onPressed: _save, child: Text(l.commonSave)),
      ],
    );
  }
}

class _Num extends StatelessWidget {
  final TextEditingController c;
  final String label;
  final bool req;
  const _Num(this.c, this.label, {this.req = false});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(labelText: label),
      validator: (raw) {
        final l = AppL10n.of(context);
        final t = (raw ?? '').trim().replaceAll(',', '.');
        if (t.isEmpty) return req ? l.commonRequired : null;
        final v = double.tryParse(t);
        if (v == null) return l.commonInvalidNumber;
        if (req && v <= 0) return l.commonMustBePositive;
        if (v < 0) return l.commonNotNegative;
        return null;
      },
    );
  }
}
