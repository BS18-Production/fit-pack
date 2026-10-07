/// Canlı etkinlik için seansta "şu an neredeyiz" (docs/32) — saf mantık.
///
/// Şu anki set = sırayla ilk tamamlanmamış set. Kullanıcı hareketleri
/// karışık sırada yapabilir; kilit ekranı yine de sıradaki işi gösterir.
/// Hepsi tamamsa `null`.
({int exercise, int set})? livePosition(List<List<bool>> doneByExercise) {
  for (var e = 0; e < doneByExercise.length; e++) {
    final i = doneByExercise[e].indexOf(false);
    if (i >= 0) return (exercise: e, set: i);
  }
  return null;
}
