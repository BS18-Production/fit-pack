import '../../data/database/app_database.dart';
import '../../data/database/daos/workout_dao.dart' show ExerciseSetPoint;
import 'record_calc.dart';

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

// ───────────────────────── Geçmiş özeti + detay (docs/31) ─────────────────────────

/// Seanstaki sayılan setler: ısınma hariç; seansta yalnız ısınma varsa hepsi
/// (kart "0 set" göstermesin).
List<WorkoutSet> workingSets(Iterable<WorkoutSet> sets) {
  final working = sets.where((s) => !s.isWarmup).toList();
  return working.isEmpty ? sets.toList() : working;
}

/// Setin "en iyi" sıralama anahtarı: e1RM (tahmini 1 tekrar maks.) > kilo >
/// tekrar > süre > mesafe. Kardiyo/süreli setler de karşılaştırılabilir.
List<num> _setRank(WorkoutSet s) => [
      epley(s.weightKg, s.reps) ?? 0,
      s.weightKg ?? 0,
      s.reps ?? 0,
      s.durationSec ?? 0,
      s.distanceM ?? 0,
    ];

int _compareRank(List<num> a, List<num> b) {
  for (var i = 0; i < a.length; i++) {
    final c = a[i].compareTo(b[i]);
    if (c != 0) return c;
  }
  return 0;
}

/// En iyi set (ısınma hariç); hiç değer yoksa null.
WorkoutSet? bestSetOf(Iterable<WorkoutSet> sets) {
  WorkoutSet? best;
  for (final s in workingSets(sets)) {
    if (_setRank(s).every((v) => v == 0)) continue;
    if (best == null || _compareRank(_setRank(s), _setRank(best)) > 0) best = s;
  }
  return best;
}

/// Kart/detayda bir hareketin özeti: kaç çalışma seti, en iyi set.
typedef ExerciseBrief = ({int exerciseId, int sets, WorkoutSet? best});

/// Hareketler seanstaki sırasıyla (ilk setin sırası).
List<ExerciseBrief> exerciseBriefs(Iterable<WorkoutSet> sets) {
  final byEx = <int, List<WorkoutSet>>{};
  // Setler seansta yapıldığı sırayla yazılır → id sırası = seans sırası.
  final ordered = sets.toList()..sort((a, b) => a.id.compareTo(b.id));
  for (final s in ordered) {
    byEx.putIfAbsent(s.exerciseId, () => []).add(s);
  }
  return [
    for (final e in byEx.entries)
      (
        exerciseId: e.key,
        sets: workingSets(e.value).length,
        best: bestSetOf(e.value),
      ),
  ];
}

/// Seans başına kırılan rekor sayısı (hareket başına en fazla 1) — Özet
/// ekranıyla aynı tanım (`newRecordFor`): seans ÖNCESİ geçmişin en iyi
/// e1RM'ini ya da en ağır kilosunu aşan hareket. Tek geçişte, tarih sırasıyla.
Map<int, int> recordCountsBySession(
  Iterable<WorkoutSession> sessions,
  Map<int, List<WorkoutSet>> setsBySession,
) {
  final ordered = sessions.toList()
    ..sort((a, b) {
      final c = a.date.compareTo(b.date);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
  final history = <int, List<ExerciseSetPoint>>{};
  final counts = <int, int>{};
  var i = 0;
  while (i < ordered.length) {
    // Aynı anı paylaşan seanslar birbirine "önceki" sayılmaz (isBefore).
    var j = i;
    while (j < ordered.length && ordered[j].date == ordered[i].date) {
      j++;
    }
    final group = ordered.sublist(i, j);
    final pending = <int, List<ExerciseSetPoint>>{};
    for (final session in group) {
      final byEx = <int, List<ExerciseSetPoint>>{};
      for (final s in setsBySession[session.id] ?? const <WorkoutSet>[]) {
        if (s.isWarmup) continue;
        byEx.putIfAbsent(s.exerciseId, () => []).add(ExerciseSetPoint(
            date: session.date, weightKg: s.weightKg, reps: s.reps));
      }
      var n = 0;
      for (final e in byEx.entries) {
        final rec = newRecordFor(
          name: '',
          priorHistory: history[e.key] ?? const [],
          sessionPoints: e.value,
        );
        if (rec != null) n++;
        pending.putIfAbsent(e.key, () => []).addAll(e.value);
      }
      counts[session.id] = n;
    }
    for (final e in pending.entries) {
      history.putIfAbsent(e.key, () => []).addAll(e.value);
    }
    i = j;
  }
  return counts;
}

/// Hareketin [before] anından önceki SON seansındaki en iyi seti (e1RM,
/// yoksa kilo). [history] tarih sıralı olmak zorunda değil.
ExerciseSetPoint? previousBest(
    Iterable<ExerciseSetPoint> history, DateTime before) {
  DateTime? last;
  for (final p in history) {
    if (p.date.isBefore(before) && (last == null || p.date.isAfter(last))) {
      last = p.date;
    }
  }
  if (last == null) return null;
  ExerciseSetPoint? best;
  for (final p in history.where((p) => p.date == last)) {
    final score = [p.e1rm ?? 0, p.weightKg ?? 0, p.reps ?? 0];
    final cur = best == null
        ? null
        : [best.e1rm ?? 0, best.weightKg ?? 0, best.reps ?? 0];
    if (cur == null || _compareRank(score, cur) > 0) best = p;
  }
  return best;
}

/// Geçen sefere göre fark: önce kilo, kilo aynıysa tekrar.
sealed class SetDelta {
  const SetDelta();
}

class WeightDelta extends SetDelta {
  final double kg;
  const WeightDelta(this.kg);
}

class RepsDelta extends SetDelta {
  final int reps;
  const RepsDelta(this.reps);
}

class SameAsLast extends SetDelta {
  const SameAsLast();
}

/// [best] bu seansın en iyi seti, [prev] geçen seferinki. Kıyas yoksa null.
SetDelta? deltaVsPrevious(WorkoutSet? best, ExerciseSetPoint? prev) {
  if (best == null || prev == null) return null;
  final w = best.weightKg, pw = prev.weightKg;
  if (w != null && pw != null && (w - pw).abs() >= 0.01) {
    return WeightDelta(w - pw);
  }
  final r = best.reps, pr = prev.reps;
  if (r != null && pr != null && r != pr) return RepsDelta(r - pr);
  if (r == null && pr == null && w == null) return null;
  return const SameAsLast();
}

/// Çalışan kaslar: birincil kas başına çalışma seti, çoktan aza.
List<(String muscle, int sets)> muscleSplit(
  Iterable<WorkoutSet> sets,
  Map<int, String?> primaryMuscleById,
) {
  final count = <String, int>{};
  for (final s in workingSets(sets)) {
    final m = primaryMuscleById[s.exerciseId];
    if (m == null || m.isEmpty) continue;
    count[m] = (count[m] ?? 0) + 1;
  }
  final list = [for (final e in count.entries) (e.key, e.value)]
    ..sort((a, b) => b.$2.compareTo(a.$2));
  return list;
}
