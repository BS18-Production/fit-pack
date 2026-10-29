import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'analytics_events.dart';
import 'analytics_remote.dart';
import 'analytics_storage.dart';

/// İsteğe bağlı ölçüm, kullanıcı kaydının kritik yolunda beklenmez.
/// Bütün kalıcı yazmalar sıralıdır; hesap/tercih değişimi devam eden işi
/// eşzamanlı bir dönem sayacıyla geçersiz kılar.
class AnalyticsController extends ChangeNotifier {
  AnalyticsController({
    required this.storage,
    required this.remote,
    required this.context,
    required this.featureEnabled,
    this.autoFlushDelay = const Duration(seconds: 10),
    DateTime Function()? now,
    String Function()? newId,
  }) : now = now ?? DateTime.now,
       newId = newId ?? const Uuid().v4;

  final AnalyticsStorage storage;
  final AnalyticsRemote remote;
  final Future<AnalyticsContext> Function() context;
  final bool featureEnabled;
  final Duration autoFlushDelay;
  final DateTime Function() now;
  final String Function() newId;

  AnalyticsSnapshot _snapshot = AnalyticsSnapshot();
  Future<void> _tail = Future.value();
  String? _owner;
  String? _lastErrorCode;
  int _epoch = 0;
  bool _accountInitialized = false;
  bool _loaded = false;
  bool _busy = false;
  bool _verified = false;
  bool _disposed = false;
  bool _foreground = false;
  bool _foregroundRequested = false;
  String? _sessionId;
  DateTime? _sessionStarted;
  Timer? _flushTimer;

  String? get ownerId => _owner;
  bool get available =>
      featureEnabled && _owner != null && _loaded && !_disposed;
  bool get enabled =>
      _snapshot.enabled && !_snapshot.revocations.containsKey(_owner);
  bool get busy => _busy;
  int get pendingCount => _snapshot.queue.length;
  String? get lastErrorCode => _lastErrorCode;
  bool get revocationPending => _snapshot.revocations.containsKey(_owner);

  bool _current(String? owner, int epoch) =>
      !_disposed && owner != null && _owner == owner && _epoch == epoch;
  bool get _collecting => available && enabled && _verified;

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  String _code(Object error) => error is AnalyticsRemoteException
      ? error.code
      : error is FormatException
      ? 'invalid_event'
      : 'storage';

  Future<T> _serial<T>(Future<T> Function() operation, T fallback) {
    final done = Completer<T>();
    final epoch = _epoch;
    _tail = _tail.then((_) async {
      if (_disposed) {
        done.complete(fallback);
        return;
      }
      try {
        done.complete(await operation());
      } catch (error) {
        if (_epoch == epoch) {
          _lastErrorCode = _code(error);
          _scheduleRetry();
          _changed();
        }
        done.complete(fallback);
      }
    });
    return done.future;
  }

  AnalyticsSnapshot _copy({
    bool? enabled,
    int? generation,
    String? policyVersion,
    List<AnalyticsEvent>? queue,
    Map<String, AnalyticsRevocation>? revocations,
  }) => AnalyticsSnapshot(
    ownerId: _owner,
    enabled: enabled ?? _snapshot.enabled,
    generation: generation ?? _snapshot.generation,
    policyVersion: policyVersion ?? _snapshot.policyVersion,
    queue: queue ?? _snapshot.queue,
    revocations: revocations ?? _snapshot.revocations,
  );

  /// Başarılı yazımdan sonra bellek değişir. Dönem değişmişse eski sonuç
  /// yalnız diskte kalabilir; sıradaki hesap/geri-alma yazması onu temizler.
  Future<bool> _persist(
    AnalyticsSnapshot next,
    String? owner,
    int epoch,
  ) async {
    await storage.write(next.encode());
    if (!_current(owner, epoch)) return false;
    _snapshot = next;
    _changed();
    return true;
  }

  Future<void> setAccount(String? owner) {
    if (owner != null && !isAnalyticsUuid(owner)) {
      _lastErrorCode = 'account_changed';
      // Geçersiz bir yeni kimlik önceki hesabın ölçümünü açık bırakamaz.
      owner = null;
    }
    if (_accountInitialized && owner == _owner) return _tail;
    _accountInitialized = true;
    final epoch = ++_epoch;
    _owner = owner;
    _verified = false;
    _loaded = false;
    _busy = true;
    _foreground = false;
    _foregroundRequested = false;
    _sessionId = null;
    _sessionStarted = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    // Kimlik değişir değişmez eski kuyruk bellekten de görünmez olur.
    _snapshot = AnalyticsSnapshot(
      ownerId: owner,
      revocations: _snapshot.revocations,
    );
    _changed();
    return _serial(() async {
      try {
        AnalyticsSnapshot saved;
        try {
          final raw = await storage.read();
          saved = raw == null
              ? AnalyticsSnapshot()
              : AnalyticsSnapshot.decode(raw, now().toUtc());
        } catch (_) {
          saved = AnalyticsSnapshot();
          _lastErrorCode = 'storage';
        }
        if (_disposed || _epoch != epoch || _owner != owner) return;
        final revocations = {...saved.revocations, ..._snapshot.revocations};
        final same = saved.ownerId == owner && owner != null;
        final next = AnalyticsSnapshot(
          ownerId: owner,
          enabled:
              featureEnabled &&
              same &&
              saved.enabled &&
              !revocations.containsKey(owner),
          generation: same ? saved.generation : 0,
          policyVersion: same ? saved.policyVersion : null,
          queue: featureEnabled && same ? saved.queue : const [],
          revocations: revocations,
        );
        // Çıkışta da kuyruk kalıcı olarak temizlenir. Aynı hesapla yeniden
        // açılışta ise önceki kuyruk korunur, sunucu doğrulamasını bekler.
        await storage.write(next.encode());
        if (_disposed || _epoch != epoch || _owner != owner) return;
        _snapshot = next;
        _loaded = true;
        if (owner != null && next.revocations.containsKey(owner)) {
          await _revoke(owner, epoch);
        }
      } finally {
        if (!_disposed && _epoch == epoch) {
          _busy = false;
          _changed();
        }
      }
    }, null);
  }

  /// Açma çevrimiçi ve sunucu onaylıdır. Kapatma ise bellekte HEMEN
  /// etkilidir; ağ yoksa geri-alma niyeti diskte, kuyruğun önünde kalır.
  Future<bool> setEnabled(bool value) {
    final owner = _owner;
    if (_disposed || owner == null || !_loaded || (value && !available)) {
      return Future.value(false);
    }
    final epoch = ++_epoch;
    _verified = false;
    _busy = true;
    _lastErrorCode = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    _sessionId = null;
    _sessionStarted = null;
    if (!value) {
      final revocations = {..._snapshot.revocations};
      if (!revocations.containsKey(owner)) {
        if (revocations.length >= AnalyticsSnapshot.maxRevocations) {
          _snapshot = _copy(enabled: false, queue: const []);
          _lastErrorCode = 'storage';
          _busy = false;
          _changed();
          return Future.value(false);
        }
        revocations[owner] = AnalyticsRevocation(newId(), _snapshot.generation);
      }
      _snapshot = _copy(
        enabled: false,
        queue: const [],
        revocations: revocations,
      );
    }
    _changed();
    return _serial(() async {
      try {
        // Kapatma yeni bir hesaba geçilse bile önce diskte yerini alır.
        // İsteğin uzaktan yürütülmesi yalnız kendi hesabında mümkündür.
        if (!value) {
          Object? storageError;
          try {
            await storage.write(_snapshot.encode());
          } catch (error) {
            storageError = error;
          }
          if (!_current(owner, epoch)) return false;
          // Yerel disk arızası sunucuya geri-alma denemesini engellemez:
          // sunucu kapatılırsa bir sonraki açılış da eski kuyruğu reddeder.
          await _revoke(owner, epoch);
          if (storageError != null) throw storageError;
          return _current(owner, epoch) &&
              !_snapshot.revocations.containsKey(owner);
        }
        if (!_current(owner, epoch)) return false;
        if (_snapshot.revocations.containsKey(owner)) {
          await _revoke(owner, epoch);
        }
        if (!_current(owner, epoch) ||
            _snapshot.revocations.containsKey(owner)) {
          return false;
        }
        if (_snapshot.revocations.length >= AnalyticsSnapshot.maxRevocations) {
          _lastErrorCode = 'storage';
          return false;
        }
        final previous = await remote.status(owner);
        if (!_current(owner, epoch)) return false;
        final confirmed = await remote.consent(
          owner,
          enabled: true,
          expectedGeneration: previous.generation,
          requestId: newId(),
        );
        if (!_current(owner, epoch) ||
            !confirmed.enabled ||
            confirmed.policyVersion != analyticsPolicyVersion) {
          return false;
        }
        final saved = await _persist(
          _copy(
            enabled: true,
            generation: confirmed.generation,
            policyVersion: confirmed.policyVersion,
            queue: const [],
          ),
          owner,
          epoch,
        );
        if (!saved) return false;
        _verified = true;
        if (_foreground) await _startSession(owner, epoch, 'foreground');
        _scheduleFlush();
        return true;
      } catch (error) {
        if (_current(owner, epoch)) {
          _snapshot = _copy(enabled: false, queue: const []);
          _lastErrorCode = _code(error);
          _scheduleRetry();
        }
        return false;
      } finally {
        if (_current(owner, epoch)) {
          _busy = false;
          _changed();
        }
      }
    }, false);
  }

  Future<void> _revoke(String owner, int epoch) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final pending = _snapshot.revocations[owner];
      if (pending == null || !_current(owner, epoch)) return;
      final result = await remote.consent(
        owner,
        enabled: false,
        expectedGeneration: pending.generation,
        requestId: pending.requestId,
      );
      if (!_current(owner, epoch)) return;
      if (result.enabled) {
        // Eski isteğin yanıtı kaybolmuş, başka cihaz sonradan açmış olabilir.
        // Tekrar kimliği güncel durumu döndürür: yerelde kapalı kal, yeni
        // geri-alma kimliğini ÖNCE kaydet; sonsuz ağ döngüsü oluşturma.
        final revocations = {
          ..._snapshot.revocations,
          owner: AnalyticsRevocation(newId(), result.generation),
        };
        if (!await _persist(
          _copy(
            enabled: false,
            generation: result.generation,
            policyVersion: result.policyVersion,
            queue: const [],
            revocations: revocations,
          ),
          owner,
          epoch,
        )) {
          return;
        }
        continue;
      }
      final revocations = {..._snapshot.revocations}..remove(owner);
      await _persist(
        _copy(
          enabled: false,
          generation: result.generation,
          policyVersion: result.policyVersion,
          queue: const [],
          revocations: revocations,
        ),
        owner,
        epoch,
      );
      _lastErrorCode = null;
      return;
    }
    if (_current(owner, epoch)) {
      _lastErrorCode = 'stale_consent';
      _scheduleRetry();
    }
  }

  Future<void> _refresh(String owner, int epoch) async {
    _verified = false;
    if (!_current(owner, epoch)) return;
    if (_snapshot.revocations.containsKey(owner)) await _revoke(owner, epoch);
    if (!_current(owner, epoch) || !available || !enabled) return;
    AnalyticsConsent result;
    try {
      result = await remote.status(owner);
    } on AnalyticsRemoteException catch (error) {
      if (_current(owner, epoch) &&
          {
            'revoked',
            'stale_consent',
            'account_changed',
          }.contains(error.code)) {
        await _persist(_copy(enabled: false, queue: const []), owner, epoch);
      }
      rethrow;
    }
    if (!_current(owner, epoch)) return;
    if (!result.enabled ||
        result.policyVersion != analyticsPolicyVersion ||
        result.generation != _snapshot.generation) {
      await _persist(
        _copy(
          enabled: false,
          generation: result.generation,
          policyVersion: result.policyVersion,
          queue: const [],
        ),
        owner,
        epoch,
      );
      _lastErrorCode = 'stale_consent';
      return;
    }
    _verified = true;
    _lastErrorCode = null;
  }

  Future<void> refresh() {
    final owner = _owner, epoch = _epoch;
    return _serial(() async {
      if (_current(owner, epoch) && _loaded) await _refresh(owner!, epoch);
      _changed();
    }, null);
  }

  Future<void> track(AnalyticsEventName name, Map<String, Object> properties) =>
      trackOwned(_owner, name, properties);

  Future<void> trackOwned(
    String? expectedOwner,
    AnalyticsEventName name,
    Map<String, Object> properties,
  ) {
    final epoch = _epoch;
    // Çağıran mutable map'i daha sonra değiştirse de sözleşme değişmez.
    final safeProperties = Map<String, Object>.unmodifiable(properties);
    if (!_current(expectedOwner, epoch) ||
        !_collecting ||
        !validAnalyticsProperties(name, safeProperties)) {
      return Future.value();
    }
    return _serial(() async {
      if (!_current(expectedOwner, epoch) || !_collecting) return;
      await _append(expectedOwner!, epoch, name, safeProperties);
      _scheduleFlush();
    }, null);
  }

  List<AnalyticsEvent> _pruned(List<AnalyticsEvent> events) {
    final at = now().toUtc();
    final ids = <String>{};
    final fresh = events
        .where(
          (event) =>
              event.occurredAt.isAfter(at.subtract(analyticsQueueRetention)) &&
              !event.occurredAt.isAfter(at.add(const Duration(minutes: 5))) &&
              ids.add(event.eventId),
        )
        .toList();
    return fresh.length <= analyticsQueueLimit
        ? fresh
        : fresh.sublist(fresh.length - analyticsQueueLimit);
  }

  Future<void> _append(
    String owner,
    int epoch,
    AnalyticsEventName name,
    Map<String, Object> properties,
  ) async {
    if (!_current(owner, epoch) || !_collecting) return;
    final metadata = await context();
    if (!_current(owner, epoch) || !_collecting) return;
    _sessionId ??= newId();
    final event = AnalyticsEvent(
      eventId: newId(),
      occurredAt: now().toUtc(),
      sessionId: _sessionId!,
      name: name,
      properties: properties,
      context: metadata,
    );
    await _persist(
      _copy(queue: _pruned([..._snapshot.queue, event])),
      owner,
      epoch,
    );
  }

  void _scheduleFlush() {
    if (!_foregroundRequested ||
        !_collecting ||
        _flushTimer != null ||
        _snapshot.queue.isEmpty) {
      return;
    }
    _flushTimer = Timer(autoFlushDelay, () {
      _flushTimer = null;
      unawaited(flush());
    });
  }

  /// Sonsuz hızlı döngü yok: öndeyken en erken 60 saniye sonra bir deneme.
  /// Yeniden bağlantı yeni izin sayılmaz; her denemede sunucu nesli okunur.
  void _scheduleRetry() {
    final owner = _owner, epoch = _epoch;
    if (!_foregroundRequested ||
        !_loaded ||
        owner == null ||
        _disposed ||
        _flushTimer != null ||
        !{'network', 'stale_consent'}.contains(_lastErrorCode) ||
        !(available && enabled || revocationPending)) {
      return;
    }
    _flushTimer = Timer(const Duration(seconds: 60), () {
      _flushTimer = null;
      if (_foregroundRequested && _current(owner, epoch)) {
        unawaited(flush());
      }
    });
  }

  Future<void> _flush(String owner, int epoch) async {
    if (!_current(owner, epoch) || !_loaded) return;
    // Her gönderimden önce güncel sunucu tercihi: başka cihazdaki geri alma
    // ya da eski diskteki bir tercih, önceki nesli yeniden canlandıramaz.
    await _refresh(owner, epoch);
    if (!_current(owner, epoch) || !_collecting) return;
    if (_foreground && _sessionId == null) {
      await _startSession(owner, epoch, 'foreground');
    }
    if (!_current(owner, epoch) || !_collecting) return;
    final fresh = _pruned(_snapshot.queue);
    if (!await _persist(_copy(queue: fresh), owner, epoch) || fresh.isEmpty) {
      return;
    }
    var sent = 0;
    while (_current(owner, epoch) &&
        _collecting &&
        _snapshot.queue.isNotEmpty &&
        sent < analyticsQueueLimit) {
      final batch = <AnalyticsEvent>[];
      for (final event in _snapshot.queue.take(analyticsBatchLimit)) {
        final next = [...batch, event];
        // Uç zarfıyla beraber 32 KiB'lık üst sınırın altında pay bırakır.
        if (utf8
                .encode(jsonEncode(next.map((e) => e.toJson()).toList()))
                .length >
            30 * 1024) {
          break;
        }
        batch.add(event);
      }
      if (batch.isEmpty) throw const AnalyticsRemoteException('invalid_event');
      try {
        await remote.ingest(owner, _snapshot.generation, batch);
      } on AnalyticsRemoteException catch (error) {
        if (_current(owner, epoch) && error.code == 'invalid_event') {
          // 400/413 tekrar denenerek iyileşmez. Yalnız reddedilen partiyi
          // at; bozuk/eski bir olay daha sonraki geçerli olayları kilitlemesin.
          // Tercih değişmez ve kullanıcı kaydına hiçbir etkisi yoktur.
          final rejected = batch.map((event) => event.eventId).toSet();
          await _persist(
            _copy(
              queue: _snapshot.queue
                  .where((event) => !rejected.contains(event.eventId))
                  .toList(),
            ),
            owner,
            epoch,
          );
          _scheduleFlush();
        }
        if (_current(owner, epoch) &&
            {
              'revoked',
              'stale_consent',
              'account_changed',
            }.contains(error.code)) {
          _verified = false;
          await _persist(_copy(enabled: false, queue: const []), owner, epoch);
        }
        rethrow;
      }
      if (!_current(owner, epoch) || !_collecting) return;
      final ids = batch.map((event) => event.eventId).toSet();
      await _persist(
        _copy(
          queue: _snapshot.queue
              .where((event) => !ids.contains(event.eventId))
              .toList(),
        ),
        owner,
        epoch,
      );
      sent += batch.length;
    }
    _lastErrorCode = null;
    _changed();
  }

  Future<void> flush() {
    final owner = _owner, epoch = _epoch;
    _flushTimer?.cancel();
    _flushTimer = null;
    return _serial(() async {
      if (_current(owner, epoch)) await _flush(owner!, epoch);
    }, null);
  }

  Future<void> _startSession(String owner, int epoch, String reason) async {
    if (!_collecting || !_current(owner, epoch)) return;
    _sessionId = newId();
    _sessionStarted = now().toUtc();
    await _append(owner, epoch, AnalyticsEventName.sessionStarted, {
      'reason': reason,
    });
  }

  Future<void> onForeground({bool coldStart = false}) {
    final owner = _owner, epoch = _epoch;
    _foregroundRequested = true;
    return _serial(() async {
      if (!_current(owner, epoch) || !_loaded) return;
      if (_foreground) return;
      _foreground = true;
      await _refresh(owner!, epoch);
      if (!_current(owner, epoch) || !_collecting) return;
      await _startSession(
        owner,
        epoch,
        coldStart ? 'cold_start' : 'foreground',
      );
      await _flush(owner, epoch);
    }, null);
  }

  Future<void> onBackground() {
    final owner = _owner, epoch = _epoch;
    final at = now().toUtc();
    _foregroundRequested = false;
    _flushTimer?.cancel();
    _flushTimer = null;
    return _serial(() async {
      if (!_current(owner, epoch) || !_loaded) return;
      _foreground = false;
      final start = _sessionStarted;
      if (_collecting && start != null) {
        await _append(owner!, epoch, AnalyticsEventName.sessionEnded, {
          'duration_bucket': analyticsSessionDurationBucket(
            at.difference(start),
          ),
        });
      }
      _sessionId = null;
      _sessionStarted = null;
      if (_current(owner, epoch)) await _flush(owner!, epoch);
    }, null);
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    _flushTimer?.cancel();
    super.dispose();
  }
}
