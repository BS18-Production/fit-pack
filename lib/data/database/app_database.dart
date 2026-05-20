import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/workout_tables.dart';
import 'tables/nutrition_tables.dart';
import 'tables/body_tables.dart';
import 'tables/achievement_tables.dart';
import 'daos/workout_dao.dart';
import 'daos/nutrition_dao.dart';
import 'daos/body_dao.dart';
import 'daos/achievement_dao.dart';
import 'daos/user_profile_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Exercises,
    WorkoutSessions,
    WorkoutSets,
    Foods,
    FoodLogs,
    RecipeItems,
    BodyMeasurements,
    ProgressPhotos,
    Achievements,
    UserProfile,
  ],
  daos: [
    WorkoutDao,
    NutritionDao,
    BodyDao,
    AchievementDao,
    UserProfileDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  /// Şema versiyonu. DEĞİŞTİRİRKEN KURAL (Workflow §4, Testing §3.1):
  /// schemaVersion artışı + ilgili `onUpgrade` adımı + yeni `migration_test`
  /// AYNI commit'te olur. Yıkıcı migration (tablo/kolon silme) YASAK (ADR-007).
  ///
  /// v1 → v2 (2026-05-18, Beslenme V2 — docs/07-nutrition-v2.md):
  /// `foods.defaultPortionGrams` + `foods.unitLabel` eklendi (ikisi de
  /// nullable → additive, V1 verisi kayıpsız). İlk gerçek şema değişikliği.
  /// Aşama 1 (rir, daily_log, supplement) bunun ÜSTÜNE v3+ olarak gelecek;
  /// migration'lar zincirleme uygulanır.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      // İlk kurulum: sıfırdan tüm tabloları oluştur.
      onCreate: (Migrator m) async {
        await m.createAll();
      },

      // Sürümden sürüme göç. Her `from` için bir sonraki adıma yol tarif edilir.
      // Adımlar zincirleme uygulanır (1→2, sonra 2→3...). Veri KORUNUR.
      onUpgrade: (Migrator m, int from, int to) async {
        // v1 → v2: Beslenme V2 — adet/birim porsiyon (docs/07-nutrition-v2.md).
        // Sadece kolon EKLEME (nullable) → mevcut veri korunur, satırlar NULL
        // alır = "sadece gram" davranışı. Yıkıcı işlem YOK (ADR-007).
        if (from < 2) {
          await m.addColumn(foods, foods.defaultPortionGrams);
          await m.addColumn(foods, foods.unitLabel);
        }
        // Aşama 1'de v3 buraya zincirlenecek (rir, daily_log, supplement...).
      },

      // Her DB açılışında çalışır. SQLite'ta yabancı anahtar (foreign key)
      // kısıtları varsayılan KAPALI gelir; burada açıyoruz ki ilişkisel
      // bütünlük korunsun.
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'fit_pack.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
