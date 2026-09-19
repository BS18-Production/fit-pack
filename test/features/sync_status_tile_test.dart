import 'package:drift/native.dart';
import 'package:fit_pack/core/theme/app_colors.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/sync/sync_controller.dart';
import 'package:fit_pack/features/sync/sync_providers.dart';
import 'package:fit_pack/features/sync/sync_push.dart';
import 'package:fit_pack/features/sync/sync_status.dart';
import 'package:fit_pack/features/sync/sync_status_tile.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_sync_server.dart';

/// Hesap ekranındaki senkron satırı (docs/20 §9). Durum sağlayıcısı sabit bir
/// değerle ezilir; satırın her durumda doğru metni gösterdiği ölçülür.
///
/// Görsel (piksel) doğrulama değildir — o simülatörde yapılır. Burada ölçülen:
/// doğru metin, doğru koşulda, doğru dilde; ve "tekrar dene" dokunuşunun
/// gerçekten hatalı satırları kuyruğa alması.
void main() {
  late AppDatabase db;
  late _SpyController controller;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    controller = _SpyController(db);
  });
  tearDown(() => db.close());

  final simdi = DateTime(2026, 9, 19, 14, 32);

  Future<void> goster(WidgetTester tester, SyncStatus status) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        syncControllerProvider.overrideWithValue(controller),
        syncStatusProvider.overrideWith((ref) => Stream.value(status)),
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: AppColors.lightScheme,
          extensions: [AppColors.lightSemantic],
        ),
        locale: const Locale('tr'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: const Scaffold(body: SyncStatusTile()),
      ),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('güncel + son yedekleme bugün', (tester) async {
    await goster(
      tester,
      SyncStatus(
        pending: 0,
        state: SyncState.synced,
        lastOk: DateTime(2026, 9, 19, 9, 5),
        now: simdi,
      ),
    );
    expect(find.text('Verilerin güncel'), findsOneWidget);
    expect(find.text('Son yedekleme: bugün 09:05'), findsOneWidget);
    expect(find.textContaining('yedeklenemedi'), findsNothing);
    expect(find.textContaining('yüklenemedi'), findsNothing);
  });

  testWidgets('son yedekleme dün', (tester) async {
    await goster(
      tester,
      SyncStatus(
        pending: 2,
        state: SyncState.pending,
        lastOk: DateTime(2026, 9, 18, 21, 40),
        now: simdi,
      ),
    );
    expect(find.text('Son yedekleme: dün 21:40'), findsOneWidget);
  });

  testWidgets('hiç yedeklenmediyse satır görünmez (yanlış tarih yazılmaz)',
      (tester) async {
    await goster(
      tester,
      SyncStatus(pending: 1, state: SyncState.pending, now: simdi),
    );
    expect(find.textContaining('Son yedekleme'), findsNothing);
  });

  testWidgets('3 günden uzun kesinti → uyarı, "güvende" güvencesiyle',
      (tester) async {
    await goster(
      tester,
      SyncStatus(
        pending: 5,
        state: SyncState.failed,
        unreachableSince: simdi.subtract(const Duration(days: 4)),
        now: simdi,
      ),
    );
    expect(
      find.text('4 gündür yedeklenemedi. Veriler bu telefonda güvende.'),
      findsOneWidget,
    );
  });

  testWidgets('kısa kesintide uyarı YOK', (tester) async {
    await goster(
      tester,
      SyncStatus(
        pending: 5,
        state: SyncState.failed,
        unreachableSince: simdi.subtract(const Duration(hours: 30)),
        now: simdi,
      ),
    );
    expect(find.textContaining('yedeklenemedi'), findsNothing);
  });

  testWidgets('hatalı satır → dokununca tekrar denenir', (tester) async {
    await goster(
      tester,
      SyncStatus(pending: 0, state: SyncState.synced, failed: 3, now: simdi),
    );
    final uyari =
        find.text('3 kayıt yüklenemedi — tekrar denemek için dokun');
    expect(uyari, findsOneWidget);

    await tester.tap(uyari);
    await tester.pump();
    expect(controller.retryCalls, 1);
  });
}

/// Yalnız "tekrar dene" çağrısını sayan kontrolcü.
class _SpyController extends SyncController {
  _SpyController(AppDatabase db)
      : super(
          db: db,
          push: SyncPush(db, FakeSyncServer()),
          currentUserId: () => null,
        );

  int retryCalls = 0;

  @override
  Future<void> retryFailed() async => retryCalls++;
}
