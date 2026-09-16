/// Kilo değişiminin görsel tonu (C-31). Artış kendiliğinden "kötü" değildir:
/// kilo almaya çalışan için artış iyi haberdir. Renk yalnız hedef kilo
/// biliniyorsa ve değişim hedefe doğruysa olumlu olur; aksi halde nötr kalır
/// (kırmızı kullanılmaz — kilo dalgalanması hata değil).
enum WeightChangeTone { good, neutral }

/// [fromKg] → [toKg] değişimi [goalKg]'a doğru mu?
WeightChangeTone weightChangeTone({
  required double fromKg,
  required double toKg,
  double? goalKg,
}) {
  final delta = toKg - fromKg;
  if (goalKg == null || delta == 0 || goalKg == fromKg) {
    return WeightChangeTone.neutral;
  }
  final towardGoal = (goalKg - fromKg).sign == delta.sign;
  return towardGoal ? WeightChangeTone.good : WeightChangeTone.neutral;
}
