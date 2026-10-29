import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/current_day.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/workout_dao.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';
import '../home/providers/weekly_goal_provider.dart';
import 'goal_journey.dart';

final goalJourneyPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

class GoalJourneyNotifier extends AsyncNotifier<GoalJourney?> {
  int _generation = 0;
  String? _generationAccount;
  int get generation => _generation;
  @override
  Future<GoalJourney?> build() async {
    final id = ref.watch(weeklyGoalAccountProvider);
    if (id != _generationAccount) {
      _generation++;
      _generationAccount = id;
    }
    if (id == null) return null;
    final prefs = await ref.read(goalJourneyPreferencesProvider.future);
    final raw = prefs.getString('goal_journey_v1_$id');
    return raw == null
        ? null
        : GoalJourney.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map),
          );
  }

  Future<void> save(
    GoalJourney journey, {
    String? expectedAccount,
    int? expectedGeneration,
  }) async {
    final id = ref.read(weeklyGoalAccountProvider);
    final generation = _generation;
    if (id == null ||
        (expectedAccount != null && expectedAccount != id) ||
        (expectedGeneration != null && expectedGeneration != generation)) {
      throw StateError('Goal editor account changed');
    }
    final prefs = await ref.read(goalJourneyPreferencesProvider.future);
    if (ref.read(weeklyGoalAccountProvider) != id ||
        generation != _generation) {
      throw StateError('Goal editor account changed');
    }
    if (!await prefs.setString(
      'goal_journey_v1_$id',
      jsonEncode(journey.toJson()),
    )) {
      throw StateError('Goal could not be saved');
    }
    if (ref.read(weeklyGoalAccountProvider) == id &&
        generation == _generation) {
      state = AsyncData(journey);
    }
  }
}

final goalJourneyProvider =
    AsyncNotifierProvider<GoalJourneyNotifier, GoalJourney?>(
      GoalJourneyNotifier.new,
    );

class GoalEvidence {
  final List<WorkoutSession> sessions;
  final List<WorkoutSession> baselineSessions;
  final List<ExerciseProgressPoint> points;
  const GoalEvidence({
    required this.sessions,
    required this.baselineSessions,
    required this.points,
  });

  int get baselineTrainingDays =>
      baselineSessions.map((s) => dayStart(s.date)).toSet().length;
  Map<int, String> get exercises => {
    for (final p in points) p.exerciseId: p.name,
  };
}

/// Başlangıç 28 günlük gözlem penceresiyle, ilerleme gerçek setlerle okunur.
/// Kayıtsız günün ne olduğu bilinmez; sıfır aktivite sayılmaz.
final goalEvidenceProvider = StreamProvider.autoDispose<GoalEvidence>((ref) {
  final db = ref.watch(databaseProvider);
  final today = ref.watch(currentDayProvider);
  final journey = ref.watch(goalJourneyProvider.future);
  return watchTables(
    db,
    [db.workoutSessions, db.workoutSets, db.exercises],
    () async {
      final j = await journey;
      final anchor = j?.startedAt ?? today;
      final dao = ref.read(workoutDaoProvider);
      final from = addDays(dayStart(anchor), -28);
      return GoalEvidence(
        baselineSessions: await dao.getSessionsByDateRange(from, anchor),
        sessions: await dao.getSessionsByDateRange(anchor, addDays(today, 1)),
        points: await dao.getWeightedSetPointsInRange(
          from,
          addDays(today, 1),
          onlyComplete: true,
        ),
      );
    },
  );
});
