import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'macro_goals.dart';
import 'meal_copy_sheet.dart';
import 'add_food_sheet.dart';
import 'meal_types.dart';
import 'nutrition_habit_widgets.dart';

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
            // Beslenme + İlerleme FAB'ları sekme yığınında birlikte canlı
            // (IndexedStack) — varsayılan ortak hero etiketi sayfa geçişinde
            // "multiple heroes share the same tag" hatası veriyordu.
            heroTag: null,
            onPressed: () => _showAddFoodSheet(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: Text(l.nutritionAddFood),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _invalidateAll(ref),
        child: ListView(
          // Alt boşluk: içerik buzlu gezinme çubuğunun altından akar + FAB
          // payı (C-2) — son öğün kartı "Yemek Ekle"nin altında kalmasın.
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg,
              AppSpacing.lg, context.fabScrollInset),
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
            // Kayıt alışkanlığı (docs/26) — yalnız bugün: haftalık hedef,
            // "her zamanki öğün" tek dokunuş, hatırlatıcı önerisi.
            if (isToday) ...[
              AppSpacing.vGapMd,
              const LogWeekLineText(),
              AppSpacing.vGapMd,
              const UsualMealCard(),
              const MealReminderCta(),
            ] else
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
                        onPressed: ref.watch(copyDayBusyProvider)
                            ? null
                            : () => _copyYesterday(context, ref),
                        icon: const Icon(Icons.content_copy_rounded,
                            size: AppIconSize.sm),
                        label: Text(isToday
                            ? l.nutritionCopyYesterday
                            : l.nutritionCopyPrevDay),
                      ),
                    ),
                  ...mealTypes.map((mealType) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _MealSection(
                            mealType: mealType,
                            items: logs
                                .where((l) => l.log.mealType == mealType)
                                .toList(),
                            onAddFood: () => _showAddFoodSheet(context, ref,
                                mealType: mealType),
                            onCopyFromDay: () => showMealCopySheet(
                              context,
                              mealType: mealType,
                              // Gün başına normalize: panel hedef günü
                              // listeden düşürmek için karşılaştırıyor.
                              targetDay:
                                  DateTime(date.year, date.month, date.day),
                            ),
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
    final busy = ref.read(copyDayBusyProvider.notifier);
    if (busy.state) return; // ikinci dokunuş
    busy.state = true;
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
    } finally {
      busy.state = false;
    }
  }

  void _showAddFoodSheet(BuildContext context, WidgetRef ref,
      {String? mealType}) {
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


class _MealSection extends StatelessWidget {
  final String mealType;
  final List<FoodLogWithFood> items;
  final VoidCallback onAddFood;
  final VoidCallback onCopyFromDay;
  final void Function(FoodLogWithFood) onDelete;

  const _MealSection({
    required this.mealType,
    required this.items,
    required this.onAddFood,
    required this.onCopyFromDay,
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
                  child: Icon(mealIcon(mealType),
                      size: AppIconSize.sm,
                      color: context.colors.secondary),
                ),
                AppSpacing.hGapMd,
                Text(mealName(l, mealType),
                    style: context.texts.titleSmall),
                const Spacer(),
                if (totalKcal > 0)
                  Text('${totalKcal.round()} kcal',
                      style: context.texts.labelMedium?.copyWith(
                          color: context.colors.onSurfaceVariant)),
                IconButton(
                  tooltip: l.nutritionAddTo(mealName(l, mealType)),
                  icon: const Icon(Icons.add_rounded),
                  onPressed: onAddFood,
                  visualDensity: VisualDensity.compact,
                ),
                // Öğün düzeyinde kopyalama (docs/21 #2): gün boş olmasa da
                // çalışır — mevcut öğüne EKLER.
                PopupMenuButton<String>(
                  tooltip: l.nutritionMealMenu,
                  icon: const Icon(Icons.more_horiz_rounded),
                  onSelected: (_) => onCopyFromDay(),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'copy',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.copy_all_rounded,
                            size: AppIconSize.sm),
                        title: Text(l.nutritionCopyFromDay),
                      ),
                    ),
                  ],
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
                    // Hızlı girişte gram anlamsız (100 g = girilen değer).
                    prefix: item.food.source == quickFoodSource
                        ? '${AppL10n.of(context).nhQuickEntry}  ·  '
                        : '${log.grams.round()} g  ·  ',
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
