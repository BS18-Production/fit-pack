import 'dart:async';

import '../../core/feedback/feedback_service.dart';
import '../../core/feedback/rest_alarm.dart';
import '../../core/feedback/rest_sound.dart';
import '../../core/notifications/notification_prefs.dart';
import '../../core/notifications/notification_service.dart';
import '../../l10n/app_l10n.dart';

/// Mola sonu sesi/titreşimi ve bildirimi için yerel köprü (docs/25, docs/45
/// §3) — aktif seans ekranından ayrıldı (CR-018).
///
/// Tek karar burada: ses Android yerel servisinden mi geliyor ([native]) yoksa
/// uygulama içinden mi (iOS, servis başlatılamadı). Molanın kendisi (bitiş
/// anı, ekrandaki sayı, taslak) ekranda kalır; bu sınıf yalnız verilen bitiş
/// anına göre çalar, susturur ve bildirimi kurar/kaldırır.
class SessionRestSound {
  final RestAlarm _alarm;
  final FeedbackService _feedback;

  SessionRestSound(this._alarm, this._feedback);

  /// Ses/titreşim Android yerel servisinde mi? true ise uygulama çalmaz.
  bool native = false;
  Timer? _countdownTimer; // uygulama içi yol: geri sayım sesinin başlangıcı

  /// Kurulumdan önce: bekleyen uygulama içi geri sayımı ve sesini keser.
  void resetCountdown() {
    _countdownTimer?.cancel();
    _feedback.stopCountdown();
  }

  /// Yerel servisi [deadline]'a kurar; servis çalıyorsa true döner.
  /// Sonucu [native]'e yazmak çağıranın işidir — beklerken mola değiştiyse
  /// sonuç eskimiştir.
  Future<bool> startNative({
    required DateTime deadline,
    required NotificationPrefs prefs,
    required AppL10n l,
  }) => _alarm.start(
    deadline: deadline,
    sound: prefs.restSoundEnabled,
    soundFile: prefs.restSound,
    title: l.labelRest,
    // Boş = "bitti" bildirimi yok (kullanıcı mola bildirimini kapattı).
    doneTitle: prefs.restEnabled ? l.notifRestDoneTitle : '',
    doneBody: l.notifRestDoneBody,
  );

  /// Uygulama içi yol: bitişten 3 sn önce tek parça geri sayım sesini
  /// başlatır. [isCurrent] false dönerse (mola değişti/atlandı) çalmaz.
  void scheduleCountdown(
    DateTime deadline,
    RestSound sound,
    bool Function() isCurrent,
  ) {
    final plan = countdownPlan(
      deadline.difference(DateTime.now()).inMilliseconds,
    );
    if (plan == null) return;
    _countdownTimer = Timer(Duration(milliseconds: plan.delayMs), () {
      if (!isCurrent()) return;
      // Zamanlayıcı geç düştüyse dosyanın doğru yerinden başla.
      final now = countdownPlan(
        deadline.difference(DateTime.now()).inMilliseconds,
      );
      if (now != null) {
        _feedback.playCountdown(offsetMs: now.offsetMs, sound: sound);
      }
    });
  }

  /// Mola sonu bildirimini duruma göre kurar ya da kaldırır (docs/45 §3).
  ///
  /// Kurulur: dinlenme sürüyor, uygulama ön planda DEĞİL, bildirim açık ve
  /// sesi Android yerel servisi vermiyor (docs/25). Yalnız `paused` anında
  /// kurmak yetmiyordu: kilit ekranından "Seti tamamla" ile başlayan
  /// dinlenme uygulama zaten arkadayken başlar — o molanın bildirimi hiç
  /// kurulmazdı. Bu yüzden dinlenme başlarken/değişirken de çağrılır.
  Future<void> syncNotification({
    required NotificationService service,
    required NotificationPrefs prefs,
    required DateTime? deadline,
    required bool inForeground,
    required AppL10n l,
  }) {
    final now = DateTime.now();
    if (native ||
        inForeground ||
        deadline == null ||
        !deadline.isAfter(now) ||
        !prefs.restEnabled) {
      return service.cancelRestDone();
    }
    return service.scheduleRestDone(
      at: deadline,
      title: l.notifRestDoneTitle,
      body: l.notifRestDoneBody,
      earlyTitle: l.notifRestEndingTitle,
      earlyBody: l.notifRestEndingBody,
      sound: prefs.restSoundEnabled ? prefs.restSound : null,
    );
  }

  /// Bitiş titreşimi — Android'de servis veriyor (çift titreşim olmasın).
  void restDoneIfInApp() {
    if (!native) _feedback.restDone();
  }

  /// Mola atlandı: geri sayım, ses ve yerel servis durur.
  void stop() {
    _countdownTimer?.cancel();
    _feedback.stopCountdown();
    _alarm.stop();
  }

  /// Öne dönüldü: "mola bitti" bildirimi kalksın.
  void dismissDone() => _alarm.dismissDone();

  /// Ekran kapanıyor. [restRunning] ise çalan mola servisi de kapanır.
  void dispose({required bool restRunning}) {
    _countdownTimer?.cancel();
    if (restRunning) {
      // Seanstan çıkıldı/bitti: çalan mola servisi de kapansın.
      _alarm.stop();
      _feedback.stopCountdown();
    }
  }
}
