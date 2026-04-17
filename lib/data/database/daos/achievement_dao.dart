import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/achievement_tables.dart';

part 'achievement_dao.g.dart';

@DriftAccessor(tables: [Achievements])
class AchievementDao extends DatabaseAccessor<AppDatabase> with _$AchievementDaoMixin {
  AchievementDao(super.db);

  Future<List<Achievement>> getAllAchievements() =>
      (select(achievements)..orderBy([(a) => OrderingTerm.desc(a.unlockedAt)])).get();

  Future<Achievement?> getAchievementByType(String type) =>
      (select(achievements)..where((a) => a.type.equals(type))).getSingleOrNull();

  Future<bool> hasAchievement(String type) async {
    final a = await getAchievementByType(type);
    return a != null;
  }

  Future<int> unlockAchievement(String type, {String? metadata}) =>
      into(achievements).insert(AchievementsCompanion(
        type: Value(type),
        unlockedAt: Value(DateTime.now()),
        metadataJson: Value(metadata),
      ));
}
