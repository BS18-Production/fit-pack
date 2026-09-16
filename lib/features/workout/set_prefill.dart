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
/// Bu seansta YUKARIDAKİ en yakın dolu set referans alınır (ısınma seti
/// çalışma setine referans olmaz — hafif kilo taşınmasın; hedef set de
/// ısınmaysa olur):
/// 1. Referans set geçen seansın aynı numaralı setiyle AYNIYSA kullanıcı geçen
///    seansı takip ediyordur → geçen seansın bu numaralı seti önerilir
///    (piramit 100→120→140 bozulmaz; öneri "ÖNCEKİ" sütunuyla aynı kalır).
///    Geçen seansta bu numara yoksa referans set taşınır.
/// 2. Referans set farklıysa (bugün kilo artırıldı) o değer sonraki setlere
///    taşınır — Samet'in asıl isteği: "önceki setin değeri sonrakine".
/// 3. Yukarıda dolu set yoksa geçen seansın aynı numaralı seti; o da yoksa
///    öneri yok.
SetValues? suggestionFor({
  required int index,
  required List<CurrentSet> current,
  required List<SetValues> lastSession,
  required String measure,
}) {
  SetValues? last(int i) =>
      i < lastSession.length && lastSession[i].hasAny(measure)
      ? lastSession[i]
      : null;

  final targetWarmup = current[index].warmup;
  for (var j = index - 1; j >= 0; j--) {
    final above = current[j];
    if (above.warmup && !targetWarmup) continue;
    if (!above.values.hasAny(measure)) continue;
    final following = _sameMeasure(above.values, last(j), measure);
    return following ? (last(index) ?? above.values) : above.values;
  }
  return last(index);
}

/// İki setin ölçüm tipindeki alanları aynı mı (RPE vb. dikkate alınmaz).
bool _sameMeasure(SetValues a, SetValues? b, String measure) {
  if (b == null) return false;
  return switch (measure) {
    'reps' => a.reps == b.reps,
    'time' => a.durationSec == b.durationSec,
    'distance' => a.distanceM == b.distanceM && a.durationSec == b.durationSec,
    _ => a.weightKg == b.weightKg && a.reps == b.reps,
  };
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
