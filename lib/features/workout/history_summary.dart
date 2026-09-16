import '../../data/database/app_database.dart';

/// Seans toplamları — antrenman geçmişi kartı ve açılan detay aynı hesabı
/// kullanır (C-19). Set sayısı kayıtlı tüm setler; hacim = Σ kg × tekrar
/// (kilo ya da tekrarı olmayan set hacme katkı vermez).
typedef SessionTotals = ({int sets, double volumeKg});

SessionTotals sessionTotals(Iterable<WorkoutSet> sets) {
  var count = 0;
  double volume = 0;
  for (final s in sets) {
    count++;
    volume += (s.weightKg ?? 0) * (s.reps ?? 0);
  }
  return (sets: count, volumeKg: volume);
}

/// Geçmiş kartının tarih kalıbı: bu yılın seansında yıl yazılmaz, eski
/// yıllarda yazılır — "12 Mart Pazartesi" / "12 Mart 2025, Pazartesi" (C-19).
String historyDatePattern(DateTime date, DateTime now) =>
    date.year == now.year ? 'd MMMM EEEE' : 'd MMMM y, EEEE';
