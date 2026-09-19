import '../../core/notifications/notification_service.dart';
import '../../l10n/app_l10n.dart';

/// Haftalık değerlendirme hatırlatıcısının saati (docs/22 §9 soru 1).
const weeklyReviewHour = 20;
const weeklyReviewMinute = 0;

/// Haftalık değerlendirme bildirimini **hafta kapanış günü 20:00**'ye kurar
/// (docs/22 §5). İki yerden çağrılır ve ikisi de aynı günü hesaplamalı:
/// bildirim ayarı açılınca ve hafta başlangıcı tercihi değişince.
///
/// Metin bilinçli olarak sayı İÇERMEZ: tekrar eden bildirimin metni kurulduğu
/// an sabitlenir; "3 antrenman" yazsaydı pazar akşamı çoktan eskimiş bir
/// sayıyı gösterirdi. Sayılar dokununca açılan ekranda, canlı.
Future<void> scheduleWeeklyReviewReminder({
  required NotificationService service,
  required AppL10n l,
  required int weekStart,
}) =>
    service.scheduleWeekly(
      id: NotificationService.idWeeklyReview,
      weekday: weekClosingDay(weekStart),
      hour: weeklyReviewHour,
      minute: weeklyReviewMinute,
      title: l.notifWeeklyTitle,
      body: l.notifWeeklyBody,
      payload: NotificationService.payloadWeeklyReview,
    );
