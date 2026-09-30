import '../../data/database/app_database.dart';
import '../workout/exercise_search.dart' show searchNormalize;

/// Yemek ekleme panelinin saf mantığı — arayüz ve DB bilmez.
/// Test: `test/features/food_search_test.dart`.

/// Bir besinin eklenecek miktarı. [units] > 0 ise birimle ("1 porsiyon"),
/// değilse yalnız gram. Kayıt için tek doğruluk kaynağı [grams].
typedef FoodPortion = ({double grams, double units, String? unit});

bool hasUnit(Food f) =>
    f.unitLabel != null && (f.defaultPortionGrams ?? 0) > 0;

/// Tek dokunuşla eklenecek miktar: son kullanılan gram (varsa) → 1 birim
/// (varsa) → 100 g.
FoodPortion defaultPortion(Food f, {double? lastGrams}) {
  final p = f.defaultPortionGrams;
  if (lastGrams != null && lastGrams > 0) {
    return hasUnit(f)
        ? (grams: lastGrams, units: lastGrams / p!, unit: f.unitLabel)
        : (grams: lastGrams, units: 0, unit: null);
  }
  if (hasUnit(f)) return (grams: p!, units: 1, unit: f.unitLabel);
  return (grams: 100, units: 0, unit: null);
}

/// Miktarın besin değerleri.
({double kcal, double protein, double carb, double fat}) macrosFor(
    Food f, double grams) {
  final r = grams / 100;
  return (
    kcal: f.kcalPer100g * r,
    protein: f.proteinPer100g * r,
    carb: f.carbPer100g * r,
    fat: f.fatPer100g * r,
  );
}

/// Alaka puanı: büyük olan önce. 0 = eşleşmedi.
int _score(String name, List<String> q) {
  final n = searchNormalize(name);
  final words = n.split(' ');
  var total = 0;
  for (final t in q) {
    if (words.first == t) {
      total += 45; // ilk kelime tam: "sut" → "Süt (Yağsız)", "Kakaolu Süt"ten önce
    } else if (words.contains(t)) {
      total += 40; // tam kelime: "sut" → "Kakaolu Süt", "Sütlaç"tan önce
    } else if (n.startsWith(t)) {
      total += 30; // ad bu parçayla başlıyor: "sut" → "Süt (Tam Yağlı)"
    } else if (words.any((w) => w.startsWith(t))) {
      total += 20; // bir kelimenin başı: "yag" → "Süt (Tam Yağlı)"
    } else if (n.contains(t)) {
      total += 5; // kelime içi: zayıf eşleşme
    } else {
      return 0; // her arama kelimesi eşleşmeli
    }
  }
  return total;
}

/// Arama: Türkçe harf farkı yok ("sut" = "Süt"), her kelime eşleşmeli,
/// sıra = alaka → son kullanılan → kendi besinin → kısa ad → alfabe.
/// Boş aramada: son kullanılan → kendi besinin → alfabe.
///
/// [recentRank]: besin kimliği → son kullanım sırası (0 = en son).
List<Food> rankFoods(
  List<Food> all,
  String query, {
  Map<int, int> recentRank = const {},
}) {
  final q = searchNormalize(query).split(' ').where((w) => w.isNotEmpty).toList();
  final scored = <(Food, int)>[];
  for (final f in all) {
    final s = q.isEmpty ? 1 : _score(f.name, q);
    if (s > 0) scored.add((f, s));
  }
  int rank(Food f) => recentRank[f.id] ?? 1 << 30;
  scored.sort((a, b) {
    if (a.$2 != b.$2) return b.$2.compareTo(a.$2);
    final r = rank(a.$1).compareTo(rank(b.$1));
    if (r != 0) return r;
    if (a.$1.isCustom != b.$1.isCustom) return a.$1.isCustom ? -1 : 1;
    if (q.isNotEmpty && a.$1.name.length != b.$1.name.length) {
      return a.$1.name.length.compareTo(b.$1.name.length);
    }
    return searchNormalize(a.$1.name).compareTo(searchNormalize(b.$1.name));
  });
  return [for (final s in scored) s.$1];
}
