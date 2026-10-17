import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../feedback/rest_sound.dart';

/// Bildirim tercihleri (docs/16 §5 — B6). Kalıcı; zamanlama/iptal ekran
/// tarafında yapılır (tercih değişince ekran servis çağırır).
class NotificationPrefs {
  final bool restEnabled;
  // G-1: seans ekranı açıkken mola geri sayımı + bitiş sesi. Bildirimden
  // bağımsız (izin gerektirmez) → varsayılan AÇIK.
  final bool restSoundEnabled;
  // Mola sonu sesi (docs/45 §3) — geri sayım, Android servisi ve iOS
  // bildirimi aynı seçimi kullanır.
  final RestSound restSound;
  final bool workoutEnabled;
  final int workoutHour, workoutMinute;
  final bool waterEnabled;
  final int waterHour, waterMinute;
  // Haftalık değerlendirme (docs/22 §5): hafta kapanış günü 20:00. Diğer
  // hatırlatıcılar gibi varsayılan KAPALI — izin istemeden bildirim yok.
  final bool weeklyReviewEnabled;
  // Öğün hatırlatıcısı (docs/26): girilmemiş öğün için, alışkanlık saatinden
  // biraz sonra. İzin gerektirir → varsayılan KAPALI.
  final bool mealEnabled;
  // Beslenme ekranındaki "hatırlatıcıyı aç" önerisi kapatıldı mı.
  final bool mealCtaDismissed;
  // Dinlenme bildirimi izni ilk molada bir kez soruldu mu. Varsayılan kapalı
  // ayar yüzünden iPhone'da alttayken mola sonu hiç bildirilmiyordu
  // (Samet, 2026-10-07) — artık ilk mola başlarken bir kez sorulur.
  final bool restPrompted;
  // "Sıradaki antrenmanını hatırlatayım mı?" önerisi (docs/51 karar 4) ilk
  // antrenmandan sonra bir kez gösterildi mi. Kurulumda izin istenmez.
  final bool recallPrompted;

  const NotificationPrefs({
    this.restEnabled = false,
    this.restSoundEnabled = true,
    this.restSound = RestSound.fallback,
    this.workoutEnabled = false,
    this.workoutHour = 18,
    this.workoutMinute = 0,
    this.waterEnabled = false,
    this.waterHour = 14,
    this.waterMinute = 0,
    this.weeklyReviewEnabled = false,
    this.mealEnabled = false,
    this.mealCtaDismissed = false,
    this.restPrompted = false,
    this.recallPrompted = false,
  });

  /// İlk molada bildirim izni istenmeli mi: kullanıcı bildirimi hiç açmadı ve
  /// daha önce sorulmadı. Bir kez sorulur; reddederse Ayarlar'dan açar.
  bool get shouldOfferRest => !restEnabled && !restPrompted;

  /// Antrenman sonunda geri çağırma önerisi gösterilmeli mi: hatırlatıcı
  /// kapalı ve daha önce sorulmadı.
  bool get shouldOfferRecall => !workoutEnabled && !recallPrompted;

  NotificationPrefs copyWith({
    bool? restEnabled,
    bool? restSoundEnabled,
    RestSound? restSound,
    bool? workoutEnabled,
    int? workoutHour,
    int? workoutMinute,
    bool? waterEnabled,
    int? waterHour,
    int? waterMinute,
    bool? weeklyReviewEnabled,
    bool? mealEnabled,
    bool? mealCtaDismissed,
    bool? restPrompted,
    bool? recallPrompted,
  }) =>
      NotificationPrefs(
        restEnabled: restEnabled ?? this.restEnabled,
        restSoundEnabled: restSoundEnabled ?? this.restSoundEnabled,
        restSound: restSound ?? this.restSound,
        workoutEnabled: workoutEnabled ?? this.workoutEnabled,
        workoutHour: workoutHour ?? this.workoutHour,
        workoutMinute: workoutMinute ?? this.workoutMinute,
        waterEnabled: waterEnabled ?? this.waterEnabled,
        waterHour: waterHour ?? this.waterHour,
        waterMinute: waterMinute ?? this.waterMinute,
        weeklyReviewEnabled: weeklyReviewEnabled ?? this.weeklyReviewEnabled,
        mealEnabled: mealEnabled ?? this.mealEnabled,
        mealCtaDismissed: mealCtaDismissed ?? this.mealCtaDismissed,
        restPrompted: restPrompted ?? this.restPrompted,
        recallPrompted: recallPrompted ?? this.recallPrompted,
      );
}

class NotificationPrefsNotifier extends Notifier<NotificationPrefs> {
  static const _kRest = 'notif_rest';
  static const _kRestSound = 'notif_rest_sound';
  static const _kRestSoundId = 'notif_rest_sound_id';
  static const _kWorkout = 'notif_workout';
  static const _kWorkoutH = 'notif_workout_h';
  static const _kWorkoutM = 'notif_workout_m';
  static const _kWater = 'notif_water';
  static const _kWaterH = 'notif_water_h';
  static const _kWaterM = 'notif_water_m';
  static const _kWeekly = 'notif_weekly_review';
  static const _kMeal = 'notif_meal';
  static const _kMealCta = 'notif_meal_cta_dismissed';
  static const _kRestPrompted = 'notif_rest_prompted';
  static const _kRecallPrompted = 'notif_recall_prompted';

  @override
  NotificationPrefs build() {
    _load();
    return const NotificationPrefs();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = NotificationPrefs(
      restEnabled: p.getBool(_kRest) ?? false,
      restSoundEnabled: p.getBool(_kRestSound) ?? true,
      restSound: RestSound.fromId(p.getString(_kRestSoundId)),
      workoutEnabled: p.getBool(_kWorkout) ?? false,
      workoutHour: p.getInt(_kWorkoutH) ?? 18,
      workoutMinute: p.getInt(_kWorkoutM) ?? 0,
      waterEnabled: p.getBool(_kWater) ?? false,
      waterHour: p.getInt(_kWaterH) ?? 14,
      waterMinute: p.getInt(_kWaterM) ?? 0,
      weeklyReviewEnabled: p.getBool(_kWeekly) ?? false,
      mealEnabled: p.getBool(_kMeal) ?? false,
      mealCtaDismissed: p.getBool(_kMealCta) ?? false,
      restPrompted: p.getBool(_kRestPrompted) ?? false,
      recallPrompted: p.getBool(_kRecallPrompted) ?? false,
    );
  }

  /// Yeni hesap bu cihazda kurulumu bitirdi (docs/50 karar 3): haftalık
  /// değerlendirme bildirimi açık başlar. Kullanıcı bu ayarı daha önce
  /// seçtiyse (anahtar var) dokunulmaz — mevcut kullanıcı etkilenmez.
  /// Diskten okur/yazar; tembel `state` henüz yüklenmemiş olabilir.
  Future<bool> enableWeeklyReviewByDefault() async {
    final p = await SharedPreferences.getInstance();
    if (p.containsKey(_kWeekly)) return false;
    await p.setBool(_kWeekly, true);
    await _load();
    return true;
  }

  Future<void> update(NotificationPrefs next) async {
    state = next;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kRest, next.restEnabled);
    await p.setBool(_kRestSound, next.restSoundEnabled);
    await p.setString(_kRestSoundId, next.restSound.id);
    await p.setBool(_kWorkout, next.workoutEnabled);
    await p.setInt(_kWorkoutH, next.workoutHour);
    await p.setInt(_kWorkoutM, next.workoutMinute);
    await p.setBool(_kWater, next.waterEnabled);
    await p.setInt(_kWaterH, next.waterHour);
    await p.setInt(_kWaterM, next.waterMinute);
    await p.setBool(_kWeekly, next.weeklyReviewEnabled);
    await p.setBool(_kMeal, next.mealEnabled);
    await p.setBool(_kMealCta, next.mealCtaDismissed);
    await p.setBool(_kRestPrompted, next.restPrompted);
    await p.setBool(_kRecallPrompted, next.recallPrompted);
  }
}

final notificationPrefsProvider =
    NotifierProvider<NotificationPrefsNotifier, NotificationPrefs>(
        NotificationPrefsNotifier.new);
