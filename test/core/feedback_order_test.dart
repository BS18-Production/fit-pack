import 'dart:async';
import 'dart:io';

import 'package:fit_pack/core/feedback/audio_session_release.dart';
import 'package:fit_pack/core/feedback/feedback_service.dart';
import 'package:fit_pack/core/feedback/rest_sound.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// docs/45 (Codex 2. tur): kuyruktaki geri sayım "Atla" ile iptal edilirse
/// sonradan çalmamalı; ses yüklemesi sürerken gelen durdurma kazanır.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <String>[];
  late Completer<void> sourceGate;
  late Directory tmp;

  setUp(() {
    calls.clear();
    sourceGate = Completer<void>();
    tmp = Directory.systemTemp.createTempSync('fb');
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final sinks = <String, MockStreamHandlerEventSink>{};
    m.setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'),
        (c) async {
      calls.add(c.method);
      final id = (c.arguments as Map)['playerId'] as String;
      if (c.method == 'create') {
        m.setMockStreamHandler(
            EventChannel('xyz.luan/audioplayers/events/$id'),
            MockStreamHandler.inline(
                onListen: (_, sink) => sinks[id] = sink));
      }
      if (c.method == 'setSourceUrl') {
        await sourceGate.future; // ses yüklemesi yavaş
        // Yerel taraf gibi "hazır" olayı gönder.
        scheduleMicrotask(() => sinks[id]
            ?.success({'event': 'audio.onPrepared', 'value': true}));
      }
      return null;
    });
    m.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global'), (c) async => null);
    m.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (c) async => tmp.path);
  });

  test('yükleme sürerken çalma iptal edilirse ses çalmaz', () async {
    final f = FeedbackService(release: _NoRelease());
    // Kuyruğa alındı, henüz başlamadı — hemen "Atla" (Codex 2. tur durumu).
    f.playCountdown(sound: RestSound.boxingBell);
    f.stopCountdown();
    sourceGate.complete();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(calls, isNot(contains('resume')));
  });

  test('iptal yoksa çalar (kontrol)', () async {
    final f = FeedbackService(release: _NoRelease());
    f.playCountdown(sound: RestSound.boxingBell);
    sourceGate.complete();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(calls, contains('resume'));
  });
}

class _NoRelease extends AudioSessionRelease {
  const _NoRelease();
  @override
  Future<void> call() async {}
}
