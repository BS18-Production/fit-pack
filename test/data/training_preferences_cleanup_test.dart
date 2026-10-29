import 'package:fit_pack/data/services/training_preferences_cleanup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'only deleted account setup, goal and target history are removed',
    () async {
      final prefixes = [
        'training_setup_v1_',
        'goal_journey_v1_',
        'weekly_target_history_v1_',
        'weekly_goal_v1_',
      ];
      SharedPreferences.setMockInitialValues({
        for (final prefix in prefixes) '${prefix}a': 'a',
        for (final prefix in prefixes) '${prefix}b': 'b',
        'theme': 'dark',
      });
      final prefs = await SharedPreferences.getInstance();
      await clearTrainingPreferencesForAccount('a', preferences: prefs);
      for (final prefix in prefixes) {
        expect(prefs.containsKey('${prefix}a'), isFalse);
        expect(prefs.getString('${prefix}b'), 'b');
      }
      expect(prefs.getString('theme'), 'dark');
      await clearTrainingPreferencesForAccount('a', preferences: prefs);
      expect(prefs.getString('theme'), 'dark');
    },
  );
}
