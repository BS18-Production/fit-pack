import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'analytics_events.dart';

class AnalyticsConsent {
  const AnalyticsConsent({
    required this.enabled,
    required this.generation,
    required this.policyVersion,
  });

  final bool enabled;
  final int generation;
  final String? policyVersion;

  factory AnalyticsConsent.fromJson(Object? value) {
    if (value is! Map ||
        value['enabled'] is! bool ||
        value['generation'] is! int ||
        (value['generation'] as int) < 0 ||
        (value['policy_version'] != null &&
            value['policy_version'] != analyticsPolicyVersion)) {
      throw const AnalyticsRemoteException('invalid_response');
    }
    return AnalyticsConsent(
      enabled: value['enabled'] as bool,
      generation: value['generation'] as int,
      policyVersion: value['policy_version'] as String?,
    );
  }
}

/// Kod dışındaki hata metinleri tutulmaz veya analitik olaya dönüştürülmez.
class AnalyticsRemoteException implements Exception {
  const AnalyticsRemoteException(this.code);
  final String code;
}

abstract interface class AnalyticsRemote {
  Future<AnalyticsConsent> status(String ownerId);
  Future<AnalyticsConsent> consent(
    String ownerId, {
    required bool enabled,
    required int expectedGeneration,
    required String requestId,
  });
  Future<void> ingest(
    String ownerId,
    int generation,
    List<AnalyticsEvent> events,
  );
}

/// Mevcut Supabase oturumu kullanılır. İstek ilk hesabın belirteciyle gider;
/// async işlem ortasında B giriş yaparsa A'nın olayı B'ye damgalanamaz.
class SupabaseAnalyticsRemote implements AnalyticsRemote {
  SupabaseAnalyticsRemote(this.client);
  final SupabaseClient Function() client;
  static const timeout = Duration(seconds: 8);

  Future<Object?> _call(String ownerId, Map<String, Object> body) async {
    try {
      final c = client();
      final session = c.auth.currentSession;
      if (session == null || session.user.id != ownerId) {
        throw const AnalyticsRemoteException('account_changed');
      }
      final response = await c.functions
          .invoke(
            'product-data',
            body: body,
            headers: {'Authorization': 'Bearer ${session.accessToken}'},
          )
          .timeout(timeout);
      if (response.status < 200 || response.status >= 300) {
        throw AnalyticsRemoteException(_statusCode(response.status));
      }
      return response.data;
    } on AnalyticsRemoteException {
      rethrow;
    } on FunctionException catch (error) {
      throw AnalyticsRemoteException(_statusCode(error.status));
    } on TimeoutException {
      throw const AnalyticsRemoteException('network');
    } catch (_) {
      throw const AnalyticsRemoteException('network');
    }
  }

  static String _statusCode(int status) => switch (status) {
    401 => 'account_changed',
    403 => 'revoked',
    409 => 'stale_consent',
    400 || 413 => 'invalid_event',
    _ => 'network',
  };

  @override
  Future<AnalyticsConsent> status(String ownerId) async =>
      AnalyticsConsent.fromJson(
        await _call(ownerId, {'action': 'consent_status'}),
      );

  @override
  Future<AnalyticsConsent> consent(
    String ownerId, {
    required bool enabled,
    required int expectedGeneration,
    required String requestId,
  }) async => AnalyticsConsent.fromJson(
    await _call(ownerId, {
      'action': 'consent',
      'enabled': enabled,
      'expected_generation': expectedGeneration,
      'request_id': requestId,
      'policy_version': analyticsPolicyVersion,
    }),
  );

  @override
  Future<void> ingest(
    String ownerId,
    int generation,
    List<AnalyticsEvent> events,
  ) async {
    final result = await _call(ownerId, {
      'action': 'ingest',
      'generation': generation,
      'events': events.map((event) => event.toJson()).toList(),
    });
    // accepted=0 da başarılıdır: aynı kimlikler önceki istekte kabul edilmiş
    // olabilir. Başarılı zarf, partinin tamamının doğrulandığını söyler.
    if (result is! Map ||
        result['accepted'] is! int ||
        (result['accepted'] as int) < 0 ||
        (result['accepted'] as int) > events.length) {
      throw const AnalyticsRemoteException('invalid_response');
    }
  }
}
