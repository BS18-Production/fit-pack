import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/achievement_tables.dart';

part 'user_profile_dao.g.dart';

@DriftAccessor(tables: [UserProfile])
class UserProfileDao extends DatabaseAccessor<AppDatabase> with _$UserProfileDaoMixin {
  UserProfileDao(super.db);

  Future<UserProfileData?> getProfile() =>
      (select(userProfile)..limit(1)).getSingleOrNull();

  Future<int> insertProfile(UserProfileCompanion entry) =>
      into(userProfile).insert(entry);

  Future<bool> updateProfile(UserProfileData entry) =>
      update(userProfile).replace(entry);

  Future<void> ensureProfile() async {
    final existing = await getProfile();
    if (existing == null) {
      await insertProfile(UserProfileCompanion(
        startDate: Value(DateTime.now()),
      ));
    }
  }
}
