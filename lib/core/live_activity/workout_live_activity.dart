import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kilit ekranı / Dynamic Island'da gösterilen seans durumu (docs/32).
@immutable
class WorkoutLiveState {
  final String exercise;
  final String setLabel;
  final String target;
  final DateTime? restEndsAt;
  final int doneSets;
  final int totalSets;

  const WorkoutLiveState({
    required this.exercise,
    required this.setLabel,
    required this.target,
    required this.restEndsAt,
    required this.doneSets,
    required this.totalSets,
  });

  Map<String, Object?> toMap() => {
        'exercise': exercise,
        'setLabel': setLabel,
        'target': target,
        'restEndsAtMs': restEndsAt?.millisecondsSinceEpoch,
        'doneSets': doneSets,
        'totalSets': totalSets,
      };

  @override
  bool operator ==(Object other) =>
      other is WorkoutLiveState &&
      other.exercise == exercise &&
      other.setLabel == setLabel &&
      other.target == target &&
      other.restEndsAt == restEndsAt &&
      other.doneSets == doneSets &&
      other.totalSets == totalSets;

  @override
  int get hashCode => Object.hash(
      exercise, setLabel, target, restEndsAt, doneSets, totalSets);
}

/// iOS Canlı Etkinlik köprüsü (yerel taraf: `AppDelegate.swift` +
/// `WorkoutLiveActivityController.swift`). Android'de ve iOS 16.2 altında
/// işlem yok. En iyi çaba: hata seansı bozmaz.
class WorkoutLiveActivity {
  static const channel = MethodChannel('fit_pack/live_activity');

  WorkoutLiveState? _last;
  bool _active = false;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Etkinlik yoksa başlatır, varsa günceller. Aynı durum tekrar gönderilmez
  /// (her tık değil, yalnız değişiklik — iOS güncelleme bütçesi sınırlı).
  Future<void> show({
    required String title,
    required DateTime startedAt,
    required WorkoutLiveState state,
  }) async {
    if (!_supported) return;
    if (_active && state == _last) return;
    final args = {
      ...state.toMap(),
      'title': title,
      'startedAtMs': startedAt.millisecondsSinceEpoch,
    };
    try {
      await channel.invokeMethod<bool>(_active ? 'update' : 'start', args);
      _active = true;
      _last = state;
    } catch (_) {
      // Kanal yok / ActivityKit reddetti: kilit ekranı yok, seans sürer.
    }
  }

  Future<void> end() async {
    if (!_supported || !_active) return;
    _active = false;
    _last = null;
    try {
      await channel.invokeMethod<bool>('end');
    } catch (_) {
      // En iyi çaba — etkinlik zaten kapanmış olabilir.
    }
  }
}

final workoutLiveActivityProvider =
    Provider<WorkoutLiveActivity>((ref) => WorkoutLiveActivity());
