import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/prefs/week_start_provider.dart';
import '../../data/database/app_database.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';
import '../cloud/auth_service.dart';
import 'assistant_calculator.dart';
import 'assistant_routing.dart';

final assistantRouterProvider = FutureProvider<FrozenAssistantRouter>(
  (ref) async => FrozenAssistantRouter(
    jsonDecode(
          await rootBundle.loadString('assets/data/assistant_router_v2.json'),
        )
        as Map<String, dynamic>,
  ),
);
final assistantClockProvider = StreamProvider.autoDispose<DateTime>((
  ref,
) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});
final assistantDataProvider = StreamProvider.autoDispose<AssistantData>((ref) {
  ref.watch(currentUserProvider); // hesap değişiminde eski sonuç gösterilmez
  final now = ref.watch(assistantClockProvider).valueOrNull ?? DateTime.now();
  final weekStart = ref.watch(weekStartProvider);
  final db = ref.watch(databaseProvider);
  // Saat/hesap değişip sağlayıcı kapanırken devam eden DAO çağrısı ref kullanmaz.
  final wo = ref.watch(workoutDaoProvider);
  final nut = ref.watch(nutritionDaoProvider);
  final body = ref.watch(bodyDaoProvider);
  final profile = ref.watch(userProfileDaoProvider);
  return watchTables(
    db,
    [
      db.workoutSessions,
      db.workoutSets,
      db.exercises,
      db.routines,
      db.foodLogs,
      db.foods,
      db.nutritionDays,
      db.bodyMeasurements,
      db.userProfile,
    ],
    () async {
      final start = DateTime(now.year, now.month, now.day - 30);
      final end = DateTime(now.year, now.month, now.day + 1);
      final sessions = await wo.getAllSessions();
      return AssistantData(
        now: now,
        weekStart: weekStart,
        sessions: sessions.where((v) => v.date.isBefore(end)).toList(),
        sets: await wo.getSetsForSessions(sessions.map((v) => v.id).toList()),
        exercises: {for (final e in await wo.getAllExercises()) e.id: e},
        points: await wo.getWeightedSetPointsInRange(
          DateTime(1970),
          end,
          onlyComplete: true,
        ),
        logs: await nut.getLogsInRange(start, end),
        completedDays: {
          for (final key in await nut.getCompletedDays(start, end))
            DateTime.parse(key),
        },
        foods: {for (final f in await nut.getAllFoods()) f.id: f},
        measurements: await body.getDailyMeasurements(),
        scheduledWeekdays: {
          for (final r in await wo.getActiveRoutines())
            if (r.scheduledWeekday != null) r.scheduledWeekday!,
        },
        profile: await profile.getProfile(),
      );
    },
  );
});
final assistantQualityProvider =
    StreamProvider.autoDispose<List<AssistantQualityEvent>>((ref) async* {
      final owner = ref.watch(currentUserProvider)?.id;
      final db = ref.watch(databaseProvider);
      if (owner == null) {
        yield const [];
        return;
      }
      await db.assistantQualityDao.prune(DateTime.now());
      yield* watchTables(db, [
        db.assistantQualityEvents,
      ], () => db.assistantQualityDao.events(owner));
    });
