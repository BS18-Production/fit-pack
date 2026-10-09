import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/nutrition_theme.dart';
import '../../core/i18n/formatting.dart';
import '../../core/onboarding/first_run_hints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/nutrition_dao.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/progress_indicators.dart';
import '../home/providers/home_providers.dart';
import 'warm_nutrition_summary.dart';
import 'meal_copy_sheet.dart';
import 'add_food_sheet.dart';
import 'meal_types.dart';
import 'nutrition_habit_widgets.dart';
import '../../shared/widgets/fitpack_icon.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// "Dünü kopyala" sürüyor mu. Düğme yalnız gün boşken görünür ve kopyalama
/// bitene kadar ekran tazelenmez → hızlı iki dokunuş iki kopya başlatabiliyordu
/// (dış inceleme 2026-09-15, #12). DAO tarafında da hedef kontrolü var; bu
/// bayrak kullanıcıya düğmeyi sönük gösterip ikinci dokunuşu hiç başlatmaz.
final copyDayBusyProvider = StateProvider<bool>((ref) => false);

/// Kayıtlar + yemek adı (join). **Reaktif** (H-05): öğün eklenince/silinince
/// kendiliğinden tazelenir. Seçili gün değişince provider yeniden kurulur.
final logsWithFoodProvider = StreamProvider<List<FoodLogWithFood>>((ref) {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedDateProvider);
  return watchTables(db, [
    db.foodLogs,
    db.foods,
  ], () => ref.read(nutritionDaoProvider).getLogsWithFoodForDate(date));
});

final nutritionTotalsProvider = StreamProvider<DailyNutrition>((ref) {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedDateProvider);
  return watchTables(db, [
    db.foodLogs,
    db.foods,
  ], () => ref.read(nutritionDaoProvider).getDailyTotals(date));
});

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});
  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  bool _showMacros = false;

  void _invalidateAll(WidgetRef ref) {
    ref.invalidate(logsWithFoodProvider);
    ref.invalidate(nutritionTotalsProvider);
    ref.invalidate(todayNutritionProvider);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    FoodLogWithFood item,
  ) async {
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
    messenger.showSnackBar(
      SnackBar(
        content: Text(l.foodsDeleted(item.food.name)),
        // Flutter 3.41'de düğmeli SnackBar varsayılan olarak kapanmıyor
        // (persist = action != null) — "silindi" şeridi ekranda kalıyordu.
        persist: false,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: NutritionTheme.of(Theme.of(context)),
    child: Builder(builder: _buildPage),
  );

  Widget _buildPage(BuildContext context) {
    final date = ref.watch(selectedDateProvider);
    final totalsAsync = ref.watch(nutritionTotalsProvider);
    final logsAsync = ref.watch(logsWithFoodProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    final l = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        actionsPadding: const EdgeInsets.only(right: AppSpacing.lg),
        toolbarHeight:
            76 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.6),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FIT PACK',
              style: context.texts.labelSmall?.copyWith(
                color: context.colors.secondary,
                letterSpacing: 2,
              ),
            ),
            AppSpacing.vGapXs,
            Text(l.navNutrition, style: context.texts.headlineMedium),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l.nutritionPickDate,
            style: IconButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.brControl,
              ),
              backgroundColor: context.colors.secondaryContainer,
              foregroundColor: context.colors.secondary,
            ),
            icon: const FitPackIcon.material(Icons.calendar_today_rounded),
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
      // extendBody ile gelen gezinme payı ayrılır; eylemler listeye binmez.
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          MediaQuery.paddingOf(context).bottom + AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: CoachMark(
                hint: FirstRunHint.nutrition,
                message: (l) => l.hintNutrition,
                child: FilledButton.icon(
                  key: const ValueKey('nutrition.addFood'),
                  onPressed: () => _showAddFoodSheet(context, ref),
                  icon: const FitPackIcon.material(Icons.add_rounded),
                  label: Text(l.nutritionAddFood),
                ),
              ),
            ),
            AppSpacing.hGapSm,
            SizedBox.square(
              dimension: AppNavigation.primaryButtonHeight,
              child: IconButton.filledTonal(
                key: const ValueKey('nutrition.scan'),
                tooltip: l.nutritionScanBarcode,
                style: IconButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.brControl,
                  ),
                  backgroundColor: context.colors.surfaceContainerHigh,
                  foregroundColor: context.colors.secondary,
                ),
                onPressed: () =>
                    showAddFoodSheet(context, startWithBarcode: true),
                icon: const FitPackIcon.material(Icons.qr_code_scanner_rounded),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _invalidateAll(ref),
        child: ListView(
          // Alt boşluk: içerik buzlu gezinme çubuğunun altından akar + FAB
          // payı (C-2) — son öğün kartı "Yemek Ekle"nin altında kalmasın.
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            _DateBar(
              date: date,
              isToday: isToday,
              onPrev: () => ref.read(selectedDateProvider.notifier).state = date
                  .subtract(const Duration(days: 1)),
              onNext: isToday
                  ? null
                  : () => ref.read(selectedDateProvider.notifier).state = date
                        .add(const Duration(days: 1)),
            ),
            AppSpacing.vGapLg,
            totalsAsync.when(
              data: (totals) => profileAsync.maybeWhen(
                data: (profile) => WarmNutritionSummary(
                  totals: totals,
                  kcalGoal: profile?.kcalGoal ?? 2200,
                  proteinGoal: profile?.proteinGoal ?? 180,
                  onGoals: () => context.push(AppRoutes.settings),
                ),
                orElse: () => Skeleton.card(height: 280),
              ),
              loading: () => Skeleton.card(height: 280),
              error: (_, _) => const SizedBox.shrink(),
            ),
            AppSpacing.vGapXl,
            LayoutBuilder(
              builder: (context, constraints) {
                final toggle = TextButton(
                  key: const ValueKey('nutrition.macros'),
                  onPressed: () => setState(() => _showMacros = !_showMacros),
                  child: Text(
                    _showMacros ? l.nutritionHideMacros : l.nutritionShowMacros,
                  ),
                );
                final title = Text(
                  l.nutritionDiary,
                  style: context.texts.titleMedium,
                );
                if (constraints.maxWidth < 330 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.15) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, toggle],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: title),
                    toggle,
                  ],
                );
              },
            ),
            AppSpacing.vGapSm,
            logsAsync.when(
              loading: () => Column(
                children: [
                  Skeleton.card(height: 96),
                  AppSpacing.vGapMd,
                  Skeleton.card(height: 96),
                ],
              ),
              error: (_, _) => ErrorState(
                message: l.nutritionLoadError,
                onRetry: () => _invalidateAll(ref),
              ),
              data: (logs) {
                final latest = logs.isEmpty
                    ? null
                    : logs
                          .reduce((a, b) => a.log.id > b.log.id ? a : b)
                          .log
                          .mealType;
                return Column(
                  children: [
                    if (logs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: OutlinedButton.icon(
                          onPressed: ref.watch(copyDayBusyProvider)
                              ? null
                              : () => _copyYesterday(context, ref),
                          icon: const FitPackIcon.material(
                            Icons.content_copy_rounded,
                            size: AppIconSize.sm,
                          ),
                          label: Text(
                            isToday
                                ? l.nutritionCopyYesterday
                                : l.nutritionCopyPrevDay,
                          ),
                        ),
                      ),
                    ...mealTypes.map(
                      (mealType) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _MealSection(
                          key: ValueKey(
                            '${date.year}-${date.month}-${date.day}-$mealType',
                          ),
                          initiallyExpanded: latest == mealType,
                          showMacros: _showMacros,
                          showUsual: isToday,
                          mealType: mealType,
                          items: logs
                              .where((l) => l.log.mealType == mealType)
                              .toList(),
                          onAddFood: () => _showAddFoodSheet(
                            context,
                            ref,
                            mealType: mealType,
                          ),
                          onCopyFromDay: () => showMealCopySheet(
                            context,
                            mealType: mealType,
                            // Gün başına normalize: panel hedef günü
                            // listeden düşürmek için karşılaştırıyor.
                            targetDay: DateTime(
                              date.year,
                              date.month,
                              date.day,
                            ),
                          ),
                          onDelete: (item) => _delete(context, ref, item),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (isToday) ...[
              AppSpacing.vGapMd,
              const LogWeekLineText(),
              AppSpacing.vGapMd,
              const MealReminderCta(),
            ],
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
    final busy = ref.read(copyDayBusyProvider.notifier);
    if (busy.state) return; // ikinci dokunuş
    busy.state = true;
    try {
      final copied = await ref
          .read(nutritionDaoProvider)
          .copyDayLogs(from, date);
      // Reaktif provider'lar (H-05) kopyalanan öğünleri kendiliğinden yansıtır.
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            copied == 0 ? l.nutritionCopyEmpty : l.nutritionCopied(copied),
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.nutritionCopyFailed)));
    } finally {
      busy.state = false;
    }
  }

  void _showAddFoodSheet(
    BuildContext context,
    WidgetRef ref, {
    String? mealType,
  }) {
    showAddFoodSheet(context, mealType: mealType);
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
            Text(
              isToday ? l.commonToday : context.dateFmt('EEEE').format(date),
              style: context.texts.titleMedium,
            ),
            Text(
              context.dateFmt('d MMMM').format(date),
              style: context.texts.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
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
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: FitPackIcon.material(icon),
      color: context.colors.secondary,
    );
  }
}

/// Yerel aç/kapa durumu DB'ye yazılmaz. Yeni kayıt eklenen öğün açılır;
/// başka öğündeki güncelleme kullanıcının daraltma seçimini değiştirmez.
class _MealSection extends StatefulWidget {
  final String mealType;
  final List<FoodLogWithFood> items;
  final bool initiallyExpanded, showMacros, showUsual;
  final VoidCallback onAddFood, onCopyFromDay;
  final void Function(FoodLogWithFood) onDelete;
  const _MealSection({
    super.key,
    required this.mealType,
    required this.items,
    required this.initiallyExpanded,
    required this.showMacros,
    required this.showUsual,
    required this.onAddFood,
    required this.onCopyFromDay,
    required this.onDelete,
  });
  @override
  State<_MealSection> createState() => _MealSectionState();
}

class _MealSectionState extends State<_MealSection> {
  late bool _expanded;
  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant _MealSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.items.map((i) => i.log.id).toSet();
    if (widget.items.any((i) => !previous.contains(i.log.id))) _expanded = true;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final total = widget.items.fold<double>(
      0,
      (s, i) => s + i.log.computedKcal,
    );
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.15;
    final reading = Text(
      '${context.numFmt.format(total.round())} kcal',
      style: context.texts.labelMedium?.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Semantics(
                button: widget.items.isNotEmpty,
                expanded: widget.items.isNotEmpty ? _expanded : null,
                child: InkWell(
                  key: ValueKey('nutrition.meal.${widget.mealType}'),
                  borderRadius: AppRadius.brControl,
                  onTap: widget.items.isEmpty
                      ? null
                      : () => setState(() => _expanded = !_expanded),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppA11y.minTapTarget,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mealName(l, widget.mealType),
                            style: context.texts.titleMedium,
                          ),
                          AppSpacing.vGapXs,
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  l.nutritionFoodCount(widget.items.length),
                                  style: context.texts.bodySmall?.copyWith(
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              if (widget.items.isNotEmpty) ...[
                                AppSpacing.hGapXs,
                                FitPackIcon.material(
                                  _expanded
                                      ? Icons.expand_less_rounded
                                      : Icons.expand_more_rounded,
                                  size: AppIconSize.sm,
                                ),
                              ],
                            ],
                          ),
                          if (large) ...[AppSpacing.vGapXs, reading],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!large) ...[AppSpacing.hGapSm, reading],
            IconButton(
              tooltip: l.nutritionAddTo(mealName(l, widget.mealType)),
              style: IconButton.styleFrom(
                foregroundColor: context.colors.secondary,
              ),
              icon: const FitPackIcon.material(Icons.add_rounded),
              onPressed: widget.onAddFood,
            ),
            PopupMenuButton<String>(
              tooltip: l.nutritionMealMenu,
              icon: const FitPackIcon.material(Icons.more_horiz_rounded),
              onSelected: (_) => widget.onCopyFromDay(),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'copy',
                  child: Text(l.nutritionCopyFromDay),
                ),
              ],
            ),
          ],
        ),
        if (_expanded)
          ...widget.items.map(
            (item) => _FoodLogRow(
              key: ValueKey(item.log.id),
              item: item,
              showMacros: widget.showMacros,
              onDelete: () => widget.onDelete(item),
            ),
          ),
        if (widget.showUsual)
          UsualMealCard(mealType: widget.mealType, compact: true),
      ],
    );
  }
}

/// Tek kayıt satırı: yemek adı + gram + kcal + makro, görünür sil butonu.
/// Hem buton hem kaydırma ile silinir (kaydırma keşfedilebilir değil tek
/// başına — açık buton şart).
class _FoodLogRow extends StatelessWidget {
  final FoodLogWithFood item;
  final VoidCallback onDelete;
  final bool showMacros;

  const _FoodLogRow({
    super.key,
    required this.item,
    required this.onDelete,
    required this.showMacros,
  });

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
        child: FitPackIcon.material(
          Icons.delete_rounded,
          color: context.colors.onError,
        ),
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
                  Text(
                    item.food.name,
                    style: context.texts.bodyLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.vGapXs,
                  Text(
                    item.food.source == quickFoodSource
                        ? AppL10n.of(context).nhQuickEntry
                        : '${context.numFmt.format(log.grams.round())} g',
                    style: context.texts.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  if (showMacros) ...[
                    AppSpacing.vGapXs,
                    MacroInlineText(
                      protein: log.computedProtein,
                      carb: log.computedCarb,
                      fat: log.computedFat,
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.hGapSm,
            Text(
              '${context.numFmt.format(log.computedKcal.round())}\nkcal',
              textAlign: TextAlign.end,
              style: context.texts.labelMedium,
            ),
            IconButton(
              tooltip: AppL10n.of(context).commonDelete,
              icon: const FitPackIcon.material(Icons.delete_outline_rounded),
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
