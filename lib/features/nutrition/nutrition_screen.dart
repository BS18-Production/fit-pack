import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/formatting.dart';
import '../../core/onboarding/first_run_hints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import '../../core/utils/format.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/nutrition_dao.dart';
import '../../data/services/openfoodfacts_service.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/progress_indicators.dart';
import '../home/providers/home_providers.dart';
import 'barcode_flow.dart';
import 'macro_goals.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Kayıtlar + yemek adı (join). **Reaktif** (H-05): öğün eklenince/silinince
/// kendiliğinden tazelenir. Seçili gün değişince provider yeniden kurulur.
final logsWithFoodProvider = StreamProvider<List<FoodLogWithFood>>((ref) {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedDateProvider);
  return watchTables(db, [db.foodLogs, db.foods],
      () => ref.read(nutritionDaoProvider).getLogsWithFoodForDate(date));
});

final nutritionTotalsProvider = StreamProvider<DailyNutrition>((ref) {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedDateProvider);
  return watchTables(db, [db.foodLogs, db.foods],
      () => ref.read(nutritionDaoProvider).getDailyTotals(date));
});

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  void _invalidateAll(WidgetRef ref) {
    ref.invalidate(logsWithFoodProvider);
    ref.invalidate(nutritionTotalsProvider);
    ref.invalidate(todayNutritionProvider);
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, FoodLogWithFood item) async {
    // SnackBar ekrandan uzun yaşar (M-06): kullanıcı sekme değiştirdikten
    // sonra "Geri al"a basarsa ekranın ref'i ölmüş olabilir. DAO önceden
    // yakalanır — ekranın yaşam döngüsünden bağımsız; yazma sonrası tazeleme
    // artık reaktif provider'ların işi (elle invalidate yok).
    final dao = ref.read(nutritionDaoProvider);
    final l = AppL10n.of(context);
    await dao.deleteFoodLog(item.log.id);
    // Kayıt/toplam provider'ları reaktif (H-05) → silme kendiliğinden yansır.
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      content: Text(l.foodsDeleted(item.food.name)),
      action: SnackBarAction(
        label: l.commonUndo,
        onPressed: () async {
          await dao.insertFoodLog(
            FoodLogsCompanion(
              date: Value(item.log.date),
              mealType: Value(item.log.mealType),
              foodId: Value(item.log.foodId),
              grams: Value(item.log.grams),
              computedKcal: Value(item.log.computedKcal),
              computedProtein: Value(item.log.computedProtein),
              computedCarb: Value(item.log.computedCarb),
              computedFat: Value(item.log.computedFat),
            ),
          );
          // Reaktif provider'lar (H-05) geri-al eklemesini kendiliğinden yansıtır.
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final totalsAsync = ref.watch(nutritionTotalsProvider);
    final logsAsync = ref.watch(logsWithFoodProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    final l = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.navNutrition),
        actions: [
          IconButton(
            tooltip: l.nutritionPickDate,
            icon: const Icon(Icons.calendar_today_rounded),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                ref.read(selectedDateProvider.notifier).state = picked;
              }
            },
          ),
        ],
      ),
      // İlk-kullanım ipucu (docs/15 §B): sekmeye ilk girişte öğün eklemeyi
      // işaret eder; bir kez gösterilir.
      // Alt boşluk: içerik buzlu gezinme çubuğunun altından aktığı için
      // (extendBody) iç Scaffold FAB'ı çubuğun arkasına koyar — yukarı kaldır.
      floatingActionButton: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: CoachMark(
          hint: FirstRunHint.nutrition,
          message: (l) => l.hintNutrition,
          child: FloatingActionButton.extended(
            onPressed: () => _showAddFoodSheet(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: Text(l.nutritionAddFood),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _invalidateAll(ref),
        child: ListView(
          // Alt boşluk: içerik buzlu gezinme çubuğunun altından akar.
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg,
              AppSpacing.lg, context.bottomScrollInset),
          children: [
            _DateBar(
              date: date,
              isToday: isToday,
              onPrev: () => ref.read(selectedDateProvider.notifier).state =
                  date.subtract(const Duration(days: 1)),
              onNext: isToday
                  ? null
                  : () => ref.read(selectedDateProvider.notifier).state =
                      date.add(const Duration(days: 1)),
            ),
            AppSpacing.vGapLg,
            totalsAsync.when(
              data: (totals) => profileAsync.maybeWhen(
                data: (profile) => _SummaryHero(
                  totals: totals,
                  kcalGoal: profile?.kcalGoal ?? 2200,
                  proteinGoal: profile?.proteinGoal ?? 180,
                ),
                orElse: () => Skeleton.card(height: 280),
              ),
              loading: () => Skeleton.card(height: 280),
              error: (_, _) => const SizedBox.shrink(),
            ),
            AppSpacing.vGapLg,
            logsAsync.when(
              loading: () => Column(children: [
                Skeleton.card(height: 96),
                AppSpacing.vGapMd,
                Skeleton.card(height: 96),
              ]),
              error: (_, _) => ErrorState(
                message: l.nutritionLoadError,
                onRetry: () => _invalidateAll(ref),
              ),
              data: (logs) => Column(
                children: [
                  if (logs.isEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.md),
                      child: OutlinedButton.icon(
                        onPressed: () => _copyYesterday(context, ref),
                        icon: const Icon(Icons.content_copy_rounded,
                            size: AppIconSize.sm),
                        label: Text(isToday
                            ? l.nutritionCopyYesterday
                            : l.nutritionCopyPrevDay),
                      ),
                    ),
                  ...['breakfast', 'lunch', 'dinner', 'snack']
                    .map((mealType) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _MealSection(
                            mealType: mealType,
                            items: logs
                                .where((l) => l.log.mealType == mealType)
                                .toList(),
                            onAddFood: () => _showAddFoodSheet(context, ref,
                                mealType: mealType),
                            onDelete: (item) => _delete(context, ref, item),
                          ),
                        )),
                ],
              ),
            ),
            const SizedBox(height: 88),
          ],
        ),
      ),
    );
  }

  /// Seçili gün boşsa bir önceki günün tüm kayıtlarını kopyalar.
  Future<void> _copyYesterday(BuildContext context, WidgetRef ref) async {
    final l = AppL10n.of(context);
    final date = ref.read(selectedDateProvider);
    final from = date.subtract(const Duration(days: 1));
    final messenger = ScaffoldMessenger.of(context);
    try {
      final copied =
          await ref.read(nutritionDaoProvider).copyDayLogs(from, date);
      // Reaktif provider'lar (H-05) kopyalanan öğünleri kendiliğinden yansıtır.
      messenger.clearSnackBars();
      messenger.showSnackBar(SnackBar(
        content: Text(copied == 0
            ? l.nutritionCopyEmpty
            : l.nutritionCopied(copied)),
      ));
    } catch (_) {
      messenger.showSnackBar(
          SnackBar(content: Text(l.nutritionCopyFailed)));
    }
  }

  void _showAddFoodSheet(BuildContext context, WidgetRef ref,
      {String? mealType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colors.surface,
      builder: (ctx) =>
          _AddFoodSheet(mealType: mealType ?? 'lunch'),
    );
  }
}

class _DateBar extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  const _DateBar({
    required this.date,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _DateNavButton(
          tooltip: l.nutritionPrevDay,
          icon: Icons.chevron_left_rounded,
          onPressed: onPrev,
        ),
        Column(
          children: [
            Text(isToday ? l.commonToday : context.dateFmt('EEEE').format(date),
                style: context.texts.titleMedium),
            Text(context.dateFmt('d MMMM').format(date),
                style: context.texts.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ),
        _DateNavButton(
          tooltip: l.nutritionNextDay,
          icon: Icons.chevron_right_rounded,
          onPressed: onNext,
        ),
      ],
    );
  }
}

/// Tarih gezinme oku — tasarım diline uyumlu yumuşak indigo yuvarlak buton
/// (hafif gradient geçiş + ince kenar). Pasifken (bugüne gelince "sonraki")
/// soluk gri tona düşer. `filledTonal`'ın getirdiği baskın secondaryContainer
/// (açık temada mint yeşili) yerine gelir.
class _DateNavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  const _DateNavButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final tint = enabled ? context.colors.primary : context.colors.outline;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint.withValues(alpha: enabled ? 0.20 : 0.08),
                  tint.withValues(alpha: enabled ? 0.10 : 0.04),
                ],
              ),
              border: Border.all(color: tint.withValues(alpha: 0.14)),
            ),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(child: Icon(icon, color: tint, size: 22)),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  final DailyNutrition totals;
  final int kcalGoal;
  final int proteinGoal;

  const _SummaryHero({
    required this.totals,
    required this.kcalGoal,
    required this.proteinGoal,
  });

  @override
  Widget build(BuildContext context) {
    // Karb/yağ hedefi kaloriden türetilir — "hedefsiz çıplak sayı" kalmasın.
    final derived =
        deriveMacroGoals(kcalGoal: kcalGoal, proteinGoal: proteinGoal);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            CalorieRing(consumed: totals.kcal, goal: kcalGoal),
            AppSpacing.vGapSm,
            Text('${totals.kcal.round()} / $kcalGoal kcal',
                style: context.texts.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
            AppSpacing.vGapXl,
            MacroBar(
              label: AppL10n.of(context).macroProtein,
              current: totals.protein,
              goal: proteinGoal,
              unit: 'g',
              color: context.semantic.macroProtein,
            ),
            AppSpacing.vGapMd,
            MacroBar(
              label: AppL10n.of(context).macroCarbs,
              current: totals.carb,
              goal: derived.carb,
              unit: 'g',
              color: context.semantic.macroCarbs,
            ),
            AppSpacing.vGapMd,
            MacroBar(
              label: AppL10n.of(context).macroFat,
              current: totals.fat,
              goal: derived.fat,
              unit: 'g',
              color: context.semantic.macroFat,
            ),
          ],
        ),
      ),
    );
  }
}


String _mealName(AppL10n l, String type) => switch (type) {
      'breakfast' => l.mealBreakfast,
      'lunch' => l.mealLunch,
      'dinner' => l.mealDinner,
      'snack' => l.mealSnack,
      _ => type,
    };

IconData _mealIcon(String type) => switch (type) {
      'breakfast' => Icons.bakery_dining_rounded,
      'lunch' => Icons.lunch_dining_rounded,
      'dinner' => Icons.dinner_dining_rounded,
      'snack' => Icons.cookie_rounded,
      _ => Icons.restaurant_rounded,
    };

class _MealSection extends StatelessWidget {
  final String mealType;
  final List<FoodLogWithFood> items;
  final VoidCallback onAddFood;
  final void Function(FoodLogWithFood) onDelete;

  const _MealSection({
    required this.mealType,
    required this.items,
    required this.onAddFood,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final totalKcal =
        items.fold<double>(0, (sum, i) => sum + i.log.computedKcal);

    return Card(
      child: Padding(
        padding: AppSpacing.cardCompact,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color:
                        context.colors.secondary.withValues(alpha: 0.14),
                    borderRadius: AppRadius.brSm,
                  ),
                  child: Icon(_mealIcon(mealType),
                      size: AppIconSize.sm,
                      color: context.colors.secondary),
                ),
                AppSpacing.hGapMd,
                Text(_mealName(l, mealType),
                    style: context.texts.titleSmall),
                const Spacer(),
                if (totalKcal > 0)
                  Text('${totalKcal.round()} kcal',
                      style: context.texts.labelMedium?.copyWith(
                          color: context.colors.onSurfaceVariant)),
                IconButton(
                  tooltip: l.nutritionAddTo(_mealName(l, mealType)),
                  icon: const Icon(Icons.add_rounded),
                  onPressed: onAddFood,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(
                    left: AppSpacing.xs, bottom: AppSpacing.sm),
                child: Text(l.nutritionNoEntries,
                    style: context.texts.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant)),
              )
            else
              ...items.map((item) => _FoodLogRow(
                    item: item,
                    onDelete: () => onDelete(item),
                  )),
          ],
        ),
      ),
    );
  }
}

/// Tek kayıt satırı: yemek adı + gram + kcal + makro, görünür sil butonu.
/// Hem buton hem kaydırma ile silinir (kaydırma keşfedilebilir değil tek
/// başına — açık buton şart).
class _FoodLogRow extends StatelessWidget {
  final FoodLogWithFood item;
  final VoidCallback onDelete;

  const _FoodLogRow({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final log = item.log;
    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.colors.error,
          borderRadius: AppRadius.brMd,
        ),
        child: Icon(Icons.delete_rounded, color: context.colors.onError),
      ),
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.food.name,
                      style: context.texts.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  AppSpacing.vGapXs,
                  MacroInlineText(
                    protein: log.computedProtein,
                    carb: log.computedCarb,
                    fat: log.computedFat,
                    prefix: '${log.grams.round()} g  ·  ',
                  ),
                ],
              ),
            ),
            AppSpacing.hGapSm,
            Text('${log.computedKcal.round()} kcal',
                style: context.texts.titleSmall),
            IconButton(
              tooltip: AppL10n.of(context).commonDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: context.colors.onSurfaceVariant,
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ConsumerStatefulWidget (M-06): WidgetRef'i parametre olarak taşımak
// anti-pattern — üst ekran dispose olursa ref ölür. Sheet kendi ref'ini alır.
class _AddFoodSheet extends ConsumerStatefulWidget {
  final String mealType;

  const _AddFoodSheet({required this.mealType});

  @override
  ConsumerState<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends ConsumerState<_AddFoodSheet> {
  final _searchController = TextEditingController();
  final _gramsController = TextEditingController(text: '100');
  final _unitController = TextEditingController(text: '1');
  List<Food> _all = [];
  List<Food> _recent = [];
  List<Food> _results = [];
  Food? _selected;
  double _grams = 100;
  // Birim modu: yemeğin unitLabel'i varsa adet/dilim ile gir; gram = adet ×
  // defaultPortionGrams. _grams loglama için tek doğruluk kaynağı kalır.
  bool _useUnit = false;
  double _units = 1;
  String _currentMealType = 'lunch';
  bool _saving = false;
  int _sessionCount = 0;
  String? _lastAdded;
  // OpenFoodFacts metin araması (docs/11): paketli ürünü adıyla bul.
  bool _offSearching = false;
  List<OffProduct> _offResults = const [];
  String _offQuery = '';

  bool _hasUnit(Food f) =>
      f.unitLabel != null && (f.defaultPortionGrams ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    _currentMealType = widget.mealType;
    _loadAllFoods();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gramsController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _setGrams(double g) {
    final clamped = g.clamp(1.0, 3000.0);
    setState(() => _grams = clamped);
    final txt = clamped.round().toString();
    if (_gramsController.text != txt) _gramsController.text = txt;
  }

  /// Yemek seçilince: birimi varsa adet moduna geç (1 birim), yoksa 100 g.
  void _selectFood(Food food) {
    setState(() {
      _selected = food;
      if (_hasUnit(food)) {
        _useUnit = true;
        _units = 1;
        _grams = food.defaultPortionGrams!;
        _unitController.text = '1';
      } else {
        _useUnit = false;
        _grams = 100;
        _gramsController.text = '100';
      }
    });
  }

  void _setUnits(double u) {
    final clamped = u.clamp(0.25, 99.0);
    final portion = _selected?.defaultPortionGrams ?? 100;
    setState(() {
      _units = clamped;
      _grams = (clamped * portion).clamp(1.0, 5000.0);
    });
    final txt = clamped == clamped.roundToDouble()
        ? clamped.round().toString()
        : clamped.toString();
    if (_unitController.text != txt) _unitController.text = txt;
  }

  void _bumpUnits(double delta) => _setUnits(_units + delta);

  void _setUnitMode(bool useUnit) {
    if (_selected == null) return;
    setState(() => _useUnit = useUnit);
    if (useUnit) {
      _setUnits(_units);
    } else {
      _setGrams(_grams);
    }
  }

  /// TÜM yemekleri yükler (artık 30 ile sınırlı DEĞİL). Özel (custom)
  /// yemekler en üstte, sonra alfabetik.
  Future<void> _loadAllFoods() async {
    final dao = ref.read(nutritionDaoProvider);
    final foods = await dao.getAllFoods();
    final recent = await dao.getRecentFoods();
    foods.sort((a, b) {
      if (a.isCustom != b.isCustom) return a.isCustom ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    if (mounted) {
      setState(() {
        _all = foods;
        _recent = recent;
        _applyFilter(_searchController.text);
      });
    }
  }

  void _applyFilter(String query) {
    final q = query.trim().toLowerCase();
    _results = q.isEmpty
        ? _all
        : _all.where((f) => f.name.toLowerCase().contains(q)).toList();
  }

  void _bumpGrams(double delta) => _setGrams(_grams + delta);

  /// Ekler ama SAYFAYI KAPATMAZ — kullanıcı bir öğüne arka arkaya birden
  /// fazla şey girebilsin (1 avokado + 3 yumurta + 50g peynir...).
  /// Bitince üstteki ✕ ile kapatır.
  Future<void> _addFood() async {
    if (_selected == null || _saving) return;
    setState(() => _saving = true);
    final added = _selected!;
    final addedGrams = _grams;
    final addedLabel = _useUnit && _hasUnit(added)
        ? '${fmtNum(_units)} ${added.unitLabel}'
        : '${addedGrams.round()} g';
    final ratio = addedGrams / 100;
    final date = ref.read(selectedDateProvider);
    try {
      await ref
          .read(nutritionDaoProvider)
          .insertFoodLog(FoodLogsCompanion(
            date: Value(date),
            mealType: Value(_currentMealType),
            foodId: Value(added.id),
            grams: Value(addedGrams),
            computedKcal: Value(added.kcalPer100g * ratio),
            computedProtein: Value(added.proteinPer100g * ratio),
            computedCarb: Value(added.carbPer100g * ratio),
            computedFat: Value(added.fatPer100g * ratio),
          ));
      // Reaktif provider'lar (H-05) yeni öğünü kendiliğinden yansıtır.
      HapticFeedback.lightImpact();
      if (mounted) {
        setState(() {
          _saving = false;
          _sessionCount++;
          _lastAdded = '${added.name} ($addedLabel)';
          _selected = null;
          _grams = 100;
          _useUnit = false;
          _units = 1;
        });
        _gramsController.text = '100';
        _unitController.text = '1';
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppL10n.of(context).nutritionAddFailed),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  /// OpenFoodFacts'te ada göre ara (paketli ürünler — Canga, Ülker...).
  Future<void> _searchOff() async {
    final q = _searchController.text.trim();
    if (q.length < 2 || _offSearching) return;
    FocusScope.of(context).unfocus();
    setState(() => _offSearching = true);
    final results =
        await ref.read(openFoodFactsServiceProvider).searchByName(q);
    if (!mounted) return;
    setState(() {
      _offSearching = false;
      _offResults = results;
      _offQuery = q;
    });
    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context).nutritionOffNoResults)),
      );
    }
  }

  /// OFF sonucunu DB'ye yaz (varsa barkoddan bul) → seç. Tekrar eklemeyi önler.
  Future<void> _pickOffProduct(OffProduct p) async {
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
      if (!_all.any((f) => f.id == food!.id)) _all = [food!, ..._all];
      _offResults = const [];
    });
    _selectFood(food);
  }

  /// Barkod tara → lokal/OpenFoodFacts çöz → seç.
  Future<void> _scanBarcode() async {
    final food = await scanBarcodeToFood(context, ref);
    if (food == null || !mounted) return;
    setState(() {
      if (!_all.any((f) => f.id == food.id)) _all = [food, ..._all];
      _searchController.clear();
      _applyFilter('');
    });
    _selectFood(food);
  }

  Future<void> _openCustomFood() async {
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
      _all = [food, ..._all];
      _searchController.clear();
      _applyFilter('');
    });
    _selectFood(food);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final subtitle = _sessionCount == 0
        ? l.nutritionMultiAddHint
        : l.nutritionSessionAdded(_sessionCount, _lastAdded ?? '');
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
          ),
          child: Column(
            children: [
              SheetHeader(title: l.nutritionAddFood, subtitle: subtitle),
              AppSpacing.vGapSm,
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                      value: 'breakfast', label: Text(l.mealBreakfast)),
                  ButtonSegment(value: 'lunch', label: Text(l.mealLunch)),
                  ButtonSegment(value: 'dinner', label: Text(l.mealDinner)),
                  ButtonSegment(
                      value: 'snack', label: Text(l.mealSnackShort)),
                ],
                selected: {_currentMealType},
                onSelectionChanged: (v) =>
                    setState(() => _currentMealType = v.first),
              ),
              AppSpacing.vGapMd,
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: l.nutritionSearchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _applyFilter(''));
                                },
                              ),
                      ),
                      onChanged: (v) => setState(() {
                        _applyFilter(v);
                        if (_offResults.isNotEmpty) _offResults = const [];
                      }),
                    ),
                  ),
                  AppSpacing.hGapSm,
                  IconButton.filledTonal(
                    tooltip: l.nutritionScanBarcode,
                    onPressed: _scanBarcode,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                  ),
                  AppSpacing.hGapSm,
                  IconButton.filledTonal(
                    tooltip: l.nutritionAddCustom,
                    onPressed: _openCustomFood,
                    icon: const Icon(Icons.edit_note_rounded),
                  ),
                ],
              ),
              // Paketli ürünü adıyla internette ara (OpenFoodFacts).
              if (_searchController.text.trim().length >= 2) ...[
                AppSpacing.vGapSm,
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _offSearching ? null : _searchOff,
                    icon: _offSearching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.travel_explore_rounded,
                            size: AppIconSize.sm),
                    label: Text(_offSearching
                        ? l.nutritionOffSearching
                        : l.nutritionOffSearchFor(
                            _searchController.text.trim())),
                  ),
                ),
              ],
              // Son kullanılanlar — arama boşken tek dokunuşla seç.
              if (_recent.isNotEmpty && _searchController.text.isEmpty) ...[
                AppSpacing.vGapMd,
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recent.length,
                    separatorBuilder: (_, _) => AppSpacing.hGapSm,
                    itemBuilder: (context, i) {
                      final food = _recent[i];
                      return ActionChip(
                        avatar: Icon(Icons.history_rounded,
                            size: 16,
                            color: context.colors.onSurfaceVariant),
                        label: Text(food.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _selectFood(food),
                      );
                    },
                  ),
                ),
              ],
              // OpenFoodFacts internet sonuçları (paketli ürünler).
              if (_offResults.isNotEmpty) ...[
                AppSpacing.vGapMd,
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l.nutritionOffHeader(_offQuery, _offResults.length),
                    style: context.texts.labelMedium
                        ?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ),
                AppSpacing.vGapSm,
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _offResults.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = _offResults[i];
                      return ListTile(
                        dense: true,
                        leading: Icon(Icons.public_rounded,
                            size: AppIconSize.sm,
                            color: context.colors.primary),
                        title: Text(p.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: MacroInlineText(
                          protein: p.proteinPer100g,
                          carb: p.carbPer100g,
                          fat: p.fatPer100g,
                          prefix: '${p.kcalPer100g.round()} kcal · ',
                          suffix: ' /100g',
                        ),
                        trailing: const Icon(Icons.add_rounded),
                        onTap: () => _pickOffProduct(p),
                      );
                    },
                  ),
                ),
                const Divider(height: AppSpacing.lg),
              ],
              AppSpacing.vGapMd,
              Expanded(
                child: _results.isEmpty
                    ? _EmptyResults(
                        query: _searchController.text,
                        onCreate: _openCustomFood,
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: _results.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final food = _results[index];
                          final isSelected = _selected?.id == food.id;
                          return ListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.brMd),
                            title: Row(
                              children: [
                                Flexible(child: Text(food.name)),
                                if (food.isCustom) ...[
                                  AppSpacing.hGapSm,
                                  Icon(Icons.person_rounded,
                                      size: AppIconSize.sm,
                                      color: context.colors.secondary),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                MacroInlineText(
                                  protein: food.proteinPer100g,
                                  carb: food.carbPer100g,
                                  fat: food.fatPer100g,
                                  prefix:
                                      '${food.kcalPer100g.round()} kcal · ',
                                  suffix: ' /100g',
                                ),
                                if (food.unitLabel != null &&
                                    (food.defaultPortionGrams ?? 0) > 0)
                                  Text(
                                    l.nutritionUnitApprox(food.unitLabel!,
                                        food.defaultPortionGrams!.round()),
                                    style: context.texts.labelSmall
                                        ?.copyWith(
                                            color:
                                                context.colors.secondary),
                                  ),
                              ],
                            ),
                            selected: isSelected,
                            selectedTileColor: context.colors.primary
                                .withValues(alpha: 0.12),
                            trailing: isSelected
                                ? Icon(Icons.check_circle_rounded,
                                    color: context.colors.primary)
                                : const Icon(
                                    Icons.add_circle_outline_rounded),
                            onTap: () => _selectFood(food),
                          );
                        },
                      ),
              ),
              if (_selected != null) _QuantityFooter(
                food: _selected!,
                grams: _grams,
                hasUnit: _hasUnit(_selected!),
                useUnit: _useUnit,
                units: _units,
                gramsController: _gramsController,
                unitController: _unitController,
                saving: _saving,
                onBumpGrams: _bumpGrams,
                onSetGrams: _setGrams,
                onBumpUnits: _bumpUnits,
                onSetUnits: _setUnits,
                onSetUnitMode: _setUnitMode,
                onAdd: _addFood,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final String query;
  final VoidCallback onCreate;
  const _EmptyResults({required this.query, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return EmptyState(
      icon: Icons.no_food_rounded,
      title: query.isEmpty ? l.nutritionNoFoods : l.nutritionNotFound(query),
      message: l.nutritionNotInListHint,
      actionLabel: l.nutritionAddCustom,
      onAction: onCreate,
      compact: true,
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

/// Custom yemek + Yemekler ekranında ortak birim seçenekleri (docs/14 —
/// locale'e göre). Seçilen etiket yemeğin `unitLabel`'ına YAZILIR (içerik):
/// eski/karışık dilde kayıtlı etiketler için çağıran taraf, mevcut değeri
/// listeye ekleyerek dropdown'ı korur ([unitOptionsWith]).
List<String> unitOptions(AppL10n l) => [
      l.unitPortion,
      l.unitPiece,
      l.unitSlice,
      l.unitBowl,
      l.unitWaterGlass,
      l.unitCup,
      l.unitTablespoon,
      l.unitHandful,
      l.unitClove,
      l.unitScoop,
      l.unitCan,
    ];

/// Seçenekler + (listede olmayan) mevcut kayıtlı birim — dropdown value'su
/// items'ta yoksa Flutter assert atar; farklı dilde kaydedilmiş birimler
/// böyle korunur.
List<String> unitOptionsWith(AppL10n l, String? current) {
  final options = unitOptions(l);
  if (current != null && !options.contains(current)) {
    return [current, ...options];
  }
  return options;
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

/// Seçili yemek için miktar (adet/birim VEYA gram) + canlı kalori + Ekle.
/// Yemeğin birimi varsa adet/g geçişi; gram her zaman tek doğruluk kaynağı.
class _QuantityFooter extends StatelessWidget {
  final Food food;
  final double grams;
  final bool hasUnit;
  final bool useUnit;
  final double units;
  final TextEditingController gramsController;
  final TextEditingController unitController;
  final bool saving;
  final void Function(double) onBumpGrams;
  final void Function(double) onSetGrams;
  final void Function(double) onBumpUnits;
  final void Function(double) onSetUnits;
  final void Function(bool) onSetUnitMode;
  final VoidCallback onAdd;

  const _QuantityFooter({
    required this.food,
    required this.grams,
    required this.hasUnit,
    required this.useUnit,
    required this.units,
    required this.gramsController,
    required this.unitController,
    required this.saving,
    required this.onBumpGrams,
    required this.onSetGrams,
    required this.onBumpUnits,
    required this.onSetUnits,
    required this.onSetUnitMode,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final ratio = grams / 100;
    final kcal = (food.kcalPer100g * ratio).round();
    final unitMode = hasUnit && useUnit;
    final unitLabel = food.unitLabel ?? l.unitPiece;
    final summary = unitMode
        ? '$kcal kcal · ${fmtNum(units)} $unitLabel ≈ ${grams.round()} g'
        : '$kcal kcal · ${grams.round()} g';

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(food.name,
                        style: context.texts.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(summary,
                        style: context.texts.labelMedium?.copyWith(
                            color: context.semantic.macroCalories,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              if (hasUnit)
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap),
                  segments: [
                    ButtonSegment(
                        value: true, label: Text(unitLabel)),
                    const ButtonSegment(
                        value: false, label: Text('g')),
                  ],
                  selected: {useUnit},
                  onSelectionChanged: (v) =>
                      onSetUnitMode(v.first),
                ),
            ],
          ),
          AppSpacing.vGapMd,
          if (unitMode)
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: '-1 $unitLabel',
                  onPressed:
                      units > 0.25 ? () => onBumpUnits(-1) : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm),
                    child: TextField(
                      controller: unitController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]')),
                      ],
                      decoration: InputDecoration(
                          suffixText: unitLabel, isDense: true),
                      onChanged: (v) {
                        final u = double.tryParse(
                            v.replaceAll(',', '.'));
                        if (u != null && u >= 0.25 && u <= 99) {
                          onSetUnits(u);
                        }
                      },
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: '+1 $unitLabel',
                  onPressed:
                      units < 99 ? () => onBumpUnits(1) : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            )
          else
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: '-10 g',
                  onPressed:
                      grams > 1 ? () => onBumpGrams(-10) : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm),
                    child: TextField(
                      controller: gramsController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                          suffixText: 'g', isDense: true),
                      onChanged: (v) {
                        final g = double.tryParse(v);
                        if (g != null && g >= 1 && g <= 3000) {
                          onSetGrams(g);
                        }
                      },
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: '+10 g',
                  onPressed:
                      grams < 3000 ? () => onBumpGrams(10) : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          AppSpacing.vGapMd,
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: saving ? null : onAdd,
              icon: saving
                  ? SizedBox(
                      width: AppIconSize.sm,
                      height: AppIconSize.sm,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colors.onPrimary),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(saving ? l.nutritionAdding : l.commonAdd),
            ),
          ),
        ],
      ),
    );
  }
}
