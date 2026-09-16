import 'package:fit_pack/core/feedback/feedback_service.dart';
import 'package:fit_pack/core/notifications/notification_prefs.dart';
import 'package:flutter_test/flutter_test.dart';

/// G-1 — mola sonu sesi. Seans ekranı açıkken uygulama ön planda kaldığı
/// için bildirim düşmüyordu; ses/titreşim bu karardan çıkar.
void main() {
  RestCue cue(int prev, int left, {int overdueMs = 0}) =>
      restCueFor(prevLeft: prev, left: left, overdueMs: overdueMs);

  group('restCueFor', () {
    test('son 3 saniyede her inişte tık', () {
      expect(cue(4, 3), RestCue.tick);
      expect(cue(3, 2), RestCue.tick);
      expect(cue(2, 1), RestCue.tick);
    });

    test('3 saniyeden önce sessiz', () {
      expect(cue(60, 59), RestCue.none);
      expect(cue(5, 4), RestCue.none);
    });

    test('atlanan saniye olsa da geri sayıma girişte tık verilir', () {
      expect(cue(5, 2), RestCue.tick);
    });

    test('zamanında 0 → bitiş', () {
      expect(cue(1, 0, overdueMs: 20), RestCue.done);
      expect(cue(1, 0, overdueMs: restDoneLateMs), RestCue.done);
    });

    test('arka plandan geç dönüşte bitiş sesi çalmaz (bildirim karşıladı)',
        () {
      expect(cue(40, 0, overdueMs: 25000), RestCue.none);
    });

    test('süre artırılınca ya da yeni mola başlayınca sessiz', () {
      expect(cue(2, 17), RestCue.none); // +15 sn
      expect(cue(0, 60), RestCue.none); // yeni mola
      expect(cue(0, 2), RestCue.none); // 0'dan kısa mola başlatma
      expect(cue(3, 3), RestCue.none); // aynı saniyede ikinci tik
    });

    test('bitmiş sayaç tekrar bitiş üretmez', () {
      expect(cue(0, 0), RestCue.none);
      expect(cue(0, -3, overdueMs: 3000), RestCue.none);
    });
  });

  test('mola sesi varsayılan AÇIK, arka plan bildirimi varsayılan kapalı', () {
    const p = NotificationPrefs();
    expect(p.restSoundEnabled, isTrue);
    expect(p.restEnabled, isFalse);
    expect(p.copyWith(restSoundEnabled: false).restSoundEnabled, isFalse);
    expect(p.copyWith(restEnabled: true).restSoundEnabled, isTrue);
  });
}
