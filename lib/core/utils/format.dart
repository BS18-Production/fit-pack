// Paylaşılan biçimleme yardımcıları — ekranlar arası tekrarı önler.

/// Sayıyı tam sayıysa ondalıksız, değilse olduğu gibi gösterir (kg, makro).
/// Örn: 60.0 → "60", 62.5 → "62.5".
String fmtNum(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toString();

/// Saniyeyi "dakika:saniye" biçimine çevirir (dakika dolgusuz). 1 saati
/// aşınca "saat:dk:sn" olur (uzun kardiyoda "90:00" yerine "1:30:00").
/// Örn: 90 → "1:30", 45 → "0:45", 750 → "12:30", 5400 → "1:30:00".
String fmtDuration(int totalSeconds) {
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = (totalSeconds % 60).toString().padLeft(2, '0');
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:$s';
  }
  return '$m:$s';
}
