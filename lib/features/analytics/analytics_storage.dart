import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_events.dart';

/// Tek JSON yazımı: tercih ve kuyruk ayrı yazımlar yüzünden ayrışmaz.
abstract interface class AnalyticsStorage {
  Future<String?> read();
  Future<void> write(String value);
}

class PreferencesAnalyticsStorage implements AnalyticsStorage {
  static const key = 'product_analytics_phase1_v1';

  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> write(String value) async {
    if (!await (await SharedPreferences.getInstance()).setString(key, value)) {
      throw const AnalyticsStorageException();
    }
  }
}

class AnalyticsStorageException implements Exception {
  const AnalyticsStorageException();
}

class AnalyticsRevocation {
  const AnalyticsRevocation(this.requestId, this.generation);
  final String requestId;
  final int generation;

  Map<String, Object> toJson() => {
    'request_id': requestId,
    'generation': generation,
  };

  factory AnalyticsRevocation.fromJson(Map<Object?, Object?> json) {
    if (json.length != 2 ||
        !isAnalyticsUuid(json['request_id']) ||
        json['generation'] is! int ||
        (json['generation'] as int) < 0) {
      throw const FormatException('invalid_analytics_storage');
    }
    return AnalyticsRevocation(
      json['request_id'] as String,
      json['generation'] as int,
    );
  }
}

class AnalyticsSnapshot {
  AnalyticsSnapshot({
    this.ownerId,
    this.enabled = false,
    this.generation = 0,
    this.policyVersion,
    List<AnalyticsEvent> queue = const [],
    Map<String, AnalyticsRevocation> revocations = const {},
  }) : queue = List.unmodifiable(queue),
       revocations = Map.unmodifiable(revocations);

  static const maxRevocations = 16;
  final String? ownerId;
  final bool enabled;
  final int generation;
  final String? policyVersion;
  final List<AnalyticsEvent> queue;
  final Map<String, AnalyticsRevocation> revocations;

  String encode() => jsonEncode({
    'version': 1,
    'owner_id': ownerId,
    'enabled': enabled,
    'generation': generation,
    'policy_version': policyVersion,
    'queue': queue.map((event) => event.toJson()).toList(),
    'revocations': revocations.map(
      (owner, value) => MapEntry(owner, value.toJson()),
    ),
  });

  factory AnalyticsSnapshot.decode(String raw, DateTime now) {
    if (raw.length > 1024 * 1024) {
      throw const FormatException('invalid_analytics_storage');
    }
    final json = jsonDecode(raw);
    const keys = {
      'version',
      'owner_id',
      'enabled',
      'generation',
      'policy_version',
      'queue',
      'revocations',
    };
    if (json is! Map ||
        json.length != keys.length ||
        !json.keys.every(keys.contains) ||
        json['version'] != 1 ||
        (json['owner_id'] != null && !isAnalyticsUuid(json['owner_id'])) ||
        json['enabled'] is! bool ||
        json['generation'] is! int ||
        (json['generation'] as int) < 0 ||
        (json['policy_version'] != null &&
            json['policy_version'] != analyticsPolicyVersion) ||
        json['queue'] is! List ||
        (json['queue'] as List).length > analyticsQueueLimit ||
        json['revocations'] is! Map ||
        (json['revocations'] as Map).length > maxRevocations) {
      throw const FormatException('invalid_analytics_storage');
    }
    final revocations = <String, AnalyticsRevocation>{};
    for (final entry in (json['revocations'] as Map).entries) {
      if (!isAnalyticsUuid(entry.key) || entry.value is! Map) {
        throw const FormatException('invalid_analytics_storage');
      }
      revocations[entry.key as String] = AnalyticsRevocation.fromJson(
        entry.value as Map,
      );
    }
    final events = <AnalyticsEvent>[];
    final ids = <String>{};
    for (final rawEvent in json['queue'] as List) {
      if (rawEvent is! Map) {
        throw const FormatException('invalid_analytics_storage');
      }
      final event = AnalyticsEvent.fromJson(rawEvent);
      if (event.occurredAt.isAfter(now.add(const Duration(minutes: 5)))) {
        continue;
      }
      if (event.occurredAt.isAfter(now.subtract(analyticsQueueRetention)) &&
          ids.add(event.eventId)) {
        events.add(event);
      }
    }
    final owner = json['owner_id'] as String?;
    final enabled =
        owner != null &&
        json['enabled'] == true &&
        json['policy_version'] == analyticsPolicyVersion &&
        !revocations.containsKey(owner);
    return AnalyticsSnapshot(
      ownerId: owner,
      enabled: enabled,
      generation: json['generation'] as int,
      policyVersion: json['policy_version'] as String?,
      queue: enabled ? events : const [],
      revocations: revocations,
    );
  }
}
