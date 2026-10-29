import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home/providers/weekly_goal_provider.dart';
import 'training_setup.dart';

/// Testte okuma/yazma hatasını gerçek kullanıcı tercihlerine dokunmadan dene.
final trainingSetupPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

class TrainingSetupProfileNotifier
    extends AsyncNotifier<TrainingSetupProfile?> {
  int _accountGeneration = 0;

  @override
  Future<TrainingSetupProfile?> build() async {
    _accountGeneration++;
    final account = ref.watch(weeklyGoalAccountProvider);
    if (account == null) return null;
    final prefs = await ref.read(trainingSetupPreferencesProvider.future);
    final raw = prefs.getString('training_setup_v1_$account');
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Geçersiz antrenman kurulumu');
    }
    return TrainingSetupProfile.fromJson(decoded);
  }

  Future<void> save(
    TrainingSetupProfile profile, {
    String? expectedAccount,
  }) async {
    final account = ref.read(weeklyGoalAccountProvider);
    if (account == null) throw StateError('Kurulum için oturum gerekli');
    if (expectedAccount != null && expectedAccount != account) {
      throw StateError('Kurulum sırasında hesap değişti');
    }
    final generation = _accountGeneration;
    final prefs = await ref.read(trainingSetupPreferencesProvider.future);
    if (ref.read(weeklyGoalAccountProvider) != account ||
        generation != _accountGeneration) {
      throw StateError('Kurulum sırasında hesap değişti');
    }
    if (!await prefs.setString(
      'training_setup_v1_$account',
      jsonEncode(profile.toJson()),
    )) {
      throw StateError('Antrenman tercihi kaydedilemedi');
    }
    if (ref.read(weeklyGoalAccountProvider) != account ||
        generation != _accountGeneration) {
      throw StateError('Kurulum sırasında hesap değişti');
    }
    state = AsyncData(profile);
  }
}

final trainingSetupProfileProvider =
    AsyncNotifierProvider<TrainingSetupProfileNotifier, TrainingSetupProfile?>(
      TrainingSetupProfileNotifier.new,
    );
