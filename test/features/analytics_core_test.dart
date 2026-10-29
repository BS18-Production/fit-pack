import 'dart:async';
import 'dart:convert';

import 'package:fit_pack/features/analytics/analytics_controller.dart';
import 'package:fit_pack/features/analytics/analytics_events.dart';
import 'package:fit_pack/features/analytics/analytics_providers.dart';
import 'package:fit_pack/features/analytics/analytics_remote.dart';
import 'package:fit_pack/features/analytics/analytics_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const ownerA = '00000000-0000-4000-8000-00000000000a';
const ownerB = '00000000-0000-4000-8000-00000000000b';
final at = DateTime.utc(2026, 10, 29, 12);
AnalyticsContext metadata() => AnalyticsContext(
  version: '1.0.0',
  build: '2',
  platform: 'ios',
  osMajor: 26,
  environment: 'test',
);

class MemoryStorage implements AnalyticsStorage {
  String? raw;
  bool fail = false;
  @override
  Future<String?> read() async => raw;
  @override
  Future<void> write(String value) async {
    if (fail) throw const AnalyticsStorageException();
    raw = value;
  }
}

class FakeRemote implements AnalyticsRemote {
  final preferences = <String, AnalyticsConsent>{};
  final ingestions =
      <({String owner, int generation, List<AnalyticsEvent> events})>[];
  final accepted = <String>{};
  final revocations = <String>[];
  final requests = <String>{};
  int calls = 0;
  bool fail = false;
  bool loseAcknowledgement = false;
  bool loseConsentAcknowledgement = false;
  String? ingestError;
  Completer<void>? ingestionGate;
  Completer<void>? ingestionStarted;
  Completer<void>? statusGate;

  AnalyticsConsent preference(String owner) =>
      preferences[owner] ??
      const AnalyticsConsent(
        enabled: false,
        generation: 0,
        policyVersion: null,
      );
  void check() {
    calls++;
    if (fail) throw const AnalyticsRemoteException('network');
  }

  @override
  Future<AnalyticsConsent> status(String ownerId) async {
    check();
    await statusGate?.future;
    return preference(ownerId);
  }

  @override
  Future<AnalyticsConsent> consent(
    String ownerId, {
    required bool enabled,
    required int expectedGeneration,
    required String requestId,
  }) async {
    check();
    final before = preference(ownerId);
    if (!requests.add('$ownerId:$requestId')) return before;
    if (enabled && before.generation != expectedGeneration) {
      throw const AnalyticsRemoteException('stale_consent');
    }
    if (!enabled) revocations.add(ownerId);
    final result = preferences[ownerId] = AnalyticsConsent(
      enabled: enabled,
      generation: before.generation + 1,
      policyVersion: analyticsPolicyVersion,
    );
    if (loseConsentAcknowledgement) {
      throw const AnalyticsRemoteException('network');
    }
    return result;
  }

  @override
  Future<void> ingest(
    String ownerId,
    int generation,
    List<AnalyticsEvent> events,
  ) async {
    check();
    final code = ingestError;
    if (code != null) throw AnalyticsRemoteException(code);
    ingestionStarted?.complete();
    await ingestionGate?.future;
    final current = preference(ownerId);
    if (!current.enabled || current.generation != generation) {
      throw const AnalyticsRemoteException('stale_consent');
    }
    ingestions.add((
      owner: ownerId,
      generation: generation,
      events: List.of(events),
    ));
    accepted.addAll(events.map((event) => event.eventId));
    if (loseAcknowledgement) throw const AnalyticsRemoteException('network');
  }
}

AnalyticsController makeController(
  MemoryStorage store,
  FakeRemote remote, {
  bool featureEnabled = true,
  DateTime Function()? clock,
  Future<AnalyticsContext> Function()? context,
}) {
  final controller = AnalyticsController(
    storage: store,
    remote: remote,
    context: context ?? () async => metadata(),
    featureEnabled: featureEnabled,
    now: clock ?? () => at,
    autoFlushDelay: const Duration(days: 1),
  );
  addTearDown(controller.dispose);
  return controller;
}

Future<void> activate(AnalyticsController controller) async {
  await controller.setAccount(ownerA);
  expect(await controller.setEnabled(true), isTrue);
}

void main() {
  group('kapalı veri sözleşmesi', () {
    test('ek sağlık, serbest metin ve iç içe alanlar reddedilir', () {
      expect(
        validAnalyticsProperties(AnalyticsEventName.workoutSaved, {
          'mode': 'routine',
          'source': 'live',
        }),
        isTrue,
      );
      for (final field in [
        'weight',
        'reps',
        'exercise',
        'email',
        'question',
        'note',
        'url',
        'token',
      ]) {
        expect(
          validAnalyticsProperties(AnalyticsEventName.workoutSaved, {
            'mode': 'routine',
            'source': 'live',
            field: 'private',
          }),
          isFalse,
        );
      }
      expect(
        validAnalyticsProperties(AnalyticsEventName.workoutStarted, {
          'mode': {'name': 'private'},
        }),
        isFalse,
      );
      expect(
        validAnalyticsProperties(AnalyticsEventName.workoutStarted, {
          'mode': 'my custom routine',
        }),
        isFalse,
      );
    });

    test(
      'zarf ve bağlam ek alanları kabul etmez, özellik kopyası değişmez',
      () {
        final props = <String, Object>{'mode': 'free'};
        final event = AnalyticsEvent(
          eventId: ownerA,
          occurredAt: at,
          sessionId: ownerB,
          name: AnalyticsEventName.workoutStarted,
          properties: props,
          context: metadata(),
        );
        props['mode'] = 'private';
        expect(event.properties, {'mode': 'free'});
        expect(
          () => event.properties['note'] = 'private',
          throwsUnsupportedError,
        );
        expect(
          () => AnalyticsEvent.fromJson({...event.toJson(), 'health': 80}),
          throwsFormatException,
        );
        expect(
          () => AnalyticsContext.fromJson({
            ...metadata().toJson(),
            'device_id': 'x',
          }),
          throwsFormatException,
        );
        expect(
          () => AnalyticsContext.fromJson({
            ...metadata().toJson(),
            'os_major': 26.1,
          }),
          throwsFormatException,
        );
        expect(
          AnalyticsEvent.fromJson(event.toJson()).toJson(),
          event.toJson(),
        );
        for (final version in ['1000.1.0', '1.0.0-preview', '1.0.0+2']) {
          expect(
            () => AnalyticsContext.fromJson({
              ...metadata().toJson(),
              'version': version,
            }),
            throwsFormatException,
          );
        }
      },
    );

    test('aralıklar değerlerin kendisini saklamaz', () {
      expect(analyticsPendingBucket(0), 'zero');
      expect(analyticsPendingBucket(9), '1_10');
      expect(analyticsPendingBucket(100), '11_100');
      expect(analyticsPendingBucket(101), 'over_100');
      expect(
        analyticsSessionDurationBucket(const Duration(minutes: 5)),
        '5_15m',
      );
      expect(analyticsSyncDurationBucket(const Duration(seconds: 5)), '5_30s');
      expect(analyticsOsMajor('ios', 'Version 26.1 (Build 23B74)'), 26);
      expect(analyticsOsMajor('android', 'Android 16'), 16);
      expect(analyticsOsMajor('android', '#1 SMP Linux 6.6.30-android15'), 0);
      expect(analyticsOsMajor('other', 'macOS Version 26'), 0);
    });
  });

  test(
    'varsayılan kapalı; tercih öncesi olay, bağlam okuma ve ağ yok',
    () async {
      final store = MemoryStorage(), remote = FakeRemote();
      var contextReads = 0;
      final c = makeController(
        store,
        remote,
        context: () async {
          contextReads++;
          return metadata();
        },
      );
      await c.setAccount(ownerA);
      await c.onForeground(coldStart: true);
      await c.track(AnalyticsEventName.workoutStarted, {'mode': 'free'});
      await c.flush();
      expect(c.enabled, isFalse);
      expect(c.pendingCount, 0);
      expect(remote.calls, 0);
      expect(contextReads, 0);
    },
  );

  test('derleme kapısı kapalıysa kullanıcı bile etkinleştiremez', () async {
    final remote = FakeRemote();
    final c = makeController(MemoryStorage(), remote, featureEnabled: false);
    await c.setAccount(ownerA);
    expect(await c.setEnabled(true), isFalse);
    await c.onForeground();
    await c.track(AnalyticsEventName.workoutStarted, {'mode': 'routine'});
    expect(remote.calls, 0);
    expect(c.pendingCount, 0);
  });

  test(
    'geri alınmış derlemede açık tercih görünmese de kullanıcı sunucuda geri alabilir',
    () async {
      final store = MemoryStorage(), remote = FakeRemote();
      final earlier = makeController(store, remote);
      await activate(earlier);
      await earlier.track(AnalyticsEventName.workoutStarted, {
        'mode': 'routine',
      });
      expect(earlier.pendingCount, 1);
      final callsBeforeRollback = remote.calls;

      final rollback = makeController(store, remote, featureEnabled: false);
      await rollback.setAccount(ownerA);
      await rollback.onForeground(coldStart: true);
      await rollback.track(AnalyticsEventName.workoutStarted, {'mode': 'free'});
      expect(rollback.available, isFalse);
      expect(rollback.enabled, isFalse);
      expect(rollback.pendingCount, 0);
      expect(remote.calls, callsBeforeRollback);
      expect(remote.preference(ownerA).enabled, isTrue);

      expect(await rollback.setEnabled(false), isTrue);
      expect(remote.calls, callsBeforeRollback + 1);
      expect(remote.preference(ownerA).enabled, isFalse);
      expect(remote.revocations, [ownerA]);
      expect(remote.ingestions, isEmpty);
      final saved = AnalyticsSnapshot.decode(store.raw!, at);
      expect(saved.enabled, isFalse);
      expect(saved.queue, isEmpty);
      expect(saved.revocations, isEmpty);
    },
  );

  test('sunucu onayı başarısızsa kapalı kalır', () async {
    final remote = FakeRemote()..fail = true;
    final c = makeController(MemoryStorage(), remote);
    await c.setAccount(ownerA);
    expect(await c.setEnabled(true), isFalse);
    await c.track(AnalyticsEventName.workoutStarted, {'mode': 'free'});
    expect(c.enabled, isFalse);
    expect(c.pendingCount, 0);
    expect(c.lastErrorCode, 'network');
  });

  test('yerel kuyruk 500 olay ve yedi günle sınırlıdır', () async {
    var clock = at;
    final store = MemoryStorage(), remote = FakeRemote();
    final c = makeController(store, remote, clock: () => clock);
    await activate(c);
    for (var i = 0; i < 503; i++) {
      await c.track(AnalyticsEventName.workoutStarted, {'mode': 'free'});
    }
    expect(c.pendingCount, 500);
    expect(AnalyticsSnapshot.decode(store.raw!, clock).queue.length, 500);
    clock = at.add(const Duration(days: 7));
    await c.track(AnalyticsEventName.workoutStarted, {'mode': 'routine'});
    expect(c.pendingCount, 1);
  });

  test('başarısız ağ onayı aynı event_id ile yeniden denenir', () async {
    final remote = FakeRemote()..loseAcknowledgement = true;
    final c = makeController(MemoryStorage(), remote);
    await activate(c);
    await c.track(AnalyticsEventName.workoutSaved, {
      'mode': 'free',
      'source': 'live',
    });
    await c.flush();
    expect(c.pendingCount, 1);
    final firstId = remote.ingestions.single.events.single.eventId;
    remote.loseAcknowledgement = false;
    await c.flush();
    expect(c.pendingCount, 0);
    expect(remote.ingestions.last.events.single.eventId, firstId);
    expect(remote.accepted.length, 1);
  });

  test(
    'kuyruk süreç yeniden açılınca korunur ama sunucu doğrulanmadan kullanılmaz',
    () async {
      final store = MemoryStorage(), remote = FakeRemote();
      final first = makeController(store, remote);
      await activate(first);
      await first.track(AnalyticsEventName.workoutStarted, {'mode': 'routine'});
      final second = makeController(store, remote);
      await second.setAccount(ownerA);
      expect(second.pendingCount, 1);
      await second.track(AnalyticsEventName.workoutStarted, {'mode': 'free'});
      expect(second.pendingCount, 1);
      await second.flush();
      expect(remote.accepted.length, 1);
      expect(second.pendingCount, 0);
    },
  );

  test(
    'başka cihazda geri alınmış nesil yerel kuyruğu yeniden gönderemez',
    () async {
      final remote = FakeRemote();
      final actual = makeController(MemoryStorage(), remote);
      await activate(actual);
      await actual.track(AnalyticsEventName.workoutStarted, {'mode': 'free'});
      remote.preferences[ownerA] = const AnalyticsConsent(
        enabled: false,
        generation: 2,
        policyVersion: analyticsPolicyVersion,
      );
      await actual.flush();
      expect(actual.enabled, isFalse);
      expect(actual.pendingCount, 0);
      expect(remote.ingestions, isEmpty);
    },
  );

  test(
    'kaybolan geri-alma yanıtından sonra diğer cihaz açtıysa yeni kimlikle kapatır',
    () async {
      final remote = FakeRemote();
      final c = makeController(MemoryStorage(), remote);
      await activate(c);
      remote.loseConsentAcknowledgement = true;
      expect(await c.setEnabled(false), isFalse);
      expect(c.revocationPending, isTrue);
      remote.loseConsentAcknowledgement = false;
      remote.preferences[ownerA] = const AnalyticsConsent(
        enabled: true,
        generation: 3,
        policyVersion: analyticsPolicyVersion,
      );
      await c.flush();
      expect(c.enabled, isFalse);
      expect(c.revocationPending, isFalse);
      expect(remote.preference(ownerA).enabled, isFalse);
      expect(remote.revocations, [ownerA, ownerA]);
    },
  );

  test(
    'geri alma ağsızken derhal kapatır, diskte niyet tutar ve yeniden denemeyi öne alır',
    () async {
      final store = MemoryStorage(), remote = FakeRemote();
      final c = makeController(store, remote);
      await activate(c);
      await c.track(AnalyticsEventName.workoutStarted, {'mode': 'free'});
      remote.fail = true;
      final revoke = c.setEnabled(false);
      expect(c.enabled, isFalse);
      expect(c.pendingCount, 0);
      expect(await revoke, isFalse);
      expect(c.revocationPending, isTrue);
      final saved = AnalyticsSnapshot.decode(store.raw!, at);
      expect(saved.enabled, isFalse);
      expect(saved.queue, isEmpty);
      expect(saved.revocations.containsKey(ownerA), isTrue);
      remote.fail = false;
      await c.flush();
      expect(c.revocationPending, isFalse);
      expect(remote.revocations, [ownerA]);
      expect(remote.ingestions, isEmpty);
    },
  );

  test(
    'hesap değişimi eski kuyruğu atar ve geciken ekran olayını reddeder',
    () async {
      final store = MemoryStorage(), remote = FakeRemote();
      final c = makeController(store, remote);
      await activate(c);
      await c.track(AnalyticsEventName.workoutStarted, {'mode': 'free'});
      await c.setAccount(ownerB);
      expect(c.pendingCount, 0);
      expect(c.enabled, isFalse);
      expect(await c.setEnabled(true), isTrue);
      await c.trackOwned(ownerA, AnalyticsEventName.workoutSaved, {
        'mode': 'free',
        'source': 'live',
      });
      await c.trackOwned(ownerB, AnalyticsEventName.workoutSaved, {
        'mode': 'routine',
        'source': 'historical',
      });
      await c.flush();
      expect(remote.ingestions.single.owner, ownerB);
      expect(remote.ingestions.single.events.single.properties, {
        'mode': 'routine',
        'source': 'historical',
      });
    },
  );

  test(
    'A için bekleyen geri alma B belirteciyle çalıştırılmaz, A dönünce tamamlanır',
    () async {
      final store = MemoryStorage(), remote = FakeRemote();
      final c = makeController(store, remote);
      await activate(c);
      remote.fail = true;
      await c.setEnabled(false);
      await c.setAccount(ownerB);
      remote.fail = false;
      await c.flush();
      expect(remote.revocations, isEmpty);
      await c.setAccount(ownerA);
      expect(remote.revocations, [ownerA]);
      expect(c.enabled, isFalse);
    },
  );

  test(
    'süren gönderim hesabı değişse de eski kimlikte kalır, B kuyruğuna dokunamaz',
    () async {
      final remote = FakeRemote()
        ..ingestionGate = Completer<void>()
        ..ingestionStarted = Completer<void>();
      final c = makeController(MemoryStorage(), remote);
      await activate(c);
      await c.track(AnalyticsEventName.workoutStarted, {'mode': 'routine'});
      final flushing = c.flush();
      await remote.ingestionStarted!.future;
      final switching = c.setAccount(ownerB);
      remote.ingestionGate!.complete();
      await flushing;
      await switching;
      expect(remote.ingestions.single.owner, ownerA);
      expect(c.ownerId, ownerB);
      expect(c.pendingCount, 0);
      expect(c.enabled, isFalse);
    },
  );

  test('bağlam okunurken geri alınırsa bekleyen olay yazılmaz', () async {
    final gate = Completer<AnalyticsContext>();
    final remote = FakeRemote();
    final c = makeController(
      MemoryStorage(),
      remote,
      context: () => gate.future,
    );
    await activate(c);
    final track = c.track(AnalyticsEventName.workoutStarted, {'mode': 'free'});
    await Future<void>.delayed(Duration.zero);
    final off = c.setEnabled(false);
    gate.complete(metadata());
    await track;
    await off;
    expect(c.pendingCount, 0);
    expect(remote.ingestions, isEmpty);
  });

  test(
    'kuyruk yazma arızası çağıranın antrenman kaydına hata taşımaz',
    () async {
      final store = MemoryStorage(), remote = FakeRemote();
      final c = makeController(store, remote);
      await activate(c);
      store.fail = true;
      await expectLater(
        c.track(AnalyticsEventName.workoutSaved, {
          'mode': 'free',
          'source': 'live',
        }),
        completes,
      );
      expect(c.pendingCount, 0);
      expect(c.lastErrorCode, 'storage');
      expect(await c.setEnabled(false), isFalse);
      expect(c.enabled, isFalse);
    },
  );

  test(
    'bozuk yerel veri kapalı başlar; ham veri yeni olaya dönüşmez',
    () async {
      final store = MemoryStorage()..raw = jsonEncode({'health': 'private'});
      final remote = FakeRemote();
      final c = makeController(store, remote);
      await c.setAccount(ownerA);
      await c.onForeground();
      expect(c.enabled, isFalse);
      expect(c.pendingCount, 0);
      expect(remote.calls, 0);
      expect(store.raw, isNot(contains('private')));
    },
  );

  test('geciken tercih yanıtı geri almayı geçersiz kılamaz', () async {
    final remote = FakeRemote();
    final c = makeController(MemoryStorage(), remote);
    await activate(c);
    await c.track(AnalyticsEventName.workoutStarted, {'mode': 'free'});
    remote.statusGate = Completer<void>();
    final flushing = c.flush();
    await Future<void>.delayed(Duration.zero);
    final off = c.setEnabled(false);
    remote.statusGate!.complete();
    await flushing;
    await off;
    expect(c.enabled, isFalse);
    expect(c.pendingCount, 0);
    expect(remote.ingestions, isEmpty);
  });

  test(
    'kalıcı olarak reddedilen parti sonraki geçerli olayı kilitlemez',
    () async {
      final remote = FakeRemote();
      final c = makeController(MemoryStorage(), remote);
      await activate(c);
      await c.track(AnalyticsEventName.workoutStarted, {'mode': 'free'});
      remote.ingestError = 'invalid_event';
      await c.flush();
      expect(c.pendingCount, 0);
      expect(c.enabled, isTrue);
      expect(c.lastErrorCode, 'invalid_event');
      remote.ingestError = null;
      await c.track(AnalyticsEventName.workoutSaved, {
        'mode': 'free',
        'source': 'live',
      });
      await c.flush();
      expect(c.pendingCount, 0);
      expect(
        remote.ingestions.single.events.single.name,
        AnalyticsEventName.workoutSaved,
      );
    },
  );

  testWidgets(
    'öndeyken ağ hatası en erken 60 saniye sonra doğrulanarak yeniden denenir',
    (tester) async {
      final remote = FakeRemote();
      final c = makeController(MemoryStorage(), remote);
      await activate(c);
      remote.fail = true;
      await c.onForeground(coldStart: true);
      final before = remote.calls;
      await c.track(AnalyticsEventName.workoutStarted, {'mode': 'free'});
      expect(c.pendingCount, 0);
      await tester.pump(const Duration(seconds: 59));
      expect(remote.calls, before);
      remote.fail = false;
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(remote.calls, greaterThan(before));
      expect(
        remote.ingestions.single.events.single.name,
        AnalyticsEventName.sessionStarted,
      );
      expect(c.pendingCount, 0);
    },
  );

  testWidgets('arka plana geçiş yeniden deneme zamanlayıcısını iptal eder', (
    tester,
  ) async {
    final remote = FakeRemote();
    final c = makeController(MemoryStorage(), remote);
    await activate(c);
    remote.fail = true;
    await c.onForeground();
    await c.onBackground();
    final before = remote.calls;
    await tester.pump(const Duration(seconds: 61));
    expect(remote.calls, before);
  });

  testWidgets('hesap değişimi eski hesabın yeniden denemesini iptal eder', (
    tester,
  ) async {
    final remote = FakeRemote();
    final c = makeController(MemoryStorage(), remote);
    await activate(c);
    remote.fail = true;
    await c.onForeground();
    await c.setAccount(ownerB);
    final before = remote.calls;
    remote.fail = false;
    await tester.pump(const Duration(seconds: 61));
    expect(remote.calls, before);
    expect(remote.ingestions, isEmpty);
  });

  testWidgets('dispose eski yeniden deneme zamanlayıcısını iptal eder', (
    tester,
  ) async {
    final remote = FakeRemote();
    final c = AnalyticsController(
      storage: MemoryStorage(),
      remote: remote,
      context: () async => metadata(),
      featureEnabled: true,
      now: () => at,
    );
    await activate(c);
    remote.fail = true;
    await c.onForeground();
    final before = remote.calls;
    c.dispose();
    await tester.pump(const Duration(seconds: 61));
    expect(remote.calls, before);
  });
}
