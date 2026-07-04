import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';
import '../database/daos/workout_dao.dart' show RoutineExerciseWithExercise;

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
  final List<Routine> routines;
  final Map<int, List<RoutineExerciseWithExercise>> routineExercises;
  final List<FoodLog> foodLogs;
  final Map<int, String> foodNames;
  final Map<DateTime, int> water; // gün → ml
  final List<BodyMeasurement> measurements;

  _ExportSnapshot({
    required this.start,
    required this.end,
    required this.scope,
    required this.profile,
    required this.sessions,
    required this.setsBySession,
    required this.exerciseNames,
    required this.routines,
    required this.routineExercises,
    required this.foodLogs,
    required this.foodNames,
    required this.water,
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

  // Rutin haftalık gün etiketi — data katmanı feature koduna bağlanmasın diye
  // yerel tutulur (kWeekdayTr'nin kopyası değil, export'a özgü kısa biçim).
  static const _weekdayTr = {
    1: 'Pzt', 2: 'Sal', 3: 'Çar', 4: 'Per', 5: 'Cum', 6: 'Cmt', 7: 'Paz',
  };

  /// Süre saniye → "m:ss"; null → "-". Ölçüm-tipli setlerin (plank/kardiyo)
  /// dışa aktarımı için.
  static String _dur(int? s) =>
      s == null ? '-' : '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  /// Mesafe metre → "x.xx km"; null → "-".
  static String _dist(double? m) =>
      m == null ? '-' : '${(m / 1000).toStringAsFixed(2)} km';

  /// Set tipi kodunu okunur etikete çevirir (normal → boş).
  static String _setTypeTr(String t) => switch (t) {
        'warmup' => 'Isınma',
        'drop' => 'Drop',
        'failure' => 'Fail',
        _ => '',
      };

  Future<_ExportSnapshot> _snapshot(
    DateTime start,
    DateTime end,
    ExportScope scope,
  ) async {
    // Profile always included as a header block.
    final profile = await db.userProfileDao.getProfile();

    // Workout branch — sessions + bulk sets + rutin tanımları.
    List<WorkoutSession> sessions = const [];
    Map<int, List<WorkoutSet>> setsBySession = const {};
    Map<int, String> exerciseNames = const {};
    List<Routine> routines = const [];
    Map<int, List<RoutineExerciseWithExercise>> routineExercises = const {};
    if (scope == ExportScope.all || scope == ExportScope.workout) {
      final results = await (
        db.workoutDao.getSessionsByDateRange(start, end),
        db.workoutDao.getAllExercises(),
        db.workoutDao.getActiveRoutines(),
      ).wait;
      sessions = results.$1;
      exerciseNames = {for (final e in results.$2) e.id: e.name};
      routines = results.$3;
      setsBySession = await db.workoutDao
          .getSetsForSessions(sessions.map((s) => s.id).toList());
      // Rutin şablonları (tarih aralığından bağımsız — kullanıcının kurduğu
      // programlar). Az sayıda rutin → N+1 kabul edilebilir.
      final re = <int, List<RoutineExerciseWithExercise>>{};
      for (final r in routines) {
        re[r.id] = await db.workoutDao.getRoutineExercises(r.id);
      }
      routineExercises = re;
    }

    // Nutrition branch — logs + food name lookup + su takibi.
    List<FoodLog> foodLogs = const [];
    Map<int, String> foodNames = const {};
    Map<DateTime, int> water = const {};
    if (scope == ExportScope.all || scope == ExportScope.nutrition) {
      final results = await (
        db.nutritionDao.getLogsInRange(start, end),
        db.nutritionDao.getAllFoods(),
        db.nutritionDao.getWaterInRange(start, end),
      ).wait;
      foodLogs = results.$1;
      foodNames = {for (final f in results.$2) f.id: f.name};
      water = results.$3;
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
      routines: routines,
      routineExercises: routineExercises,
      foodLogs: foodLogs,
      foodNames: foodNames,
      water: water,
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

    if (snap.includesWorkout) {
      _workoutsMarkdown(buffer, snap);
      _routinesMarkdown(buffer, snap);
    }
    if (snap.includesNutrition) {
      _nutritionMarkdown(buffer, snap);
      _waterMarkdown(buffer, snap);
    }
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
      buffer.writeln('### ${_isoDate.format(s.date)} — ${s.workoutType}');
      if (s.durationMin != null) buffer.writeln('- Süre: ${s.durationMin} dk');
      if (s.rpe != null) buffer.writeln('- RPE: ${s.rpe}/10');
      if (s.notes != null && s.notes!.isNotEmpty) {
        buffer.writeln('- Not: ${s.notes}');
      }
      final sets = snap.setsBySession[s.id] ?? const [];
      if (sets.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('| Egzersiz | Set | Kg | Tekrar | RPE | Süre | Mesafe | Tip |')
          ..writeln('|---|---|---|---|---|---|---|---|');
        for (final set in sets) {
          final name = snap.exerciseNames[set.exerciseId] ?? '?';
          final kg = set.weightKg?.toStringAsFixed(1) ?? '-';
          final reps = set.reps?.toString() ?? '-';
          final rpe = set.rpe == null ? '-' : _trimNum(set.rpe!);
          final dur = set.durationSec == null ? '-' : _dur(set.durationSec);
          final dist = set.distanceM == null ? '-' : _dist(set.distanceM);
          buffer.writeln('| $name | ${set.setNumber} | $kg | $reps | '
              '$rpe | $dur | $dist | ${_setTypeTr(set.setType)} |');
        }
      }
      buffer.writeln();
    }
  }

  void _routinesMarkdown(StringBuffer buffer, _ExportSnapshot snap) {
    if (snap.routines.isEmpty) return;
    buffer..writeln('## Rutinler (${snap.routines.length})')..writeln();
    for (final r in snap.routines) {
      final day = r.scheduledWeekday == null
          ? ''
          : ' (${_weekdayTr[r.scheduledWeekday]})';
      buffer.writeln('### ${r.name}$day');
      for (final re in snap.routineExercises[r.id] ?? const []) {
        final t = re.routineExercise;
        final reps = (t.targetRepsMin != null && t.targetRepsMax != null)
            ? '${t.targetRepsMin}-${t.targetRepsMax}'
            : '-';
        buffer.writeln('- ${re.exercise.name} — ${t.targetSets ?? '-'}×$reps');
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

  void _waterMarkdown(StringBuffer buffer, _ExportSnapshot snap) {
    if (snap.water.isEmpty) return;
    final days = snap.water.keys.toList()..sort((a, b) => b.compareTo(a));
    buffer..writeln('## Su (${days.length} gün)')..writeln();
    buffer..writeln('| Tarih | ml |')..writeln('|---|---|');
    for (final d in days) {
      buffer.writeln('| ${_isoDate.format(d)} | ${snap.water[d]} |');
    }
    buffer.writeln();
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
  String _trimNum(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

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
        'birthDate': profile.birthDate?.toIso8601String(),
        'gender': profile.gender,
        'activityLevel': profile.activityLevel,
        'waterGoalMl': profile.waterGoalMl,
      };
    }

    if (snap.includesWorkout) {
      data['workouts'] = snap.sessions.map((s) {
        final sets = snap.setsBySession[s.id] ?? const [];
        return {
          'id': s.id,
          'date': s.date.toIso8601String(),
          'workoutType': s.workoutType,
          'routineId': s.routineId,
          'durationMin': s.durationMin,
          'rpe': s.rpe,
          'notes': s.notes,
          'sets': sets
              .map((set) => {
                    'exerciseId': set.exerciseId,
                    'exerciseName': snap.exerciseNames[set.exerciseId],
                    'setNumber': set.setNumber,
                    'weightKg': set.weightKg,
                    'reps': set.reps,
                    'rpe': set.rpe,
                    'setType': set.setType,
                    'isComplete': set.isComplete,
                    'durationSec': set.durationSec,
                    'distanceM': set.distanceM,
                    'isWarmup': set.isWarmup,
                    'restSeconds': set.restSeconds,
                  })
              .toList(),
        };
      }).toList();

      data['routines'] = snap.routines.map((r) {
        final exs = snap.routineExercises[r.id] ?? const [];
        return {
          'id': r.id,
          'name': r.name,
          'scheduledWeekday': r.scheduledWeekday,
          'exercises': exs.map((re) {
            final t = re.routineExercise;
            return {
              'exerciseId': re.exercise.id,
              'exerciseName': re.exercise.name,
              'orderIndex': t.orderIndex,
              'targetSets': t.targetSets,
              'targetRepsMin': t.targetRepsMin,
              'targetRepsMax': t.targetRepsMax,
              'targetRestSec': t.targetRestSec,
            };
          }).toList(),
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

      data['water'] = (snap.water.keys.toList()..sort())
          .map((d) => {'date': _isoDate.format(d), 'ml': snap.water[d]})
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
          'date', 'workoutType', 'exercise', 'setNumber', 'weightKg', 'reps',
          'rpe', 'setType', 'isComplete', 'durationSec', 'distanceM',
          'isWarmup', 'restSeconds',
        ],
      ];
      for (final s in snap.sessions) {
        final sets = snap.setsBySession[s.id] ?? const [];
        for (final set in sets) {
          rows.add([
            _isoDate.format(s.date),
            s.workoutType,
            snap.exerciseNames[set.exerciseId] ?? '',
            set.setNumber,
            set.weightKg ?? '',
            set.reps ?? '',
            set.rpe ?? '',
            set.setType,
            set.isComplete,
            set.durationSec ?? '',
            set.distanceM ?? '',
            set.isWarmup,
            set.restSeconds ?? '',
          ]);
        }
      }
      buffer..writeln(converter.convert(rows))..writeln();

      if (snap.routines.isNotEmpty) {
        buffer.writeln('# ROUTINES');
        final rRows = <List<dynamic>>[
          [
            'routine', 'weekday', 'exercise', 'orderIndex',
            'targetSets', 'targetRepsMin', 'targetRepsMax', 'targetRestSec',
          ],
        ];
        for (final r in snap.routines) {
          for (final re in snap.routineExercises[r.id] ?? const []) {
            final t = re.routineExercise;
            rRows.add([
              r.name,
              r.scheduledWeekday == null
                  ? ''
                  : _weekdayTr[r.scheduledWeekday] ?? '',
              re.exercise.name,
              t.orderIndex,
              t.targetSets ?? '',
              t.targetRepsMin ?? '',
              t.targetRepsMax ?? '',
              t.targetRestSec ?? '',
            ]);
          }
        }
        buffer..writeln(converter.convert(rRows))..writeln();
      }
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

      if (snap.water.isNotEmpty) {
        buffer.writeln('# WATER');
        final wRows = <List<dynamic>>[
          ['date', 'ml'],
        ];
        for (final d in snap.water.keys.toList()..sort()) {
          wRows.add([_isoDate.format(d), snap.water[d]]);
        }
        buffer..writeln(converter.convert(wRows))..writeln();
      }
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
