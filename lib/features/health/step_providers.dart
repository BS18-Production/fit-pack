import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/current_day.dart';
import 'health_prefs.dart';
import 'step_source.dart';
import 'step_stats.dart';

/// Adım sağlayıcıları (docs/39). Okuma uygulama açılınca ve öne gelince
/// yapılır (S-9): öne gelişte [stepWeekProvider] `invalidate` edilir.

final stepSourceProvider = Provider<StepSource>((ref) => HealthStepSource());

final stepPlatformStatusProvider = FutureProvider<StepPlatformStatus>(
  (ref) => ref.watch(stepSourceProvider).platformStatus(),
);

/// Ekranın göstereceği bağlantı durumu.
enum StepLinkState {
  /// Bu cihazda sağlık deposu yok → hücre gösterilmez.
  unavailable,

  /// Android: Health Connect kurulmalı.
  needsInstall,

  /// Kullanıcı henüz bağlanmadı (ya da Android'de izni kaldırdı).
  notConnected,

  /// Bağlı → [stepWeekProvider] okunur.
  connected,
}

final stepLinkStateProvider = FutureProvider<StepLinkState>((ref) async {
  final status = await ref.watch(stepPlatformStatusProvider.future);
  switch (status) {
    case StepPlatformStatus.unavailable:
      return StepLinkState.unavailable;
    case StepPlatformStatus.needsInstall:
      return StepLinkState.needsInstall;
    case StepPlatformStatus.available:
      if (!ref.watch(healthPrefsProvider).connected) {
        return StepLinkState.notConnected;
      }
      // Android izni kesin bilir; kaldırılmışsa bağlantı düşer. iOS `null`
      // döner (okuma izni gizli) → tercihe güvenilir, S-4 boş haftayı yakalar.
      final access = await ref.watch(stepSourceProvider).hasAccess();
      return access == false
          ? StepLinkState.notConnected
          : StepLinkState.connected;
  }
});

/// Son 7 günün adımları. Bağlı değilse `null`.
final stepWeekProvider = FutureProvider<StepWeek?>((ref) async {
  final link = await ref.watch(stepLinkStateProvider.future);
  if (link != StepLinkState.connected) return null;
  final source = ref.watch(stepSourceProvider);
  final goal = ref.watch(healthPrefsProvider.select((p) => p.stepGoal));
  ref.watch(currentDayProvider); // gün dönümünde yeni hafta (CR-010)
  final now = DateTime.now();
  final windows = stepDayWindows(now);
  final values = await Future.wait([
    for (final w in windows) source.stepsBetween(w.start, w.end),
  ]);
  return buildStepWeek(
    now: now,
    stepsByDay: {
      for (var i = 0; i < windows.length; i++) windows[i].start: values[i],
    },
    goal: goal,
  );
});

/// "Bağlan" akışı: izin penceresi → tercih → tazeleme. iOS'ta dönüş değeri
/// izni kanıtlamaz; tercih yine kaydedilir, S-4 boş haftada kullanıcıyı
/// izinlere yönlendirir.
Future<void> connectSteps(WidgetRef ref) async {
  final source = ref.read(stepSourceProvider);
  final shown = await source.requestAccess();
  if (!shown) return;
  await ref.read(healthPrefsProvider.notifier).setConnected(true);
  ref.invalidate(stepLinkStateProvider);
  ref.invalidate(stepWeekProvider);
}

/// Ayarlar → "Bağlantıyı kes": yalnız Fit Pack tercihi silinir; platform
/// izni Sağlık / Health Connect ayarlarından kaldırılır (ekran yönlendirir).
Future<void> disconnectSteps(WidgetRef ref) async {
  await ref.read(healthPrefsProvider.notifier).setConnected(false);
  ref.invalidate(stepLinkStateProvider);
  ref.invalidate(stepWeekProvider);
}
