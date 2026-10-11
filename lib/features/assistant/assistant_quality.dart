import 'dart:math' as math;
import '../../core/prefs/week_start_provider.dart';
import '../../data/database/app_database.dart';

bool assistantEventCorrected(AssistantQualityEvent e) =>
    (e.correctedQueryId != null && e.correctedQueryId != e.queryId) ||
    (e.correctedPeriodId != null && e.correctedPeriodId != e.periodId) ||
    e.exerciseChanged;

class AssistantQualityStats {
  final int automatic, corrected, inputTokens, outputTokens;
  final int? medianMs, p95Ms;
  final Map<String, int> decisions, queries, transitions;
  final bool twoWeekWarning;
  const AssistantQualityStats({
    required this.automatic,
    required this.corrected,
    required this.inputTokens,
    required this.outputTokens,
    required this.medianMs,
    required this.p95Ms,
    required this.decisions,
    required this.queries,
    required this.transitions,
    required this.twoWeekWarning,
  });
}

AssistantQualityStats assistantQualityStats(
  List<AssistantQualityEvent> events,
  DateTime now, {
  int weekStart = DateTime.monday,
}) {
  final start = now.subtract(const Duration(days: 7));
  final recent = events
      .where(
        (e) =>
            !e.occurredAt.isBefore(start) &&
            !e.occurredAt.isAfter(now) &&
            e.source == 'free',
      )
      .toList();
  final autos = recent.where((e) => e.decision == 'auto').toList();
  final latency = recent.map((e) => e.latencyMs).whereType<int>().toList()
    ..sort();
  final decisions = <String, int>{},
      queries = <String, int>{},
      transitions = <String, int>{};
  for (final e in recent) {
    decisions[e.decision] = (decisions[e.decision] ?? 0) + 1;
    if (e.queryId != null) queries[e.queryId!] = (queries[e.queryId!] ?? 0) + 1;
    if (e.correctedQueryId != null && e.correctedQueryId != e.queryId) {
      final key = '${e.queryId ?? 'out_of_scope'}→${e.correctedQueryId}';
      transitions[key] = (transitions[key] ?? 0) + 1;
    }
  }
  final sow = startOfWeek(now, weekStart);
  bool high(int offset) {
    final a = DateTime(sow.year, sow.month, sow.day - 7 * offset),
        b = DateTime(sow.year, sow.month, sow.day - 7 * (offset - 1));
    final list = events
        .where(
          (e) =>
              e.source == 'free' &&
              e.decision == 'auto' &&
              !e.occurredAt.isBefore(a) &&
              e.occurredAt.isBefore(b),
        )
        .toList();
    return list.isNotEmpty &&
        list.where(assistantEventCorrected).length / list.length > .03;
  }

  return AssistantQualityStats(
    automatic: autos.length,
    corrected: autos.where(assistantEventCorrected).length,
    inputTokens: recent.fold(0, (n, e) => n + (e.inputTokens ?? 0)),
    outputTokens: recent.fold(0, (n, e) => n + (e.outputTokens ?? 0)),
    medianMs: latency.isEmpty
        ? null
        : ((latency[(latency.length - 1) ~/ 2] + latency[latency.length ~/ 2]) /
                  2)
              .round(),
    p95Ms: latency.isEmpty
        ? null
        : latency[math.max(0, (latency.length * .95).ceil() - 1)],
    decisions: decisions,
    queries: queries,
    transitions: transitions,
    twoWeekWarning: high(1) && high(2),
  );
}
