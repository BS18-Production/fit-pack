import '../../data/database/app_database.dart';

/// Önceki setin değerini sonrakine taşıma (G-2, Samet 2026-09-15).
///
/// **Veri doğruluğu kuralı:** alanlar kendiliğinden DOLDURULMAZ. Seans
/// kaydı, işaretlenmemiş ama değer girilmiş seti de yazar; otomatik doldurma
/// kullanıcının hiç onaylamadığı (geçen haftanın) değerleri kayda sokardı.
/// Bunun yerine öneri boş alanda soluk görünür, ✓'e basılınca boş alanlar
/// öneriyle dolar — tek dokunuş = kullanıcı onayı.

/// Bir setin ölçüm değerleri (DB birimleri: kg, sn, m). RPE bilinçli olarak
/// yok — algılanan zorluk her set için öznel, taşınmaz.
class SetValues {
  final double? weightKg;
  final int? reps;
  final int? durationSec;
  final double? distanceM;

  const SetValues({this.weightKg, this.reps, this.durationSec, this.distanceM});

  factory SetValues.fromSet(WorkoutSet s) => SetValues(
    weightKg: s.weightKg,
    reps: s.reps,
    durationSec: s.durationSec,
    distanceM: s.distanceM,
  );

  /// Ölçüm tipine göre anlamlı bir değer var mı (aktif seanstaki
  /// `hasInput` ile aynı tanım).
  bool hasAny(String measure) => switch (measure) {
    'reps' => reps != null,
    'time' => durationSec != null,
    'distance' => distanceM != null || durationSec != null,
    _ => weightKg != null || reps != null,
  };

  @override
  bool operator ==(Object other) =>
      other is SetValues &&
      other.weightKg == weightKg &&
      other.reps == reps &&
      other.durationSec == durationSec &&
      other.distanceM == distanceM;

  @override
  int get hashCode => Object.hash(weightKg, reps, durationSec, distanceM);

  @override
  String toString() =>
      'SetValues(kg: $weightKg, reps: $reps, sec: $durationSec, m: $distanceM)';
}

/// Bu seanstaki bir set: değerleri + ısınma seti mi.
typedef CurrentSet = ({SetValues values, bool warmup});

/// [index]'teki set için öneri.
///
/// **Kural (sade — Samet 2026-09-30):** öneri bu seansta YUKARIDAKİ en yakın
/// dolu settir. 1. set 55×10 yapıldıysa 2. ve 3. sete 55×10 önerilir;
/// kilo artırılacaksa kullanıcı yazar (ya da ± adım düğmesini kullanır).
/// Isınma seti çalışma setine referans olmaz — hafif kilo taşınmasın; hedef
/// set de ısınmaysa olur.
///
/// Yukarıda dolu set yoksa (ilk set, ya da yalnız ısınma yapılmış) geçen
/// seansın aynı numaralı seti; o da yoksa öneri yok.
///
/// *Eski kural (G-2, 2026-09-15):* 1. set geçen seansla aynıysa 2. sete
/// geçen seansın 2. seti öneriliyordu (piramit için). Salonda anlaşılmadı —
/// bugün 55 yapılmışken başka kilo önerilmesi kafa karıştırıyordu.
SetValues? suggestionFor({
  required int index,
  required List<CurrentSet> current,
  required List<SetValues> lastSession,
  required String measure,
}) {
  final targetWarmup = current[index].warmup;
  for (var j = index - 1; j >= 0; j--) {
    final above = current[j];
    if (above.warmup && !targetWarmup) continue;
    if (!above.values.hasAny(measure)) continue;
    // Üstteki set yarım olabilir (ör. ± ile yalnız kilo yazıldı): eksik
    // alanları kendi önerisinden tamamlanır — ✓'e basılınca kaydedeceği
    // değerin aynısı. Yoksa 3. sete "57,5 × —" önerilirdi.
    final aboveSuggestion = suggestionFor(
      index: j,
      current: current,
      lastSession: lastSession,
      measure: measure,
    );
    return aboveSuggestion == null
        ? above.values
        : fillMissing(above.values, aboveSuggestion, measure);
  }
  return index < lastSession.length && lastSession[index].hasAny(measure)
      ? lastSession[index]
      : null;
}

/// ✓'e basılınca: [entered] içinde BOŞ olan alanları [suggestion]'dan
/// doldurur (ölçüm tipinin alanlarıyla sınırlı). Kullanıcının yazdığı değerin
/// üstüne asla yazmaz.
SetValues fillMissing(SetValues entered, SetValues suggestion, String measure) {
  switch (measure) {
    case 'reps':
      return SetValues(
        weightKg: entered.weightKg,
        reps: entered.reps ?? suggestion.reps,
        durationSec: entered.durationSec,
        distanceM: entered.distanceM,
      );
    case 'time':
      return SetValues(
        weightKg: entered.weightKg,
        reps: entered.reps,
        durationSec: entered.durationSec ?? suggestion.durationSec,
        distanceM: entered.distanceM,
      );
    case 'distance':
      return SetValues(
        weightKg: entered.weightKg,
        reps: entered.reps,
        durationSec: entered.durationSec ?? suggestion.durationSec,
        distanceM: entered.distanceM ?? suggestion.distanceM,
      );
    default:
      return SetValues(
        weightKg: entered.weightKg ?? suggestion.weightKg,
        reps: entered.reps ?? suggestion.reps,
        durationSec: entered.durationSec,
        distanceM: entered.distanceM,
      );
  }
}
