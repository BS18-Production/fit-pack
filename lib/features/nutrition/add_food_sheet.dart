import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/formatting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/format.dart';
import '../../data/database/app_database.dart';
import '../../data/providers.dart';
import '../../data/services/openfoodfacts_service.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/progress_indicators.dart';
import 'barcode_flow.dart';
import 'food_search.dart';
import 'foods_screen.dart' show foodCategoryLabel, availableFoodCategories;
import 'meal_types.dart';
import 'nutrition_habits.dart' show mealForTime;
import 'nutrition_screen.dart' show selectedDateProvider, unitOptionsWith;

/// **Yemek ekleme paneli** (2026-09-30 yeniden tasarım — NEXT_TASKS
/// "Yemek ekleme paneli").
///
/// İlkeler (MyFitnessPal / Yazio / Lose It ortak pratiği, Samet: "pürüzü
/// azalt"):
/// 1. **Tek dokunuş:** her satırda ⊕ — porsiyonu (ya da son kullanılan
///    miktarı) anında ekler. Satıra dokunmak yalnız miktarı değiştirmek için.
/// 2. **Porsiyon kalorisi:** satır "1 porsiyon · 200 g · 194 kcal" der,
///    "/100g" değil — kullanıcının merak ettiği yediği miktar.
/// 3. **Akıllı arama:** Türkçe harf farkı yok, kelime başı önce, son
///    kullanılan üstte (`rankFoods`).
/// 4. **Kısayollar tek sırada:** barkod · hızlı kalori · kendi besinin.
/// 5. **Geri alınabilir:** eklenen kayıt panelin içinde "Geri al"la silinir.
///
/// Panel ekledikten sonra KAPANMAZ — bir öğüne arka arkaya birkaç şey
/// girilir (1 avokado + 3 yumurta + 50 g peynir); "Bitti" ile kapanır.
Future<void> showAddFoodSheet(BuildContext context, {String? mealType}) {
  return showModalBottomSheet<void>(
    context: context,
    // Kök navigator (C-1): sekme navigator'ında açılan panel buzlu alt
    // çubuğun ARKASINDA kalıyordu (AppShell extendBody).
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.colors.surface,
    builder: (_) => AddFoodSheet(mealType: mealType),
  );
}

/// Yemek grubu ikonu — liste satırının solunda.
IconData foodIcon(Food f) {
  if (f.isCustom) return Icons.person_rounded;
  return switch (f.category) {
    'meat' => Icons.kebab_dining_rounded,
    'dairy' => Icons.local_drink_rounded,
    'grain' => Icons.bakery_dining_rounded,
    'legume' => Icons.rice_bowl_rounded,
    'vegetable' => Icons.eco_rounded,
    'fruit' => Icons.spa_rounded,
    'fat' => Icons.water_drop_rounded,
    'dish' => Icons.ramen_dining_rounded,
    'sweet' => Icons.cake_rounded,
    'drink' => Icons.local_cafe_rounded,
    _ => f.barcode != null ? Icons.qr_code_rounded : Icons.restaurant_rounded,
  };
}

String _addToMeal(AppL10n l, String meal) => switch (meal) {
      'breakfast' => l.afAddBreakfast,
      'lunch' => l.afAddLunch,
      'dinner' => l.afAddDinner,
      _ => l.afAddSnack,
    };

/// "1 porsiyon · 200 g" / "150 g".
String portionText(FoodPortion p) => p.unit != null && p.units > 0
    ? '${fmtNum(p.units)} ${p.unit} · ${p.grams.round()} g'
    : '${p.grams.round()} g';

class AddFoodSheet extends ConsumerStatefulWidget {
  /// null → günün saatine göre öğün (bugünse), yoksa öğle.
  final String? mealType;
  const AddFoodSheet({super.key, this.mealType});

  @override
  ConsumerState<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends ConsumerState<AddFoodSheet> {
  final _search = TextEditingController();
  late String _meal;
  List<Food> _all = [];
  List<({Food food, double grams})> _recent = [];
  Map<int, int> _recentRank = {};
  Map<int, double> _lastGrams = {};
  bool _loading = true;
  String? _category; // null = Tümü
  Food? _editing; // miktar paneli açık besin
  bool _saving = false;
  // Bu açılışta eklenenler — "Geri al" son eklemeyi siler.
  int _sessionCount = 0;
  ({String label, List<int> ids})? _lastAdded;
  // OpenFoodFacts metin araması (paketli ürünler).
  bool _offSearching = false;
  List<OffProduct> _offResults = const [];

  DateTime get _day => ref.read(selectedDateProvider);

  @override
  void initState() {
    super.initState();
    final d = ref.read(selectedDateProvider);
    _meal = widget.mealType ??
        (DateUtils.isSameDay(d, DateTime.now())
            ? mealForTime(DateTime.now())
            : 'lunch');
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final dao = ref.read(nutritionDaoProvider);
    final foods = await dao.getAllFoods();
    final recent = await dao.getRecentPortions();
    if (!mounted) return;
    setState(() {
      _all = foods;
      _recent = recent;
      _recentRank = {
        for (final (i, r) in recent.indexed) r.food.id: i,
      };
      _lastGrams = {for (final r in recent) r.food.id: r.grams};
      _loading = false;
    });
  }

  String get _query => _search.text.trim();

  List<Food> get _results {
    final ranked = rankFoods(_all, _query, recentRank: _recentRank);
    if (_query.isNotEmpty || _category == null) return ranked;
    return [for (final f in ranked) if (f.category == _category) f];
  }

  FoodPortion _portion(Food f) => defaultPortion(f, lastGrams: _lastGrams[f.id]);

  // ───────── ekleme ─────────

  Future<void> _add(Food f, double grams) async {
    if (_saving || grams <= 0) return;
    setState(() => _saving = true);
    final l = AppL10n.of(context);
    final m = macrosFor(f, grams);
    try {
      final id = await ref.read(nutritionDaoProvider).insertFoodLog(
            FoodLogsCompanion(
              date: Value(_day),
              mealType: Value(_meal),
              foodId: Value(f.id),
              grams: Value(grams),
              computedKcal: Value(m.kcal),
              computedProtein: Value(m.protein),
              computedCarb: Value(m.carb),
              computedFat: Value(m.fat),
            ),
          );
      HapticFeedback.lightImpact();
      if (!mounted) return;
      setState(() {
        _saving = false;
        _sessionCount++;
        _lastAdded = (label: '${f.name} · ${m.kcal.round()} kcal', ids: [id]);
        _editing = null;
        _pushRecent(f, grams);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.nutritionAddFailed),
        backgroundColor: context.colors.error,
      ));
    }
  }

  Future<void> _undo() async {
    final last = _lastAdded;
    if (last == null) return;
    await ref.read(nutritionDaoProvider).deleteFoodLogs(last.ids);
    if (!mounted) return;
    setState(() {
      _lastAdded = null;
      _sessionCount = (_sessionCount - 1).clamp(0, 1 << 30);
    });
  }

  /// Eklenen besin "Son eklediklerin"in başına geçer (panel açıkken de).
  void _pushRecent(Food f, double grams) {
    _recent = [
      (food: f, grams: grams),
      for (final r in _recent)
        if (r.food.id != f.id) r,
    ].take(8).toList();
    _recentRank = {for (final (i, r) in _recent.indexed) r.food.id: i};
    _lastGrams = {..._lastGrams, f.id: grams};
  }

  void _addToList(Food f) {
    if (!_all.any((x) => x.id == f.id)) _all = [f, ..._all];
  }

  // ───────── kısayollar ─────────

  Future<void> _scan() async {
    final food = await scanBarcodeToFood(context, ref);
    if (food == null || !mounted) return;
    setState(() {
      _addToList(food);
      _editing = food;
    });
  }

  Future<void> _quick() async {
    final r = await showDialog<_QuickEntry>(
      context: context,
      builder: (_) => const _QuickAddDialog(),
    );
    if (r == null || !mounted) return;
    final l = AppL10n.of(context);
    final name = r.name.isEmpty ? l.nhQuickDefaultName : r.name;
    setState(() => _saving = true);
    try {
      final id = await ref.read(nutritionDaoProvider).quickAddLog(
            day: _day,
            mealType: _meal,
            name: name,
            kcal: r.kcal,
            protein: r.protein,
            portionLabel: l.nhPortion,
          );
      HapticFeedback.lightImpact();
      if (!mounted) return;
      setState(() {
        _saving = false;
        _sessionCount++;
        _lastAdded = (label: '$name · ${r.kcal.round()} kcal', ids: [id]);
      });
      _load(); // yeni besin listeye (ve son eklenenlere) girsin
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.nutritionAddFailed),
        backgroundColor: context.colors.error,
      ));
    }
  }

  Future<void> _custom() async {
    final result = await showDialog<_CustomFood>(
      context: context,
      builder: (_) => const _CustomFoodDialog(),
    );
    if (result == null || !mounted) return;
    final dao = ref.read(nutritionDaoProvider);
    final id = await dao.insertFood(FoodsCompanion(
      name: Value(result.name),
      kcalPer100g: Value(result.kcalPer100g),
      proteinPer100g: Value(result.proteinPer100g),
      carbPer100g: Value(result.carbPer100g),
      fatPer100g: Value(result.fatPer100g),
      source: const Value('custom'),
      isCustom: const Value(true),
      isRecipe: const Value(false),
      defaultPortionGrams: Value(result.defaultGrams),
      unitLabel: Value(result.unitLabel),
    ));
    final food = await dao.getFoodById(id);
    if (food == null || !mounted) return;
    setState(() {
      _addToList(food);
      _search.clear();
      _editing = food;
    });
  }

  Future<void> _searchOff() async {
    final q = _query;
    if (q.length < 2 || _offSearching) return;
    FocusScope.of(context).unfocus();
    setState(() => _offSearching = true);
    final results =
        await ref.read(openFoodFactsServiceProvider).searchByName(q);
    if (!mounted) return;
    setState(() {
      _offSearching = false;
      _offResults = results;
    });
    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context).nutritionOffNoResults)),
      );
    }
  }

  /// OFF sonucunu DB'ye yaz (barkodla varsa onu kullan) → miktar paneli.
  Future<void> _pickOff(OffProduct p) async {
    final dao = ref.read(nutritionDaoProvider);
    var food = await dao.getFoodByBarcode(p.barcode);
    food ??= await dao.getFoodById(await dao.insertFood(FoodsCompanion(
      name: Value(p.name),
      barcode: Value(p.barcode),
      kcalPer100g: Value(p.kcalPer100g),
      proteinPer100g: Value(p.proteinPer100g),
      carbPer100g: Value(p.carbPer100g),
      fatPer100g: Value(p.fatPer100g),
      source: const Value('openfoodfacts'),
      isCustom: const Value(false),
      isRecipe: const Value(false),
    )));
    if (food == null || !mounted) return;
    setState(() {
      _addToList(food!);
      _offResults = const [];
      _editing = food;
    });
  }

  // ───────── arayüz ─────────

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.colors;
    final results = _results;
    final searching = _query.isNotEmpty;
    final editing = _editing;

    return DraggableScrollableSheet(
      initialChildSize: 0.94,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scroll) => Padding(
        padding: EdgeInsets.only(bottom: context.sheetBottomInset),
        child: Column(
          children: [
            _Header(
              meal: _meal,
              day: _day,
              sessionCount: _sessionCount,
              onMeal: (m) => setState(() => _meal = m),
              onDone: () => Navigator.of(context).pop(),
            ),
            if (_lastAdded != null)
              _AddedBanner(
                label: l.afAdded(_lastAdded!.label),
                onUndo: _undo,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: _SearchField(
                controller: _search,
                onChanged: (_) => setState(() {
                  _offResults = const [];
                  _editing = null;
                }),
                onScan: _scan,
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomScrollView(
                      controller: scroll,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        if (!searching) ...[
                          SliverToBoxAdapter(
                            child: _Shortcuts(
                              onScan: _scan,
                              onQuick: _saving ? null : _quick,
                              onCustom: _custom,
                            ),
                          ),
                          if (_recent.isNotEmpty) ...[
                            _SectionTitle(l.afRecent),
                            SliverList.list(children: [
                              for (final r in _recent) _row(r.food),
                            ]),
                          ],
                          _SectionTitle(l.afAllCount(_all.length)),
                          SliverToBoxAdapter(
                            child: _CategoryChips(
                              categories: availableFoodCategories(_all),
                              selected: _category,
                              onSelect: (cat) =>
                                  setState(() => _category = cat),
                            ),
                          ),
                        ] else
                          _SectionTitle(l.afResults(results.length)),
                        if (results.isEmpty)
                          SliverToBoxAdapter(
                            child: _NoResults(
                              query: _query,
                              onQuick: _quick,
                              onCustom: _custom,
                            ),
                          )
                        else
                          SliverList.builder(
                            itemCount: results.length,
                            itemBuilder: (_, i) => _row(results[i]),
                          ),
                        // Listede yoksa: paketli ürünü internette ara.
                        if (searching && _query.length >= 2) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md),
                              child: ListTile(
                                leading: _offSearching
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : Icon(Icons.travel_explore_rounded,
                                        color: c.secondary),
                                title: Text(
                                    _offSearching
                                        ? l.nutritionOffSearching
                                        : l.nutritionOffSearchFor(_query),
                                    style: context.texts.bodyMedium
                                        ?.copyWith(color: c.secondary)),
                                onTap: _offSearching ? null : _searchOff,
                              ),
                            ),
                          ),
                          if (_offResults.isNotEmpty)
                            SliverList.list(children: [
                              for (final p in _offResults)
                                _OffRow(product: p, onTap: () => _pickOff(p)),
                            ]),
                        ],
                        const SliverToBoxAdapter(
                            child: SizedBox(height: AppSpacing.xl)),
                      ],
                    ),
            ),
            if (editing != null)
              _AmountPanel(
                key: ValueKey(editing.id),
                food: editing,
                initial: _portion(editing),
                addLabel: _addToMeal(l, _meal),
                saving: _saving,
                onClose: () => setState(() => _editing = null),
                onAdd: (grams) => _add(editing, grams),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(Food f) => _FoodRow(
        key: ValueKey('food-${f.id}'),
        food: f,
        portion: _portion(f),
        selected: _editing?.id == f.id,
        onTap: () => setState(() => _editing = f),
        onQuickAdd: _saving ? null : () => _add(f, _portion(f).grams),
      );
}

// ───────────────────────────── Başlık ─────────────────────────────

class _Header extends StatelessWidget {
  final String meal;
  final DateTime day;
  final int sessionCount;
  final ValueChanged<String> onMeal;
  final VoidCallback onDone;
  const _Header({
    required this.meal,
    required this.day,
    required this.sessionCount,
    required this.onMeal,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.colors;
    final today = DateUtils.isSameDay(day, DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, 0),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: c.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: AppRadius.brSm,
            ),
          ),
          AppSpacing.vGapSm,
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.nutritionAddFood,
                        style: context.texts.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _MealPicker(meal: meal, onSelect: onMeal),
                        if (!today) ...[
                          AppSpacing.hGapSm,
                          Text(context.dateFmt('d MMM').format(day),
                              style: context.texts.labelMedium?.copyWith(
                                  color: c.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (sessionCount > 0)
                FilledButton.tonal(
                  onPressed: onDone,
                  child: Text(l.afDone),
                )
              else
                IconButton(
                  tooltip: l.commonClose,
                  onPressed: onDone,
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Öğün seçici: "🍽 Öğle ▾" — dört bölümlü geniş blok yerine tek dokunuş.
class _MealPicker extends StatelessWidget {
  final String meal;
  final ValueChanged<String> onSelect;
  const _MealPicker({required this.meal, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.colors;
    return PopupMenuButton<String>(
      tooltip: l.afChangeMeal,
      initialValue: meal,
      onSelected: onSelect,
      itemBuilder: (_) => [
        for (final m in mealTypes)
          PopupMenuItem(
            value: m,
            child: Row(
              children: [
                Icon(mealIcon(m), size: AppIconSize.sm, color: c.secondary),
                AppSpacing.hGapSm,
                Text(mealName(l, m)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm, AppSpacing.xs, AppSpacing.xs, AppSpacing.xs),
        decoration: BoxDecoration(
          color: c.secondary.withValues(alpha: 0.12),
          borderRadius: AppRadius.brPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(mealIcon(meal), size: 16, color: c.secondary),
            const SizedBox(width: 6),
            Text(mealName(l, meal),
                style: context.texts.labelLarge?.copyWith(
                    color: c.secondary, fontWeight: FontWeight.w700)),
            Icon(Icons.arrow_drop_down_rounded, color: c.secondary),
          ],
        ),
      ),
    );
  }
}

/// "✓ Menemen · 194 kcal eklendi   Geri al"
class _AddedBanner extends StatelessWidget {
  final String label;
  final VoidCallback onUndo;
  const _AddedBanner({required this.label, required this.onUndo});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final ok = context.semantic.success;
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.xs, AppSpacing.xs),
      decoration: BoxDecoration(
        color: ok.withValues(alpha: 0.12),
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: AppIconSize.sm, color: ok),
          AppSpacing.hGapSm,
          Expanded(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          TextButton(onPressed: onUndo, child: Text(l.commonUndo)),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onScan;
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: l.nutritionSearchHint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? IconButton(
                tooltip: l.nutritionScanBarcode,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                onPressed: onScan,
              )
            : IconButton(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

/// Barkod · Hızlı kalori · Kendi besinin — tek sırada, eşit genişlikte.
class _Shortcuts extends StatelessWidget {
  final VoidCallback onScan;
  final VoidCallback? onQuick;
  final VoidCallback onCustom;
  const _Shortcuts({
    required this.onScan,
    required this.onQuick,
    required this.onCustom,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
              child: _ShortcutTile(
                  icon: Icons.qr_code_scanner_rounded,
                  label: l.afScan,
                  onTap: onScan)),
          AppSpacing.hGapSm,
          Expanded(
              child: _ShortcutTile(
                  icon: Icons.bolt_rounded, label: l.afQuick, onTap: onQuick)),
          AppSpacing.hGapSm,
          Expanded(
              child: _ShortcutTile(
                  icon: Icons.edit_note_rounded,
                  label: l.afCustom,
                  onTap: onCustom)),
        ],
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ShortcutTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.secondary.withValues(alpha: 0.10),
      borderRadius: AppRadius.brMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md, horizontal: AppSpacing.xs),
          child: Column(
            children: [
              Icon(icon, color: c.secondary),
              const SizedBox(height: 4),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelMedium?.copyWith(
                      color: c.onSurface, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
          // Türkçede i → İ (toUpperCase "BESINLER" yazıyordu).
          child: Text(upperForLanguage(text, Localizations.localeOf(context)),
              style: context.texts.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8)),
        ),
      );
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelect;
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          for (final cat in <String?>[null, ...categories])
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(cat == null ? l.afCatAll : foodCategoryLabel(l, cat)),
                selected: selected == cat,
                showCheckmark: false,
                onSelected: (_) => onSelect(cat),
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Satır ─────────────────────────────

/// Besin satırı: grup ikonu · ad · porsiyon + makro · porsiyon kalorisi · ⊕.
class _FoodRow extends StatelessWidget {
  final Food food;
  final FoodPortion portion;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onQuickAdd;
  const _FoodRow({
    super.key,
    required this.food,
    required this.portion,
    required this.selected,
    required this.onTap,
    required this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.colors;
    final m = macrosFor(food, portion.grams);
    return Material(
      color: selected ? c.secondary.withValues(alpha: 0.10) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.secondary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.brMd,
                ),
                child: Icon(foodIcon(food), size: 20, color: c.secondary),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(food.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    MacroInlineText(
                      protein: m.protein,
                      carb: m.carb,
                      fat: m.fat,
                      prefix: '${portionText(portion)}  ·  ',
                    ),
                  ],
                ),
              ),
              AppSpacing.hGapSm,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${m.kcal.round()}',
                      style: context.texts.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Text('kcal',
                      style: context.texts.labelSmall
                          ?.copyWith(color: c.onSurfaceVariant)),
                ],
              ),
              IconButton(
                tooltip: l.afQuickAddTip(portionText(portion)),
                onPressed: onQuickAdd,
                icon: Icon(Icons.add_circle_rounded,
                    size: 30, color: c.secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OffRow extends StatelessWidget {
  final OffProduct product;
  final VoidCallback onTap;
  const _OffRow({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      leading: Icon(Icons.public_rounded, color: c.secondary),
      title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: MacroInlineText(
        protein: product.proteinPer100g,
        carb: product.carbPer100g,
        fat: product.fatPer100g,
        prefix: '${product.kcalPer100g.round()} kcal · ',
        suffix: ' /100 g',
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: c.onSurfaceVariant),
      onTap: onTap,
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  final VoidCallback onQuick;
  final VoidCallback onCustom;
  const _NoResults({
    required this.query,
    required this.onQuick,
    required this.onCustom,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(Icons.no_food_rounded,
              size: AppIconSize.xl, color: context.colors.onSurfaceVariant),
          AppSpacing.vGapSm,
          Text(query.isEmpty ? l.nutritionNoFoods : l.nutritionNotFound(query),
              textAlign: TextAlign.center, style: context.texts.titleSmall),
          AppSpacing.vGapXs,
          Text(l.nutritionNotInListHint,
              textAlign: TextAlign.center,
              style: context.texts.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant)),
          AppSpacing.vGapMd,
          Wrap(
            spacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onQuick,
                icon: const Icon(Icons.bolt_rounded, size: AppIconSize.sm),
                label: Text(l.afQuick),
              ),
              OutlinedButton.icon(
                onPressed: onCustom,
                icon: const Icon(Icons.edit_note_rounded, size: AppIconSize.sm),
                label: Text(l.afCustom),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Miktar paneli ─────────────────────────────

/// Satıra dokununca alttan açılır: canlı kalori + makrolar, birim/gram,
/// −/+ ve hazır miktar çipleri, "Öğle yemeğine ekle".
class _AmountPanel extends StatefulWidget {
  final Food food;
  final FoodPortion initial;
  final String addLabel;
  final bool saving;
  final VoidCallback onClose;
  final ValueChanged<double> onAdd;
  const _AmountPanel({
    super.key,
    required this.food,
    required this.initial,
    required this.addLabel,
    required this.saving,
    required this.onClose,
    required this.onAdd,
  });

  @override
  State<_AmountPanel> createState() => _AmountPanelState();
}

class _AmountPanelState extends State<_AmountPanel> {
  late bool _unitMode = hasUnit(widget.food);
  late double _grams = widget.initial.grams;
  late final TextEditingController _field =
      TextEditingController(text: _fieldText());

  double get _portionG => widget.food.defaultPortionGrams ?? 100;
  double get _units => _grams / _portionG;

  String _fieldText() => _unitMode ? fmtNum(_round(_units)) : '${_grams.round()}';

  double _round(double v) => (v * 100).round() / 100;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _setGrams(double g, {bool syncField = true}) {
    setState(() => _grams = g.clamp(1, 5000).toDouble());
    if (syncField) _field.text = _fieldText();
  }

  void _setMode(bool unit) {
    setState(() => _unitMode = unit);
    _field.text = _fieldText();
  }

  void _step(int dir) => _setGrams(_unitMode
      ? (_units + dir * 0.5).clamp(0.25, 99) * _portionG
      : _grams + dir * 10);

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.colors;
    final f = widget.food;
    final m = macrosFor(f, _grams);
    final unitLabel = f.unitLabel ?? l.unitPortion;
    final presets = _unitMode
        ? const [0.5, 1.0, 1.5, 2.0]
        : const [50.0, 100.0, 150.0, 200.0];

    Widget macro(String label, double g, Color color) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('$label ${g.round()} g',
                style: context.texts.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surfaceContainerHigh,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        boxShadow: [
          BoxShadow(
              color: c.shadow.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(f.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
              IconButton(
                tooltip: l.commonClose,
                visualDensity: VisualDensity.compact,
                onPressed: widget.onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${m.kcal.round()}',
                  style: context.texts.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.semantic.macroCalories,
                      height: 1)),
              const SizedBox(width: 4),
              Text('kcal',
                  style: context.texts.labelLarge
                      ?.copyWith(color: c.onSurfaceVariant)),
              const Spacer(),
              if (hasUnit(f))
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  segments: [
                    ButtonSegment(value: true, label: Text(unitLabel)),
                    const ButtonSegment(value: false, label: Text('g')),
                  ],
                  selected: {_unitMode},
                  onSelectionChanged: (v) => _setMode(v.first),
                ),
            ],
          ),
          AppSpacing.vGapSm,
          Wrap(
            spacing: AppSpacing.md,
            children: [
              macro(l.macroProtein, m.protein, context.semantic.macroProtein),
              macro(l.macroCarbs, m.carb, context.semantic.macroCarbs),
              macro(l.macroFat, m.fat, context.semantic.macroFat),
            ],
          ),
          AppSpacing.vGapMd,
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: () => _step(-1),
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: TextField(
                    controller: _field,
                    textAlign: TextAlign.center,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    style: context.texts.titleMedium,
                    decoration: InputDecoration(
                      isDense: true,
                      suffixText: _unitMode
                          ? '$unitLabel · ${_grams.round()} g'
                          : 'g',
                    ),
                    onChanged: (v) {
                      final n = double.tryParse(v.replaceAll(',', '.'));
                      if (n == null || n <= 0) return;
                      _setGrams(_unitMode ? n * _portionG : n,
                          syncField: false);
                    },
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => _step(1),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Row(
            children: [
              for (final p in presets)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ChoiceChip(
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(
                            _unitMode ? fmtNum(p) : '${p.round()} g',
                            textAlign: TextAlign.center),
                      ),
                      showCheckmark: false,
                      selected: _unitMode
                          ? (_units - p).abs() < 0.01
                          : (_grams - p).abs() < 0.5,
                      onSelected: (_) =>
                          _setGrams(_unitMode ? p * _portionG : p),
                    ),
                  ),
                ),
            ],
          ),
          AppSpacing.vGapMd,
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  widget.saving ? null : () => widget.onAdd(_grams),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: widget.saving
                  ? SizedBox(
                      width: AppIconSize.sm,
                      height: AppIconSize.sm,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: c.onPrimary))
                  : const Icon(Icons.check_rounded),
              label: Text('${widget.addLabel} · ${m.kcal.round()} kcal'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── Diyaloglar (nutrition_screen'den taşındı) ───────────────────

typedef _QuickEntry = ({String name, double kcal, double protein});

/// Hızlı giriş formu: ad (isteğe bağlı) + kcal (zorunlu) + protein.
class _QuickAddDialog extends StatefulWidget {
  const _QuickAddDialog();

  @override
  State<_QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends State<_QuickAddDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _kcal = TextEditingController();
  final _protein = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _kcal.dispose();
    _protein.dispose();
    super.dispose();
  }

  double? _num(String v) => double.tryParse(v.trim().replaceAll(',', '.'));

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop<_QuickEntry>(context, (
      name: _name.text.trim(),
      kcal: _num(_kcal.text)!,
      protein: _num(_protein.text) ?? 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final numeric = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
    ];
    return AlertDialog(
      title: Text(l.nhQuickTitle),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.nhQuickHint,
                  style: context.texts.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant)),
              AppSpacing.vGapMd,
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l.nhQuickName),
              ),
              AppSpacing.vGapSm,
              TextFormField(
                controller: _kcal,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: numeric,
                decoration: InputDecoration(labelText: l.nhQuickKcal),
                validator: (v) {
                  final n = _num(v ?? '');
                  return n == null || n <= 0 ? l.nhQuickKcal : null;
                },
              ),
              AppSpacing.vGapSm,
              TextFormField(
                controller: _protein,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: numeric,
                decoration: InputDecoration(labelText: l.nhQuickProtein),
                onFieldSubmitted: (_) => _save(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.commonCancel)),
        FilledButton(onPressed: _save, child: Text(l.nhUsualAdd)),
      ],
    );
  }
}


/// Custom food creator sonucu — porsiyon değerleri /100g'a çevrilir.
class _CustomFood {
  final String name;
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbPer100g;
  final double fatPer100g;
  final double defaultGrams;
  final String? unitLabel; // null → birim yok (sadece gram)

  _CustomFood({
    required this.name,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbPer100g,
    required this.fatPer100g,
    required this.defaultGrams,
    required this.unitLabel,
  });
}


/// Kullanıcı kendi yemeğini girer. "Yediğin porsiyon" mantığı: toplam
/// gram + o porsiyonun toplam kcal/P/K/Y'si → /100g'a çevrilip kaydedilir
/// (tekrar kullanılabilir). Örn: "3 Yumurtalı Omlet" 220 g, 320 kcal...
class _CustomFoodDialog extends StatefulWidget {
  const _CustomFoodDialog();

  @override
  State<_CustomFoodDialog> createState() => _CustomFoodDialogState();
}

class _CustomFoodDialogState extends State<_CustomFoodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _grams = TextEditingController(text: '100');
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carb = TextEditingController();
  final _fat = TextEditingController();
  // Birim: "porsiyon" varsayılan (locale'e göre, ilk build'de atanır).
  // null → "birim yok" (sadece gram).
  String? _unit;
  bool _unitInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_unitInitialized) {
      _unitInitialized = true;
      _unit = AppL10n.of(context).unitPortion;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _grams, _kcal, _protein, _carb, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final g = _num(_grams);
    final f = 100 / g; // porsiyon → /100g
    Navigator.pop(
      context,
      _CustomFood(
        name: _name.text.trim(),
        kcalPer100g: _num(_kcal) * f,
        proteinPer100g: _num(_protein) * f,
        carbPer100g: _num(_carb) * f,
        fatPer100g: _num(_fat) * f,
        defaultGrams: g,
        unitLabel: _unit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return AlertDialog(
      title: Text(l.nutritionCustomTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.nutritionCustomHelp,
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
              AppSpacing.vGapMd,
              _NumberField(
                  controller: _grams,
                  label: _unit == null
                      ? l.nutritionPortionGrams
                      : l.nutritionUnitGramsQuestion(_unit!),
                  requiredField: true),
              AppSpacing.vGapMd,
              _NumberField(
                  controller: _kcal,
                  label: l.nutritionTotalKcal,
                  requiredField: true),
              AppSpacing.vGapMd,
              _NumberField(
                  controller: _protein, label: '${l.macroProtein} (g)'),
              AppSpacing.vGapMd,
              _NumberField(
                  controller: _carb, label: '${l.macroCarbs} (g)'),
              AppSpacing.vGapMd,
              _NumberField(controller: _fat, label: '${l.macroFat} (g)'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonCancel),
        ),
        FilledButton(onPressed: _save, child: Text(l.commonSave)),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool requiredField;

  const _NumberField({
    required this.controller,
    required this.label,
    this.requiredField = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(labelText: label),
      validator: (raw) {
        final l = AppL10n.of(context);
        final t = (raw ?? '').trim().replaceAll(',', '.');
        if (t.isEmpty) return requiredField ? l.commonRequired : null;
        final v = double.tryParse(t);
        if (v == null) return l.commonInvalidNumber;
        if (requiredField && v <= 0) return l.commonMustBePositive;
        if (v < 0) return l.commonNotNegative;
        return null;
      },
    );
  }
}

