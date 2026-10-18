import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/prefs/week_start_provider.dart';
import '../../core/utils/current_day.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';
import 'training_progress.dart';

/// İlerleme → Antrenman (docs/56). Reaktif: seans/set yazılınca tazelenir.
/// Tüm geçmişin kilo×tekrar noktaları tek sorguda — rekor tespiti önceki en
/// iyiyi bilmeli; 8 haftalık pencere hesapta uygulanır.
final trainingProgressProvider = StreamProvider<TrainingProgress>((ref) {
  final db = ref.watch(databaseProvider);
  final day = ref.watch(currentDayProvider);
  final weekStart = ref.watch(weekStartProvider);
  return watchTables(db, [db.workoutSessions, db.workoutSets], () async {
    final end = DateTime(day.year, day.month, day.day + 1);
    final points = await ref
        .read(workoutDaoProvider)
        .getWeightedSetPointsInRange(DateTime(2000), end);
    return trainingProgressOf(points, now: day, weekStart: weekStart);
  });
});

/// İlerleme sekmesinin parçaları (docs/56).
enum ProgressSegment { training, body, week }

/// Son seçilen parça — cihaz/izleyici başına kolaylık (shared_preferences).
/// null: henüz seçim yok → ekran varsayılanı uygular (Antrenman; antrenman
/// verisi yoksa Vücut).
class ProgressSegmentNotifier extends Notifier<ProgressSegment?> {
  static const _key = 'progress_segment_v1';

  @override
  ProgressSegment? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    for (final s in ProgressSegment.values) {
      if (s.name == saved && state == null) state = s;
    }
  }

  Future<void> select(ProgressSegment segment) async {
    state = segment;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, segment.name);
  }
}

final progressSegmentProvider =
    NotifierProvider<ProgressSegmentNotifier, ProgressSegment?>(
        ProgressSegmentNotifier.new);
