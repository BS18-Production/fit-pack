import 'package:drift/drift.dart';

class Achievements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // streak_10, streak_25, session_50, etc.
  DateTimeColumn get unlockedAt => dateTime()();
  TextColumn get metadataJson => text().nullable()();
}

class UserProfile extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get currentPhase => integer().withDefault(const Constant(1))();
  IntColumn get currentWeek => integer().withDefault(const Constant(1))();
  DateTimeColumn get startDate => dateTime()();
  IntColumn get kcalGoal => integer().withDefault(const Constant(2200))();
  IntColumn get proteinGoal => integer().withDefault(const Constant(180))();
  DateTimeColumn get lastDeload => dateTime().nullable()();
  RealColumn get heightCm => real().nullable()();
  RealColumn get goalWeightKg => real().nullable()();
  // v3 (P-10 Onboarding): ilk açılış kişiselleştirmesi tamamlandı mı?
  // default false → sıfır kurulumda onboarding gösterilir. Migration v2→v3
  // mevcut profili true yapar (zaten kullanan pilot onboarding görmez).
  BoolColumn get onboarded => boolean().withDefault(const Constant(false))();
  // v4 (Home su takibi): günlük su hedefi (ml). Varsayılan 2.5 L.
  IntColumn get waterGoalMl => integer().withDefault(const Constant(2500))();
  // v8 (BMR/TDEE — docs/12): tam günlük enerji harcaması tahmini için.
  // Hepsi nullable → eski profiller boş gelir, kullanıcı Ayarlar'dan doldurur.
  DateTimeColumn get birthDate => dateTime().nullable()(); // yaş türetimi
  TextColumn get gender => text().nullable()(); // 'male' | 'female'
  // Aktiflik düzeyi (TDEE çarpanı): sedentary|light|moderate|active|veryActive.
  TextColumn get activityLevel => text().nullable()();
}
