import 'set_prefill.dart';

/// Antrenmanda bir sonraki hedef (docs/21 §2 #3) — **çift ilerleme**
/// (double progression): aynı kiloda tekrar aralığının üstüne çık, sonra
/// kiloyu artır ve aralığın altından yeniden başla.
///
/// **Samet'in kuralı (2026-09-17):** kilo artışı kendiliğinden uygulanmaz;
/// öneri ekranda gerekçesiyle görünür, kullanıcı düğmeye basarsa yalnız o
/// seansın önerileri değişir. Rutin hedefi hiçbir zaman değişmez, önerilen
/// set yapılmış sayılmaz.

enum ProgressionKind {
  /// Geçen sefer bütün çalışma setleri aralığın üst sınırına ulaştı.
  increaseWeight,

  /// Aralık içinde kaldı — aynı kiloda her sete bir tekrar ekle.
  addRep,

  /// En az bir set aralığın altında kaldı — aynı hedefi tekrar dene.
  repeat,
}

class ProgressionAdvice {
  final ProgressionKind kind;
  final int repsMin;
  final int repsMax;

  /// Geçen seansın çalışma setlerindeki en yüksek kilo (gerekçe metni için).
  final double lastTopWeightKg;

  /// Geçen seansın çalışma setlerindeki tekrarlar, sırasıyla.
  final List<int> lastReps;

  /// Aynı sıradaki kilolar (kg) — gerekçe metni piramidi doğru anlatsın.
  final List<double> lastWeightsKg;

  const ProgressionAdvice({
    required this.kind,
    required this.repsMin,
    required this.repsMax,
    required this.lastTopWeightKg,
    required this.lastReps,
    required this.lastWeightsKg,
  });

  /// Bütün çalışma setleri aynı kiloda mı.
  bool get uniformWeight =>
      lastWeightsKg.every((w) => w == lastWeightsKg.first);

  /// Kullanıcıya uygulanabilir bir öneri var mı (düğme gösterilir).
  bool get actionable => kind != ProgressionKind.repeat;

  /// Geçen seansın bir çalışma setini öneriye çevirir. Isınma setleri
  /// çağıran tarafta atlanır; `repeat` hiçbir şeyi değiştirmez.
  SetValues apply(SetValues last, {required double incrementKg}) {
    switch (kind) {
      case ProgressionKind.increaseWeight:
        final w = last.weightKg;
        return SetValues(
          weightKg: w == null ? null : w + incrementKg,
          reps: repsMin,
        );
      case ProgressionKind.addRep:
        final r = last.reps;
        return SetValues(
          weightKg: last.weightKg,
          reps: r == null ? null : (r + 1 > repsMax ? repsMax : r + 1),
        );
      case ProgressionKind.repeat:
        return last;
    }
  }
}

/// Geçen seansın çalışma setlerinden (ısınma hariç) öneri çıkarır.
/// Kilo × tekrar olmayan, aralığı tanımsız ya da geçmişi olmayan harekette
/// `null` — öneri gösterilmez.
ProgressionAdvice? progressionFor({
  required List<SetValues> lastWorkingSets,
  required int? repsMin,
  required int? repsMax,
}) {
  if (repsMin == null || repsMax == null || repsMin > repsMax) return null;
  final sets = [
    for (final s in lastWorkingSets)
      if (s.weightKg != null && s.reps != null) s,
  ];
  if (sets.isEmpty) return null;

  final reps = [for (final s in sets) s.reps!];
  final top = sets.map((s) => s.weightKg!).reduce((a, b) => a > b ? a : b);

  final ProgressionKind kind;
  if (reps.any((r) => r < repsMin)) {
    kind = ProgressionKind.repeat;
  } else if (reps.every((r) => r >= repsMax)) {
    kind = ProgressionKind.increaseWeight;
  } else {
    kind = ProgressionKind.addRep;
  }
  return ProgressionAdvice(
    kind: kind,
    repsMin: repsMin,
    repsMax: repsMax,
    lastTopWeightKg: top,
    lastReps: reps,
    lastWeightsKg: [for (final s in sets) s.weightKg!],
  );
}
