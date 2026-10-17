/// Kurulumda program önerisi (docs/49 §1) — iki cevaptan katalogdaki 9
/// programdan biri. Saf fonksiyon; metinler l10n'da.
library;

/// "Ne kadar süredir antrenman yapıyorsun?"
enum TrainingExperience { beginner, some, long }

/// "Haftada kaç gün?"
enum WeeklyDays { twoThree, four, fiveSix }

/// docs/49 §1 tablosu. Yeni başlayan 5–6 gün istese de 4 günlük alt-üst
/// önerilir — başlangıçta dinlenme günü gelişimi hızlandırır
/// ([restDayNote]). 3 günlük itiş-çekiş-bacak başlangıç programı tabloda
/// yok; Keşfet'ten seçilebilir.
String recommendProgram(TrainingExperience exp, WeeklyDays days) =>
    switch ((exp, days)) {
      (TrainingExperience.beginner, WeeklyDays.twoThree) => 'fullbody_beginner',
      (TrainingExperience.beginner, _) => 'upperlower_beginner',
      (TrainingExperience.some, WeeklyDays.twoThree) => 'fullbody_intermediate',
      (TrainingExperience.some, WeeklyDays.four) => 'upperlower_intermediate',
      (TrainingExperience.some, WeeklyDays.fiveSix) => 'ppl_intermediate',
      (TrainingExperience.long, WeeklyDays.twoThree) => 'fullbody_advanced',
      (TrainingExperience.long, WeeklyDays.four) => 'upperlower_advanced',
      (TrainingExperience.long, WeeklyDays.fiveSix) => 'ppl_advanced',
    };

/// Öneri kartında "neden daha az gün" notu gösterilsin mi.
bool restDayNote(TrainingExperience exp, WeeklyDays days) =>
    exp == TrainingExperience.beginner && days == WeeklyDays.fiveSix;
