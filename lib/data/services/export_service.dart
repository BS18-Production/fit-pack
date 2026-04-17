import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';

/// Exports workout, nutrition, and body data as Markdown, JSON, or CSV.
enum ExportScope { all, workout, nutrition }

/// Snapshot of everything the export needs, fetched up-front in one pass so
/// the three formatters don't redo queries or lookup-maps.
class _ExportSnapshot {
  final DateTime start;
  final DateTime end;
  final ExportScope scope;
  final UserProfileData? profile;
  final List<WorkoutSession> sessions;
  final Map<int, List<WorkoutSet>> setsBySession;
  final Map<int, String> exerciseNames;
  final List<FoodLog> foodLogs;
  final Map<int, String> foodNames;
  final List<BodyMeasurement> measurements;

  _ExportSnapshot({
    required this.start,
    required this.end,
    required this.scope,
    required this.profile,
    required this.sessions,
    required this.setsBySession,
    required this.exerciseNames,
    required this.foodLogs,
    required this.foodNames,
    required this.measurements,
  });

  bool get includesWorkout =>
      scope == ExportScope.all || scope == ExportScope.workout;
  bool get includesNutrition =>
      scope == ExportScope.all || scope == ExportScope.nutrition;
  bool get includesBody => scope == ExportScope.all;
}

class ExportService {
  final AppDatabase db;

  ExportService(this.db);

  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');
  static final DateFormat _isoDateTime = DateFormat('yyyy-MM-dd HH:mm');

  Future<_ExportSnapshot> _snapshot(
    DateTime start,
    DateTime end,
    ExportScope scope,
  ) async {
    // Profile always included as a header block.
    final profile = await db.userProfileDao.getProfile();

    // Workout branch — one session query + one bulk set query.
    List<WorkoutSession> sessions = const [];
    Map<int, List<WorkoutSet>> setsBySession = const {};
    Map<int, String> exerciseNames = const {};
    if (scope == ExportScope.all || scope == ExportScope.workout) {
      final results = await (
        db.workoutDao.getSessionsByDateRange(start, end),
        db.workoutDao.getAllExercises(),
      ).wait;
      sessions = results.$1;
      exerciseNames = {for (final e in results.$2) e.id: e.name};
      setsBySession = await db.workoutDao
          .getSetsForSessions(sessions.map((s) => s.id).toList());
    }

    // Nutrition branch — logs + food name lookup in parallel.
    List<FoodLog> foodLogs = const [];
    Map<int, String> foodNames = const {};
    if (scope == ExportScope.all || scope == ExportScope.nutrition) {
      final results = await (
        db.nutritionDao.getLogsInRange(start, end),
        db.nutritionDao.getAllFoods(),
      ).wait;
      foodLogs = results.$1;
      foodNames = {for (final f in results.$2) f.id: f.name};
    }

    // Body branch — single query, only for full exports.
    List<BodyMeasurement> measurements = const [];
    if (scope == ExportScope.all) {
      measurements = await db.bodyDao.getMeasurementsInRange(start, end);
    }

    return _ExportSnapshot(
      start: start,
      end: end,
      scope: scope,
      profile: profile,
      sessions: sessions,
      setsBySession: setsBySession,
      exerciseNames: exerciseNames,
      foodLogs: foodLogs,
      foodNames: foodNames,
      measurements: measurements,
    );
  }

  Future<String> exportMarkdown(
    DateTime start,
    DateTime end, {
    ExportScope scope = ExportScope.all,
  }) async {
    final snap = await _snapshot(start, end, scope);
    final buffer = StringBuffer()
      ..writeln('# Fit Pack Export')
      ..writeln()
      ..writeln('Aralık: ${_isoDate.format(snap.start)} → ${_isoDate.format(snap.end)}')
      ..writeln('Oluşturulma: ${_isoDateTime.format(DateTime.now())}')
      ..writeln();

    final profile = snap.profile;
    if (profile != null) {
      buffer
        ..writeln('## Profil')
        ..writeln('- Faz: ${profile.currentPhase}, Hafta: ${profile.currentWeek}')
        ..writeln('- Kalori hedefi: ${profile.kcalGoal} kcal')
        ..writeln('- Protein hedefi: ${profile.proteinGoal} g');
      if (profile.heightCm != null) buffer.writeln('- Boy: ${profile.heightCm} cm');
      if (profile.goalWeightKg != null) {
        buffer.writeln('- Hedef kilo: ${profile.goalWeightKg} kg');
      }
      buffer.writeln();
    }

    if (snap.includesWorkout) _workoutsMarkdown(buffer, snap);
    if (snap.includesNutrition) _nutritionMarkdown(buffer, snap);
    if (snap.includesBody) _bodyMarkdown(buffer, snap);
    return buffer.toString();
  }

  void _workoutsMarkdown(StringBuffer buffer, _ExportSnapshot snap) {
    buffer..writeln('## Antrenmanlar (${snap.sessions.length} seans)')..writeln();
    if (snap.sessions.isEmpty) {
      buffer..writeln('_Bu aralıkta antrenman yok._')..writeln();
      return;
    }
    for (final s in snap.sessions) {
      buffer.writeln(
        '### ${_isoDate.format(s.date)} — ${s.workoutType} (Faz ${s.phase})',
      );
      if (s.durationMin != null) buffer.writeln('- Süre: ${s.durationMin} dk');
      if (s.energy != null) buffer.writeln('- Enerji: ${s.energy}/10');
      if (s.rpe != null) buffer.writeln('- RPE: ${s.rpe}/10');
      buffer.writeln('- Diz: ${s.kneeStatus}');
      if (s.isDeload) buffer.writeln('- **Deload haftası**');
      if (s.notes != null && s.notes!.isNotEmpty) {
        buffer.writeln('- Not: ${s.notes}');
      }
      final sets = snap.setsBySession[s.id] ?? const [];
      if (sets.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('| Egzersiz | Set | Kg | Reps | Isınma |')
          ..writeln('|---|---|---|---|---|');
        for (final set in sets) {
          final name = snap.exerciseNames[set.exerciseId] ?? '?';
          final kg = set.weightKg?.toStringAsFixed(1) ?? '-';
          final reps = set.reps?.toString() ?? '-';
          final warmup = set.isWarmup ? '✓' : '';
          buffer.writeln('| $name | ${set.setNumber} | $kg | $reps | $warmup |');
        }
      }
      buffer.writeln();
    }
  }

  void _nutritionMarkdown(StringBuffer buffer, _ExportSnapshot snap) {
    buffer..writeln('## Beslenme (${snap.foodLogs.length} kayıt)')..writeln();
    if (snap.foodLogs.isEmpty) {
      buffer..writeln('_Bu aralıkta beslenme kaydı yok._')..writeln();
      return;
    }

    final byDate = <String, List<FoodLog>>{};
    for (final log in snap.foodLogs) {
      byDate.putIfAbsent(_isoDate.format(log.date), () => []).add(log);
    }
    final sortedKeys = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

    for (final dateKey in sortedKeys) {
      final dayLogs = byDate[dateKey]!;
      double kcal = 0, protein = 0, carb = 0, fat = 0;
      for (final l in dayLogs) {
        kcal += l.computedKcal;
        protein += l.computedProtein;
        carb += l.computedCarb;
        fat += l.computedFat;
      }
      buffer
        ..writeln('### $dateKey')
        ..writeln(
          '- Toplam: ${kcal.toStringAsFixed(0)} kcal · '
          'P ${protein.toStringAsFixed(0)}g · '
          'K ${carb.toStringAsFixed(0)}g · '
          'Y ${fat.toStringAsFixed(0)}g',
        )
        ..writeln()
        ..writeln('| Öğün | Yemek | Gram | Kcal | Protein |')
        ..writeln('|---|---|---|---|---|');
      for (final l in dayLogs) {
        final name = snap.foodNames[l.foodId] ?? '?';
        buffer.writeln(
          '| ${l.mealType} | $name | ${l.grams.toStringAsFixed(0)} | '
          '${l.computedKcal.toStringAsFixed(0)} | '
          '${l.computedProtein.toStringAsFixed(1)} |',
        );
      }
      buffer.writeln();
    }
  }

  void _bodyMarkdown(StringBuffer buffer, _ExportSnapshot snap) {
    buffer..writeln('## Vücut Ölçüleri (${snap.measurements.length} kayıt)')..writeln();
    if (snap.measurements.isEmpty) {
      buffer..writeln('_Bu aralıkta ölçüm yok._')..writeln();
      return;
    }
    buffer
      ..writeln('| Tarih | Kilo | Bel | Göğüs | Kol | Kalça | Boyun | YY% |')
      ..writeln('|---|---|---|---|---|---|---|---|');
    for (final m in snap.measurements) {
      buffer.writeln(
        '| ${_isoDate.format(m.date)} | ${_num(m.weightKg)} | '
        '${_num(m.waistCm)} | ${_num(m.chestCm)} | ${_num(m.armCm)} | '
        '${_num(m.hipCm)} | ${_num(m.neckCm)} | ${_num(m.bodyFatPct)} |',
      );
    }
    buffer.writeln();
  }

  String _num(double? v) => v == null ? '-' : v.toStringAsFixed(1);

  Future<String> exportJson(
    DateTime start,
    DateTime end, {
    ExportScope scope = ExportScope.all,
  }) async {
    final snap = await _snapshot(start, end, scope);
    final data = <String, dynamic>{
      'range': {
        'start': snap.start.toIso8601String(),
        'end': snap.end.toIso8601String(),
      },
      'generatedAt': DateTime.now().toIso8601String(),
    };

    final profile = snap.profile;
    if (profile != null) {
      data['profile'] = {
        'currentPhase': profile.currentPhase,
        'currentWeek': profile.currentWeek,
        'kcalGoal': profile.kcalGoal,
        'proteinGoal': profile.proteinGoal,
        'heightCm': profile.heightCm,
        'goalWeightKg': profile.goalWeightKg,
      };
    }

    if (snap.includesWorkout) {
      data['workouts'] = snap.sessions.map((s) {
        final sets = snap.setsBySession[s.id] ?? const [];
        return {
          'id': s.id,
          'date': s.date.toIso8601String(),
          'phase': s.phase,
          'workoutType': s.workoutType,
          'durationMin': s.durationMin,
          'kneeStatus': s.kneeStatus,
          'energy': s.energy,
          'rpe': s.rpe,
          'isDeload': s.isDeload,
          'notes': s.notes,
          'sets': sets
              .map((set) => {
                    'exerciseId': set.exerciseId,
                    'exerciseName': snap.exerciseNames[set.exerciseId],
                    'setNumber': set.setNumber,
                    'weightKg': set.weightKg,
                    'reps': set.reps,
                    'isWarmup': set.isWarmup,
                    'restSeconds': set.restSeconds,
                  })
              .toList(),
        };
      }).toList();
    }

    if (snap.includesNutrition) {
      data['nutritionLogs'] = snap.foodLogs
          .map((l) => {
                'id': l.id,
                'date': l.date.toIso8601String(),
                'mealType': l.mealType,
                'foodId': l.foodId,
                'foodName': snap.foodNames[l.foodId],
                'grams': l.grams,
                'kcal': l.computedKcal,
                'protein': l.computedProtein,
                'carb': l.computedCarb,
                'fat': l.computedFat,
              })
          .toList();
    }

    if (snap.includesBody) {
      data['bodyMeasurements'] = snap.measurements
          .map((m) => {
                'id': m.id,
                'date': m.date.toIso8601String(),
                'weightKg': m.weightKg,
                'waistCm': m.waistCm,
                'chestCm': m.chestCm,
                'armCm': m.armCm,
                'hipCm': m.hipCm,
                'neckCm': m.neckCm,
                'bodyFatPct': m.bodyFatPct,
              })
          .toList();
    }

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// CSV emits one labeled section per scope, separated by blank lines so
  /// Excel/Sheets/pandas can read each chunk independently.
  Future<String> exportCsv(
    DateTime start,
    DateTime end, {
    ExportScope scope = ExportScope.all,
  }) async {
    final snap = await _snapshot(start, end, scope);
    const converter = ListToCsvConverter();
    final buffer = StringBuffer();

    if (snap.includesWorkout) {
      buffer.writeln('# WORKOUT_SETS');
      final rows = <List<dynamic>>[
        [
          'date', 'phase', 'workoutType', 'exercise', 'setNumber',
          'weightKg', 'reps', 'isWarmup', 'restSeconds',
        ],
      ];
      for (final s in snap.sessions) {
        final sets = snap.setsBySession[s.id] ?? const [];
        for (final set in sets) {
          rows.add([
            _isoDate.format(s.date),
            s.phase,
            s.workoutType,
            snap.exerciseNames[set.exerciseId] ?? '',
            set.setNumber,
            set.weightKg ?? '',
            set.reps ?? '',
            set.isWarmup,
            set.restSeconds ?? '',
          ]);
        }
      }
      buffer..writeln(converter.convert(rows))..writeln();
    }

    if (snap.includesNutrition) {
      buffer.writeln('# NUTRITION_LOGS');
      final rows = <List<dynamic>>[
        ['date', 'mealType', 'food', 'grams', 'kcal', 'protein', 'carb', 'fat'],
      ];
      for (final l in snap.foodLogs) {
        rows.add([
          _isoDate.format(l.date),
          l.mealType,
          snap.foodNames[l.foodId] ?? '',
          l.grams,
          l.computedKcal,
          l.computedProtein,
          l.computedCarb,
          l.computedFat,
        ]);
      }
      buffer..writeln(converter.convert(rows))..writeln();
    }

    if (snap.includesBody) {
      buffer.writeln('# BODY_MEASUREMENTS');
      final rows = <List<dynamic>>[
        [
          'date', 'weightKg', 'waistCm', 'chestCm', 'armCm',
          'hipCm', 'neckCm', 'bodyFatPct',
        ],
      ];
      for (final m in snap.measurements) {
        rows.add([
          _isoDate.format(m.date),
          m.weightKg ?? '',
          m.waistCm ?? '',
          m.chestCm ?? '',
          m.armCm ?? '',
          m.hipCm ?? '',
          m.neckCm ?? '',
          m.bodyFatPct ?? '',
        ]);
      }
      buffer.writeln(converter.convert(rows));
    }

    return buffer.toString();
  }
}
