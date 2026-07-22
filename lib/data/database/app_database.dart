import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/workout_tables.dart';
import 'tables/nutrition_tables.dart';
import 'tables/body_tables.dart';
import 'tables/achievement_tables.dart';
import 'tables/sync_columns.dart';
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
    Routines,
    RoutineExercises,
    Foods,
    FoodLogs,
    RecipeItems,
    WaterIntake,
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
  ///
  /// v2 → v3 (2026-06-20, P-10 Onboarding — docs/03-ux-flows.md §3):
  /// `user_profile.onboarded` eklendi (BOOL, default 0). Migration mevcut
  /// profili onboarded=1 yapar → kullanan pilot onboarding görmez, yalnız
  /// sıfır kurulum görür. Additive, veri kayıpsız (ADR-007).
  ///
  /// v3 → v4 (2026-06-21, Home su takibi): `water_intake` tablosu (gün başına
  /// kümülatif ml) + `user_profile.waterGoalMl` (default 2500) eklendi.
  ///
  /// v4 → v5 (2026-06-21, Antrenman V2 Faz A — docs/09-workout-v2.md):
  /// `exercises` +primaryMuscle/+equipment/+measurementType/+isCustom/
  /// +isArchived (hareket kütüphanesi filtreleri).
  ///
  /// v5 → v6 (2026-06-21, Antrenman V2 Faz B+C): `routines` +
  /// `routine_exercises` tabloları + `workout_sessions` +routineId/+startedAt/
  /// +endedAt + `workout_sets` +rpe/+setType/+isComplete/+distanceM/
  /// +durationSec. Hepsi additive → veri kayıpsız.
  ///
  /// v6 → v7 (2026-06-29, İçerik Zenginleştirme — docs/11-content-enrichment.md):
  /// `exercises` +imagePath/+instructions/+level/+force (free-exercise-db form
  /// görseli + talimat + meta) + `foods.category` (TÜRKOMP gıda grubu). Hepsi
  /// nullable → additive, veri kayıpsız (ADR-007).
  ///
  /// v8 → v9 (2026-07-21, Zorunlu hesap + senkron — docs/18-auth-and-sync.md):
  /// 12 tabloya senkron kolonları: `uid` (dünyada tek kimlik, UUID v4),
  /// `userId` (Supabase auth.uid), `updatedAt` (çakışma çözümü), `syncState`
  /// (giden kutusu: 0 temiz / 1 beklemede / 2 hata). `Achievements` hariç —
  /// kullanılmıyor (docs/18 §3.3). Hepsi nullable ya da default'lu → additive,
  /// veri kayıpsız (ADR-007). Göç ayrıca eski satırlara `uid` backfill eder,
  /// `uid` unique index'lerini kurar ve mevcut satırları kuyruğa alır (katalog
  /// tablolarında yalnız `is_custom = 1` olanları — 1022 seed hareket girmez).
  @override
  int get schemaVersion => 9;

  /// v5→v6 gibi ARA göç adımları `m.createTable()` ile GÜNCEL tanımı kullanır —
  /// yani o adımda doğan tablo (routines, routine_exercises, water_intake)
  /// senkron kolonlarını zaten taşır. v<6 → v9 yükseltmesinde aynı kolonu
  /// ikinci kez eklemek "duplicate column" hatası verirdi. Bu yüzden kolon
  /// eklenmeden önce varlığı `PRAGMA table_info` ile kontrol edilir.
  Future<void> _addColumnIfMissing(
      Migrator m, TableInfo table, GeneratedColumn column) async {
    final info = await m.database
        .customSelect('PRAGMA table_info(${table.actualTableName})')
        .get();
    final exists = info.any((r) => r.read<String>('name') == column.name);
    if (!exists) await m.addColumn(table, column);
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      // İlk kurulum: sıfırdan tüm tabloları oluştur.
      onCreate: (Migrator m) async {
        await m.createAll();
        // `uid` unique index'leri (docs/18 §4). Kolonun kendisine UNIQUE
        // konulamıyor çünkü göç yolunda SQLite `ALTER TABLE ADD COLUMN` ile
        // UNIQUE kolon eklenemez — iki yol da aynı index'i kursun diye burada
        // da elle kuruluyor.
        for (final t in syncedTableNames) {
          await m.database.customStatement(createUidIndexSql(t));
        }
      },

      // Sürümden sürüme göç. Her `from` için bir sonraki adıma yol tarif edilir.
      // Adımlar zincirleme uygulanır (1→2, sonra 2→3...). Veri KORUNUR.
      onUpgrade: (Migrator m, int from, int to) async {
        // v1 → v2: Beslenme V2 — adet/birim porsiyon (docs/07-nutrition-v2.md).
        // Sadece kolon EKLEME (nullable) → mevcut veri korunur, satırlar NULL
        // alır = "sadece gram" davranışı. Yıkıcı işlem YOK (ADR-007).
        // Her adım hem `from` hem `to` ile sınırlanır: ara hedefe göç
        // (örn. v1→v2 göç testi) sonraki adımları çalıştırıp hedefi aşmasın.
        if (from < 2 && to >= 2) {
          await m.addColumn(foods, foods.defaultPortionGrams);
          await m.addColumn(foods, foods.unitLabel);
        }
        // v2 → v3: Onboarding (P-10). onboarded kolonu eklenir (default 0).
        // Mevcut profil = uygulamayı zaten kullanan pilot → onboarded=1 yap,
        // ilk açılış akışını ona GÖSTERME. Yeni kurulum onCreate'ten geçer
        // (onboarded=0) → onboarding gösterilir.
        if (from < 3 && to >= 3) {
          await m.addColumn(userProfile, userProfile.onboarded);
          await m.database.customStatement(
            'UPDATE user_profile SET onboarded = 1',
          );
        }
        // v3 → v4: Home su takibi. Yeni tablo + profile su hedefi kolonu.
        // İkisi de additive (tablo ekleme + default'lu kolon) → veri korunur.
        if (from < 4 && to >= 4) {
          // DİKKAT: `m.createTable(waterIntake)` GÜNCEL tanımı kullanır — yani
          // v9'un senkron kolonlarını da eklerdi ve bu adım artık "v4 şeması"
          // üretmezdi. Göç adımı tarihte donmuş olmalı: v4'teki şekil elle
          // yazılır. (v9 kolonları kendi adımında eklenir.)
          await m.database.customStatement(
            'CREATE TABLE IF NOT EXISTS "water_intake" ('
            '"id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
            '"date" INTEGER NOT NULL, '
            '"amount_ml" INTEGER NOT NULL DEFAULT (0))',
          );
          await m.addColumn(userProfile, userProfile.waterGoalMl);
        }
        // v4 → v5: Antrenman V2 hareket kütüphanesi. Hepsi additive kolon.
        // Backfill (mevcut hareketlere meta yazımı) SeedManager'da.
        if (from < 5 && to >= 5) {
          await m.addColumn(exercises, exercises.primaryMuscle);
          await m.addColumn(exercises, exercises.equipment);
          await m.addColumn(exercises, exercises.measurementType);
          await m.addColumn(exercises, exercises.isCustom);
          await m.addColumn(exercises, exercises.isArchived);
        }
        // v5 → v6: Antrenman V2 Faz B+C — rutinler + gelişmiş set takibi.
        if (from < 6 && to >= 6) {
          // Yukarıdaki v4 notunun aynısı: bu iki tablo v6'daki şekliyle
          // oluşturulur, güncel tanımla değil.
          await m.database.customStatement(
            'CREATE TABLE IF NOT EXISTS "routines" ('
            '"id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
            '"name" TEXT NOT NULL, '
            '"note" TEXT NULL, '
            '"order_index" INTEGER NOT NULL DEFAULT (0), '
            '"scheduled_weekday" INTEGER NULL, '
            '"created_at" INTEGER NOT NULL, '
            '"is_archived" INTEGER NOT NULL DEFAULT (0) '
            'CHECK ("is_archived" IN (0, 1)))',
          );
          await m.database.customStatement(
            'CREATE TABLE IF NOT EXISTS "routine_exercises" ('
            '"id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
            '"routine_id" INTEGER NOT NULL REFERENCES routines (id), '
            '"exercise_id" INTEGER NOT NULL REFERENCES exercises (id), '
            '"order_index" INTEGER NOT NULL DEFAULT (0), '
            '"target_sets" INTEGER NULL, '
            '"target_reps_min" INTEGER NULL, '
            '"target_reps_max" INTEGER NULL, '
            '"target_rest_sec" INTEGER NULL, '
            '"note" TEXT NULL)',
          );
          await m.addColumn(workoutSessions, workoutSessions.routineId);
          await m.addColumn(workoutSessions, workoutSessions.startedAt);
          await m.addColumn(workoutSessions, workoutSessions.endedAt);
          await m.addColumn(workoutSets, workoutSets.rpe);
          await m.addColumn(workoutSets, workoutSets.setType);
          await m.addColumn(workoutSets, workoutSets.isComplete);
          await m.addColumn(workoutSets, workoutSets.distanceM);
          await m.addColumn(workoutSets, workoutSets.durationSec);
        }
        // v6 → v7: İçerik zenginleştirme (docs/11-content-enrichment.md).
        // Hareket görseli/talimat/meta + gıda grubu. Hepsi nullable kolon
        // ekleme → mevcut veri (özel hareket/yemek dahil) korunur.
        if (from < 7 && to >= 7) {
          await m.addColumn(exercises, exercises.imagePath);
          await m.addColumn(exercises, exercises.instructions);
          await m.addColumn(exercises, exercises.level);
          await m.addColumn(exercises, exercises.force);
          await m.addColumn(foods, foods.category);
        }
        // v7 → v8: BMR/TDEE — tam günlük enerji harcaması (docs/12).
        // user_profile +birthDate +gender +activityLevel. Hepsi nullable
        // kolon ekleme → mevcut profil + tüm veri korunur (boş gelir).
        if (from < 8 && to >= 8) {
          await m.addColumn(userProfile, userProfile.birthDate);
          await m.addColumn(userProfile, userProfile.gender);
          await m.addColumn(userProfile, userProfile.activityLevel);
        }
        // v8 → v9: Zorunlu hesap + senkron (docs/18 §4). 12 tabloya senkron
        // kolonları + uid backfill + unique index + mevcut satırları kuyruğa
        // alma. Hepsi additive → mevcut veri korunur (ADR-007).
        if (from < 9 && to >= 9) {
          // Kolonlar açıkça sayılır (döngü değil): drift'in ürettiği tanımla
          // birebir aynı SQL üretilsin — göç testi tam da bunu doğrular.
          await _addColumnIfMissing(m, userProfile, userProfile.uid);
          await _addColumnIfMissing(m, userProfile, userProfile.userId);
          await _addColumnIfMissing(m, userProfile, userProfile.updatedAt);
          await _addColumnIfMissing(m, userProfile, userProfile.syncState);
          await _addColumnIfMissing(m, workoutSessions, workoutSessions.uid);
          await _addColumnIfMissing(m, workoutSessions, workoutSessions.userId);
          await _addColumnIfMissing(m, workoutSessions, workoutSessions.updatedAt);
          await _addColumnIfMissing(m, workoutSessions, workoutSessions.syncState);
          await _addColumnIfMissing(m, workoutSets, workoutSets.uid);
          await _addColumnIfMissing(m, workoutSets, workoutSets.userId);
          await _addColumnIfMissing(m, workoutSets, workoutSets.updatedAt);
          await _addColumnIfMissing(m, workoutSets, workoutSets.syncState);
          await _addColumnIfMissing(m, routines, routines.uid);
          await _addColumnIfMissing(m, routines, routines.userId);
          await _addColumnIfMissing(m, routines, routines.updatedAt);
          await _addColumnIfMissing(m, routines, routines.syncState);
          await _addColumnIfMissing(m, routineExercises, routineExercises.uid);
          await _addColumnIfMissing(m, routineExercises, routineExercises.userId);
          await _addColumnIfMissing(m, routineExercises, routineExercises.updatedAt);
          await _addColumnIfMissing(m, routineExercises, routineExercises.syncState);
          await _addColumnIfMissing(m, foodLogs, foodLogs.uid);
          await _addColumnIfMissing(m, foodLogs, foodLogs.userId);
          await _addColumnIfMissing(m, foodLogs, foodLogs.updatedAt);
          await _addColumnIfMissing(m, foodLogs, foodLogs.syncState);
          await _addColumnIfMissing(m, waterIntake, waterIntake.uid);
          await _addColumnIfMissing(m, waterIntake, waterIntake.userId);
          await _addColumnIfMissing(m, waterIntake, waterIntake.updatedAt);
          await _addColumnIfMissing(m, waterIntake, waterIntake.syncState);
          await _addColumnIfMissing(m, bodyMeasurements, bodyMeasurements.uid);
          await _addColumnIfMissing(m, bodyMeasurements, bodyMeasurements.userId);
          await _addColumnIfMissing(m, bodyMeasurements, bodyMeasurements.updatedAt);
          await _addColumnIfMissing(m, bodyMeasurements, bodyMeasurements.syncState);
          await _addColumnIfMissing(m, progressPhotos, progressPhotos.uid);
          await _addColumnIfMissing(m, progressPhotos, progressPhotos.userId);
          await _addColumnIfMissing(m, progressPhotos, progressPhotos.updatedAt);
          await _addColumnIfMissing(m, progressPhotos, progressPhotos.syncState);
          await _addColumnIfMissing(m, recipeItems, recipeItems.uid);
          await _addColumnIfMissing(m, recipeItems, recipeItems.userId);
          await _addColumnIfMissing(m, recipeItems, recipeItems.updatedAt);
          await _addColumnIfMissing(m, recipeItems, recipeItems.syncState);
          await _addColumnIfMissing(m, exercises, exercises.uid);
          await _addColumnIfMissing(m, exercises, exercises.userId);
          await _addColumnIfMissing(m, exercises, exercises.updatedAt);
          await _addColumnIfMissing(m, exercises, exercises.syncState);
          await _addColumnIfMissing(m, foods, foods.uid);
          await _addColumnIfMissing(m, foods, foods.userId);
          await _addColumnIfMissing(m, foods, foods.updatedAt);
          await _addColumnIfMissing(m, foods, foods.syncState);
          for (final name in syncedTableNames) {
            // Sıra önemli: önce backfill, sonra index. (Index NULL'ları
            // engellemez ama backfill'i tek seferde bitirmek daha temiz.)
            await m.database.customStatement(backfillUidSql(name));
            await m.database.customStatement(createUidIndexSql(name));
            await m.database.customStatement(queueExistingRowsSql(name));
          }
        }
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
