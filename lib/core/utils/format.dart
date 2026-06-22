// Paylaşılan biçimleme yardımcıları — ekranlar arası tekrarı önler.

/// Sayıyı tam sayıysa ondalıksız, değilse olduğu gibi gösterir (kg, makro).
/// Örn: 60.0 → "60", 62.5 → "62.5".
String fmtNum(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toString();

/// Saniyeyi "dakika:saniye" biçimine çevirir (dakika dolgusuz).
/// Örn: 90 → "1:30", 45 → "0:45", 750 → "12:30".
String fmtDuration(int totalSeconds) {
  final m = totalSeconds ~/ 60;
  final s = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
