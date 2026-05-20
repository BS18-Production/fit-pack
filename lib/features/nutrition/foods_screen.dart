import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/providers.dart';
import '../../data/database/app_database.dart';
import '../../shared/widgets/app_state_views.dart';
import 'barcode_flow.dart';
import 'nutrition_screen.dart' show kUnitOptions;

/// Besin veritabanı (P-1 + P-2, docs/07-nutrition-v2.md).
/// "Yemekler frontend'de değil" → buradan görünür/yönetilir: lokal SQLite
/// `foods` tablosu. Değerleri gör, custom yemekleri düzenle/sil.
final allFoodsProvider = FutureProvider<List<Food>>(
    (ref) => ref.watch(nutritionDaoProvider).getAllFoods());

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
    ref.invalidate(allFoodsProvider);
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
    ref.invalidate(allFoodsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${form.name} eklendi')));
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
    ref.invalidate(allFoodsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Güncellendi')));
    }
  }

  Future<void> _delete(Food food) async {
    final dao = ref.read(nutritionDaoProvider);
    final logCount = await dao.foodLogCount(food.id);
    if (!mounted) return;
    if (logCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '"${food.name}" için $logCount kayıt var — önce o kayıtları sil'),
      ));
      return;
    }
    final ok = await confirmAction(
      context,
      title: 'Yemeği sil',
      message: '"${food.name}" besin veritabanından silinsin mi?',
    );
    if (!ok) return;
    await dao.deleteFood(food.id);
    ref.invalidate(allFoodsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${food.name} silindi')));
    }
  }

  void _showReadOnly(Food food) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(food.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv(context, '100 g\'da', ''),
            _kv(context, 'Kalori', '${food.kcalPer100g.round()} kcal'),
            _kv(context, 'Protein', '${food.proteinPer100g.round()} g'),
            _kv(context, 'Karbonhidrat', '${food.carbPer100g.round()} g'),
            _kv(context, 'Yağ', '${food.fatPer100g.round()} g'),
            if (food.unitLabel != null &&
                (food.defaultPortionGrams ?? 0) > 0) ...[
              const Divider(),
              _kv(context, 'Birim',
                  '1 ${food.unitLabel} ≈ ${food.defaultPortionGrams!.round()} g'),
            ],
            AppSpacing.vGapSm,
            Text('Hazır yemek — düzenlenemez (veritabanı korunur).',
                style: context.texts.labelSmall
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat')),
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
    final foodsAsync = ref.watch(allFoodsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yemekler'),
        actions: [
          IconButton(
            tooltip: 'Barkod tara',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: _scan,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yeni yemek'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Yemek ara…',
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
                message: 'Yemekler yüklenemedi',
                onRetry: () => ref.invalidate(allFoodsProvider),
              ),
              data: (all) {
                final list = _filtered(all);
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.no_food_rounded,
                    title: _query.isEmpty
                        ? 'Yemek yok'
                        : '"$_query" bulunamadı',
                    message: 'Sağ alttan yeni yemek ekleyebilirsin',
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
          Text(
            '${food.kcalPer100g.round()} kcal · P${food.proteinPer100g.round()} K${food.carbPer100g.round()} Y${food.fatPer100g.round()} /100g',
            style: context.texts.labelSmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          if (hasUnit)
            Text(
              '1 ${food.unitLabel} ≈ ${food.defaultPortionGrams!.round()} g',
              style: context.texts.labelSmall
                  ?.copyWith(color: context.colors.secondary),
            ),
        ],
      ),
      trailing: onDelete == null
          ? Icon(Icons.chevron_right_rounded,
              color: context.colors.onSurfaceVariant)
          : IconButton(
              tooltip: 'Sil',
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
    _unit = f?.unitLabel ?? (f == null ? 'porsiyon' : null);
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
    final editing = widget.initial != null;
    return AlertDialog(
      title: Text(editing ? 'Yemeği düzenle' : 'Yeni yemek'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Değerler 100 gram için girilir. Birim seçersen "1 birim '
                'kaç gram" de yaz — loglarken adet/dilim ile girebilirsin.',
                style: context.texts.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant),
              ),
              AppSpacing.vGapMd,
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Yemek adı'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ad gir' : null,
              ),
              AppSpacing.vGapMd,
              _Num(_kcal, 'Kalori /100g (kcal)', req: true),
              AppSpacing.vGapMd,
              _Num(_protein, 'Protein /100g (g)'),
              AppSpacing.vGapMd,
              _Num(_carb, 'Karbonhidrat /100g (g)'),
              AppSpacing.vGapMd,
              _Num(_fat, 'Yağ /100g (g)'),
              AppSpacing.vGapMd,
              DropdownButtonFormField<String?>(
                initialValue: _unit,
                decoration: const InputDecoration(labelText: 'Birim'),
                items: [
                  const DropdownMenuItem(
                      value: null,
                      child: Text('(birim yok — sadece gram)')),
                  ...kUnitOptions.map((u) =>
                      DropdownMenuItem(value: u, child: Text('1 $u'))),
                ],
                onChanged: (v) => setState(() => _unit = v),
              ),
              if (_unit != null) ...[
                AppSpacing.vGapMd,
                _Num(_portion, '1 $_unit kaç gram?', req: true),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç')),
        FilledButton(onPressed: _save, child: const Text('Kaydet')),
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
        final t = (raw ?? '').trim().replaceAll(',', '.');
        if (t.isEmpty) return req ? 'Zorunlu' : null;
        final v = double.tryParse(t);
        if (v == null) return 'Geçersiz sayı';
        if (req && v <= 0) return '0\'dan büyük olmalı';
        if (v < 0) return 'Negatif olamaz';
        return null;
      },
    );
  }
}
