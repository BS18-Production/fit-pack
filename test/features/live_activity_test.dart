import 'package:fit_pack/core/live_activity/workout_live_activity.dart';
import 'package:fit_pack/features/workout/live_position.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// docs/32 — kilit ekranı canlı etkinliği.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('şu anki set', () {
    test('ilk tamamlanmamış set; karışık sırada da sıradaki iş', () {
      expect(livePosition([
        [true, true, false],
        [false, false],
      ]), (exercise: 0, set: 2));
      expect(livePosition([
        [true, true],
        [true, false],
      ]), (exercise: 1, set: 1));
      expect(livePosition([
        [true],
        [true],
      ]), isNull);
      expect(livePosition([]), isNull);
    });
  });

  group('köprü', () {
    final calls = <String>[];
    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(WorkoutLiveActivity.channel, (c) async {
        calls.add(c.method);
        return true;
      });
    });
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    WorkoutLiveState st(int done, {DateTime? rest}) => WorkoutLiveState(
        exercise: 'Bench',
        setLabel: 'Set ${done + 1}/4',
        target: '80 kg × 8',
        restEndsAt: rest,
        doneSets: done,
        totalSets: 4);

    test('iOS: ilk gösterim başlatır, sonrası günceller, aynı durum gitmez',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final live = WorkoutLiveActivity();
      final t = DateTime(2026, 10, 8, 18);
      await live.show(title: 'İtme', startedAt: t, state: st(0));
      await live.show(title: 'İtme', startedAt: t, state: st(0));
      await live.show(title: 'İtme', startedAt: t, state: st(1));
      await live.end();
      await live.end();
      expect(calls, ['start', 'update', 'end']);
    });

    test('Android: hiçbir çağrı yok', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final live = WorkoutLiveActivity();
      await live.show(title: 'x', startedAt: DateTime(2026), state: st(0));
      await live.end();
      expect(calls, isEmpty);
    });
  });
}
