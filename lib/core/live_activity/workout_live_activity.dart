import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kilit ekranı / Dynamic Island / Android bildiriminde gösterilen seans
/// durumu (docs/32, docs/45).
@immutable
class WorkoutLiveState {
  final String exercise;
  final String setLabel;
  final String target;

  /// Dinlenme başlangıcı ve bitişi; dinlenme yoksa ikisi de null. Başlangıç
  /// kilit ekranındaki ilerleme çubuğu için (sistem kendisi çizer).
  final DateTime? restStartedAt;
  final DateTime? restEndsAt;
  final int doneSets;
  final int totalSets;

  /// Kilit ekranında "Seti tamamla" düğmesi gösterilsin mi (tamamlanmamış
  /// set var ve canlı seans).
  final bool canComplete;

  /// Kartta görünen setin kimliği. Kilit ekranı eylemi bununla gelir;
  /// arada set değiştiyse (gecikmiş/çift dokunuş) eylem uygulanmaz.
  final String setKey;

  /// Etkin mola sürümü; doğal bitiş sıradaki set anahtarını değiştirmez.
  final String restKey;

  /// ± düğmelerinin etiketi ("−2,5 kg" / "+1 tekrar"); boşsa düğme yok
  /// (süre/mesafe hareketi).
  final String stepDownLabel;
  final String stepUpLabel;

  const WorkoutLiveState({
    required this.exercise,
    required this.setLabel,
    required this.target,
    this.restStartedAt,
    required this.restEndsAt,
    required this.doneSets,
    required this.totalSets,
    this.canComplete = false,
    this.setKey = '',
    this.restKey = '',
    this.stepDownLabel = '',
    this.stepUpLabel = '',
  });

  bool get resting => restEndsAt != null;

  Map<String, Object?> toMap() => {
        'exercise': exercise,
        'setLabel': setLabel,
        'target': target,
        'restStartedAtMs': restStartedAt?.millisecondsSinceEpoch,
        'restEndsAtMs': restEndsAt?.millisecondsSinceEpoch,
        'doneSets': doneSets,
        'totalSets': totalSets,
        'canComplete': canComplete,
        'setKey': setKey,
        'restKey': restKey,
        'stepDownLabel': stepDownLabel,
        'stepUpLabel': stepUpLabel,
      };

  @override
  bool operator ==(Object other) =>
      other is WorkoutLiveState &&
      other.exercise == exercise &&
      other.setLabel == setLabel &&
      other.target == target &&
      other.restStartedAt == restStartedAt &&
      other.restEndsAt == restEndsAt &&
      other.doneSets == doneSets &&
      other.totalSets == totalSets &&
      other.canComplete == canComplete &&
      other.setKey == setKey &&
      other.restKey == restKey &&
      other.stepDownLabel == stepDownLabel &&
      other.stepUpLabel == stepUpLabel;

  @override
  int get hashCode => Object.hash(exercise, setLabel, target, restStartedAt,
      restEndsAt, doneSets, totalSets, canComplete, setKey, stepDownLabel,
      stepUpLabel, restKey);
}

/// Kilit ekranı metinleri — seans boyunca sabit, aktif dilden (ARB) gelir.
/// Yerel taraf metin üretmez; tek kaynak `.arb`.
@immutable
class WorkoutLiveLabels {
  final String rest;
  final String restOver;
  final String next;
  final String completeSet;
  final String addRest;
  final String skipRest;
  final String elapsed;

  const WorkoutLiveLabels({
    required this.rest,
    required this.restOver,
    required this.next,
    required this.completeSet,
    required this.addRest,
    required this.skipRest,
    required this.elapsed,
  });

  @override
  bool operator ==(Object other) =>
      other is WorkoutLiveLabels &&
      other.rest == rest &&
      other.restOver == restOver &&
      other.next == next &&
      other.completeSet == completeSet &&
      other.addRest == addRest &&
      other.skipRest == skipRest &&
      other.elapsed == elapsed;

  @override
  int get hashCode => Object.hash(
      rest, restOver, next, completeSet, addRest, skipRest, elapsed);

  Map<String, String> toMap() => {
        'rest': rest,
        'restOver': restOver,
        'next': next,
        'completeSet': completeSet,
        'addRest': addRest,
        'skipRest': skipRest,
        'elapsed': elapsed,
      };
}

/// Kilit ekranından gelen eylemler (docs/45 §2). Yerel taraf yalnız iletir;
/// seans durumunu değiştiren tek yer seans ekranıdır.
enum LiveAction { completeSet, stepDown, stepUp, addRest, skipRest }

/// Eylemi uygulayan taraf. [setKey]: dokunulan kartın gösterdiği set
/// ([WorkoutLiveState.setKey]; dinlenmede [WorkoutLiveState.restKey]). `true` =
/// uygulandı; `false` = açık seans yok ya da kart bayat.
typedef LiveActionHandler = Future<bool> Function(
    LiveAction action, String? setKey);

/// iOS Canlı Etkinlik + Android seans bildirimi köprüsü (yerel taraf:
/// `AppDelegate.swift` + `WorkoutLiveActivityController.swift`,
/// `MainActivity.kt` + `WorkoutNotification.kt`). En iyi çaba: hata seansı
/// bozmaz.
///
/// **Çağrılar sıralıdır** (kuyruk). Eskiden `_active` bayrağı kanal cevabı
/// gelince kuruluyordu: seans açılışında aynı karede iki `show` gelince
/// ikisi de "etkin değil" görüp iki kez `start` gönderiyordu → iOS'ta kilit
/// ekranında iki aynı etkinlik (Samet, 2026-10-11). Artık niyet eşzamanlı
/// kaydedilir, kanal çağrıları sırayla gider.
class WorkoutLiveActivity {
  static const channel = MethodChannel('fit_pack/live_activity');
  // Hesap/taslak dışarıdan temizlenince bekleyen eski yayınlar da iptal olur.
  static int _endGeneration = 0;
  int _generation = _endGeneration;

  WorkoutLiveState? _last;
  WorkoutLiveLabels? _lastLabels;
  bool _active = false;
  Future<void> _queue = Future.value();
  LiveActionHandler? _handler;
  bool _listening = false;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  /// Etkinlik yoksa başlatır, varsa günceller. Aynı durum tekrar gönderilmez
  /// (her tık değil, yalnız değişiklik — iOS güncelleme bütçesi sınırlı).
  Future<void> show({
    required String title,
    required DateTime startedAt,
    required WorkoutLiveState state,
    WorkoutLiveLabels? labels,
  }) {
    if (!_supported) return Future.value();
    if (_generation != _endGeneration) {
      _generation = _endGeneration;
      _active = false;
      _last = null;
      _lastLabels = null;
    }
    if (_active && state == _last && labels == _lastLabels) return _queue;
    final method = _active ? 'update' : 'start';
    _active = true;
    _last = state;
    _lastLabels = labels;
    final args = {
      ...state.toMap(),
      'title': title,
      'startedAtMs': startedAt.millisecondsSinceEpoch,
      if (labels != null) 'labels': labels.toMap(),
    };
    final generation = _endGeneration;
    return _enqueue(() async {
      if (generation != _endGeneration) return;
      try {
        await channel.invokeMethod<bool>(method, args);
      } catch (_) {
        // Kanal yok / ActivityKit reddetti: kilit ekranı yok, seans sürer.
        // Bir sonraki gösterim yeniden başlatmayı denesin.
        if (identical(_last, state)) {
          _active = false;
          _last = null;
        }
      }
    });
  }

  Future<void> end() {
    if (!_supported || !_active) return Future.value();
    final generation = _generation;
    _active = false;
    _last = null;
    _lastLabels = null;
    return _enqueue(() async {
      // Eski ekranın kuyruktaki kapanışı yeni hesaba/seansa dokunamaz.
      if (generation != _endGeneration) return;
      try {
        await channel.invokeMethod<bool>('end');
      } catch (_) {
        // En iyi çaba — etkinlik zaten kapanmış olabilir.
      }
    });
  }

  /// Seans taslağı ekran dışından silindi (banner "Sil", hesap değişimi):
  /// kilit ekranında kart kalmasın. Uygulama seans sürerken öldürülmüşse
  /// kart sahipsiz kalır; seans ekranı açık değilken çağrılır.
  static Future<void> endAll() async {
    _endGeneration++;
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.android)) {
      return;
    }
    try {
      await channel.invokeMethod<bool>('end');
    } catch (_) {}
  }

  /// Sıradaki kanal çağrıları gidene kadar bekler (kilit ekranı eylemi
  /// dönmeden kart güncellensin).
  Future<void> flush() => _queue;

  /// Seans ekranı eylemleri karşılar; ekran kapanınca [detach].
  void attach(LiveActionHandler handler) {
    _handler = handler;
    if (_supported && !_listening) {
      _listening = true;
      channel.setMethodCallHandler(_onNativeCall);
    }
  }

  void detach(LiveActionHandler handler) {
    if (identical(_handler, handler)) _handler = null;
  }

  Future<Object?> _onNativeCall(MethodCall call) async {
    if (call.method != 'action') throw MissingPluginException();
    // Yerel taraf {action, setKey} gönderir; eski biçim yalnız ad.
    final args = call.arguments;
    final name = args is Map ? args['action'] : args;
    final setKey = args is Map ? args['setKey'] as String? : null;
    final action =
        LiveAction.values.where((a) => a.name == name).firstOrNull;
    final h = _handler;
    if (action == null || h == null) return false;
    return h(action, setKey);
  }

  Future<void> _enqueue(Future<void> Function() op) =>
      _queue = _queue.then((_) => op());
}

final workoutLiveActivityProvider =
    Provider<WorkoutLiveActivity>((ref) => WorkoutLiveActivity());
