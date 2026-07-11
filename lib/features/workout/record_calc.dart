import '../../data/database/daos/workout_dao.dart';

/// Kişisel rekor (PR = Personal Record) hesabı — saf mantık, widget'sız
/// (CONVENTIONS §1). Rekor tanımı Hareket Detayı > Rekorlar sekmesiyle
/// tutarlı: (1) en iyi tahmini 1RM (Epley), (2) en ağır kilo.
///
/// Kural: geçmişi olmayan hareket rekor üretmez — yoksa ilk seansın her
/// seti "rekor" olurdu (Rekorlar sekmesindeki "henüz PR yok" ile tutarlı).

/// Tahmini 1RM (Epley): kg × (1 + tekrar/30). Girdi yoksa/0 ise null.
double? epley(double? weightKg, int? reps) =>
    (weightKg != null && reps != null && weightKg > 0 && reps > 0)
        ? weightKg * (1 + reps / 30)
        : null;

/// Bir hareketin geçmişindeki en iyi değerler. 0 = hiç kayıt yok.
class ExerciseBests {
  final double e1rm;
  final double weightKg;
  const ExerciseBests({required this.e1rm, required this.weightKg});

  bool get isEmpty => e1rm <= 0 && weightKg <= 0;
}

/// Set noktalarından en iyi e1RM + en ağır kiloyu çıkarır (ısınma setlerini
/// çağıran filtreler — `getExerciseHistory` zaten hariç tutuyor).
ExerciseBests bestsOf(Iterable<ExerciseSetPoint> points) {
  var bestE1 = 0.0, bestW = 0.0;
  for (final p in points) {
    final e1 = p.e1rm;
    if (e1 != null && e1 > bestE1) bestE1 = e1;
    final w = p.weightKg;
    if (w != null && w > bestW) bestW = w;
  }
  return ExerciseBests(e1rm: bestE1, weightKg: bestW);
}

/// Antrenman özetinde gösterilecek yeni rekor: hangi harekette, hangi türde
/// (e1RM öncelikli), hangi set değeriyle.
class NewRecord {
  final String name;
  final bool isE1rm; // true: tahmini 1RM rekoru, false: en ağır kilo
  final double value; // e1RM (kg) ya da kilo (kg)
  final double weightKg; // rekor setin kilosu
  final int reps; // rekor setin tekrarı
  const NewRecord({
    required this.name,
    required this.isE1rm,
    required this.value,
    required this.weightKg,
    required this.reps,
  });
}

/// Seans setleri, seans ÖNCESİ geçmişin en iyisini aşıyor mu? Aşmıyorsa ya da
/// geçmiş boşsa null. Bir hareket iki rekoru birden kırdıysa e1RM önceliklidir
/// (tek satır gösterilir).
NewRecord? newRecordFor({
  required String name,
  required Iterable<ExerciseSetPoint> priorHistory,
  required Iterable<ExerciseSetPoint> sessionPoints,
}) {
  final prior = bestsOf(priorHistory);
  if (prior.isEmpty) return null; // ilk kez yapılan hareket — rekor sayılmaz

  ExerciseSetPoint? bestE1Point, bestWPoint;
  var bestE1 = prior.e1rm, bestW = prior.weightKg;
  for (final p in sessionPoints) {
    final e1 = p.e1rm;
    if (e1 != null && e1 > bestE1) {
      bestE1 = e1;
      bestE1Point = p;
    }
    final w = p.weightKg;
    if (w != null && w > bestW) {
      bestW = w;
      bestWPoint = p;
    }
  }

  if (bestE1Point != null) {
    return NewRecord(
      name: name,
      isE1rm: true,
      value: bestE1,
      weightKg: bestE1Point.weightKg!,
      reps: bestE1Point.reps!,
    );
  }
  if (bestWPoint != null) {
    return NewRecord(
      name: name,
      isE1rm: false,
      value: bestW,
      weightKg: bestWPoint.weightKg!,
      reps: bestWPoint.reps ?? 0,
    );
  }
  return null;
}
