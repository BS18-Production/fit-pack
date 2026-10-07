import 'package:fit_pack/core/feedback/audio_session_release.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <String>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AudioSessionRelease.channel, (c) async {
      calls.add(c.method);
      return null;
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AudioSessionRelease.channel, null);
  });

  test('iOS: ses bitince oturum bırakılır (müzik geri açılır)', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await const AudioSessionRelease()();
    expect(calls, ['release']);
  });

  test('Android: işlem yok — ses odağını oynatıcı bırakır', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await const AudioSessionRelease()();
    expect(calls, isEmpty);
  });

  test('yerel hata seansı bozmaz', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AudioSessionRelease.channel,
            (c) async => throw PlatformException(code: 'audio_session'));
    await expectLater(const AudioSessionRelease()(), completes);
  });
}
