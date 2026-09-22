import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_version_gate.dart';

/// Sunucudaki asgari sürüm kaydını okur (docs/23 §3.2).
///
/// Hata YUTULMAZ, yukarı bırakılır: [AppVersionGate.check] onu yakalayıp
/// "kapı yok" sayar. Burada yutulsaydı "tablo yok" ile "kayıt yok" ayrımı
/// kaybolurdu.
Future<({int minBuild, String? message})?> _fetchMinimum() async {
  final platform = Platform.isIOS ? 'ios' : 'android';
  final row = await Supabase.instance.client
      .from('app_min_version')
      .select('min_build, message')
      .eq('platform', platform)
      .maybeSingle();
  if (row == null) return null;
  final min = row['min_build'];
  if (min is! int) return null;
  final message = row['message'];
  return (minBuild: min, message: message is String ? message : null);
}

/// Kurulu sürümün build numarası. Okunamazsa 0 → kapı atlanır: kendi
/// hatamız yüzünden kullanıcıyı uygulamadan etmeyiz.
Future<int> _currentBuild() async {
  final info = await PackageInfo.fromPlatform();
  return int.tryParse(info.buildNumber) ?? 0;
}

final appVersionGateProvider = Provider<AppVersionGate>(
  (ref) => const AppVersionGate(
    currentBuild: _currentBuild,
    fetchMinimum: _fetchMinimum,
  ),
);

/// Kapının canlı durumu. **`autoDispose` DEĞİL**: yönlendiricinin
/// `refreshListenable`ına bağlı, ekran değişince yok olmamalı.
final updateGateProvider = Provider<UpdateGate>((ref) {
  final gate = UpdateGate(ref.watch(appVersionGateProvider));
  ref.onDispose(gate.dispose);
  return gate;
});
