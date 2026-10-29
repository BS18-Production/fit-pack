/// Hesaba bağlı, yalnız cihazda tutulan haftalık antrenman GÜNÜ hedefleri.
/// Eski sayısal tercihin bilinmeyen geçmişi yeni hedefle doldurulmaz.
library;

DateTime targetDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String targetDateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

DateTime _parseDate(Object? raw) {
  if (raw is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
    throw const FormatException('invalid_weekly_target_date');
  }
  final date = DateTime.tryParse(raw);
  if (date == null || targetDateKey(date) != raw) {
    throw const FormatException('invalid_weekly_target_date');
  }
  return date;
}

void validateWeeklyTarget(int days) {
  if (days < 1 || days > 7) throw ArgumentError.value(days, 'days');
}

class WeeklyTargetRevision {
  final DateTime effectiveWeekStart;
  final int targetDays;

  const WeeklyTargetRevision({
    required this.effectiveWeekStart,
    required this.targetDays,
  });

  Map<String, Object> toJson() => {
    'week': targetDateKey(effectiveWeekStart),
    'days': targetDays,
  };

  factory WeeklyTargetRevision.fromJson(Object? raw) {
    if (raw is! Map || raw['days'] is! int) {
      throw const FormatException('invalid_weekly_target_revision');
    }
    final days = raw['days'] as int;
    if (days < 1 || days > 7) {
      throw const FormatException('invalid_weekly_target_days');
    }
    return WeeklyTargetRevision(
      effectiveWeekStart: _parseDate(raw['week']),
      targetDays: days,
    );
  }
}

class WeeklyTargetHistory {
  final List<WeeklyTargetRevision> revisions;

  WeeklyTargetHistory(Iterable<WeeklyTargetRevision> values)
    : revisions = List.unmodifiable(
        values.toList()..sort(
          (a, b) => a.effectiveWeekStart.compareTo(b.effectiveWeekStart),
        ),
      ) {
    DateTime? previous;
    for (final revision in revisions) {
      validateWeeklyTarget(revision.targetDays);
      if (targetDate(revision.effectiveWeekStart) !=
              revision.effectiveWeekStart ||
          revision.effectiveWeekStart == previous) {
        throw const FormatException('invalid_weekly_target_history');
      }
      previous = revision.effectiveWeekStart;
    }
  }

  WeeklyTargetRevision? revisionFor(DateTime periodStart) {
    final day = targetDate(periodStart);
    WeeklyTargetRevision? result;
    for (final revision in revisions) {
      if (revision.effectiveWeekStart.isAfter(day)) break;
      result = revision;
    }
    return result;
  }

  int? targetFor(DateTime day) => revisionFor(day)?.targetDays;

  /// Gelecek haftanın bekleyen seçimi tekrar düzenlenebilir; geçmiş
  /// revizyonlar çağıran tarafından değiştirilemez (aşağıdaki sözleşme).
  WeeklyTargetHistory schedule({
    required DateTime currentWeekStart,
    required DateTime effectiveWeekStart,
    required int targetDays,
  }) {
    validateWeeklyTarget(targetDays);
    final current = targetDate(currentWeekStart);
    final effective = targetDate(effectiveWeekStart);
    final next = DateTime(current.year, current.month, current.day + 7);
    if (effective != next) {
      throw ArgumentError('Yeni hedef yalnız gelecek tam haftaya uygulanır');
    }
    return WeeklyTargetHistory([
      for (final revision in revisions)
        if (revision.effectiveWeekStart != effective) revision,
      WeeklyTargetRevision(
        effectiveWeekStart: effective,
        targetDays: targetDays,
      ),
    ]);
  }

  Map<String, Object> toJson() => {
    'version': 1,
    'metric': 'training_days',
    'revisions': [for (final revision in revisions) revision.toJson()],
  };

  factory WeeklyTargetHistory.fromJson(Object? raw) {
    if (raw is! Map ||
        raw['version'] != 1 ||
        raw['metric'] != 'training_days' ||
        raw['revisions'] is! List) {
      throw const FormatException('invalid_weekly_target_history');
    }
    return WeeklyTargetHistory(
      (raw['revisions'] as List).map(WeeklyTargetRevision.fromJson),
    );
  }
}

class WeeklyTargetPeriod {
  final DateTime start;
  final DateTime end;
  final int? targetDays;
  final DateTime? targetEffectiveFrom;

  bool get targetKnown => targetDays != null;

  /// Hafta başlangıcı ayarı değiştiğinde dönem iki farklı planı içerebilir.
  /// Seçim bilinir ama bu haftanın tamamı için başarı kıyası yapılamaz.
  bool get coversWholePeriod =>
      targetKnown &&
      (targetEffectiveFrom == null || !targetEffectiveFrom!.isAfter(start));

  const WeeklyTargetPeriod({
    required this.start,
    required this.end,
    required this.targetDays,
    this.targetEffectiveFrom,
  });
}

/// Eski hedef/program yalnız bu haftanın bağlamıdır. Daha eski haftada
/// ne seçildiğinin kanıtı olamaz; null, sıfır/başarısızlık değildir.
WeeklyTargetPeriod resolveWeeklyTargetPeriod({
  required DateTime periodStart,
  required DateTime currentWeekStart,
  required WeeklyTargetHistory? history,
  int? legacyCurrentGoal,
  DateTime? currentDate,
}) {
  final start = targetDate(periodStart);
  final end = DateTime(start.year, start.month, start.day + 7);
  final current = start == targetDate(currentWeekStart);
  // Hafta başlangıcı sonradan değiştirilse bile Pazartesi yürürlüğe
  // girecek seçim Pazar'a taşınmaz. Bu haftada bugünden sonraki revizyon
  // henüz uygulanmaz; kapalı/future dönemde son takvim gününün planı okunur.
  final reference = current
      ? targetDate(currentDate ?? currentWeekStart)
      : DateTime(end.year, end.month, end.day - 1);
  final revision = history?.revisionFor(reference);
  return WeeklyTargetPeriod(
    start: start,
    end: end,
    targetDays: revision?.targetDays ?? (current ? legacyCurrentGoal : null),
    targetEffectiveFrom: revision?.effectiveWeekStart,
  );
}
