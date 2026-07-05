import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/providers.dart';
import '../../l10n/app_l10n.dart';
import 'barcode_scan_screen.dart';

/// Barkod akışı (docs/07-nutrition-v2.md §6.3):
/// tara → lokal `foods.barcode` eşleşir mi → yoksa OpenFoodFacts → ekle.
/// Dönen `Food`: çağıran onu seçer/listeler. null = iptal/elle ekle/bulunamadı.
Future<Food?> scanBarcodeToFood(BuildContext context, WidgetRef ref) async {
  // await'lerden önce yakala — sonrasında context.mounted kontrolleri var
  // ama l güvenle taşınabilir.
  final l = AppL10n.of(context);
  final code = await Navigator.of(context, rootNavigator: true).push<String>(
    MaterialPageRoute(
      builder: (_) => const BarcodeScanScreen(),
      fullscreenDialog: true,
    ),
  );
  if (code == null || code.isEmpty) return null;
  if (!context.mounted) return null;

  final dao = ref.read(nutritionDaoProvider);

  // 1) Lokal eşleşme (internetsiz, anında).
  final existing = await dao.getFoodByBarcode(code);
  if (existing != null) {
    if (context.mounted) {
      _snack(context, l.nutritionAlreadySaved(existing.name));
    }
    return existing;
  }

  // 2) OpenFoodFacts — sorgu sırasında engelleyici ilerleme göstergesi.
  if (!context.mounted) return null;
  BuildContext? progressCtx;
  var progressDone = false; // sorgu bitti mi (diyalog kurulumundan hızlıysa)
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      progressCtx = ctx;
      // Yarış koruması (L-04): sorgu, diyalog daha kurulmadan bittiyse
      // diyalog kendini ilk karede kapatır — açık kalamaz.
      if (progressDone) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => Navigator.of(ctx).pop());
      }
      return PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 16),
              Expanded(child: Text(l.nutritionOffQuerying)),
            ],
          ),
        ),
      );
    },
  );

  final off =
      await ref.read(openFoodFactsServiceProvider).fetchByBarcode(code);

  progressDone = true;
  if (progressCtx != null && progressCtx!.mounted) {
    Navigator.of(progressCtx!).pop();
  }
  if (!context.mounted) return null;

  if (off == null) {
    _snack(context, l.nutritionProductNotFound(code));
    return null;
  }

  final id = await dao.insertFood(FoodsCompanion(
    name: Value(off.name),
    barcode: Value(off.barcode),
    kcalPer100g: Value(off.kcalPer100g),
    proteinPer100g: Value(off.proteinPer100g),
    carbPer100g: Value(off.carbPer100g),
    fatPer100g: Value(off.fatPer100g),
    source: const Value('openfoodfacts'),
    isCustom: const Value(false),
    isRecipe: const Value(false),
  ));
  final food = await dao.getFoodById(id);
  if (context.mounted && food != null) {
    _snack(context, l.nutritionAddedFromOff(food.name));
  }
  return food;
}

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(msg)));
}
