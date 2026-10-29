import 'dart:async';

import '../sync/sync_errors.dart';
import 'analytics_controller.dart';
import 'analytics_events.dart';

/// Ham sunucu/SQL hata mesajı bu sınırın ötesine taşınmaz.
String analyticsSyncOutcome(
  Object? error, {
  bool permanent = false,
  bool ok = true,
}) {
  if (permanent) return 'permanent';
  if (error == null) return ok ? 'success' : 'unknown';
  return switch (classifySyncError(error)) {
    SyncErrorKind.unreachable => 'unreachable',
    SyncErrorKind.noSession => 'no_session',
    SyncErrorKind.permanent => 'permanent',
    SyncErrorKind.repairable => 'repairable',
    SyncErrorKind.transient => 'unknown',
  };
}

void recordAnalyticsSync(
  AnalyticsController analytics, {
  required String owner,
  required String direction,
  required String outcome,
  required int pending,
  required Duration elapsed,
}) {
  // Bütün işlemler ölçümden bağımsız tamamlanır. Testte/bozuk eklentide
  // beklenmeyen analitik hatası da kullanıcı yazmasını değiştiremez.
  try {
    unawaited(
      analytics
          .trackOwned(owner, AnalyticsEventName.syncCycleResult, {
            'direction': direction,
            'outcome': outcome,
            'pending_bucket': analyticsPendingBucket(pending),
            'duration_bucket': analyticsSyncDurationBucket(elapsed),
          })
          .catchError((_) {}),
    );
  } catch (_) {
    // İsteğe bağlı ölçümün kritik yazma yolunu kesmesine izin verilmez.
  }
}
