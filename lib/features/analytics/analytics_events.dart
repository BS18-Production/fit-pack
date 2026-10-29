/// Faz 1'in kapalı veri sözleşmesi. Sağlık değerleri ve serbest metin yok.
enum AnalyticsEventName {
  sessionStarted('session_started'),
  sessionEnded('session_ended'),
  onboardingStepCompleted('onboarding_step_completed'),
  workoutStarted('workout_started'),
  workoutSaved('workout_saved'),
  appError('app_error'),
  syncCycleResult('sync_cycle_result');

  const AnalyticsEventName(this.wireName);
  final String wireName;

  static AnalyticsEventName? parse(Object? value) {
    for (final name in values) {
      if (name.wireName == value) return name;
    }
    return null;
  }
}

const analyticsPolicyVersion = 'phase1-v1';
const analyticsQueueLimit = 500;
const analyticsBatchLimit = 50;
const analyticsQueueRetention = Duration(days: 7);

const _durationValues = {'under_1m', '1_5m', '5_15m', '15_60m', 'over_60m'};
const _modeValues = {'routine', 'free'};
const _schemas = <AnalyticsEventName, Map<String, Set<String>>>{
  AnalyticsEventName.sessionStarted: {
    'reason': {'cold_start', 'foreground'},
  },
  AnalyticsEventName.sessionEnded: {'duration_bucket': _durationValues},
  AnalyticsEventName.onboardingStepCompleted: {
    'step': {'training', 'nutrition', 'complete'},
  },
  AnalyticsEventName.workoutStarted: {'mode': _modeValues},
  AnalyticsEventName.workoutSaved: {
    'mode': _modeValues,
    'source': {'live', 'historical'},
  },
  AnalyticsEventName.appError: {
    'code': {'startup', 'ui', 'storage', 'network', 'unknown'},
    'screen': {'app', 'onboarding', 'workout', 'settings', 'sync'},
  },
  AnalyticsEventName.syncCycleResult: {
    'direction': {'push', 'pull'},
    'outcome': {
      'success',
      'unreachable',
      'no_session',
      'permanent',
      'repairable',
      'unknown',
    },
    'pending_bucket': {'zero', '1_10', '11_100', 'over_100'},
    'duration_bucket': {'under_1s', '1_5s', '5_30s', 'over_30s'},
  },
};

bool _keys(Map<Object?, Object?> json, Set<String> expected) =>
    json.length == expected.length && json.keys.every(expected.contains);

bool isAnalyticsUuid(Object? value) =>
    value is String &&
    RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(value);

/// İzinli olmayan ek alan tek başına tüm olayı geçersiz kılar.
bool validAnalyticsProperties(
  AnalyticsEventName name,
  Map<Object?, Object?> properties,
) {
  final schema = _schemas[name]!;
  return _keys(properties, schema.keys.toSet()) &&
      schema.entries.every(
        (entry) =>
            properties[entry.key] is String &&
            entry.value.contains(properties[entry.key]),
      );
}

class AnalyticsContext {
  AnalyticsContext({
    required this.version,
    required this.build,
    required this.platform,
    required this.osMajor,
    required this.environment,
  }) {
    if (!RegExp(r'^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$').hasMatch(version) ||
        !RegExp(r'^[0-9]{1,10}$').hasMatch(build) ||
        !{'ios', 'android', 'other'}.contains(platform) ||
        osMajor < 0 ||
        osMajor > 99 ||
        !{'production', 'development', 'test'}.contains(environment)) {
      throw const FormatException('invalid_analytics_context');
    }
  }

  final String version;
  final String build;
  final String platform;
  final int osMajor;
  final String environment;

  factory AnalyticsContext.fromJson(Map<Object?, Object?> json) {
    if (!_keys(json, {
          'version',
          'build',
          'platform',
          'os_major',
          'environment',
        }) ||
        json['version'] is! String ||
        json['build'] is! String ||
        json['platform'] is! String ||
        json['os_major'] is! int ||
        json['environment'] is! String) {
      throw const FormatException('invalid_analytics_context');
    }
    return AnalyticsContext(
      version: json['version'] as String,
      build: json['build'] as String,
      platform: json['platform'] as String,
      osMajor: json['os_major'] as int,
      environment: json['environment'] as String,
    );
  }

  Map<String, Object> toJson() => {
    'version': version,
    'build': build,
    'platform': platform,
    'os_major': osMajor,
    'environment': environment,
  };
}

class AnalyticsEvent {
  AnalyticsEvent({
    required this.eventId,
    required this.occurredAt,
    required this.sessionId,
    required this.name,
    required Map<String, Object> properties,
    required this.context,
  }) : properties = Map<String, Object>.unmodifiable(properties) {
    if (!isAnalyticsUuid(eventId) ||
        !isAnalyticsUuid(sessionId) ||
        !validAnalyticsProperties(name, this.properties)) {
      throw const FormatException('invalid_analytics_event');
    }
  }

  final String eventId;
  final DateTime occurredAt;
  final String sessionId;
  final AnalyticsEventName name;
  final Map<String, Object> properties;
  final AnalyticsContext context;

  factory AnalyticsEvent.fromJson(Map<Object?, Object?> json) {
    const keys = {
      'event_id',
      'occurred_at',
      'session_id',
      'name',
      'properties',
      'context',
    };
    final name = AnalyticsEventName.parse(json['name']);
    final at = json['occurred_at'] is String
        ? DateTime.tryParse(json['occurred_at'] as String)
        : null;
    if (!_keys(json, keys) ||
        name == null ||
        at == null ||
        json['event_id'] is! String ||
        json['session_id'] is! String ||
        json['properties'] is! Map ||
        json['context'] is! Map) {
      throw const FormatException('invalid_analytics_event');
    }
    final raw = json['properties'] as Map;
    if (!validAnalyticsProperties(name, raw)) {
      throw const FormatException('invalid_analytics_event');
    }
    return AnalyticsEvent(
      eventId: json['event_id'] as String,
      occurredAt: at.toUtc(),
      sessionId: json['session_id'] as String,
      name: name,
      properties: Map<String, Object>.from(raw),
      context: AnalyticsContext.fromJson(json['context'] as Map),
    );
  }

  Map<String, Object> toJson() => {
    'event_id': eventId,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'session_id': sessionId,
    'name': name.wireName,
    'properties': properties,
    'context': context.toJson(),
  };
}

String analyticsSessionDurationBucket(Duration duration) =>
    switch (duration.inSeconds) {
      < 60 => 'under_1m',
      < 300 => '1_5m',
      < 900 => '5_15m',
      < 3600 => '15_60m',
      _ => 'over_60m',
    };

String analyticsPendingBucket(int count) => switch (count) {
  <= 0 => 'zero',
  <= 10 => '1_10',
  <= 100 => '11_100',
  _ => 'over_100',
};

String analyticsSyncDurationBucket(Duration duration) =>
    switch (duration.inMilliseconds) {
      < 1000 => 'under_1s',
      < 5000 => '1_5s',
      < 30000 => '5_30s',
      _ => 'over_30s',
    };
