import 'package:flutter/material.dart';

import '../../core/utils/format.dart';
import '../../data/database/app_database.dart';
import '../../l10n/app_l10n.dart';
import 'food_search.dart' show FoodPortion;

// Besin etiketleri ve birim/grup yardımcıları (CR-018). Önceden ekran
// dosyalarındaydı; yemek ekleme paneli ile Yemekler ekranı bunlar için
// birbirini içe aktarıyordu.

/// Yemek grupları (C-5) — `foods.category` değerleri. Sıra ekrandaki çip
/// sırasıdır: en çok kullanılandan başlar.
const foodCategoryOrder = <String>[
  'meat',
  'dairy',
  'grain',
  'legume',
  'vegetable',
  'fruit',
  'fat',
  'dish',
  'sweet',
  'drink',
  'other',
];

/// Grup kodunu kullanıcı diline çevirir. Bilinmeyen kod olduğu gibi gösterilir
/// (dış kaynaktan gelen yemekte beklenmedik değer ekranı boş bırakmasın).
String foodCategoryLabel(AppL10n l, String category) => switch (category) {
  'meat' => l.foodCatMeat,
  'dairy' => l.foodCatDairy,
  'grain' => l.foodCatGrain,
  'legume' => l.foodCatLegume,
  'vegetable' => l.foodCatVegetable,
  'fruit' => l.foodCatFruit,
  'fat' => l.foodCatFat,
  'dish' => l.foodCatDish,
  'sweet' => l.foodCatSweet,
  'drink' => l.foodCatDrink,
  'other' => l.foodCatOther,
  _ => category,
};

/// Listede gerçekten bulunan gruplar, [foodCategoryOrder] sırasıyla.
/// Hiç kategorili yemek yoksa boş döner → çip şeridi çizilmez.
List<String> availableFoodCategories(Iterable<Food> foods) {
  final present = {
    for (final f in foods)
      if (f.category != null && f.category!.isNotEmpty) f.category!,
  };
  return [
    for (final c in foodCategoryOrder)
      if (present.remove(c)) c,
    ...present.toList()..sort(),
  ];
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

/// "1 porsiyon · 200 g" / "150 g".
String portionText(FoodPortion p) => p.unit != null && p.units > 0
    ? '${fmtNum(p.units)} ${p.unit} · ${p.grams.round()} g'
    : '${p.grams.round()} g';

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
