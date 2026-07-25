import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import 'exercises_seed.dart';

class SeedManager {
  final AppDatabase db;

  SeedManager(this.db);

  /// Seed/backfill içeriği değişince ARTIR (M-04). Sürüm eşleşiyorsa açılışta
  /// tablo taramaları + 1022 kayıtlık JSON parse tamamen atlanır (runApp'ten
  /// önce koştuğu için ilk kareyi geciktiriyordu).
  /// v2 (2026-07-25): küratörlü hareketlere form görseli backfill'i
  /// (`_backfillExerciseImages`, docs/11 §12) — artırılmazsa mevcut
  /// kurulumlarda hiç çalışmaz (M-04 dersi).
  static const seedVersion = 2;
  static const seedVersionKey = 'seed_version';

  Future<void> seedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(seedVersionKey) == seedVersion) return; // hızlı çıkış

    // Check if exercises already exist
    final existingExercises = await db.workoutDao.getAllExercises();
    if (existingExercises.isEmpty) {
      await _seedExercises();
      await _seedTurkishFoods();
      await db.userProfileDao.ensureProfile();
    } else {
      // V2 (docs/07-nutrition-v2.md): seed yalnız boş kurulumda çalışır;
      // mevcut DB'lerdeki hazır yemekler birim/porsiyon verisi almadan
      // kalırdı. Bu idempotent backfill, birimi NULL olan LOCAL yemekleri
      // JSON'dan ada göre doldurur. İlk çalıştırmadan sonra no-op
      // (custom/OpenFoodFacts yemeklere ve loglara dokunmaz).
      await _backfillFoodUnits();
      // Antrenman V2 (docs/09-workout-v2.md): mevcut kurulumlara yeni
      // İngilizce hareket kütüphanesini getir (eksikleri ekle + meta doldur).
      await _backfillExercises();
      // #1 duplike temizliği: free-exercise-db'den gelen, küratörlü hareketle
      // sadece kelime sırası/noktalama farkıyla aynı olan varyantları birleştir.
      await _dedupeExercises();
    }

    // Form görseli backfill'i HER İKİ yolda da çalışmalı: küratörlü seed
    // (`_seedExercises`) görselsiz kayıt yazdığı için sıfırdan kuran kullanıcı
    // da temel lift'leri görselsiz görürdü (docs/11 §12).
    await _backfillExerciseImages();

    await prefs.setInt(seedVersionKey, seedVersion);
  }

  /// Küratörlü seed ile free-exercise-db'nin aynı hareketi farklı yazdığı 7
  /// duplike (#1). Anahtar = silinecek extended varyant, değer = korunacak
  /// küratörlü ad. Referanslar korunana taşınıp varyant silinir (idempotent:
  /// varyant yoksa no-op). Yeni kurulumlarda zaten JSON'dan çıkarıldı.
  static const _duplicateVariants = <String, String>{
    'Bent Over Barbell Row': 'Bent-Over Barbell Row',
    'Front Cable Raise': 'Cable Front Raise',
    'Upright Barbell Row': 'Barbell Upright Row',
    'Upright Cable Row': 'Cable Upright Row',
    'Muscle Up': 'Muscle-Up',
    'Running, Treadmill': 'Treadmill Running',
    'Walking, Treadmill': 'Treadmill Walking',
  };

  Future<void> _dedupeExercises() async {
    final all = await db.workoutDao.getAllExercises();
    final byName = <String, Exercise>{};
    for (final e in all) {
      if (!e.isCustom) byName[e.name] = e; // özel hareketlere dokunma
    }
    for (final pair in _duplicateVariants.entries) {
      final dup = byName[pair.key];
      final keep = byName[pair.value];
      if (dup == null || keep == null || dup.id == keep.id) continue;
      try {
        await db.workoutDao.mergeExercise(fromId: dup.id, toId: keep.id);
      } catch (_) {
        // Nadir referans çakışması → bu varyantı atla, seed bozulmasın.
      }
    }
  }

  /// İngilizce hareket kütüphanesini mevcut DB'ye uyarlar (idempotent):
  /// - Adı seed'de olup DB'de OLMAYAN hareketleri ekler.
  /// - Var olan ama ekipmanı NULL olan (eski V1) hareketlere meta yazar
  ///   (ada göre eşleşirse). Custom hareketlere ve loglara dokunmaz.
  Future<void> _backfillExercises() async {
    final existing = await db.workoutDao.getAllExercises();
    final byName = {for (final e in existing) e.name: e};

    final toInsert = <ExercisesCompanion>[];
    for (final seed in exerciseSeedData) {
      final current = byName[seed.name];
      if (current == null) {
        toInsert.add(ExercisesCompanion(
          name: Value(seed.name),
          category: Value(seed.category),
          muscleGroups: Value(jsonEncode(seed.muscles)),
          primaryMuscle: Value(seed.primaryMuscle),
          equipment: Value(seed.equipment),
          measurementType: Value(seed.measurement),
          isCustom: const Value(false),
        ));
      } else if (current.equipment == null && !current.isCustom) {
        // Eski V1 hareketi → meta doldur (ekipman/kas/ölçüm tipi).
        await db.workoutDao.updateExerciseMeta(
          current.id,
          ExercisesCompanion(
            primaryMuscle: Value(seed.primaryMuscle),
            equipment: Value(seed.equipment),
            measurementType: Value(seed.measurement),
          ),
        );
      }
    }

    // İçerik zenginleştirme (docs/11): free-exercise-db genişletilmiş kütüphane.
    // Adı DB'de OLMAYANları ekler (mevcut/özel hareketlere dokunmaz).
    for (final ex in await _extendedExerciseCompanions()) {
      if (!byName.containsKey(ex.name.value)) toInsert.add(ex);
    }

    if (toInsert.isNotEmpty) {
      await db.workoutDao.insertExercises(toInsert);
    }
  }

  /// Küratörlü hareketlere form görseli bağlar (içerik turu 2, docs/11 §12).
  ///
  /// **Sorun:** D-2 birleştirme kuralı "ad eşleşmesinde mevcut kazanır" diyordu.
  /// Sonuç: Samet'in küratörlü çekirdek listesi (Squat, Deadlift, Bench…)
  /// korundu ama o satırlarda `imagePath` yok, ve isimler free-exercise-db'nin
  /// adlandırmasıyla tutmadığı için ("Barbell Back Squat" ≠ "Barbell Squat")
  /// zenginleştirme onlara hiç uğramadı. Yani **görseli olmayanlar tam da
  /// salonun en çok kullanılan hareketleriydi** — 1015 hareketin 814'ünde
  /// görsel varken temel lift'lerde yoktu.
  ///
  /// `_duplicateVariants` bunu ayrıca büyütmüştü: dedupe, free-exercise-db'den
  /// gelen **görselli** satırı silip küratörlü **görselsiz** satırı koruyordu.
  ///
  /// **Çözüm:** elle onaylanmış eşleme tablosu (`exercise_image_map.json`).
  /// Otomatik isim benzerliği bu iş için kullanılamaz — denendi ve
  /// "Barbell Back Squat → Barbell Hack Squat", "Bench Press → Guillotine
  /// Bench Press" gibi hatalar üretti. **Yanlış form görseli, görsel
  /// olmamasından daha kötüdür** (kullanıcı yanlış hareketi öğrenir), o yüzden
  /// emin olunmayan hareketler bilerek boş bırakıldı.
  ///
  /// İdempotent: yalnız `image_path` boş olan, özel olmayan satırlara yazar.
  Future<void> _backfillExerciseImages() async {
    final Map<String, dynamic> map = json.decode(
        await rootBundle.loadString('assets/data/exercise_image_map.json'));
    if (map.isEmpty) return;

    final all = await db.workoutDao.getAllExercises();
    for (final ex in all) {
      if (ex.isCustom) continue;
      if (ex.imagePath != null && ex.imagePath!.isNotEmpty) continue;
      final path = map[ex.name] as String?;
      if (path == null) continue;
      await db.workoutDao.updateExerciseMeta(
        ex.id,
        ExercisesCompanion(imagePath: Value(path)),
      );
    }
  }

  /// free-exercise-db'den türetilen genişletilmiş hareket kütüphanesini
  /// (public domain — docs/11) ExercisesCompanion listesine çevirir.
  /// Görsel/talimat/seviye/kuvvet meta dahil. Mevcut küratörlü seed'le
  /// çakışan adlar üretim aşamasında (import script) zaten çıkarılmıştır.
  Future<List<ExercisesCompanion>> _extendedExerciseCompanions() async {
    final jsonStr =
        await rootBundle.loadString('assets/data/exercises_extended.json');
    final List<dynamic> list = json.decode(jsonStr);
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final instr = (m['instructions'] as List?)?.cast<String>() ?? const [];
      return ExercisesCompanion(
        name: Value(m['name'] as String),
        category: Value(m['category'] as String),
        muscleGroups: Value(jsonEncode(m['muscles'] ?? const [])),
        primaryMuscle: Value(m['primaryMuscle'] as String?),
        equipment: Value(m['equipment'] as String?),
        measurementType: Value(m['measurement'] as String? ?? 'weight_reps'),
        instructions: Value(instr.isEmpty ? null : jsonEncode(instr)),
        level: Value(m['level'] as String?),
        force: Value(m['force'] as String?),
        imagePath: Value(m['imagePath'] as String?),
        isCustom: const Value(false),
      );
    }).toList();
  }

  Future<void> _backfillFoodUnits() async {
    final all = await db.nutritionDao.getAllFoods();
    final needs = all
        .where((f) =>
            f.source == 'local' && !f.isCustom && f.unitLabel == null)
        .toList();
    if (needs.isEmpty) return; // zaten dolu → ucuz çıkış

    final jsonStr =
        await rootBundle.loadString('assets/data/turkish_foods.json');
    final List<dynamic> foodList = json.decode(jsonStr);
    final byName = <String, Map<String, dynamic>>{
      for (final f in foodList) (f['name'] as String): f as Map<String, dynamic>
    };

    for (final food in needs) {
      final src = byName[food.name];
      final portion = src?['default_portion_g'];
      final unit = src?['unit_label'];
      if (portion == null || unit == null) continue;
      await db.nutritionDao.updateFood(
        food.id,
        FoodsCompanion(
          defaultPortionGrams: Value((portion as num).toDouble()),
          unitLabel: Value(unit as String),
        ),
      );
    }
  }

  Future<void> _seedExercises() async {
    // Küratörlü çekirdek (TR/MacFit makineleri dahil) + genişletilmiş
    // free-exercise-db kütüphanesi (docs/11). İkisi ad olarak çakışmaz.
    await db.workoutDao.insertExercises(exercisesSeed);
    await db.workoutDao.insertExercises(await _extendedExerciseCompanions());
  }

  Future<void> _seedTurkishFoods() async {
    final jsonStr = await rootBundle.loadString('assets/data/turkish_foods.json');
    final List<dynamic> foodList = json.decode(jsonStr);

    final foods = foodList.map((f) {
      // V2 birim alanları opsiyonel: JSON'da yoksa NULL (sadece gram).
      final portion = f['default_portion_g'];
      final unit = f['unit_label'];
      return FoodsCompanion(
        name: Value(f['name'] as String),
        kcalPer100g: Value((f['kcal_per_100g'] as num).toDouble()),
        proteinPer100g: Value((f['protein_per_100g'] as num).toDouble()),
        carbPer100g: Value((f['carb_per_100g'] as num).toDouble()),
        fatPer100g: Value((f['fat_per_100g'] as num).toDouble()),
        source: const Value('local'),
        isCustom: const Value(false),
        isRecipe: const Value(false),
        defaultPortionGrams:
            Value(portion == null ? null : (portion as num).toDouble()),
        unitLabel: Value(unit as String?),
      );
    }).toList();

    await db.nutritionDao.insertFoods(foods);
  }
}
