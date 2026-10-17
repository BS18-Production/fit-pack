import 'dart:math';

import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/workout_dao.dart';
import 'package:fit_pack/features/workout/history_summary.dart';
import 'package:fit_pack/features/workout/record_calc.dart';
import 'package:flutter_test/flutter_test.dart';

/// CR-016 — rekor sayımı geçmişi yeniden taramadan aynı sonucu vermeli.
///
/// [_reference] düzeltmeden önceki algoritmanın birebir kopyası: her seansta
/// hareketin bütün geçmiş listesini `newRecordFor` ile baştan tarar.
Map<int, int> _reference(
  Iterable<WorkoutSession> sessions,
  Map<int, List<WorkoutSet>> setsBySession,
) {
  final ordered = sessions.toList()
    ..sort((a, b) {
      final c = a.date.compareTo(b.date);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
  final history = <int, List<ExerciseSetPoint>>{};
  final counts = <int, int>{};
  var i = 0;
  while (i < ordered.length) {
    var j = i;
    while (j < ordered.length && ordered[j].date == ordered[i].date) {
      j++;
    }
    final pending = <int, List<ExerciseSetPoint>>{};
    for (final session in ordered.sublist(i, j)) {
      final byEx = <int, List<ExerciseSetPoint>>{};
      for (final s in setsBySession[session.id] ?? const <WorkoutSet>[]) {
        if (s.isWarmup) continue;
        byEx.putIfAbsent(s.exerciseId, () => []).add(ExerciseSetPoint(
            date: session.date, weightKg: s.weightKg, reps: s.reps));
      }
      var n = 0;
      for (final e in byEx.entries) {
        final rec = newRecordFor(
          name: '',
          priorHistory: history[e.key] ?? const [],
          sessionPoints: e.value,
        );
        if (rec != null) n++;
        pending.putIfAbsent(e.key, () => []).addAll(e.value);
      }
      counts[session.id] = n;
    }
    for (final e in pending.entries) {
      history.putIfAbsent(e.key, () => []).addAll(e.value);
    }
    i = j;
  }
  return counts;
}

void main() {
  var seq = 0;
  WorkoutSet set(int session, int ex, double? kg, int? reps,
          {bool warmup = false}) =>
      WorkoutSet(
        id: ++seq,
        sessionId: session,
        exerciseId: ex,
        setNumber: seq,
        weightKg: kg,
        reps: reps,
        isWarmup: warmup,
        setType: warmup ? 'warmup' : 'normal',
        isComplete: true,
      );
  WorkoutSession session(int id, DateTime date) => WorkoutSession(
        id: id,
        date: date,
        phase: 0,
        workoutType: 'Push',
        kneeStatus: 'normal',
        isDeload: false,
      );

  /// Rastgele geçmiş: aynı anı paylaşan seanslar, ısınma, kilosuz/tekrarsız
  /// setler, sıfır değerler — kenar durumların hepsi.
  ({List<WorkoutSession> sessions, Map<int, List<WorkoutSet>> sets}) randomHistory(
      Random r, int n) {
    final base = DateTime(2025, 1, 1);
    final sessions = <WorkoutSession>[];
    final sets = <int, List<WorkoutSet>>{};
    for (var id = 1; id <= n; id++) {
      // Gün aralığı dar → sık sık aynı an (grup kuralı sınanır).
      final date = base.add(Duration(hours: r.nextInt(n ~/ 2 + 1) * 12));
      sessions.add(session(id, date));
      sets[id] = [
        for (var k = 0; k < r.nextInt(6); k++)
          set(
            id,
            1 + r.nextInt(4),
            r.nextInt(8) == 0 ? null : (r.nextInt(30) * 2.5),
            r.nextInt(8) == 0 ? null : r.nextInt(13),
            warmup: r.nextInt(5) == 0,
          ),
      ];
    }
    sessions.shuffle(r);
    return (sessions: sessions, sets: sets);
  }

  test('rastgele geçmişlerde eski algoritmayla birebir aynı', () {
    final r = Random(16);
    for (var round = 0; round < 300; round++) {
      final h = randomHistory(r, 1 + r.nextInt(40));
      expect(recordCountsBySession(h.sessions, h.sets),
          _reference(h.sessions, h.sets),
          reason: 'tur $round');
    }
  });

  test('aynı anı paylaşan seanslar birbirine "önceki" sayılmaz', () {
    final t = DateTime(2026, 10, 1);
    final counts = recordCountsBySession([
      session(1, DateTime(2026, 9, 1)),
      session(2, t),
      session(3, t),
    ], {
      1: [set(1, 1, 60, 8)],
      2: [set(2, 1, 70, 8)],
      3: [set(3, 1, 65, 8)], // 2'yi geçmez ama 1'i geçer → rekor
    });
    expect(counts, {1: 0, 2: 1, 3: 1});
  });

  test('2000 seanslık tek hareket geçmişi hızlı hesaplanır', () {
    final sessions = <WorkoutSession>[];
    final sets = <int, List<WorkoutSet>>{};
    for (var id = 1; id <= 2000; id++) {
      sessions.add(session(id, DateTime(2020, 1, 1).add(Duration(days: id))));
      sets[id] = [for (var k = 0; k < 5; k++) set(id, 1, 40.0 + id % 50, 8)];
    }
    final sw = Stopwatch()..start();
    final counts = recordCountsBySession(sessions, sets);
    sw.stop();
    expect(counts.length, 2000);
    expect(sw.elapsedMilliseconds, lessThan(1000),
        reason: 'doğrusal olmalı — eski hâli ~10M set noktası tarıyordu '
            '(sınır makine yüküne karşı geniş)');
  });

  test('withPoints bestsOf ile aynı', () {
    final pts = [
      ExerciseSetPoint(date: DateTime(2026), weightKg: 100, reps: 3),
      ExerciseSetPoint(date: DateTime(2026), weightKg: 80, reps: 12),
      ExerciseSetPoint(date: DateTime(2026), weightKg: null, reps: 20),
    ];
    final a = bestsOf(pts);
    final b = bestsOf(pts.take(1)).withPoints(pts.skip(1));
    expect((b.e1rm, b.weightKg), (a.e1rm, a.weightKg));
  });
}
