import 'package:shared_preferences/shared_preferences.dart';

/// Hesap silme yeni cihaz içi hedef/kurulum tercihlerine de uygulanır.
/// Başka hesabın anahtarları veya mevcut iş kayıtları etkilenmez.
Future<void> clearTrainingPreferencesForAccount(
  String account, {
  SharedPreferences? preferences,
}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  for (final prefix in [
    'training_setup_v1_',
    'goal_journey_v1_',
    'weekly_target_history_v1_',
    'weekly_goal_v1_',
  ]) {
    final key = '$prefix$account';
    if (prefs.containsKey(key) && !await prefs.remove(key)) {
      throw StateError('Hesabın yerel antrenman tercihleri temizlenemedi');
    }
  }
}
