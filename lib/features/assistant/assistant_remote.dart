import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'assistant_contract.dart';
import 'assistant_routing.dart';

class AssistantRemoteError implements Exception {
  final String code;
  final DateTime? resetAt;
  const AssistantRemoteError(this.code, [this.resetAt]);
}

class AssistantEnvelope {
  final AssistantRoute route;
  final int? latencyMs, inputTokens, outputTokens;
  const AssistantEnvelope(
    this.route, {
    this.latencyMs,
    this.inputTokens,
    this.outputTokens,
  });
}

class AssistantRemote {
  Future<AssistantEnvelope> route(
    String question,
    String requestId,
    FrozenAssistantRouter router,
  ) async {
    try {
      final r = await Supabase.instance.client.functions
          .invoke(
            'ask-route',
            body: {
              'question': question,
              'request_id': requestId,
              'contract_version': assistantContractVersion,
            },
          )
          .timeout(const Duration(seconds: 10));
      final j = r.data;
      if (j is! Map<String, dynamic> ||
          j['request_id'] != requestId ||
          j['contract_version'] != assistantContractVersion ||
          j['model'] != assistantModel ||
          j['fingerprint'] != assistantFingerprint ||
          j['route'] is! Map<String, dynamic>) {
        throw const AssistantRemoteError('invalid_response');
      }
      int? count(String key) =>
          j[key] is int && (j[key] as int) >= 0 ? j[key] as int : null;
      return AssistantEnvelope(
        AssistantRoute.fromJson(
          j['route'] as Map<String, dynamic>,
          router.exerciseIds,
        ),
        latencyMs: count('latency_ms'),
        inputTokens: count('input_tokens'),
        outputTokens: count('output_tokens'),
      );
    } on AssistantRemoteError {
      rethrow;
    } on FunctionException catch (e) {
      final j = e.details;
      const codes = {
        'daily_quota',
        'minute_quota',
        'provider_quota',
        'disabled',
        'unauthorized',
        'invalid_request',
        'duplicate_request',
        'timeout',
        'invalid_response',
      };
      final code = j is Map && codes.contains(j['error'])
          ? j['error'] as String
          : 'unavailable';
      final reset = j is Map && j['reset_at'] is String
          ? DateTime.tryParse(j['reset_at'] as String)
          : null;
      throw AssistantRemoteError(code, reset);
    } on TimeoutException {
      throw const AssistantRemoteError('timeout');
    } catch (_) {
      throw const AssistantRemoteError('unavailable');
    }
  }
}

final assistantRemoteProvider = Provider<AssistantRemote>(
  (ref) => AssistantRemote(),
);
