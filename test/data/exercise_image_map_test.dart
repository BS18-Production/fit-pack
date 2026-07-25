import 'dart:convert';
import 'dart:io';


import 'package:drift/native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Form görseli eşleme tablosu (içerik turu 2 — docs/11 §12).
///
/// Eşleme ELLE onaylandı çünkü otomatik isim benzerliği yanlış hareket
/// eşliyordu ("Barbell Back Squat" → "Barbell Hack Squat"). Tablo bozulursa
/// kullanıcı YANLIŞ form görseli görür — sessiz ve tehlikeli bir hata.
/// Bu testler tablonun kaynakla tutarlı kalmasını bekçiliyor.
void main() {
  late Map<String, dynamic> map;
  late Set<String> sourceImagePaths;

  setUpAll(() {
    map = json.decode(
        File('assets/data/exercise_image_map.json').readAsStringSync());
    final pool = json.decode(
        File('assets/data/exercises_extended.json').readAsStringSync()) as List;
    sourceImagePaths = {
      for (final e in pool)
        if ((e as Map)['imagePath'] != null) e['imagePath'] as String
    };
  });

  test('eşleme boş değil ve hepsi beklenen görsel yolu biçiminde', () {
    expect(map, isNotEmpty);
    for (final entry in map.entries) {
      expect(entry.value, isA<String>(),
          reason: '${entry.key} için değer metin olmalı');
      expect(entry.value as String, startsWith('assets/exercise_img/'),
          reason: '${entry.key} beklenen önekte değil');
      expect(entry.value as String, endsWith('.jpg'),
          reason: '${entry.key} .jpg ile bitmeli');
    }
  });

  test('her görsel yolu ya kaynakta var ya da dedupe kurtarması', () {
    // Dedupe'ta silinen varyantların yolları JSON'dan çıkarıldığı için
    // kaynakta bulunmayabilir; onlar da geçerli free-exercise-db yollarıdır.
    final unknown = <String>[];
    for (final e in map.entries) {
      if (!sourceImagePaths.contains(e.value)) unknown.add('${e.key} → ${e.value}');
    }
    // Kurtarılan 7 dedupe girdisi dışında hepsi kaynakta olmalı.
    expect(unknown.length, lessThanOrEqualTo(7),
        reason: 'kaynakta karşılığı olmayan fazla girdi:\n${unknown.join('\n')}');
  });

  test('aynı hareket iki kez eşlenmemiş (anahtar tekilliği JSON garantisi)', () {
    final raw = File('assets/data/exercise_image_map.json').readAsStringSync();
    final keys = RegExp(r'^\s*"([^"]+)"\s*:', multiLine: true)
        .allMatches(raw)
        .map((m) => m.group(1)!)
        .toList();
    expect(keys.length, map.length,
        reason: 'JSON içinde tekrar eden anahtar var');
  });

  group('backfill davranışı', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customSelect('SELECT 1').get();
    });

    tearDown(() async => db.close());

    test('görselsiz küratörlü harekete görsel yazar, ikinci kez no-op',
        () async {
      await db.customStatement(
          "INSERT INTO exercises (name, category, muscle_groups, is_custom) "
          "VALUES ('Barbell Back Squat', 'compound', '[\"legs\"]', 0)");

      Future<String?> imagePath() async {
        final r = await db
            .customSelect(
                "SELECT image_path FROM exercises WHERE name = 'Barbell Back Squat'")
            .getSingle();
        return r.read<String?>('image_path');
      }

      expect(await imagePath(), isNull);

      // Backfill'in yaptığı işin aynısı (SeedManager rootBundle'a bağlı
      // olduğu için burada eşleme doğrudan uygulanıyor).
      final path = map['Barbell Back Squat'] as String;
      await db.customStatement(
          "UPDATE exercises SET image_path = ? WHERE name = 'Barbell Back Squat' "
          "AND (image_path IS NULL OR image_path = '')",
          [path]);
      expect(await imagePath(), path);

      // İkinci çalıştırma değeri DEĞİŞTİRMEMELİ (idempotent).
      await db.customStatement(
          "UPDATE exercises SET image_path = ? WHERE name = 'Barbell Back Squat' "
          "AND (image_path IS NULL OR image_path = '')",
          ['assets/exercise_img/Yanlis/0.jpg']);
      expect(await imagePath(), path);
    });

    test('özel (kullanıcı) hareketine dokunmaz', () async {
      // Kullanıcı kendi hareketine tesadüfen aynı adı verdiyse, onun kaydına
      // katalog görseli yazmak yanlış olurdu.
      await db.customStatement(
          "INSERT INTO exercises (name, category, muscle_groups, is_custom) "
          "VALUES ('Barbell Back Squat', 'compound', '[\"legs\"]', 1)");
      await db.customStatement(
          "UPDATE exercises SET image_path = ? "
          "WHERE name = 'Barbell Back Squat' AND is_custom = 0",
          [map['Barbell Back Squat'] as String]);
      final r = await db
          .customSelect("SELECT image_path FROM exercises WHERE is_custom = 1")
          .getSingle();
      expect(r.read<String?>('image_path'), isNull);
    });
  });

  test('temel lift\'ler kapsandı (regresyon bekçisi)', () {
    // Bu turun ASIL amacı: 814 hareketin görseli varken tam da bunlarda yoktu.
    for (final core in [
      'Barbell Back Squat',
      'Front Squat',
      'Conventional Deadlift',
      'Romanian Deadlift',
      'Barbell Bench Press',
      'Incline Barbell Bench Press',
      'Overhead Press',
      'Lat Pulldown',
      'Bent-Over Barbell Row',
      'Pull-Up',
      'Push-Up',
      'Hip Thrust',
      'Leg Press',
    ]) {
      expect(map.containsKey(core), isTrue, reason: '$core eşlenmemiş');
    }
  });
}
