import 'dart:async';

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

    test('dış temizlik bekleyen eski yayını iptal eder; yeni seans başlayabilir',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final started = Completer<void>();
      final release = Completer<void>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(WorkoutLiveActivity.channel, (c) async {
        calls.add(c.method);
        if (c.method == 'start' && !started.isCompleted) {
          started.complete();
          await release.future;
        }
        return true;
      });
      final live = WorkoutLiveActivity();
      final first = live.show(title: 'x', startedAt: DateTime(2026), state: st(0));
      await started.future;
      final queued = live.show(title: 'x', startedAt: DateTime(2026), state: st(1));
      await WorkoutLiveActivity.endAll();
      release.complete();
      await Future.wait([first, queued]);
      expect(calls, ['start', 'end'], reason: 'temizlik sonrası eski update yok');
      await live.show(title: 'y', startedAt: DateTime(2026, 2), state: st(1));
      expect(calls, ['start', 'end', 'start']);
      await live.end();
    });
    test('eski kuyruğun kapanışı dış temizlikten sonraki yeni kartı kapatmaz',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final started = Completer<void>();
      final release = Completer<void>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(WorkoutLiveActivity.channel, (c) async {
        calls.add(c.method);
        if (c.method == 'start' && !started.isCompleted) {
          started.complete();
          await release.future;
        }
        return true;
      });
      final oldLive = WorkoutLiveActivity();
      final oldStart = oldLive.show(
          title: 'old', startedAt: DateTime(2026), state: st(0));
      await started.future;
      final oldEnd = oldLive.end();
      await WorkoutLiveActivity.endAll();
      final fresh = WorkoutLiveActivity();
      await fresh.show(title: 'new', startedAt: DateTime(2026, 2), state: st(1));
      release.complete();
      await Future.wait([oldStart, oldEnd]);
      expect(calls, ['start', 'end', 'start']);
      await fresh.end();
    });
  });

  group('kilit ekranı eylemleri', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    Future<Object?> fromNative(Object action) async {
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
      final keys = <String?>[];
      Future<bool> handler(LiveAction a, String? key) async {
        got.add(a);
        keys.add(key);
        return true;
      }

      live.attach(handler);
      expect(await fromNative('completeSet'), isTrue);
      expect(await fromNative('skipRest'), isTrue);
      expect(await fromNative({'action': 'stepUp', 'setKey': '12:1'}), isTrue);
      expect(await fromNative('bilinmeyen'), isFalse);
      expect(got,
          [LiveAction.completeSet, LiveAction.skipRest, LiveAction.stepUp]);
      expect(keys, [null, null, '12:1'], reason: 'set kimliği iletilir');

      live.detach(handler);
      expect(await fromNative('addRest'), isFalse);
      expect(got, hasLength(3));
    });
  });
}
