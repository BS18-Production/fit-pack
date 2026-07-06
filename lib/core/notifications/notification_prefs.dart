import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bildirim tercihleri (docs/16 §5 — B6). Kalıcı; zamanlama/iptal ekran
/// tarafında yapılır (tercih değişince ekran servis çağırır).
class NotificationPrefs {
  final bool restEnabled;
  final bool workoutEnabled;
  final int workoutHour, workoutMinute;
  final bool waterEnabled;
  final int waterHour, waterMinute;

  const NotificationPrefs({
    this.restEnabled = false,
    this.workoutEnabled = false,
    this.workoutHour = 18,
    this.workoutMinute = 0,
    this.waterEnabled = false,
    this.waterHour = 14,
    this.waterMinute = 0,
  });

  NotificationPrefs copyWith({
    bool? restEnabled,
    bool? workoutEnabled,
    int? workoutHour,
    int? workoutMinute,
    bool? waterEnabled,
    int? waterHour,
    int? waterMinute,
  }) =>
      NotificationPrefs(
        restEnabled: restEnabled ?? this.restEnabled,
        workoutEnabled: workoutEnabled ?? this.workoutEnabled,
        workoutHour: workoutHour ?? this.workoutHour,
        workoutMinute: workoutMinute ?? this.workoutMinute,
        waterEnabled: waterEnabled ?? this.waterEnabled,
        waterHour: waterHour ?? this.waterHour,
        waterMinute: waterMinute ?? this.waterMinute,
      );
}

class NotificationPrefsNotifier extends Notifier<NotificationPrefs> {
  static const _kRest = 'notif_rest';
  static const _kWorkout = 'notif_workout';
  static const _kWorkoutH = 'notif_workout_h';
  static const _kWorkoutM = 'notif_workout_m';
  static const _kWater = 'notif_water';
  static const _kWaterH = 'notif_water_h';
  static const _kWaterM = 'notif_water_m';

  @override
  NotificationPrefs build() {
    _load();
    return const NotificationPrefs();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = NotificationPrefs(
      restEnabled: p.getBool(_kRest) ?? false,
      workoutEnabled: p.getBool(_kWorkout) ?? false,
      workoutHour: p.getInt(_kWorkoutH) ?? 18,
      workoutMinute: p.getInt(_kWorkoutM) ?? 0,
      waterEnabled: p.getBool(_kWater) ?? false,
      waterHour: p.getInt(_kWaterH) ?? 14,
      waterMinute: p.getInt(_kWaterM) ?? 0,
    );
  }

  Future<void> update(NotificationPrefs next) async {
    state = next;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kRest, next.restEnabled);
    await p.setBool(_kWorkout, next.workoutEnabled);
    await p.setInt(_kWorkoutH, next.workoutHour);
    await p.setInt(_kWorkoutM, next.workoutMinute);
    await p.setBool(_kWater, next.waterEnabled);
    await p.setInt(_kWaterH, next.waterHour);
    await p.setInt(_kWaterM, next.waterMinute);
  }
}

final notificationPrefsProvider =
    NotifierProvider<NotificationPrefsNotifier, NotificationPrefs>(
        NotificationPrefsNotifier.new);
