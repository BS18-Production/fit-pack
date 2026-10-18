import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/database/daos/nutrition_dao.dart';
import '../../data/providers.dart';
import '../../l10n/app_l10n.dart';
import 'add_food_sheet.dart';

Future<void> showEditFoodLogSheet(BuildContext context, FoodLogWithFood item) =>
    showModalBottomSheet<void>(
      context: context, useRootNavigator: true,
      isScrollControlled: true, useSafeArea: true,
      builder: (_) => _EditFoodLogSheet(item: item),
    );

class _EditFoodLogSheet extends ConsumerStatefulWidget {
  final FoodLogWithFood item;
  const _EditFoodLogSheet({required this.item});
  @override
  ConsumerState<_EditFoodLogSheet> createState() => _EditFoodLogSheetState();
}

class _EditFoodLogSheetState extends ConsumerState<_EditFoodLogSheet> {
  bool _saving = false;
  Future<void> _save(double grams) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(nutritionDaoProvider).updateFoodLogAmount(widget.item.log.id, grams);
      // Bütün okumalar foodLogs tablosunu reaktif izler (CONVENTIONS §2).
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppL10n.of(context).commonSaveFailed)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return PopScope(
      canPop: !_saving,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: context.sheetBottomInset),
        child: FoodAmountPanel(
          food: item.food.copyWith(
            kcalPer100g: item.log.computedKcal * 100 / item.log.grams,
            proteinPer100g: item.log.computedProtein * 100 / item.log.grams,
            carbPer100g: item.log.computedCarb * 100 / item.log.grams,
            fatPer100g: item.log.computedFat * 100 / item.log.grams,
          ),
          initial: (grams: item.log.grams,
            units: item.log.grams / (item.food.defaultPortionGrams ?? 100),
            unit: item.food.unitLabel),
          addLabel: AppL10n.of(context).expUpdate, saving: _saving,
          onClose: () { if (!_saving) Navigator.of(context).pop(); },
          onAdd: _save,
        ),
      ),
    );
  }
}
