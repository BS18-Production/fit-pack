/// **Hazır program kataloğu** (docs/28 F1) — uygulamayla gelen, salt okunur
/// veri. Kullanıcı "Programı ekle" deyince rutinler kendi rutinlerine
/// kopyalanır (`routines.program_key` ile); sonra istediği gibi düzenler.
///
/// İçerik yaygın, kamuya açık yapılardan (tüm vücut, üst/alt, itme/çekme/
/// bacak) uyarlanmıştır; set/tekrar şemaları telifli değildir, metinler
/// bizimdir. Yalnız salon ekipmanı (Samet'in kararı, 2026-10-08). Hareket adları
/// seed'deki adlarla birebir — `program_catalog_test` bekçisi.
///
/// Ad/açıklama metinleri l10n'da (`program_labels.dart`), burada yalnız yapı.
library;

enum ProgramLevel { beginner, intermediate, advanced }

enum ProgramSplit { fullBody, upperLower, ppl }

/// Kopyalanan rutinin adı (l10n anahtarı buna göre seçilir).
enum CatalogRoutineName {
  fullBodyA,
  fullBodyB,
  fullBodyC,
  upper,
  lower,
  upperA,
  lowerA,
  upperB,
  lowerB,
  upperPower,
  lowerPower,
  upperHypertrophy,
  lowerHypertrophy,
  push,
  pull,
  legs,
}

class CatalogExercise {
  /// Seed hareket adı (İngilizce, salon standardı).
  final String name;
  final int sets;
  final int repsMin;
  final int repsMax;

  /// Dinlenme (sn); null = hareket kategorisinin varsayılanı.
  final int? restSec;

  const CatalogExercise(this.name, this.sets, this.repsMin, this.repsMax,
      [this.restSec]);
}

class CatalogRoutine {
  final CatalogRoutineName name;
  final List<CatalogExercise> exercises;
  const CatalogRoutine(this.name, this.exercises);
}

class CatalogProgram {
  /// Kalıcı anahtar — `routines.program_key`'e yazılır, DEĞİŞTİRİLMEZ.
  final String key;
  final ProgramLevel level;
  final ProgramSplit split;
  final int daysPerWeek;
  final List<CatalogRoutine> routines;

  const CatalogProgram({
    required this.key,
    required this.level,
    required this.split,
    required this.daysPerWeek,
    required this.routines,
  });

  int get exerciseCount =>
      routines.fold(0, (n, r) => n + r.exercises.length);
}

// Dinlenme süreleri: ağır temel hareket / orta / yardımcı.
const _heavy = 180, _main = 120, _acc = 90;

typedef _E = CatalogExercise;
typedef _R = CatalogRoutine;
typedef _N = CatalogRoutineName;

const programCatalog = <CatalogProgram>[
  // ═════════════════════════════ TÜM VÜCUT ═════════════════════════════
  CatalogProgram(
    key: 'fullbody_beginner',
    level: ProgramLevel.beginner,
    split: ProgramSplit.fullBody,
    daysPerWeek: 3,
    routines: [
      _R(_N.fullBodyA, [
        _E('Leg Press', 3, 10, 12, _main),
        _E('Chest Press Machine', 3, 10, 12, _main),
        _E('Lat Pulldown', 3, 10, 12, _main),
        _E('Machine Shoulder Press', 2, 10, 12),
        _E('Seated Leg Curl', 2, 10, 12),
        _E('Ab Crunch Machine', 2, 12, 15),
      ]),
      _R(_N.fullBodyB, [
        _E('Goblet Squat', 3, 10, 12, _main),
        _E('Dumbbell Bench Press', 3, 8, 12, _main),
        _E('Seated Cable Row', 3, 10, 12, _main),
        _E('Dumbbell Lateral Raise', 2, 12, 15),
        _E('Leg Extension', 2, 12, 15),
        _E('Cable Crunch', 2, 12, 15),
      ]),
    ],
  ),
  CatalogProgram(
    key: 'fullbody_intermediate',
    level: ProgramLevel.intermediate,
    split: ProgramSplit.fullBody,
    daysPerWeek: 3,
    routines: [
      _R(_N.fullBodyA, [
        _E('Barbell Back Squat', 4, 6, 8, _heavy),
        _E('Barbell Bench Press', 4, 6, 8, _heavy),
        _E('Bent-Over Barbell Row', 3, 8, 10, _main),
        _E('Dumbbell Lateral Raise', 3, 12, 15),
        _E('Hammer Curl', 2, 10, 12),
      ]),
      _R(_N.fullBodyB, [
        _E('Romanian Deadlift', 3, 8, 10, _heavy),
        _E('Overhead Press', 3, 6, 8, _main),
        _E('Lat Pulldown', 3, 8, 12, _main),
        _E('Incline Dumbbell Press', 3, 8, 12, _main),
        _E('Rope Tricep Pushdown', 2, 10, 12),
      ]),
      _R(_N.fullBodyC, [
        _E('Leg Press', 3, 10, 12, _main),
        _E('Dumbbell Bench Press', 3, 8, 12, _main),
        _E('Chest-Supported Dumbbell Row', 3, 8, 12, _main),
        _E('Lying Leg Curl', 3, 10, 12),
        _E('Face Pull', 3, 12, 15),
        _E('Cable Crunch', 3, 12, 15),
      ]),
    ],
  ),
  CatalogProgram(
    key: 'fullbody_advanced',
    level: ProgramLevel.advanced,
    split: ProgramSplit.fullBody,
    daysPerWeek: 3,
    routines: [
      _R(_N.fullBodyA, [
        _E('Barbell Back Squat', 5, 3, 5, _heavy),
        _E('Barbell Bench Press', 5, 3, 5, _heavy),
        _E('Pendlay Row', 4, 5, 8, _main),
        _E('Skull Crushers', 3, 8, 10),
        _E('Hanging Leg Raise', 3, 10, 15),
      ]),
      _R(_N.fullBodyB, [
        _E('Conventional Deadlift', 4, 3, 5, _heavy),
        _E('Overhead Press', 4, 5, 8, _main),
        _E('Pull-Up', 4, 6, 10, _main),
        _E('Bulgarian Split Squat', 3, 8, 10, _acc),
        _E('Barbell Curl', 3, 8, 10),
      ]),
      _R(_N.fullBodyC, [
        _E('Front Squat', 4, 5, 8, _heavy),
        _E('Incline Barbell Bench Press', 4, 6, 8, _main),
        _E('Seated Cable Row', 4, 8, 10, _main),
        _E('Hip Thrust', 3, 8, 10, _acc),
        _E('Cable Lateral Raise', 3, 12, 15),
      ]),
    ],
  ),

  // ═════════════════════════════ ÜST / ALT ═════════════════════════════
  CatalogProgram(
    key: 'upperlower_beginner',
    level: ProgramLevel.beginner,
    split: ProgramSplit.upperLower,
    daysPerWeek: 4,
    routines: [
      _R(_N.upper, [
        _E('Chest Press Machine', 3, 8, 12, _main),
        _E('Seated Machine Row', 3, 8, 12, _main),
        _E('Machine Shoulder Press', 3, 8, 12),
        _E('Lat Pulldown', 3, 8, 12),
        _E('Cable Curl', 2, 10, 12),
        _E('Tricep Pushdown', 2, 10, 12),
      ]),
      _R(_N.lower, [
        _E('Leg Press', 3, 10, 12, _main),
        _E('Seated Leg Curl', 3, 10, 12),
        _E('Leg Extension', 3, 10, 15),
        _E('Standing Calf Raise', 3, 12, 15),
        _E('Ab Crunch Machine', 3, 12, 15),
      ]),
    ],
  ),
  CatalogProgram(
    key: 'upperlower_intermediate',
    level: ProgramLevel.intermediate,
    split: ProgramSplit.upperLower,
    daysPerWeek: 4,
    routines: [
      _R(_N.upperA, [
        _E('Barbell Bench Press', 4, 6, 8, _heavy),
        _E('Bent-Over Barbell Row', 4, 6, 8, _heavy),
        _E('Dumbbell Shoulder Press', 3, 8, 10, _main),
        _E('Lat Pulldown', 3, 8, 12),
        _E('EZ-Bar Curl', 3, 8, 12),
        _E('Overhead Tricep Extension', 3, 10, 12),
      ]),
      _R(_N.lowerA, [
        _E('Barbell Back Squat', 4, 6, 8, _heavy),
        _E('Romanian Deadlift', 3, 8, 10, _main),
        _E('Leg Press', 3, 10, 12, _main),
        _E('Seated Leg Curl', 3, 10, 12),
        _E('Standing Calf Raise', 4, 10, 15),
      ]),
      _R(_N.upperB, [
        _E('Incline Dumbbell Press', 4, 8, 10, _main),
        _E('Pull-Up', 4, 6, 10, _main),
        _E('Seated Cable Row', 3, 10, 12),
        _E('Dumbbell Lateral Raise', 3, 12, 15),
        _E('Hammer Curl', 3, 10, 12),
        _E('Rope Tricep Pushdown', 3, 10, 12),
      ]),
      _R(_N.lowerB, [
        _E('Conventional Deadlift', 3, 4, 6, _heavy),
        _E('Bulgarian Split Squat', 3, 8, 10, _acc),
        _E('Leg Extension', 3, 12, 15),
        _E('Lying Leg Curl', 3, 10, 12),
        _E('Seated Calf Raise', 3, 12, 15),
        _E('Hanging Leg Raise', 3, 10, 15),
      ]),
    ],
  ),
  CatalogProgram(
    key: 'upperlower_advanced',
    level: ProgramLevel.advanced,
    split: ProgramSplit.upperLower,
    daysPerWeek: 4,
    routines: [
      _R(_N.upperPower, [
        _E('Barbell Bench Press', 5, 3, 5, _heavy),
        _E('Pendlay Row', 5, 3, 5, _heavy),
        _E('Overhead Press', 3, 5, 8, _main),
        _E('Pull-Up', 3, 5, 8, _main),
        _E('Close-Grip Bench Press', 3, 6, 8, _main),
      ]),
      _R(_N.lowerPower, [
        _E('Barbell Back Squat', 5, 3, 5, _heavy),
        _E('Romanian Deadlift', 4, 5, 8, _heavy),
        _E('Leg Press', 3, 8, 10, _main),
        _E('Lying Leg Curl', 3, 8, 10),
        _E('Standing Calf Raise', 4, 8, 12),
      ]),
      _R(_N.upperHypertrophy, [
        _E('Incline Dumbbell Press', 4, 8, 12, _main),
        _E('Chest-Supported Machine Row', 4, 8, 12, _main),
        _E('Cable Lateral Raise', 4, 12, 15),
        _E('Lat Pulldown', 3, 10, 12),
        _E('Incline Dumbbell Curl', 3, 10, 12),
        _E('Overhead Tricep Extension', 3, 10, 12),
        _E('Face Pull', 3, 12, 15),
      ]),
      _R(_N.lowerHypertrophy, [
        _E('Hack Squat', 4, 8, 12, _main),
        _E('Hip Thrust', 4, 8, 12, _main),
        _E('Walking Lunge', 3, 10, 12, _acc),
        _E('Seated Leg Curl', 3, 10, 15),
        _E('Leg Extension', 3, 12, 15),
        _E('Seated Calf Raise', 4, 12, 15),
      ]),
    ],
  ),

  // ═══════════════════════ İTME / ÇEKME / BACAK ═══════════════════════
  CatalogProgram(
    key: 'ppl_beginner',
    level: ProgramLevel.beginner,
    split: ProgramSplit.ppl,
    daysPerWeek: 3,
    routines: [
      _R(_N.push, [
        _E('Chest Press Machine', 3, 8, 12, _main),
        _E('Machine Shoulder Press', 3, 8, 12),
        _E('Incline Dumbbell Press', 2, 10, 12),
        _E('Dumbbell Lateral Raise', 2, 12, 15),
        _E('Tricep Pushdown', 2, 10, 12),
      ]),
      _R(_N.pull, [
        _E('Lat Pulldown', 3, 8, 12, _main),
        _E('Seated Cable Row', 3, 8, 12),
        _E('Face Pull', 2, 12, 15),
        _E('Dumbbell Bicep Curl', 2, 10, 12),
        _E('Hammer Curl', 2, 10, 12),
      ]),
      _R(_N.legs, [
        _E('Leg Press', 3, 10, 12, _main),
        _E('Goblet Squat', 2, 10, 12),
        _E('Seated Leg Curl', 3, 10, 12),
        _E('Leg Extension', 2, 12, 15),
        _E('Standing Calf Raise', 3, 12, 15),
      ]),
    ],
  ),
  CatalogProgram(
    key: 'ppl_intermediate',
    level: ProgramLevel.intermediate,
    split: ProgramSplit.ppl,
    daysPerWeek: 6,
    routines: [
      _R(_N.push, [
        _E('Barbell Bench Press', 4, 6, 8, _heavy),
        _E('Overhead Press', 3, 6, 8, _main),
        _E('Incline Dumbbell Press', 3, 8, 12, _main),
        _E('Cable Lateral Raise', 3, 12, 15),
        _E('Rope Tricep Pushdown', 3, 10, 12),
        _E('Overhead Tricep Extension', 2, 10, 12),
      ]),
      _R(_N.pull, [
        _E('Bent-Over Barbell Row', 4, 6, 8, _heavy),
        _E('Lat Pulldown', 3, 8, 12, _main),
        _E('Seated Cable Row', 3, 10, 12),
        _E('Face Pull', 3, 12, 15),
        _E('EZ-Bar Curl', 3, 8, 12),
        _E('Hammer Curl', 2, 10, 12),
      ]),
      _R(_N.legs, [
        _E('Barbell Back Squat', 4, 6, 8, _heavy),
        _E('Romanian Deadlift', 3, 8, 10, _main),
        _E('Leg Press', 3, 10, 12, _main),
        _E('Lying Leg Curl', 3, 10, 12),
        _E('Standing Calf Raise', 4, 10, 15),
      ]),
    ],
  ),
  CatalogProgram(
    key: 'ppl_advanced',
    level: ProgramLevel.advanced,
    split: ProgramSplit.ppl,
    daysPerWeek: 6,
    routines: [
      _R(_N.push, [
        _E('Barbell Bench Press', 5, 4, 6, _heavy),
        _E('Incline Dumbbell Press', 4, 8, 10, _main),
        _E('Dumbbell Shoulder Press', 3, 8, 10, _main),
        _E('Cable Crossover', 3, 12, 15),
        _E('Cable Lateral Raise', 4, 12, 15),
        _E('Skull Crushers', 3, 8, 10),
        _E('Rope Tricep Pushdown', 3, 12, 15),
      ]),
      _R(_N.pull, [
        _E('Conventional Deadlift', 3, 3, 5, _heavy),
        _E('Pull-Up', 4, 6, 10, _main),
        _E('Chest-Supported Machine Row', 4, 8, 10, _main),
        _E('Straight-Arm Pulldown', 3, 12, 15),
        _E('Reverse Pec Deck', 3, 12, 15),
        _E('Barbell Curl', 3, 8, 10),
        _E('Incline Dumbbell Curl', 3, 10, 12),
      ]),
      _R(_N.legs, [
        _E('Barbell Back Squat', 5, 4, 6, _heavy),
        _E('Romanian Deadlift', 4, 6, 8, _heavy),
        _E('Hack Squat', 3, 8, 12, _main),
        _E('Seated Leg Curl', 4, 10, 12),
        _E('Leg Extension', 3, 12, 15),
        _E('Standing Calf Raise', 5, 8, 12),
        _E('Hanging Leg Raise', 3, 10, 15),
      ]),
    ],
  ),
];

/// Anahtardan program (silinmiş/eski anahtar → null).
CatalogProgram? programByKey(String? key) {
  for (final p in programCatalog) {
    if (p.key == key) return p;
  }
  return null;
}
