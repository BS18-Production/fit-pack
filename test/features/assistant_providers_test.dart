import 'dart:async';
import 'package:fit_pack/core/utils/current_day.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/body_dao.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/assistant/assistant_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_database.dart';

/// İlk okumayı [release] gelene kadar bekletir; okuma sayısını tutar.
class _SlowBodyDao extends BodyDao {
  _SlowBodyDao(super.db, {this.holdFirst = true});
  final bool holdFirst;
  final started = Completer<void>(), release = Completer<void>();
  var reads = 0;
  @override
  Future<List<BodyMeasurement>> getAllMeasurements() async {
    if (++reads == 1 && holdFirst) {
      started.complete();
      await release.future;
    }
    return super.getAllMeasurements();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late StreamController<DateTime> clock;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = newTestDatabase();
    clock = StreamController<DateTime>();
  });

  tearDown(() async {
    await clock.close();
    await db.close();
  });

  ProviderContainer containerWith(BodyDao body) => ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      bodyDaoProvider.overrideWithValue(body),
      assistantClockProvider.overrideWith((ref) => clock.stream),
    ],
  );

  test('gün değişirken devam eden okuma eski ref’e erişmez', () async {
    final body = _SlowBodyDao(db);
    final container = containerWith(body);
    final errors = <Object>[];
    final sub = container.listen(assistantDataProvider, (old, next) {
      if (next.hasError) errors.add(next.error!);
    });
    try {
      await body.started.future.timeout(const Duration(seconds: 5));
      final next = DateTime(2026, 10, 12);
      container.read(currentDayProvider.notifier).state = next;
      await Future<void>.delayed(Duration.zero);
      body.release.complete();
      final data = await container.read(assistantSnapshotProvider.future);
      expect(data.now, next);
      expect(errors, isEmpty);
      expect(body.reads, greaterThanOrEqualTo(2));
    } finally {
      if (!body.release.isCompleted) body.release.complete();
      // Bırakılan ESKİ okuma (gün değişmeden başlayan) kendi DAO'larıyla
      // tamamlanmaya devam eder; veritabanını kapatmadan önce bitmesini bekle —
      // yoksa kapalı veritabanına dokunur ve test (uygulama değil) hata verir.
      await pumpEventQueue(times: 50);
      sub.close();
      container.dispose();
    }
  });

  test('dakikalık saat veritabanını yeniden okumaz, yalnız anı günceller '
      '(CR-017)', () async {
    final body = _SlowBodyDao(db, holdFirst: false);
    final container = containerWith(body);
    final sub = container.listen(assistantDataProvider, (_, _) {});
    try {
      clock.add(DateTime(2026, 10, 12, 9, 0));
      await pumpEventQueue(times: 50);
      expect(body.reads, 1);

      for (var m = 1; m <= 3; m++) {
        clock.add(DateTime(2026, 10, 12, 9, m));
        await pumpEventQueue(times: 50);
      }

      final data = await container.read(assistantDataProvider.future);
      expect(data.now, DateTime(2026, 10, 12, 9, 3));
      expect(body.reads, 1, reason: 'saat ilerlemesi okuma tetiklememeli');
    } finally {
      sub.close();
      container.dispose();
      await pumpEventQueue(times: 50);
    }
  });

  test('tablo değişince fotoğraf yeniden okunur ve ekrana gelir', () async {
    final body = _SlowBodyDao(db, holdFirst: false);
    final container = containerWith(body);
    final sub = container.listen(assistantDataProvider, (_, _) {});
    try {
      clock.add(DateTime.now());
      await pumpEventQueue(times: 50);
      expect(
        (await container.read(assistantDataProvider.future)).measurements,
        isEmpty,
      );

      await db.customInsert(
        'INSERT INTO body_measurements (date, weight_kg) '
        'VALUES (${DateTime.now().millisecondsSinceEpoch ~/ 1000}, 80.0)',
        updates: {db.bodyMeasurements},
      );
      await pumpEventQueue(times: 50);

      final data = await container.read(assistantDataProvider.future);
      expect(data.measurements, hasLength(1));
      expect(body.reads, 2);
    } finally {
      sub.close();
      container.dispose();
      await pumpEventQueue(times: 50);
    }
  });
}
