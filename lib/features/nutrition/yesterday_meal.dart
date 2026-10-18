import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/current_day.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';
import '../../data/database/daos/nutrition_dao.dart';
import '../../l10n/app_l10n.dart';
import 'nutrition_providers.dart';

final yesterdayMealsProvider = StreamProvider<List<FoodLogWithFood>>((ref) {
  final day = ref.watch(selectedDateProvider);
  final db = ref.watch(databaseProvider);
  return watchTables(db, [db.foodLogs, db.foods], () =>
      ref.read(nutritionDaoProvider).getLogsWithFoodForDate(addDays(day, -1)));
});

/// Yalnız hedef öğün boşken gösterilir; geri al sadece eklenen kimlikleri siler.
class YesterdayMealShortcut extends ConsumerStatefulWidget {
  final String mealType;
  const YesterdayMealShortcut({super.key, required this.mealType});
  @override
  ConsumerState<YesterdayMealShortcut> createState() => _YesterdayMealShortcutState();
}

class _YesterdayMealShortcutState extends ConsumerState<YesterdayMealShortcut> {
  bool _busy = false;
  Future<void> _copy(List<FoodLogWithFood> items) async {
    if (_busy) return;
    setState(() => _busy = true);
    final dao = ref.read(nutritionDaoProvider);
    final day = ref.read(selectedDateProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l = AppL10n.of(context);
    try {
      final ids = await dao.addFoodsToMealIds(day, widget.mealType, [
        for (final i in items) MealCopyItem(foodId: i.food.id, grams: i.log.grams),
      ]);
      messenger.showSnackBar(SnackBar(
        content: Text(l.nutritionCopied(ids.length)), persist: false,
        action: SnackBarAction(label: l.commonUndo, onPressed: () async {
          try { await dao.deleteFoodLogs(ids); }
          catch (_) { messenger.showSnackBar(SnackBar(content: Text(l.commonDeleteFailed))); }
        }),
      ));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.nutritionCopyFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final items = ref.watch(yesterdayMealsProvider).valueOrNull
        ?.where((i) => i.log.mealType == widget.mealType).toList();
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    return TextButton.icon(
      key: ValueKey('nutrition.yesterday.${widget.mealType}'),
      onPressed: _busy ? null : () => _copy(items),
      icon: const Icon(Icons.history_rounded),
      label: Text(AppL10n.of(context).expYesterdayMeal),
    );
  }
}
