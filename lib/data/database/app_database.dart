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
  @override
  int get schemaVersion => 7;

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
          await m.createTable(waterIntake);
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
          await m.createTable(routines);
          await m.createTable(routineExercises);
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
