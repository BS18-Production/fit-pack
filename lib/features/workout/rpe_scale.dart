/// RPE (Rate of Perceived Exertion — Algılanan Zorluk) ölçeği: seçici
/// panelinin saf mantığı (docs/27 F4). Widget'sız, test edilebilir.
///
/// Ölçek RIR (Reps in Reserve — yedekte kalan tekrar) karşılığıdır:
/// RPE 10 = hiç tekrar kalmadı, RPE 8 = 2 tekrar kaldı. 6'nın altı kuvvet
/// antrenmanında ayırt edilemediği için seçicide yalnız 6–10 yarım adımlar
/// var; eski kayıtlardaki 6 altı değerler aynen korunur ve gösterilir.
library;

/// Seçicide sunulan değerler (soldan sağa).
const rpeChoices = <double>[6, 7, 7.5, 8, 8.5, 9, 9.5, 10];

/// Efor bandı — etiket metni l10n'dan bu banda göre seçilir.
enum RpeEffort { light, moderate, vigorous, veryHard, extremelyHard, max }

RpeEffort rpeEffort(double rpe) {
  if (rpe >= 10) return RpeEffort.max;
  if (rpe >= 9) return RpeEffort.extremelyHard;
  if (rpe >= 8) return RpeEffort.veryHard;
  if (rpe >= 7) return RpeEffort.vigorous;
  if (rpe >= 6) return RpeEffort.moderate;
  return RpeEffort.light;
}

/// Yedekte kalan tekrar aralığı. `max == null` → "en az [min]" (RPE 6 ve
/// altı: 4+ tekrar). Tam sayı RPE'de min == max; yarım adımda iki komşu
/// tam sayı (RPE 8,5 → 1–2 tekrar).
({int min, int? max}) repsInReserve(double rpe) {
  final rir = 10 - rpe.clamp(0, 10);
  if (rir >= 4) return (min: 4, max: null);
  return (min: rir.floor(), max: rir.ceil());
}

/// Hücrede/panelde gösterim: 8 → "8", 7.5 → "7.5" (ondalık ayırıcı
/// [decimalSep] ile — Türkçe ","), gereksiz ".0" yok.
String formatRpe(double rpe, {String decimalSep = '.'}) {
  final s = rpe == rpe.roundToDouble()
      ? rpe.round().toString()
      : rpe.toStringAsFixed(1);
  return s.replaceAll('.', decimalSep);
}
