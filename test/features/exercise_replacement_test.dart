import 'package:fit_pack/core/units/units.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/workout/active_session_model.dart';
import 'package:fit_pack/features/workout/exercise_replacement.dart';
import 'package:fit_pack/features/workout/workout_draft.dart';
import 'package:flutter_test/flutter_test.dart';

const _units = Units(UnitSystem.metric);

Exercise _exercise(int id, {String measure = 'weight_reps'}) => Exercise(
  id: id,
  name: 'Exercise $id',
  category: 'compound',
  muscleGroups: 'chest',
  measurementType: measure,
  isPosture: false,
  isArm: false,
  isCustom: false,
  isArchived: false,
);

SessionExerciseEntry _entry(int id, List<SessionSetEntry> sets) =>
    SessionExerciseEntry(
      _exercise(id),
      sets,
      lastSets: [],
      restSec: 45,
      units: _units,
      inRoutine: true,
    );

void main() {
  List<SessionExerciseEntry> plan(
    List<SessionExerciseEntry> entries,
    SessionExerciseEntry source, {
    Exercise? replacement,
  }) => replaceSessionExercise(
    exercises: entries,
    source: source,
    replacement: replacement ?? _exercise(2),
    lastSets: [],
    units: _units,
  );

  test('boş set sayısı korunur; eski set nesnesi yeni harekete geçmez', () {
    final source = _entry(1, [SessionSetEntry(), SessionSetEntry()]);
    final result = plan([source], source);
    expect(result.single.exercise.id, 2);
    expect(result.single.sets.length, 2);
    expect(result.single.sets.any(source.sets.contains), isFalse);
    expect(result.single.inRoutine, isFalse);
    expect(result.single.sessionOnly, isTrue);
    expect(result.single.advice, isNull);
    expect(result.single.appliedIncrementKg, isNull);
    expect(source.sets.length, 2);
  });

  test('tamamlanan set eski harekette aynı değer ve rekorla kalır', () {
    final done = SessionSetEntry()
      ..done = true
      ..weight = 60
      ..reps = 8
      ..rpe = 9
      ..isRecord = true;
    final source = _entry(1, [done, SessionSetEntry()])..bestE1rm = 80;
    final result = plan([source], source);
    expect(result.map((e) => e.exercise.id), [1, 2]);
    expect(result.first.sets.single, same(done));
    expect(result.first.bestE1rm, 80);
    final rows = sessionSetRows(15, result);
    expect(rows.length, 1);
    expect(rows.single.exerciseId.value, 1);
    expect(rows.single.weightKg.value, 60);
    expect(rows.single.rpe.value, 9);
    expect(rows.single.isComplete.value, isTrue);
  });

  test('girilmiş eksik set yeni hareketin arkasında eksiksiz kalır', () {
    final typed = SessionSetEntry()
      ..weight = 42.5
      ..reps = 7;
    final source = _entry(1, [typed, SessionSetEntry()]);
    final before = source.toDraft().toJson();
    final result = plan(
      [source],
      source,
      replacement: _exercise(2, measure: 'time'),
    );
    expect(result.map((e) => e.exercise.id), [2, 1]);
    expect(result.last.sets.single, same(typed));
    expect(result.first.sets.single.weight, isNull);
    expect(result.first.sets.single.durationSec, isNull);
    expect(
      source.toDraft().toJson(),
      before,
      reason: 'plan kaynakta mutasyon yapmaz',
    );
    final rows = sessionSetRows(15, result);
    expect(rows.single.exerciseId.value, 1);
    expect(rows.single.isComplete.value, isFalse);
    expect(rows.single.weightKg.value, 42.5);
  });

  test('yalnız RPE, tür veya ölçüm dışında kalmış alan da kaybolmaz', () {
    final sets = [
      SessionSetEntry()..rpe = 7,
      SessionSetEntry()..type = 'warmup',
      SessionSetEntry()..durationSec = 30,
      SessionSetEntry()..distanceM = 100,
      SessionSetEntry()..isRecord = true,
    ];
    final source = _entry(1, sets);
    final result = plan([source], source);
    expect(result.last.sets, sets);
    expect(result.first.sets.length, 1);
  });

  test(
    'tamamı tamamlanmış kaynak korunur, yeni hareket tek boş setle başlar',
    () {
      final source = _entry(1, [SessionSetEntry()..done = true]);
      final result = plan([source], source);
      expect(result.map((e) => e.exercise.id), [1, 2]);
      expect(result.last.sets.length, 1);
      expect(result.last.sets.single.done, isFalse);
    },
  );

  test('aynı ID iki blokta varsa yalnız seçilen nesne değişir', () {
    final first = _entry(1, [SessionSetEntry()]);
    final second = _entry(1, [SessionSetEntry()..weight = 90]);
    final other = _entry(3, [SessionSetEntry()]);
    final result = plan([first, second, other], first);
    expect(result.map((e) => e.exercise.id), [2, 1, 3]);
    expect(result[1], same(second));
    expect(result[2], same(other));
    expect(result[1].sets.single.weight, 90);
  });

  test('aynı seçim veya artık olmayan blok tam no-op', () {
    final source = _entry(1, [SessionSetEntry()]);
    final entries = [source];
    expect(plan(entries, source, replacement: _exercise(1)), same(entries));
    expect(plan(entries, _entry(1, [])), same(entries));
  });

  test(
    'sessionOnly taslak turunda kalır; eski taslak varsayılanı değişmez',
    () {
      final source = _entry(1, [SessionSetEntry()]);
      final result = plan([source], source).single;
      final decoded = DraftExercise.fromJson(result.toDraft().toJson());
      expect(decoded.sessionOnly, isTrue);
      expect(DraftExercise.fromJson({'id': 1}).sessionOnly, isFalse);
    },
  );
}
