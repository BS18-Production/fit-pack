import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'analytics_controller.dart';
import 'analytics_events.dart';
import 'analytics_remote.dart';
import 'analytics_storage.dart';

const analyticsBuildEnabled = bool.fromEnvironment(
  'FITPACK_ANALYTICS_ENABLED',
  defaultValue: false,
);

/// Android'deki uname/kernel sürümü Android sürümü diye etiketlenmez.
/// Güvenilir biçim yoksa 0=bilinmiyor; ham platform metni dışarı çıkmaz.
int analyticsOsMajor(String platform, String description) {
  final pattern = switch (platform) {
    'ios' => RegExp(r'^Version\s+(\d+)\b'),
    'android' => RegExp(r'^Android\s+(\d+)\b'),
    _ => null,
  };
  final major =
      int.tryParse(pattern?.firstMatch(description)?.group(1) ?? '') ?? 0;
  return major >= 0 && major <= 99 ? major : 0;
}

Future<AnalyticsContext> _deviceContext() async {
  final info = await PackageInfo.fromPlatform();
  final platform = switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    TargetPlatform.android => 'android',
    _ => 'other',
  };
  return AnalyticsContext(
    version: info.version,
    build: info.buildNumber,
    platform: platform,
    osMajor: analyticsOsMajor(platform, Platform.operatingSystemVersion),
    environment: kDebugMode ? 'development' : 'production',
  );
}

/// Hesap/lifecycle bağlaması çağıranda; bu provider yeni oturum sistemi kurmaz.
final analyticsControllerProvider = ChangeNotifierProvider<AnalyticsController>(
  (ref) {
    Future<AnalyticsContext>? cached;
    return AnalyticsController(
      storage: PreferencesAnalyticsStorage(),
      remote: SupabaseAnalyticsRemote(() => Supabase.instance.client),
      context: () => cached ??= _deviceContext(),
      featureEnabled: analyticsBuildEnabled,
    );
  },
);
