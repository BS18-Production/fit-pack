import 'dart:async';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/body_dao.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/assistant/assistant_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_database.dart';

class _SlowBodyDao extends BodyDao {
  _SlowBodyDao(super.db);
  final started = Completer<void>(), release = Completer<void>();
  var reads = 0;
  @override
  Future<List<BodyMeasurement>> getAllMeasurements() async {
    if (++reads == 1) {
      started.complete();
      await release.future;
    }
    return super.getAllMeasurements();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('saat değişirken devam eden okuma eski ref’e erişmez', () async {
    SharedPreferences.setMockInitialValues({});
    final db = newTestDatabase();
    final body = _SlowBodyDao(db);
    final clock = StreamController<DateTime>();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        bodyDaoProvider.overrideWithValue(body),
        assistantClockProvider.overrideWith((ref) => clock.stream),
      ],
    );
    final errors = <Object>[];
    final sub = container.listen(assistantDataProvider, (old, next) {
      if (next.hasError) errors.add(next.error!);
    });
    try {
      await body.started.future.timeout(const Duration(seconds: 5));
      final next = DateTime(2026, 10, 12);
      clock.add(next);
      await container.read(assistantClockProvider.future);
      await Future<void>.delayed(Duration.zero);
      body.release.complete();
      final data = await container.read(assistantDataProvider.future);
      expect(data.now, next);
      expect(errors, isEmpty);
      expect(body.reads, greaterThanOrEqualTo(2));
    } finally {
      if (!body.release.isCompleted) body.release.complete();
      // Bırakılan ESKİ okuma (saat değişmeden başlayan) kendi DAO'larıyla
      // tamamlanmaya devam eder; veritabanını kapatmadan önce bitmesini bekle —
      // yoksa kapalı veritabanına dokunur ve test (uygulama değil) hata verir.
      await pumpEventQueue(times: 50);
      sub.close();
      container.dispose();
      await clock.close();
      await db.close();
    }
  });
}
