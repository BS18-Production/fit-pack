import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../cloud/auth_service.dart';
import '../../workout/routine_providers.dart';
import '../weekly_goal.dart';

/// Hesap kimliği bağımlılığı testte de aynı sınırla değiştirilir.
final weeklyGoalAccountProvider = Provider<String?>((ref) =>
    ref.watch(currentUserProvider)?.id);

class SelectedWeeklyGoal extends AsyncNotifier<int?> {
  @override
  Future<int?> build() async {
    final id = ref.watch(weeklyGoalAccountProvider);
    if (id == null) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('weekly_goal_v1_$id');
  }

  Future<void> setGoal(int goal) async {
    if (goal < 1 || goal > 7) throw ArgumentError.value(goal);
    final id = ref.read(weeklyGoalAccountProvider);
    if (id == null) throw StateError('Haftalık hedef için oturum gerekli');
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setInt('weekly_goal_v1_$id', goal)) {
      throw StateError('Haftalık hedef kaydedilemedi');
    }
    if (ref.read(weeklyGoalAccountProvider) == id) state = AsyncData(goal);
  }
}

final selectedWeeklyGoalProvider =
    AsyncNotifierProvider<SelectedWeeklyGoal, int?>(SelectedWeeklyGoal.new);

final weeklyGoalProvider = FutureProvider<int>((ref) async {
  final selected = ref.watch(selectedWeeklyGoalProvider.future);
  final routines = ref.watch(activeRoutinesProvider.future);
  return resolveWeeklyGoal(selected: await selected, routines: await routines);
});
