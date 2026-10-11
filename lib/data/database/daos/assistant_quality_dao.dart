import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/assistant_tables.dart';

part 'assistant_quality_dao.g.dart';

@DriftAccessor(tables: [AssistantQualityEvents])
class AssistantQualityDao extends DatabaseAccessor<AppDatabase>
    with _$AssistantQualityDaoMixin {
  AssistantQualityDao(super.db);
  static const retention = Duration(days: 90);
  static const maxEvents = 5000;

  Future<void> record(AssistantQualityEventsCompanion event, DateTime now) =>
      transaction(() async {
        await into(assistantQualityEvents).insertOnConflictUpdate(event);
        await prune(now);
      });

  Future<void> prune(DateTime now) async {
    await (delete(assistantQualityEvents)..where(
          (t) => t.occurredAt.isSmallerThanValue(now.subtract(retention)),
        ))
        .go();
    await customUpdate(
      'DELETE FROM assistant_quality_events WHERE event_id IN '
      '(SELECT event_id FROM assistant_quality_events '
      'ORDER BY occurred_at DESC, event_id DESC LIMIT -1 OFFSET ?)',
      variables: [Variable.withInt(maxEvents)],
      updates: {assistantQualityEvents},
    );
  }

  Future<List<AssistantQualityEvent>> events(String ownerId) =>
      (select(assistantQualityEvents)
            ..where((t) => t.ownerId.equals(ownerId))
            ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
          .get();

  Future<int> correct({
    required String eventId,
    required String ownerId,
    required String queryId,
    required String periodId,
    required bool exerciseChanged,
    bool clarified = false,
  }) =>
      (update(assistantQualityEvents)..where(
            (t) => t.eventId.equals(eventId) & t.ownerId.equals(ownerId),
          ))
          .write(
            AssistantQualityEventsCompanion(
              outcome: const Value('completed'),
              correctedQueryId: Value(queryId),
              correctedPeriodId: Value(periodId),
              exerciseChanged: Value(exerciseChanged),
              clarified: Value(clarified),
            ),
          );

  Future<int> clear() => delete(assistantQualityEvents).go();

  Future<int> finish(String eventId, String ownerId, String outcome) =>
      (update(assistantQualityEvents)..where(
            (t) => t.eventId.equals(eventId) & t.ownerId.equals(ownerId),
          ))
          .write(AssistantQualityEventsCompanion(outcome: Value(outcome)));
}
