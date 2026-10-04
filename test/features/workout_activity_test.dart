import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/home/workout_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2027, 1, 3, 23);
  WorkoutSession session(int id, DateTime date, {int? minutes = 60, String type = 'Push'}) =>
      WorkoutSession(id: id, date: date, phase: 0, workoutType: type,
          durationMin: minutes, kneeStatus: 'normal', isDeload: false, syncState: 0);
  List<WorkoutActivityDay> calculate(List<WorkoutSession> sessions, {double? weight = 80}) =>
      workoutActivityDays(now: now, sessions: sessions,
          setsBySession: const {}, bodyWeightKg: weight);

  test('takvim/yıl sınırı: yedi gün, bugüne kadar; aralık dışı seans sayılmaz', () {
    final days = calculate([session(1, DateTime(2026, 12, 27)),
        session(2, DateTime(2027, 1, 4))]);
    expect(days.first.date, DateTime(2026, 12, 28));
    expect(days.last.date, DateTime(2027, 1, 3));
    expect(days.length, 7);
    expect(days.every((d) => d.sessions == 0 && d.kcal == 0), isTrue);
  });
  test('aynı günün seansları mevcut kalori formülüyle toplanır', () {
    final days = calculate([session(1, DateTime(2027, 1, 3, 10)),
        session(2, DateTime(2027, 1, 3, 20), minutes: 30)]);
    expect(days.last.sessions, 2);
    expect(days.last.kcal, 630);
  });
  test('kilo yok: kayıtlı seans tahmini null, kayıtsız gün gerçek kayıt toplamı 0', () {
    final days = calculate([session(1, now)], weight: null);
    expect(days.last.kcal, isNull);
    expect(days.last.sessions, 1);
    expect(days.first.kcal, 0);
  });
  test('eksik süre, bilinen diğer seansın kısmi toplamı olarak gösterilmez', () {
    final days = calculate([session(1, now), session(2, now, minutes: null)]);
    expect(days.last.kcal, isNull);
    expect(days.last.sessions, 2);
  });
  test('kardiyo eski tahmin motorunun kardiyo yoğunluğunu korur', () {
    expect(calculate([session(1, now, type: 'Cardio')]).last.kcal, 588);
  });
}
