import 'dart:convert';
import 'dart:io';

import 'package:fit_pack/data/seed/exercises_seed.dart';
import 'package:flutter_test/flutter_test.dart';

/// İçerik zenginleştirme (docs/11) — genişletilmiş hareket kütüphanesi
/// (free-exercise-db) bütünlük testleri. Asset JSON'u doğrudan diskten okur.
void main() {
  final raw = File('assets/data/exercises_extended.json').readAsStringSync();
  final List<dynamic> data = json.decode(raw);
  final items = data.cast<Map<String, dynamic>>();

  const validCategories = {
    'compound', 'isolation', 'calisthenics', 'cardio', 'flexibility'
  };
  const validMeasures = {'weight_reps', 'reps', 'time', 'distance'};

  test('makul boyutta zengin kütüphane (≥ 500 ek hareket)', () {
    expect(items.length, greaterThanOrEqualTo(500));
  });

  test('her hareketin geçerli kategori + ölçüm tipi var', () {
    for (final e in items) {
      expect(validCategories, contains(e['category']),
          reason: '${e['name']} kategori: ${e['category']}');
      expect(validMeasures, contains(e['measurement']),
          reason: '${e['name']} ölçüm: ${e['measurement']}');
    }
  });

  test('isim boş değil ve kendi içinde tekrar yok', () {
    final names = items.map((e) => e['name'] as String).toList();
    for (final n in names) {
      expect(n.trim(), isNotEmpty);
    }
    expect(names.toSet().length, names.length, reason: 'isim tekrarı var');
  });

  test('küratörlü seed ile ad çakışması YOK (merge: mevcut kazanır)', () {
    final curated = exerciseSeedData.map((e) => e.name).toSet();
    final extended = items.map((e) => e['name'] as String).toSet();
    expect(curated.intersection(extended), isEmpty);
  });

  test('hareketlerin çoğunda talimat + görsel yolu var', () {
    final withInstr =
        items.where((e) => (e['instructions'] as List).isNotEmpty).length;
    final withImg = items.where((e) => e['imagePath'] != null).length;
    expect(withInstr, greaterThan(items.length ~/ 2));
    expect(withImg, greaterThan(items.length ~/ 2));
  });

  test('görsel yolu assets/exercise_img/ altında', () {
    for (final e in items.where((e) => e['imagePath'] != null)) {
      expect(e['imagePath'] as String, startsWith('assets/exercise_img/'));
    }
  });
}
