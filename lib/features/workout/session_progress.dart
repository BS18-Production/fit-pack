/// Aktif seansın ilerlemesi (C-16): kaç set tamamlandı / toplam kaç set.
///
/// Isınma setleri de sayılır — kullanıcının ekranda gördüğü satır sayısıyla
/// aynı olsun ("0/6 set" altı satırı anlatır). Boş seans `total = 0`.
class SessionProgress {
  final int done;
  final int total;

  const SessionProgress({required this.done, required this.total});

  /// [setsDone]: hareket başına, her setin tamamlanma durumu.
  factory SessionProgress.of(Iterable<Iterable<bool>> setsDone) {
    var done = 0;
    var total = 0;
    for (final exercise in setsDone) {
      for (final isDone in exercise) {
        total++;
        if (isDone) done++;
      }
    }
    return SessionProgress(done: done, total: total);
  }

  /// 0.0–1.0; boş seansta 0.
  double get fraction => total == 0 ? 0 : done / total;

  bool get isEmpty => total == 0;
  bool get isComplete => total > 0 && done == total;
}
