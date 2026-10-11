import 'dart:io' show Platform;

import 'package:health/health.dart';

/// **Adım kaynağı** (docs/39 §3). Platformun sağlık deposu: iOS HealthKit,
/// Android Health Connect. Arayüz testlerde sahte kaynakla değiştirilir.
///
/// Faz 1 yalnız `STEPS` okur (S-1, en az veri). Yazma ve arka plan yok.

/// Platformda sağlık deposunun durumu.
enum StepPlatformStatus {
  /// Kullanılabilir (iOS her zaman; Android'de Health Connect hazır).
  available,

  /// Android 13 ve altı: Health Connect kurulmalı ya da güncellenmeli.
  needsInstall,

  /// Bu cihazda yok (Android 8 ve altı, desteklenmeyen platform).
  unavailable,
}

abstract class StepSource {
  Future<StepPlatformStatus> platformStatus();

  /// Sistem izin penceresini açar. iOS'ta `true` yalnız pencerenin
  /// gösterildiğini söyler, iznin verildiğini değil (Apple gizlilik kuralı).
  Future<bool> requestAccess();

  /// Android: izin durumu kesin. iOS: okuma izni bilinemez → `null`.
  Future<bool?> hasAccess();

  /// `[start, end)` aralığının tekilleştirilmiş adım toplamı (S-1). Hata ya da
  /// izin yoksa `null`; iOS'ta izin reddi 0 döner (S-3 bunu "veri yok" sayar).
  Future<int?> stepsBetween(DateTime start, DateTime end);

  /// Android: Health Connect'i Play'de açar. iOS'ta bir şey yapmaz.
  Future<void> openInstall();
}

class HealthStepSource implements StepSource {
  HealthStepSource({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  static const _types = [HealthDataType.STEPS];

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<StepPlatformStatus> platformStatus() async {
    if (Platform.isIOS) return StepPlatformStatus.available;
    if (!Platform.isAndroid) return StepPlatformStatus.unavailable;
    await _ensureConfigured();
    return switch (await _health.getHealthConnectSdkStatus()) {
      HealthConnectSdkStatus.sdkAvailable => StepPlatformStatus.available,
      HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired =>
        StepPlatformStatus.needsInstall,
      _ => StepPlatformStatus.unavailable,
    };
  }

  @override
  Future<bool> requestAccess() async {
    await _ensureConfigured();
    try {
      return await _health.requestAuthorization(_types);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool?> hasAccess() async {
    await _ensureConfigured();
    try {
      return await _health.hasPermissions(_types);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<int?> stepsBetween(DateTime start, DateTime end) async {
    await _ensureConfigured();
    try {
      return await _health.getTotalStepsInInterval(start, end);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> openInstall() async {
    await _ensureConfigured();
    await _health.installHealthConnect();
  }
}
