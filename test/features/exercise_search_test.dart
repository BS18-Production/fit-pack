import 'dart:convert';
import 'dart:io';

import 'package:fit_pack/data/seed/exercises_seed.dart';
import 'package:fit_pack/features/workout/exercise_search.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hareket arama v2 (docs/21 §2 #11). Gerçek katalog (küratörlü seed +
/// genişletilmiş JSON = 1015 hareket) üzerinde "altın liste": gerçek
/// aramalar ve ilk sonuçlarda görünmesi gereken hareket.
void main() {
  final terms = ExerciseTermData.fromJson(
    File('assets/data/exercise_terms_tr.json').readAsStringSync(),
  );

  final catalog = <SearchableExercise>[];
  var id = 1;
  for (final s in exerciseSeedData) {
    catalog.add(
      SearchableExercise(
        id: id++,
        name: s.name,
        category: s.category,
        primaryMuscle: s.primaryMuscle,
        equipment: s.equipment,
        muscles: s.muscles,
        isCurated: true,
      ),
    );
  }
  final extended =
      (jsonDecode(
                File('assets/data/exercises_extended.json').readAsStringSync(),
              )
              as List)
          .cast<Map<String, dynamic>>();
  for (final e in extended) {
    catalog.add(
      SearchableExercise(
        id: id++,
        name: e['name'] as String,
        category: e['category'] as String,
        primaryMuscle: e['primaryMuscle'] as String?,
        equipment: e['equipment'] as String?,
        muscles: ((e['muscles'] as List?) ?? const []).cast<String>(),
      ),
    );
  }
  final byId = {for (final e in catalog) e.id: e};
  final index = ExerciseSearchIndex(catalog, terms);

  List<SearchableExercise> results(
    String q, {
    Map<int, int> usage = const {},
  }) => [for (final i in index.search(q, usage: usage)) byId[i]!];
  List<String> top(String q, [int n = 3]) =>
      results(q).take(n).map((e) => e.name).toList();

  test('katalog tam yüklendi', () {
    expect(catalog.length, greaterThanOrEqualTo(1000));
  });

  group('sadeleştirme', () {
    test('Türkçe harf, tire, çoğul, birleşik yazım', () {
      expect(searchWords('Şınav'), ['sinav']);
      expect(searchWords('Pull-Ups'), ['pull', 'up']);
      expect(searchWords('pullup'), ['pull', 'up']);
      expect(searchWords('Dumbbell Flyes'), ['dumbbell', 'fly']);
      expect(searchWords('Bench Press'), ['bench', 'press']);
      expect(searchWords('İNCLİNE'), ['incline']);
    });
  });

  // Arama → ilk 3'te olması gereken hareket(ler)den biri.
  const golden = <String, List<String>>{
    'bench': ['Barbell Bench Press'],
    'bench press': ['Barbell Bench Press'],
    'squat': ['Barbell Back Squat'],
    'deadlift': ['Conventional Deadlift'],
    'lat': ['Lat Pulldown'],
    'pulldown': ['Lat Pulldown'],
    'curl': ['Dumbbell Bicep Curl', 'Barbell Curl', 'Hammer Curl'],
    'şınav': ['Push-Up'],
    'sinav': ['Push-Up'],
    'barfiks': ['Pull-Up'],
    'mekik': ['Crunch'],
    'yan açış': ['Dumbbell Lateral Raise'],
    'ölü kaldırma': ['Conventional Deadlift'],
    'omuz pres': ['Overhead Press', 'Dumbbell Shoulder Press'],
    'göğüs pres': ['Barbell Bench Press', 'Chest Press Machine'],
    'bacak pres': ['Leg Press'],
    'pullup': ['Pull-Up'],
    'pull up': ['Pull-Up'],
    'pushup': ['Push-Up'],
    'lat çekiş': ['Lat Pulldown'],
    'kürek': ['Seated Cable Row', 'Bent-Over Barbell Row', 'Dumbbell Row'],
    'kalça itiş': ['Hip Thrust'],
    'hip thrust': ['Hip Thrust'],
    'baldır': ['Standing Calf Raise'],
    'koşu bandı': ['Treadmill Running', 'Treadmill Walking'],
    'plank': ['Plank'],
    'leg curl': ['Lying Leg Curl', 'Seated Leg Curl'],
    'triceps itiş': ['Tricep Pushdown'],
    'dips': ['Parallel Bar Dips'],
    'face pull': ['Face Pull'],
    'bacak uzatma': ['Leg Extension'],
    'shoulder press': ['Dumbbell Shoulder Press', 'Machine Shoulder Press'],
    'incline dumbbell': [
      'Incline Dumbbell Press',
      'Incline Dumbbell Fly',
      'Incline Dumbbell Curl',
    ],
    'pazı': ['Dumbbell Bicep Curl', 'Barbell Curl', 'Hammer Curl'],
  };

  group('altın liste — ilk 3', () {
    for (final entry in golden.entries) {
      test('"${entry.key}" → ${entry.value.join(' / ')}', () {
        final found = top(entry.key);
        expect(
          found.any(entry.value.contains),
          isTrue,
          reason: 'ilk 3: $found',
        );
      });
    }
  });

  group('gürültü', () {
    test('"lat" kelime içinde eşleşmez; ilk 3 lat çekiş', () {
      final r = results('lat');
      // "lat" yalnız kelime içinde geçiyor, sırt kası da yok → gelmez.
      for (final n in ['Plate Twist', 'Flat Bench Cable Flyes', 'Plate Pinch']) {
        expect(r.any((e) => e.name == n), isFalse, reason: n);
      }
      expect(r.length, lessThan(300), reason: 'eskiden 485 sonuç');
      for (final e in r.take(3)) {
        expect(e.name.toLowerCase(), contains('pulldown'), reason: e.name);
      }
    });

    test('"kol": ilk 5 sonuç pazı/arka kol/ön kol hareketi', () {
      final r = results('kol').take(5);
      for (final e in r) {
        expect(
          ['biceps', 'triceps', 'forearms'],
          contains(e.primaryMuscle),
          reason: '${e.name} (${e.primaryMuscle})',
        );
      }
    });

    test('"omuz": ilk 5 sonucun birincil kası omuz', () {
      for (final e in results('omuz').take(5)) {
        expect(e.primaryMuscle, 'shoulders', reason: e.name);
      }
    });

    test('çok kelimede hepsi eşleşmeli (VE)', () {
      expect(results('şınav deadlift'), isEmpty);
      // İkisi de geçiyorsa gelir: "Barbell Squat To A Bench".
      expect(top('bench squat'), contains('Barbell Squat To A Bench'));
    });

    test('"bacak": ilk 5 sonucun birincil kası bacak', () {
      for (final e in results('bacak').take(5)) {
        expect(
          ['legs', 'glutes', 'calves'],
          contains(e.primaryMuscle),
          reason: e.name,
        );
      }
    });

    test('boş sorgu → boş liste', () {
      expect(index.search('   '), isEmpty);
    });
  });

  group('kişisel geçmiş', () {
    test('yakın zamanda yapılan çeşit öne çıkar', () {
      final medium = catalog.firstWhere(
        (e) => e.name == 'Barbell Bench Press - Medium Grip',
      );
      final before = results('bench').indexWhere((e) => e.id == medium.id);
      final after = results(
        'bench',
        usage: {medium.id: 6},
      ).indexWhere((e) => e.id == medium.id);
      expect(after, lessThan(before));
      expect(after, lessThan(3));
    });
  });
}
