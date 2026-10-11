import 'package:fit_pack/core/live_activity/workout_live_activity.dart';
import 'package:fit_pack/features/workout/live_position.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

    // Kök neden (2026-10-11, çift kilit ekranı): seans açılışında _load
    // aynı karede iki kez _syncLive çağırıyor (_syncLive + _saveDraft).
    // İlk 'start' dönmeden ikinci çağrı da "etkin değil" görüp ikinci kez
    // 'start' gönderiyordu → iOS'ta iki Canlı Etkinlik.
    test('iOS: beklenmeden art arda gösterim tek başlatma yapar', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final live = WorkoutLiveActivity();
      final t = DateTime(2026, 10, 8, 18);
      final a = live.show(title: 'İtme', startedAt: t, state: st(0));
      final b = live.show(
          title: 'İtme',
          startedAt: t,
          state: st(0, rest: DateTime(2026, 10, 8, 18, 2)));
      await Future.wait([a, b]);
      expect(calls, ['start', 'update']);
    });

    test('Android: aynı köprü (seans bildirimi), masaüstünde çağrı yok',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final live = WorkoutLiveActivity();
      await live.show(title: 'x', startedAt: DateTime(2026), state: st(0));
      await live.end();
      expect(calls, ['start', 'end']);

      calls.clear();
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final desk = WorkoutLiveActivity();
      await desk.show(title: 'x', startedAt: DateTime(2026), state: st(0));
      await desk.end();
      expect(calls, isEmpty);
    });

    test('kanal hata verirse sonraki gösterim yeniden başlatır', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      var fail = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(WorkoutLiveActivity.channel, (c) async {
        calls.add(c.method);
        if (fail) throw PlatformException(code: 'x');
        return true;
      });
      final live = WorkoutLiveActivity();
      final t = DateTime(2026, 10, 8, 18);
      await live.show(title: 'İtme', startedAt: t, state: st(0));
      fail = false;
      await live.show(title: 'İtme', startedAt: t, state: st(0));
      expect(calls, ['start', 'start']);
    });
  });

  group('kilit ekranı eylemleri', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    Future<Object?> fromNative(String action) async {
      const codec = StandardMethodCodec();
      Object? reply;
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        WorkoutLiveActivity.channel.name,
        codec.encodeMethodCall(MethodCall('action', action)),
        (data) => reply = data == null ? null : codec.decodeEnvelope(data),
      );
      return reply;
    }

    test('eylem bağlı seans ekranına gider; ekran yoksa false', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final live = WorkoutLiveActivity();
      final got = <LiveAction>[];
      Future<bool> handler(LiveAction a) async {
        got.add(a);
        return true;
      }

      live.attach(handler);
      expect(await fromNative('completeSet'), isTrue);
      expect(await fromNative('skipRest'), isTrue);
      expect(await fromNative('bilinmeyen'), isFalse);
      expect(got, [LiveAction.completeSet, LiveAction.skipRest]);

      live.detach(handler);
      expect(await fromNative('addRest'), isFalse);
      expect(got, hasLength(2));
    });
  });
}
