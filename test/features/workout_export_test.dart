import 'dart:convert';

import 'package:fit_pack/features/health/health_prefs.dart';
import 'package:fit_pack/features/health/workout_export.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// docs/44 — antrenmanı Sağlık'a yazma: giden kutusu (H-3, H-5).
class _Sink implements WorkoutSink {
  _Sink({this.ok = true});
  bool ok;
  final written = <String>[];
  @override
  Future<bool> requestWriteAccess() async => true;
  @override
  Future<bool> write(WorkoutExport w) async {
    if (ok) written.add(w.uid);
    return ok;
  }
}

WorkoutExport _seans(String uid) => WorkoutExport(
  uid: uid,
  start: DateTime(2026, 10, 11, 18),
  end: DateTime(2026, 10, 11, 19, 5),
  title: 'Push',
  isCardio: false,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'yazılan seans kutudan çıkar; aynı seans iki kez kuyruğa girmez',
    () async {
      final sink = _Sink();
      await WorkoutOutbox.enqueue(_seans('a'));
      await WorkoutOutbox.enqueue(_seans('a'));
      expect(await WorkoutOutbox.flush(sink), 1);
      expect(sink.written, ['a']);
      expect(await WorkoutOutbox.pendingCount(), 0);
      expect(await WorkoutOutbox.flush(sink), 0, reason: 'ikinci kez yazılmaz');
    },
  );

  test('başarısız yazma kutuda kalır, sonra yeniden denenir (H-5)', () async {
    final sink = _Sink(ok: false);
    await WorkoutOutbox.enqueue(_seans('a'));
    expect(await WorkoutOutbox.flush(sink), 0);
    expect(await WorkoutOutbox.pendingCount(), 1);
    sink.ok = true;
    expect(await WorkoutOutbox.flush(sink), 1);
  });

  test(
    "H-3: 'writing'te kalan (yazma sırasında kapanmış) yeniden denenmez",
    () async {
      SharedPreferences.setMockInitialValues({
        'health_workout_outbox': jsonEncode({
          'a': {'state': 'writing', 'w': _seans('a').toJson()},
        }),
      });
      final sink = _Sink();
      expect(await WorkoutOutbox.flush(sink), 0);
      expect(sink.written, isEmpty, reason: 'çift kayıt riski → atla');
      expect(await WorkoutOutbox.pendingCount(), 0);
    },
  );

  test('hesap değişiminde kutu ve tercih silinir', () async {
    SharedPreferences.setMockInitialValues({'health_write_workouts': true});
    await WorkoutOutbox.enqueue(_seans('a'));
    await HealthPrefs.clear();
    final p = await SharedPreferences.getInstance();
    expect(p.getBool('health_write_workouts'), isNull);
    expect(await WorkoutOutbox.pendingCount(), 0);
  });

  test('bozuk kutu kaydı uygulamayı durdurmaz', () async {
    SharedPreferences.setMockInitialValues({'health_workout_outbox': '{bozuk'});
    expect(await WorkoutOutbox.flush(_Sink()), 0);
  });
}
