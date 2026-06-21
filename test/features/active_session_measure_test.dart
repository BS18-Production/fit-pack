import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/workout/active_session_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// Aktif seansta ölçüm tipine göre süre/mesafe biçimlendirme ve ayrıştırma
/// (kg×tekrar olmayan hareketler: plank, koşu bandı, yüzme).
void main() {
  group('Süre biçimi (mmss)', () {
    test('saniyeyi dk:sn yapar', () {
      expect(mmss(45), '0:45');
      expect(mmss(90), '1:30');
      expect(mmss(750), '12:30');
      expect(mmss(0), '0:00');
    });
  });

  group('Süre ayrıştırma (parseDuration)', () {
    test('dk:sn metni saniyeye çevrilir', () {
      expect(parseDuration('12:30'), 750);
      expect(parseDuration('0:45'), 45);
      expect(parseDuration('1:05'), 65);
    });
    test('saf sayı dakika kabul edilir', () {
      expect(parseDuration('30'), 1800);
      expect(parseDuration('1.5'), 90);
    });
    test('boş/geçersiz → null', () {
      expect(parseDuration(''), isNull);
      expect(parseDuration('  '), isNull);
    });
  });

  group('Geçen seans etiketi (prevLabel) ölçüm tipine göre', () {
    WorkoutSet set({double? kg, int? reps, int? dur, double? dist}) => WorkoutSet(
          id: 1,
          sessionId: 1,
          exerciseId: 1,
          setNumber: 1,
          weightKg: kg,
          reps: reps,
          isWarmup: false,
          durationSec: dur,
          distanceM: dist,
          setType: 'normal',
          isComplete: true,
        );

    test('weight_reps → "60×8"', () {
      expect(prevLabel(set(kg: 60, reps: 8), 'weight_reps'), '60×8');
    });
    test('reps → "12"', () {
      expect(prevLabel(set(reps: 12), 'reps'), '12');
    });
    test('time → "12:30"', () {
      expect(prevLabel(set(dur: 750), 'time'), '12:30');
    });
    test('distance → "5.2 km"', () {
      expect(prevLabel(set(dist: 5200), 'distance'), '5.2 km');
    });
    test('veri yoksa → null', () {
      expect(prevLabel(null, 'time'), isNull);
      expect(prevLabel(set(), 'distance'), isNull);
    });
  });
}
