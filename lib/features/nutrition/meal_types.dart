import 'package:flutter/material.dart';

import '../../l10n/app_l10n.dart';

/// Öğün anahtarları — `food_logs.meal_type` sütununda bu sabitler saklanır
/// (§5: ham string tekrar edilmez). Sıra ekranda görünen sıradır.
const List<String> mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

/// Öğünün kullanıcıya görünen adı (aktif dile göre).
String mealName(AppL10n l, String type) => switch (type) {
      'breakfast' => l.mealBreakfast,
      'lunch' => l.mealLunch,
      'dinner' => l.mealDinner,
      'snack' => l.mealSnack,
      _ => type,
    };

/// Öğün ikonu — hem öğün kartında hem kopyalama panelinde aynı görünsün.
IconData mealIcon(String type) => switch (type) {
      'breakfast' => Icons.bakery_dining_rounded,
      'lunch' => Icons.lunch_dining_rounded,
      'dinner' => Icons.dinner_dining_rounded,
      'snack' => Icons.cookie_rounded,
      _ => Icons.restaurant_rounded,
    };
