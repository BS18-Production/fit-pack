import 'package:drift/drift.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/activity/activity_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Dış inceleme #10 regresyonu: aktivite takvimi sekme değişiminden sonra
/// bayat kalıyordu.
///
/// Kök neden `autoDispose` değil, üstüne kurulduğu **varsayımdı**:
/// "sekmeden çıkınca ekran dispose olur, geri dönünce taze hesaplanır". Router
/// `StatefulShellRoute.indexedStack`'e geçince sekmeler canlı kaldı ve o
/// varsayım sessizce bozuldu. Bu test varsayımı değil **davranışı** ölçüyor:
/// dinleyici hayattayken kaynak tablo değişirse yeni değer gelmeli.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = newTestDatabase();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  Future<int> yemekEkle() => db.nutritionDao.insertFood(const FoodsCompanion(
        name: Value('Test Yemeği'),
        kcalPer100g: Value(100),
        proteinPer100g: Value(10),
        carbPer100g: Value(10),
        fatPer100g: Value(5),
        source: Value('local'),
        isCustom: Value(false),
        isRecipe: Value(false),
      ));

  /// Akışın yeni değeri yayması bir olay döngüsü turu alır. [kosul] sağlanana
  /// kadar kısa aralıklarla bakar; süre dolarsa test başarısız olur (sessizce
  /// geçmesin).
  Future<Map<int, DayActivity>> tazeDegeriBekle(
    DateTime ay,
    bool Function(Map<int, DayActivity>) kosul,
  ) async {
    final sonlanma = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(sonlanma)) {
      final deger = container.read(monthActivityProvider(ay)).valueOrNull;
      if (deger != null && kosul(deger)) return deger;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    fail('akış beklenen tazelenmeyi 5 sn içinde yaymadı');
  }

  test('takvim açıkken eklenen öğün AYNI dinleyiciye yansır', () async {
    final ay = DateTime(2026, 9, 1);
    final gun = DateTime(2026, 9, 15);

    // Ekran açık: dinleyici hayatta (sekme değişse de dispose olmuyor).
    final sub = container.listen(monthActivityProvider(ay), (_, _) {});
    addTearDown(sub.close);

    final ilk = await container.read(monthActivityProvider(ay).future);
    expect(ilk[15], null, reason: 'başlangıçta o gün boş olmalı');

    // Başka bir sekmede öğün eklenir.
    final f = await yemekEkle();
    await db.nutritionDao.insertFoodLog(FoodLogsCompanion(
      date: Value(gun),
      mealType: const Value('lunch'),
      foodId: Value(f),
      grams: const Value(100),
      computedKcal: const Value(250),
      computedProtein: const Value(10),
      computedCarb: const Value(10),
      computedFat: const Value(5),
    ));

    // Yeniden kurulum/invalidate YOK — akış kendiliğinden yenilenmeli.
    final yeni = await tazeDegeriBekle(ay, (d) => d[15] != null);
    expect(yeni[15]?.kcal, 250,
        reason: 'tablo değişti, takvim kendiliğinden tazelenmeliydi');
  });

  test('su eklenince de tazelenir', () async {
    final ay = DateTime(2026, 9, 1);
    final sub = container.listen(monthActivityProvider(ay), (_, _) {});
    addTearDown(sub.close);

    await container.read(monthActivityProvider(ay).future);
    await db.nutritionDao.addWater(DateTime(2026, 9, 15), 500);

    final yeni = await tazeDegeriBekle(ay, (d) => d[15] != null);
    expect(yeni[15]?.waterMl, 500);
  });
}
