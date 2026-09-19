import 'dart:convert';

import '../../data/database/app_database.dart';
import '../../data/database/daos/workout_dao.dart';
import '../home/dashboard_stats.dart';

/// **Haftalık değerlendirme — hesap motoru** (docs/22 §3, A1).
///
/// Saf Dart: veritabanı bilmez, metin üretmez. Girdiyi sağlayıcı DAO'lardan
/// toplar, çıktıyı ekran (ve ileride asistan) yorumlar. Metin üretmemesi
/// bilinçli: motor dil bağımsız kalır, her kural birim testiyle kilitlenir.
///
/// **Samet'in kuralları** (NEXT_TASKS "Güncel sıra" #2) burada uygulanır:
/// - Beslenme ortalaması **kayıt girilmiş günlerin** ortalamasıdır; kayıtsız
///   gün sıfır sayılmaz ve eksik kayıttan başarı/başarısızlık çıkarılmaz.
/// - Hedef yönü **geçmişe uygulanmaz** (bkz. [GoalDirection]).
/// - Puan yok; farklı hareketler tek bir "gelişim puanı"na toplanmaz.
/// - Tek kilo ölçümü trend sayılmaz.

/// Kullanıcının kilo hedefi yönü (profil, şema v12).
enum GoalDirection {
  lose,
  maintain,
  gain;

  static GoalDirection? tryParse(String? v) => switch (v) {
        'lose' => lose,
        'maintain' => maintain,
        'gain' => gain,
        _ => null,
      };
}

/// Kilo değişiminin hedef yönüne göre anlamı.
enum WeightMeaning {
  /// Hedefle aynı yönde (ya da "koru"da sınır içinde).
  onTrack,

  /// Hedefin tersine. Yargı değil, dikkat notu — ekran böyle yazar.
  against,

  /// Anlamlı değişim yok.
  flat,

  /// Yön bilinmiyor (seçilmemiş ya da bu haftadan SONRA seçilmiş).
  unknown,
}

/// "Gelecek hafta" odak cümlesinin türü (docs/22 §3.3). İlk eşleşen kazanır.
enum FocusKind {
  /// Planlı gün var, gerçekleşen daha az → planı tamamlamak.
  completePlan,

  /// Bir hareket 3 haftadır aynı kiloda ve tekrar aralığının üstünde →
  /// kiloyu artırmayı denemek (docs/21 #3 ile aynı dil).
  increaseWeight,

  /// Beslenme kaydı olan gün az → kayıt alışkanlığı.
  loggingHabit,

  /// Kilo 2 haftadır hedefin tersine → kalori hedefini gözden geçirmek
  /// (öneri; hedefi DEĞİŞTİRMEZ).
  reviewCalories,

  /// Hiçbiri → aynı ritmi sürdürmek.
  keepRhythm,
}

// ─────────────────────────────── Girdi ───────────────────────────────

/// Motorun girdisi. Sağlayıcı DAO'lardan doldurur; testler elle kurar.
class WeeklyReviewInput {
  /// Haftanın başlangıcı (00:00). Pencere `[weekStart, weekStart + 7 gün)`.
  final DateTime weekStart;
  final DateTime now;

  /// Bu haftanın seansları ve setleri.
  final List<WorkoutSession> sessions;
  final Map<int, List<WorkoutSet>> setsBySession;

  /// Önceki haftanın seansları ve setleri (karşılaştırma için).
  final List<WorkoutSession> prevSessions;
  final Map<int, List<WorkoutSet>> prevSetsBySession;

  /// Seanslarda geçen hareketler (ad + kas grubu için).
  final Map<int, Exercise> exercises;

  /// Aktif rutinlerin planladığı haftalık günler (`DateTime.weekday`).
  final Set<int> scheduledWeekdays;

  /// Rutinlerdeki hedef tekrar üst sınırı, harekete göre (odak kuralı 2).
  final Map<int, int> targetRepsMaxByExercise;

  /// Tamamlanmış, ısınma dışı set noktaları: bu hafta + önceki 3 hafta.
  final List<ExerciseProgressPoint> progressPoints;

  /// Bu haftanın öğün kayıtları.
  final List<FoodLog> foodLogs;
  final int kcalGoal;
  final int proteinGoal;

  /// Kilo ölçümleri: önceki 2 hafta + bu hafta (trend için 3 hafta).
  final List<BodyMeasurement> measurements;

  /// Tahmini kalori için son vücut ağırlığı.
  final double? bodyWeightKg;

  final GoalDirection? goalDirection;

  /// Hedef yönünün seçildiği an. **Geçmişe uygulama yasağının** ölçüsü.
  final DateTime? goalDirectionSince;

  const WeeklyReviewInput({
    required this.weekStart,
    required this.now,
    this.sessions = const [],
    this.setsBySession = const {},
    this.prevSessions = const [],
    this.prevSetsBySession = const {},
    this.exercises = const {},
    this.scheduledWeekdays = const {},
    this.targetRepsMaxByExercise = const {},
    this.progressPoints = const [],
    this.foodLogs = const [],
    this.kcalGoal = 0,
    this.proteinGoal = 0,
    this.measurements = const [],
    this.bodyWeightKg,
    this.goalDirection,
    this.goalDirectionSince,
  });

  DateTime get weekEnd => weekStart.add(const Duration(days: 7));
}

// ─────────────────────────────── Çıktı ───────────────────────────────

class ReviewPeriod {
  final DateTime start;
  final DateTime end; // hariç

  /// Hafta bitti mi? Bitmediyse ekran "N günlük veriyle" der (W-2).
  final bool isComplete;

  /// Geçen gün sayısı (1–7). Bitmemiş haftada karşılaştırmalar buna göre.
  final int daysElapsed;

  const ReviewPeriod({
    required this.start,
    required this.end,
    required this.isComplete,
    required this.daysElapsed,
  });
}

class WorkoutSection {
  final int sessions;
  final int prevSessions;

  /// Tamamlanmış, ısınma dışı set sayısı.
  final int completedSets;
  final int totalMinutes;

  /// Ana sayfadaki "hacim" ile AYNI hesap (W-9): Σ kg × tekrar.
  final int volumeKg;
  final int kcalBurned;

  /// Planlı gün sayısı; plan yoksa `null` → "X/Y" değil yalnız "X" yazılır.
  final int? planned;

  const WorkoutSection({
    required this.sessions,
    required this.prevSessions,
    required this.completedSets,
    required this.totalMinutes,
    required this.volumeKg,
    required this.kcalBurned,
    required this.planned,
  });
}

/// Bir hareketin bu haftaki ilerlemesi. Her hareket AYRI satırdır; toplanmaz.
class ExerciseProgress {
  final int exerciseId;
  final String name;
  final double bestWeightKg;
  final int bestReps;

  /// Tahmini 1TM farkı (Epley): bu haftanın en iyisi − önceki kaydın en iyisi.
  final double deltaE1rm;

  const ExerciseProgress({
    required this.exerciseId,
    required this.name,
    required this.bestWeightKg,
    required this.bestReps,
    required this.deltaE1rm,
  });
}

class NutritionSection {
  /// Kayıt girilmiş gün sayısı. **0 ise hiçbir yargı yok** (W-4).
  final int loggedDays;

  /// Yalnız kayıtlı günlerin ortalaması; kayıt yoksa `null` (W-3).
  final int? avgKcal;
  final int? avgProtein;
  final int kcalGoal;
  final int proteinGoal;

  const NutritionSection({
    required this.loggedDays,
    required this.avgKcal,
    required this.avgProtein,
    required this.kcalGoal,
    required this.proteinGoal,
  });
}

class WeightSection {
  final int count;
  final double? weekAvg;
  final double? prevWeekAvg;

  /// İki haftanın ortalaması da varsa fark; yoksa `null`.
  final double? delta;

  /// Tek ölçüm — "trend sayılmaz" yazılır (W-5).
  final bool singleMeasurement;
  final WeightMeaning meaning;

  const WeightSection({
    required this.count,
    required this.weekAvg,
    required this.prevWeekAvg,
    required this.delta,
    required this.singleMeasurement,
    required this.meaning,
  });
}

class ReviewFocus {
  final FocusKind kind;

  /// Kurala göre ek bilgi: tamamlanan/planlanan, hareket adı, kayıtlı gün.
  final int? done;
  final int? planned;
  final String? exerciseName;

  const ReviewFocus(this.kind, {this.done, this.planned, this.exerciseName});
}

class WeeklyReview {
  final ReviewPeriod period;
  final WorkoutSection workout;

  /// En çok ilerleyen en fazla 3 hareket. Boşsa ekran "karşılaştırılacak
  /// önceki kayıt yok" der.
  final List<ExerciseProgress> progress;
  final NutritionSection nutrition;
  final WeightSection weight;

  /// Kas grubu → tamamlanmış set sayısı. Yalnız sayım; "az çalıştın" yok.
  final Map<String, int> muscleSets;
  final ReviewFocus focus;

  const WeeklyReview({
    required this.period,
    required this.workout,
    required this.progress,
    required this.nutrition,
    required this.weight,
    required this.muscleSets,
    required this.focus,
  });
}

// ─────────────────────────────── Motor ───────────────────────────────

WeeklyReview buildWeeklyReview(WeeklyReviewInput i) {
  final period = _period(i);
  final workout = _workout(i);
  final nutrition = _nutrition(i);
  final weight = _weight(i);
  return WeeklyReview(
    period: period,
    workout: workout,
    progress: _progress(i),
    nutrition: nutrition,
    weight: weight,
    muscleSets: _muscleSets(i),
    focus: _focus(i, period, workout, nutrition),
  );
}

ReviewPeriod _period(WeeklyReviewInput i) {
  final end = i.weekEnd;
  final complete = !i.now.isBefore(end);
  final elapsed = complete
      ? 7
      : (i.now.difference(i.weekStart).inHours ~/ 24 + 1).clamp(1, 7);
  return ReviewPeriod(
    start: i.weekStart,
    end: end,
    isComplete: complete,
    daysElapsed: elapsed,
  );
}

WorkoutSection _workout(WeeklyReviewInput i) {
  // Ana sayfayla AYNI hesap (W-9): seans, hacim, kalori `aggregateWorkouts`.
  final agg = aggregateWorkouts(
    sessions: i.sessions,
    setsBySession: i.setsBySession,
    bodyWeightKg: i.bodyWeightKg,
  );
  var completedSets = 0;
  var minutes = 0;
  for (final s in i.sessions) {
    minutes += s.durationMin ?? 0;
    for (final st in i.setsBySession[s.id] ?? const <WorkoutSet>[]) {
      if (st.isComplete && !st.isWarmup) completedSets++;
    }
  }
  return WorkoutSection(
    sessions: agg.sessions,
    prevSessions: i.prevSessions.length,
    completedSets: completedSets,
    totalMinutes: minutes,
    volumeKg: agg.volumeKg,
    kcalBurned: agg.kcalBurned,
    planned: i.scheduledWeekdays.isEmpty ? null : i.scheduledWeekdays.length,
  );
}

/// Bu hafta yapılan her hareketin en iyi seti, bu haftadan ÖNCEKİ son kayıtla
/// karşılaştırılır. Yalnız pozitif ilerleme listelenir, en fazla 3 hareket.
/// Farklı hareketler asla toplanmaz (W-8).
List<ExerciseProgress> _progress(WeeklyReviewInput i) {
  final buHafta = <int, ExerciseProgressPoint>{};
  final onceki = <int, ({DateTime day, double best})>{};

  for (final p in i.progressPoints) {
    final e1 = p.e1rm;
    if (e1 == null) continue;
    if (!p.date.isBefore(i.weekStart) && p.date.isBefore(i.weekEnd)) {
      final cur = buHafta[p.exerciseId];
      if (cur == null || e1 > cur.e1rm!) buHafta[p.exerciseId] = p;
    } else if (p.date.isBefore(i.weekStart)) {
      // Önceki haftalardan EN SON gün önemli, en iyi gün değil: "son
      // kayda göre" karşılaştırıyoruz, aylar önceki rekora göre değil.
      final day = DateTime(p.date.year, p.date.month, p.date.day);
      final cur = onceki[p.exerciseId];
      if (cur == null || day.isAfter(cur.day)) {
        onceki[p.exerciseId] = (day: day, best: e1);
      } else if (day == cur.day && e1 > cur.best) {
        onceki[p.exerciseId] = (day: day, best: e1);
      }
    }
  }

  final out = <ExerciseProgress>[];
  buHafta.forEach((id, p) {
    final prev = onceki[id];
    if (prev == null) return; // karşılaştırılacak kayıt yok
    final delta = p.e1rm! - prev.best;
    if (delta <= 0) return;
    out.add(ExerciseProgress(
      exerciseId: id,
      name: p.name,
      bestWeightKg: p.weightKg,
      bestReps: p.reps,
      deltaE1rm: delta,
    ));
  });
  out.sort((a, b) => b.deltaE1rm.compareTo(a.deltaE1rm));
  return out.take(3).toList();
}

NutritionSection _nutrition(WeeklyReviewInput i) {
  final kcal = <DateTime, double>{};
  final protein = <DateTime, double>{};
  for (final l in i.foodLogs) {
    if (l.date.isBefore(i.weekStart) || !l.date.isBefore(i.weekEnd)) continue;
    final day = DateTime(l.date.year, l.date.month, l.date.day);
    kcal[day] = (kcal[day] ?? 0) + l.computedKcal;
    protein[day] = (protein[day] ?? 0) + l.computedProtein;
  }
  final n = kcal.length;
  // Kayıtlı günlerin ortalaması — 7'ye bölünmez (Samet kuralı, W-3).
  return NutritionSection(
    loggedDays: n,
    avgKcal: n == 0 ? null : (kcal.values.reduce((a, b) => a + b) / n).round(),
    avgProtein:
        n == 0 ? null : (protein.values.reduce((a, b) => a + b) / n).round(),
    kcalGoal: i.kcalGoal,
    proteinGoal: i.proteinGoal,
  );
}

/// Bir haftanın kilo ortalaması (ölçüm yoksa `null`).
double? _weekAvg(List<BodyMeasurement> ms, DateTime start) {
  final end = start.add(const Duration(days: 7));
  final w = [
    for (final m in ms)
      if (m.weightKg != null && !m.date.isBefore(start) && m.date.isBefore(end))
        m.weightKg!,
  ];
  if (w.isEmpty) return null;
  return w.reduce((a, b) => a + b) / w.length;
}

WeightSection _weight(WeeklyReviewInput i) {
  final buHafta = [
    for (final m in i.measurements)
      if (m.weightKg != null &&
          !m.date.isBefore(i.weekStart) &&
          m.date.isBefore(i.weekEnd))
        m,
  ];
  final avg = _weekAvg(i.measurements, i.weekStart);
  final prev =
      _weekAvg(i.measurements, i.weekStart.subtract(const Duration(days: 7)));
  final delta = (avg != null && prev != null) ? avg - prev : null;
  final single = buHafta.length == 1;

  // Tek ölçüm trend sayılmaz (W-5) → anlam da çıkarılmaz.
  final meaning = (delta == null || single)
      ? WeightMeaning.unknown
      : _meaning(delta, _directionFor(i, i.weekEnd));

  return WeightSection(
    count: buHafta.length,
    weekAvg: avg,
    prevWeekAvg: prev,
    delta: delta,
    singleMeasurement: single,
    meaning: meaning,
  );
}

/// **Geçmişe uygulama yasağı** (W-6). Yön, ancak [periodEnd]'den ÖNCE
/// seçilmişse o dönemin yorumunda kullanılır. Sonradan seçilmiş bir yön eski
/// haftayı "hedefin tersine gitmişsin" diye yargılayamaz.
GoalDirection? _directionFor(WeeklyReviewInput i, DateTime periodEnd) {
  final dir = i.goalDirection;
  final since = i.goalDirectionSince;
  if (dir == null || since == null) return null;
  return since.isBefore(periodEnd) ? dir : null;
}

WeightMeaning _meaning(double delta, GoalDirection? dir) {
  if (dir == null) return WeightMeaning.unknown;
  const esik = 0.1; // kg — tartı gürültüsü
  switch (dir) {
    case GoalDirection.lose:
      if (delta < -esik) return WeightMeaning.onTrack;
      if (delta > esik) return WeightMeaning.against;
      return WeightMeaning.flat;
    case GoalDirection.gain:
      if (delta > esik) return WeightMeaning.onTrack;
      if (delta < -esik) return WeightMeaning.against;
      return WeightMeaning.flat;
    case GoalDirection.maintain:
      return delta.abs() <= 0.5 ? WeightMeaning.onTrack : WeightMeaning.against;
  }
}

/// Kas grubu → tamamlanmış set (A2). Hareketin birincil kası; yoksa kas
/// listesinin ilki; o da yoksa "other".
Map<String, int> _muscleSets(WeeklyReviewInput i) {
  final out = <String, int>{};
  for (final s in i.sessions) {
    for (final st in i.setsBySession[s.id] ?? const <WorkoutSet>[]) {
      if (!st.isComplete || st.isWarmup) continue;
      final kas = _muscleOf(i.exercises[st.exerciseId]);
      out[kas] = (out[kas] ?? 0) + 1;
    }
  }
  return out;
}

String _muscleOf(Exercise? e) {
  if (e == null) return 'other';
  final p = e.primaryMuscle;
  if (p != null && p.isNotEmpty) return p;
  try {
    final list = jsonDecode(e.muscleGroups);
    if (list is List && list.isNotEmpty && list.first is String) {
      return list.first as String;
    }
  } catch (_) {
    // Bozuk JSON: sayımı bozmasın.
  }
  return 'other';
}

/// Odak cümlesi — kural sırası (docs/22 §3.3). İlk eşleşen kazanır.
ReviewFocus _focus(
  WeeklyReviewInput i,
  ReviewPeriod period,
  WorkoutSection workout,
  NutritionSection nutrition,
) {
  // 1) Plan tamamlanmadı. Bitmemiş haftada "kaçırdın" demek haksız olur:
  //    yalnız hafta bitince bakılır.
  final planned = workout.planned;
  if (period.isComplete && planned != null && workout.sessions < planned) {
    return ReviewFocus(FocusKind.completePlan,
        done: workout.sessions, planned: planned);
  }

  // 2) Bir hareket 3 haftadır aynı kiloda ve aralığın üstünde.
  final takili = _stuckExercise(i);
  if (takili != null) {
    return ReviewFocus(FocusKind.increaseWeight, exerciseName: takili);
  }

  // 3) Beslenme kaydı az. Eşik geçen güne göre ölçeklenir: pazartesi 1 gün
  //    kayıtla "alışkanlık kur" demek anlamsız.
  final esik = period.daysElapsed < 4 ? period.daysElapsed : 4;
  if (nutrition.loggedDays < esik) {
    return ReviewFocus(FocusKind.loggingHabit, done: nutrition.loggedDays);
  }

  // 4) Kilo 2 haftadır hedefin tersine. Yön bu haftadan ÖNCE seçilmiş
  //    olmalı — iki haftalık trend yön yokken yargılanamaz (W-6).
  if (_weightAgainstTwoWeeks(i)) {
    return const ReviewFocus(FocusKind.reviewCalories);
  }

  return const ReviewFocus(FocusKind.keepRhythm);
}

/// Son 3 haftanın her birinde en ağır set AYNI kiloda ve tekrar, rutindeki
/// hedef üst sınırına ulaşmış hareket (varsa ilki, ada göre sıralı).
String? _stuckExercise(WeeklyReviewInput i) {
  final adaylar = <String>[];
  for (final entry in i.targetRepsMaxByExercise.entries) {
    final id = entry.key;
    final ust = entry.value;
    String? ad;
    final haftalik = <({double kg, int reps})>[];
    for (var w = 0; w < 3; w++) {
      final start = i.weekStart.subtract(Duration(days: 7 * w));
      final end = start.add(const Duration(days: 7));
      ({double kg, int reps})? enIyi;
      for (final p in i.progressPoints) {
        if (p.exerciseId != id) continue;
        if (p.date.isBefore(start) || !p.date.isBefore(end)) continue;
        ad = p.name;
        if (enIyi == null ||
            p.weightKg > enIyi.kg ||
            (p.weightKg == enIyi.kg && p.reps > enIyi.reps)) {
          enIyi = (kg: p.weightKg, reps: p.reps);
        }
      }
      if (enIyi == null) break;
      haftalik.add(enIyi);
    }
    if (haftalik.length < 3 || ad == null) continue;
    final ayniKilo = haftalik.every((h) => h.kg == haftalik.first.kg);
    final aralikUstu = haftalik.every((h) => h.reps >= ust);
    if (ayniKilo && aralikUstu) adaylar.add(ad);
  }
  if (adaylar.isEmpty) return null;
  adaylar.sort();
  return adaylar.first;
}

bool _weightAgainstTwoWeeks(WeeklyReviewInput i) {
  final dir = _directionFor(i, i.weekStart);
  if (dir == null) return false;
  final w0 = _weekAvg(i.measurements, i.weekStart);
  final w1 =
      _weekAvg(i.measurements, i.weekStart.subtract(const Duration(days: 7)));
  final w2 =
      _weekAvg(i.measurements, i.weekStart.subtract(const Duration(days: 14)));
  if (w0 == null || w1 == null || w2 == null) return false;
  return _meaning(w0 - w1, dir) == WeightMeaning.against &&
      _meaning(w1 - w2, dir) == WeightMeaning.against;
}
