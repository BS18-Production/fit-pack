import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import 'custom_food_dialog.dart';
import '../../data/providers.dart';
import '../../l10n/app_l10n.dart';
import 'barcode_scan_screen.dart';

/// Barkod akışı (docs/07-nutrition-v2.md §6.3):
/// tara → lokal `foods.barcode` eşleşir mi → yoksa OpenFoodFacts → ekle.
/// Dönen `Food`: çağıran onu seçer/listeler. null = iptal/elle ekle/bulunamadı.
Future<Food?> scanBarcodeToFood(BuildContext context, WidgetRef ref) async {
  // await'lerden önce yakala — sonrasında context.mounted kontrolleri var
  // ama l güvenle taşınabilir.
  final code = await Navigator.of(context, rootNavigator: true).push<String>(
    MaterialPageRoute(
      builder: (_) => const BarcodeScanScreen(),
      fullscreenDialog: true,
    ),
  );
  if (code == null || code.isEmpty || !context.mounted) return null;
  return lookupBarcodeToFood(context, ref, code);
}

Future<Food?> lookupBarcodeToFood(BuildContext context, WidgetRef ref, String code) async {
  final l = AppL10n.of(context);
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
  final progress = showDialog<void>(
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
  // İlerleme penceresi gerçekten kapanmadan yenisini açma: hızlı/null
  // cevapta kurulum callback’i yeni açılan pencereyi yanlışlıkla kapatmasın.
  await progress;
  if (!context.mounted) return null;

  if (off == null) {
    final create = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(l.nutritionProductNotFound(code)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.commonCancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.expCreateFood)),
      ],
    ));
    if (create != true || !context.mounted) return null;
    final custom = await showDialog<CustomFood>(context: context,
      builder: (_) => CustomFoodDialog(barcode: code));
    if (custom == null || !context.mounted) return null;
    final id = await dao.insertFood(FoodsCompanion(
      name: Value(custom.name), barcode: Value(code),
      kcalPer100g: Value(custom.kcalPer100g), proteinPer100g: Value(custom.proteinPer100g),
      carbPer100g: Value(custom.carbPer100g), fatPer100g: Value(custom.fatPer100g),
      defaultPortionGrams: Value(custom.defaultGrams), unitLabel: Value(custom.unitLabel),
      source: const Value('custom'), isCustom: const Value(true),
    ));
    return dao.getFoodById(id);
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
