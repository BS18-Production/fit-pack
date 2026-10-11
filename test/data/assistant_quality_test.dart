import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/assistant_quality_dao.dart';
import 'package:fit_pack/features/assistant/assistant_quality.dart';
import '../helpers/test_database.dart';

void main() {
  final now = DateTime(2026, 10, 11, 20);
  test('hesap yalıtımı, metinsiz şema, 90 gün ve 5000 olay sınırı', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    AssistantQualityEventsCompanion event(
      String id,
      String owner,
      DateTime date,
    ) => AssistantQualityEventsCompanion.insert(
      eventId: id,
      ownerId: owner,
      occurredAt: date,
      source: 'free',
      decision: 'auto',
    );
    await db.assistantQualityDao.record(
      event('old', 'a', now.subtract(const Duration(days: 91))),
      now,
    );
    expect(await db.assistantQualityDao.events('a'), isEmpty);
    await db.assistantQualityDao.record(event('b', 'b', now), now);
    await db.batch(
      (b) => b.insertAll(db.assistantQualityEvents, [
        for (var i = 0; i < 10020; i++)
          event('e$i', 'a', now.subtract(Duration(minutes: i))),
      ]),
    );
    await db.assistantQualityDao.prune(now);
    expect(
      (await db.select(db.assistantQualityEvents).get()).length,
      AssistantQualityDao.maxEvents,
    );
    expect((await db.assistantQualityDao.events('b')).single.ownerId, 'b');
    expect(
      await db.assistantQualityDao.correct(
        eventId: 'b',
        ownerId: 'a',
        queryId: 'streak',
        periodId: 'all_time',
        exerciseChanged: true,
      ),
      0,
    );
    final columns =
        (await db
                .customSelect('PRAGMA table_info(assistant_quality_events)')
                .get())
            .map((r) => r.read<String>('name'))
            .toSet();
    for (final name in [
      'question',
      'answer',
      'input_hash',
      'exercise_id',
      'exercise_name',
      'food_id',
      'weight_kg',
      'computed_kcal',
    ]) {
      expect(columns, isNot(contains(name)));
    }
    expect(
      (await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='trigger' AND tbl_name='assistant_quality_events'",
          )
          .get()),
      isEmpty,
    );
  });
  test(
    'hazır/ağ hatası otomatik paydasında yok; değiştire basmak düzeltme değil',
    () async {
      final db = newTestDatabase();
      addTearDown(db.close);
      for (final (id, source, decision) in [
        ('one', 'free', 'auto'),
        ('two', 'free', 'auto'),
        ('ready', 'ready', 'ready'),
        ('error', 'free', 'error'),
      ]) {
        await db.assistantQualityDao.record(
          AssistantQualityEventsCompanion.insert(
            eventId: id,
            ownerId: 'a',
            occurredAt: now,
            source: source,
            decision: decision,
            queryId: const Value('workout_summary'),
            periodId: const Value('this_week'),
          ),
          now,
        );
      }
      await db.assistantQualityDao.correct(
        eventId: 'one',
        ownerId: 'a',
        queryId: 'workout_summary',
        periodId: 'this_week',
        exerciseChanged: false,
      );
      var stats = assistantQualityStats(
        await db.assistantQualityDao.events('a'),
        now,
      );
      expect(stats.automatic, 2);
      expect(stats.corrected, 0);
      await db.assistantQualityDao.correct(
        eventId: 'one',
        ownerId: 'a',
        queryId: 'protein_goal',
        periodId: 'this_week',
        exerciseChanged: false,
      );
      stats = assistantQualityStats(
        await db.assistantQualityDao.events('a'),
        now,
      );
      expect(stats.corrected, 1);
      expect(stats.transitions, {'workout_summary→protein_goal': 1});
    },
  );
}
