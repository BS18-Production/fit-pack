import '../../core/prefs/week_start_provider.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/workout_dao.dart';
import '../home/dashboard_stats.dart';
import 'insight_queries.dart';
import 'insight_window.dart';
import 'weekly_review.dart' show GoalDirection;

/// **"Verime sor" — yorum kuralları** (docs/36 §2).
///
/// Saf Dart: veritabanı bilmez, **cümle üretmez**. Her kural bir
/// [InsightComment] döner: çeviri anahtarı ([CommentKey]) + parametreler +
/// notlar + kaynak. Cümleler `.arb`'de yazılır (ayrı iş, çeviri kilidi).
///
/// Dil kuralları (docs/36 §2, Codex incelemeli) anahtar seçimine gömülüdür:
/// - "Yeterli" yok — set yorumu ~10 set/hafta **düzeyine göre** konum verir.
/// - Kilo kaybı CDC **kg** aralığıyla karşılaştırılır (yüzde aralığı yok).
/// - Kendi geçmişi **medyanla** karşılaştırılır, ortalamayla değil.
/// - Devam eden dönem "şu ana kadar" ([CommentNote.soFar]); tam dönemle
///   yargılanmaz.
/// - "Sağlıklısın" sonucu yok; sağlıkla ilgili kartlarda
///   [CommentNote.consultProfessional].

// ─────────────────────────────── Çıktı ───────────────────────────────

/// Kılavuz kaynakları. [citation] bibliyografik künye (çevrilmez).
enum EvidenceSource {
  schoenfeld2017('Schoenfeld, Ogborn, Krieger. J Sports Sci 2017;35:1073–82'),
  cdcWeightLoss('CDC — Losing Weight (1–2 lb ≈ 0,45–0,9 kg/hafta)'),
  garthe2011('Garthe ve ark. IJSNEM 2011 (PMID 21558571)'),
  iraki2019('Iraki, Fitschen, Espinar, Helms. Sports 2019;7(7):154'),
  morton2018('Morton ve ark. Br J Sports Med 2018;52:376–84');

  final String citation;
  const EvidenceSource(this.citation);
}

/// Yorumun dayanağı: genel kılavuz mu, kullanıcının kendi geçmişi mi.
enum CommentBasis { guideline, ownHistory, none }

/// Karta eklenen ek notlar (her biri ayrı çeviri anahtarı).
enum CommentNote {
  /// "Genel kılavuz, kişisel tıbbi tavsiye değil" — kaynaklı her kartta.
  generalGuideline,

  /// "Tıbbi değerlendirme için uzmana danış" — kilo ve protein/kg kartları.
  consultProfessional,

  /// Devam eden dönem: "şu ana kadar".
  soFar,

  /// Bizim sayımız birincil kasa yazılan tamamlanmış set; çalışmalar
  /// zorlayıcı set sayar (Schoenfeld 2017).
  completedSetsCounted,

  /// Haftalık kayıp %1,5'i aştı — öne çıkan dikkat notu. **Ürün tercihi**,
  /// kaynak değil.
  fastLossCaution,

  /// Ek bilgi (yargı değil): kuvvet sporcularında ~%0,7/hafta kayıp yağsız
  /// kütleyi daha iyi korudu (Garthe 2011).
  leanMassInfo,

  /// Seviye bilinmiyor → aralık "başlangıç/orta seviye için" (Iraki 2019).
  beginnerIntermediateRange,

  /// "Kaydedilen protein/kalori" — kayıt eksik olabilir (#8 yoksa).
  loggedOnly,

  /// Ortalamaya yalnız kullanıcının tamamladığı günler girer (docs/37).
  completedDaysOnly,

  /// Yön seçilmemiş: "hedef yönünü seçersen yorumlarım".
  chooseGoalDirection,
}

/// Durum cümlesinin anahtarı. `.arb` anahtarı: [arbKey].
enum CommentKey {
  // muscle_balance
  muscleBelowTen,
  muscleAtTen,
  muscleBeyondTwenty,

  // weight_trend
  weightNotEnoughData,
  weightAgainstGoal,
  weightNoClearChange,
  weightLossSlower,
  weightLossInRange,
  weightLossFaster,
  weightGainSlower,
  weightGainInRange,
  weightGainFaster,
  weightStable,
  weightDriftUp,
  weightDriftDown,

  // workout_summary
  workoutNotEnoughHistory,
  workoutNoBaseline,
  workoutSoFar,
  workoutAboveMedian,
  workoutAtMedian,
  workoutBelowMedian,

  // strength_progress / exercise_history
  strengthNotApplicable,
  strengthNotEnoughData,
  strengthUp,
  strengthStable,
  strengthDown,
  strengthPlateau,

  // protein_goal / nutrition_summary
  nutritionNoLogs,
  proteinGoalDays,
  kcalVsGoal,
  proteinPerKgBelow,
  proteinPerKgInRange,
  proteinPerKgAbove,

  // today_remaining
  todayNoGoal,
  todayRemaining,
  todayGoalReached;

  /// `muscleBelowTen` → `insightMuscleBelowTen`.
  String get arbKey => 'insight${name[0].toUpperCase()}${name.substring(1)}';
}

class InsightComment {
  final CommentKey key;

  /// Cümle parametreleri (sayılar ham; biçimleme ekranda).
  final Map<String, Object?> params;
  final CommentBasis basis;
  final List<EvidenceSource> sources;

  /// Ek notlar, gösterim sırasıyla (öne çıkan ilk).
  final List<CommentNote> notes;

  const InsightComment(
    this.key, {
    this.params = const {},
    this.basis = CommentBasis.none,
    this.sources = const [],
    this.notes = const [],
  });

  @override
  String toString() => 'InsightComment($key, $params, $notes)';
}

// ─────────────────────────── muscle_balance ───────────────────────────

/// ~10 set/kas/hafta: Schoenfeld 2017'de daha fazla kazanım **eğilimi**.
const kMuscleSetsLevel = 10;

/// Bu düzeyin ötesi için kanıt sınırlı (uyarı değil, bilgi).
const kMuscleSetsLimitedEvidence = 20;

/// Bir kas grubunun haftalık set sayısının yorumu. [weekComplete] değilse
/// "şu ana kadar" notu eklenir ([daysElapsed] parametreyle).
InsightComment interpretMuscleSets({
  required String muscle,
  required int sets,
  required bool weekComplete,
  int? daysElapsed,
}) {
  final key = sets < kMuscleSetsLevel
      ? CommentKey.muscleBelowTen
      : sets > kMuscleSetsLimitedEvidence
      ? CommentKey.muscleBeyondTwenty
      : CommentKey.muscleAtTen;
  return InsightComment(
    key,
    params: {
      'muscle': muscle,
      'sets': sets,
      'level': kMuscleSetsLevel,
      'limitedEvidenceAbove': kMuscleSetsLimitedEvidence,
      if (!weekComplete) 'daysElapsed': daysElapsed,
    },
    basis: CommentBasis.guideline,
    sources: const [EvidenceSource.schoenfeld2017],
    notes: [
      if (!weekComplete) CommentNote.soFar,
      CommentNote.completedSetsCounted,
      CommentNote.generalGuideline,
    ],
  );
}

// ───────────────────────────── weight_trend ─────────────────────────────

/// Kilo yorumu için en az ölçüm ve ilk–son ölçüm arası en az gün.
const kWeightMinMeasurements = 2;
const kWeightMinSpanDays = 14;

/// Tartı gürültüsü: haftalık eğim bu kadar küçükse "belirgin değişim yok"
/// (docs/22 `_meaning` eşiğiyle aynı, 0,1 kg).
const kWeightNoiseKgPerWeek = 0.1;

/// CDC: 1–2 lb/hafta ≈ 0,45–0,9 kg/hafta.
const kCdcLossMinKg = 0.45;
const kCdcLossMaxKg = 0.9;

/// Ürün tercihi (kaynak değil): haftalık kayıp bunu aşarsa dikkat notu öne.
const kFastLossPct = 1.5;

/// Iraki 2019: başlangıç/orta seviye için %0,25–0,5/hafta artış.
const kGainMinPct = 0.25;
const kGainMaxPct = 0.5;

/// "Koru" / yön yok: pencere boyunca değişim ortalamanın ±%1'i içinde → sabit.
const kStablePct = 1.0;

/// Kilo eğilimi yorumu. [measurements] pencere dışı ve kilosuz ölçümler
/// süzülür. Eğim en küçük kareler doğrusuyla (tek tartı sıçraması baskın
/// olmasın); yüzdeler penceredeki ölçüm ortalamasına göre.
///
/// **Geçmişe uygulama yasağı** (docs/22 W-6): yön, ancak pencere bitmeden
/// önce seçilmişse kullanılır.
InsightComment interpretWeightTrend({
  required DateWindow window,
  required List<BodyMeasurement> measurements,
  GoalDirection? direction,
  DateTime? directionSince,
}) {
  final pts = [
    for (final m in measurements)
      if (m.weightKg != null && window.contains(m.date))
        (t: m.date, kg: m.weightKg!),
  ]..sort((a, b) => a.t.compareTo(b.t));

  final span = pts.isEmpty ? 0 : calendarDaysBetween(pts.first.t, pts.last.t);
  final base = <String, Object?>{
    'count': pts.length,
    'spanDays': span,
    'windowDays': window.days,
    'minDays': kWeightMinSpanDays,
    if (pts.isNotEmpty) 'firstDate': pts.first.t,
    if (pts.isNotEmpty) 'lastDate': pts.last.t,
  };
  if (pts.length < kWeightMinMeasurements || span < kWeightMinSpanDays) {
    return InsightComment(CommentKey.weightNotEnoughData, params: base);
  }

  final t0 = pts.first.t;
  final xs = [for (final p in pts) p.t.difference(t0).inMinutes / (60 * 24)];
  final ys = [for (final p in pts) p.kg];
  final mean = ys.reduce((a, b) => a + b) / ys.length;
  final weeklyKg = _slope(xs, ys) * 7;
  final pctPerWeek = weeklyKg / mean * 100;
  final params = {
    ...base,
    'weeklyChangeKg': weeklyKg,
    'pctPerWeek': pctPerWeek,
    'meanKg': mean,
  };

  final dir =
      (direction != null &&
          directionSince != null &&
          directionSince.isBefore(window.end))
      ? direction
      : null;
  final noClear = weeklyKg.abs() <= kWeightNoiseKgPerWeek;

  switch (dir) {
    case GoalDirection.lose:
      if (noClear) {
        return InsightComment(
          CommentKey.weightNoClearChange,
          params: params,
          basis: CommentBasis.ownHistory,
        );
      }
      // Artış: "hedefinin tersi" (docs/22 dili) — "yavaş kayıp" denmez.
      if (weeklyKg > 0) {
        return InsightComment(
          CommentKey.weightAgainstGoal,
          params: params,
          basis: CommentBasis.ownHistory,
        );
      }
      final lossKg = -weeklyKg;
      final key = lossKg < kCdcLossMinKg
          ? CommentKey.weightLossSlower
          : lossKg > kCdcLossMaxKg
          ? CommentKey.weightLossFaster
          : CommentKey.weightLossInRange;
      return InsightComment(
        key,
        params: {
          ...params,
          'rangeMinKg': kCdcLossMinKg,
          'rangeMaxKg': kCdcLossMaxKg,
        },
        basis: CommentBasis.guideline,
        sources: const [
          EvidenceSource.cdcWeightLoss,
          EvidenceSource.garthe2011,
        ],
        notes: [
          if (-pctPerWeek > kFastLossPct) CommentNote.fastLossCaution,
          CommentNote.leanMassInfo,
          CommentNote.generalGuideline,
          CommentNote.consultProfessional,
        ],
      );
    case GoalDirection.gain:
      if (noClear) {
        return InsightComment(
          CommentKey.weightNoClearChange,
          params: params,
          basis: CommentBasis.ownHistory,
        );
      }
      if (weeklyKg < 0) {
        return InsightComment(
          CommentKey.weightAgainstGoal,
          params: params,
          basis: CommentBasis.ownHistory,
        );
      }
      final key = pctPerWeek < kGainMinPct
          ? CommentKey.weightGainSlower
          : pctPerWeek > kGainMaxPct
          ? CommentKey.weightGainFaster
          : CommentKey.weightGainInRange;
      return InsightComment(
        key,
        params: {
          ...params,
          'rangeMinPct': kGainMinPct,
          'rangeMaxPct': kGainMaxPct,
        },
        basis: CommentBasis.guideline,
        sources: const [EvidenceSource.iraki2019],
        notes: const [
          CommentNote.beginnerIntermediateRange,
          CommentNote.generalGuideline,
          CommentNote.consultProfessional,
        ],
      );
    case GoalDirection.maintain:
    case null:
      // Pencere boyunca doğrunun öngördüğü toplam değişim, ortalamaya göre.
      final totalPct = weeklyKg * span / 7 / mean * 100;
      final key = totalPct.abs() <= kStablePct
          ? CommentKey.weightStable
          : totalPct > 0
          ? CommentKey.weightDriftUp
          : CommentKey.weightDriftDown;
      return InsightComment(
        key,
        params: {
          ...params,
          'totalChangePct': totalPct,
          'stablePct': kStablePct,
        },
        basis: CommentBasis.ownHistory,
        notes: [if (dir == null) CommentNote.chooseGoalDirection],
      );
  }
}

/// En küçük kareler eğimi (y birimi / x birimi). x'ler hep aynıysa 0.
double _slope(List<double> xs, List<double> ys) {
  final n = xs.length;
  final mx = xs.reduce((a, b) => a + b) / n;
  final my = ys.reduce((a, b) => a + b) / n;
  var num = 0.0;
  var den = 0.0;
  for (var i = 0; i < n; i++) {
    num += (xs[i] - mx) * (ys[i] - my);
    den += (xs[i] - mx) * (xs[i] - mx);
  }
  return den == 0 ? 0 : num / den;
}

// ─────────────────────────── workout_summary ───────────────────────────

enum WorkoutMetric { volume, sets, sessions }

/// Karşılaştırmanın tabanı: önceki kaç tamamlanmış hafta.
const kBaselineWeeks = 8;

/// Medyan için en az kaç geçmiş hafta. **Ürün tercihi** (docs/36'da sayı
/// yok): 1–3 haftanın medyanı "senin normalin" sayılamaz.
const kMinBaselineWeeks = 4;

/// Haftanın hacim/set/seans değeri, önceki 8 tamamlanmış haftanın
/// **medyanına** göre. Mutlak norm yok.
///
/// [sessions] en az `[weekStart − 8 hafta, weekStart + 1 hafta)` aralığını
/// kapsamalı (fazlası süzülür). [firstSessionDate]: kullanıcının ilk seansı —
/// tamamen öncesinde kalan haftalar tabana girmez (o zaman uygulama yoktu);
/// sonrasındaki boş haftalar 0 sayılır (gerçekten antrenman yok). Verilmezse
/// [sessions] içindeki en erken seans alınır.
///
/// Devam eden hafta ([now] < hafta sonu): yüzde verilmez, yalnız "şu ana
/// kadar" değeri ve medyan — tam haftayla yargılanmaz.
Map<WorkoutMetric, InsightComment> interpretWorkoutWeek({
  required DateTime weekStart,
  required DateTime now,
  required List<WorkoutSession> sessions,
  required Map<int, List<WorkoutSet>> setsBySession,
  DateTime? firstSessionDate,
}) {
  DateTime shift(int weeks) =>
      DateTime(weekStart.year, weekStart.month, weekStart.day + 7 * weeks);

  final weekEnd = shift(1);
  final complete = !now.isBefore(weekEnd);
  final daysElapsed = complete
      ? 7
      : (calendarDaysBetween(weekStart, now) + 1).clamp(1, 7);

  Map<WorkoutMetric, int> valuesIn(DateTime start, DateTime end) {
    final inWeek = [
      for (final s in sessions)
        if (!s.date.isBefore(start) && s.date.isBefore(end)) s,
    ];
    var sets = 0;
    for (final s in inWeek) {
      for (final st in setsBySession[s.id] ?? const <WorkoutSet>[]) {
        if (st.isComplete && !st.isWarmup) sets++;
      }
    }
    final agg = aggregateWorkouts(
      sessions: inWeek,
      setsBySession: setsBySession,
      bodyWeightKg: null,
    );
    return {
      WorkoutMetric.volume: agg.volumeKg,
      WorkoutMetric.sets: sets,
      WorkoutMetric.sessions: agg.sessions,
    };
  }

  DateTime? first = firstSessionDate;
  for (final s in sessions) {
    if (first == null || s.date.isBefore(first)) first = s.date;
  }

  final history = <Map<WorkoutMetric, int>>[];
  for (var w = 1; w <= kBaselineWeeks; w++) {
    final start = shift(-w);
    final end = shift(-w + 1);
    if (first == null || !first.isBefore(end)) continue; // uygulama öncesi
    history.add(valuesIn(start, end));
  }
  final current = valuesIn(weekStart, weekEnd);

  final out = <WorkoutMetric, InsightComment>{};
  for (final m in WorkoutMetric.values) {
    final value = current[m]!;
    final base = <String, Object?>{
      'metric': m.name,
      'value': value,
      'baselineWeeks': history.length,
    };
    if (history.length < kMinBaselineWeeks) {
      out[m] = InsightComment(
        CommentKey.workoutNotEnoughHistory,
        params: {...base, 'minWeeks': kMinBaselineWeeks},
        basis: CommentBasis.ownHistory,
        notes: [if (!complete) CommentNote.soFar],
      );
      continue;
    }
    final median = _median([for (final h in history) h[m]!]);
    final params = {...base, 'median': median};
    if (!complete) {
      out[m] = InsightComment(
        CommentKey.workoutSoFar,
        params: {...params, 'daysElapsed': daysElapsed},
        basis: CommentBasis.ownHistory,
        notes: const [CommentNote.soFar],
      );
      continue;
    }
    if (median == 0) {
      out[m] = InsightComment(
        CommentKey.workoutNoBaseline,
        params: params,
        basis: CommentBasis.ownHistory,
      );
      continue;
    }
    final pct = ((value - median) * 100 / median).round();
    out[m] = InsightComment(
      pct > 0
          ? CommentKey.workoutAboveMedian
          : pct < 0
          ? CommentKey.workoutBelowMedian
          : CommentKey.workoutAtMedian,
      params: {...params, 'pct': pct},
      basis: CommentBasis.ownHistory,
    );
  }
  return out;
}

double _median(List<num> xs) {
  final s = [...xs]..sort();
  final n = s.length;
  return n.isOdd ? s[n ~/ 2].toDouble() : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2;
}

// ──────────────────── strength_progress / exercise_history ────────────────────

/// e1RM (tahmini tek tekrar maksimumu) farkı bu yüzdenin içindeyse "sabit".
/// **Ürün tercihi**: 100×10 → 102,5×9 gibi eşdeğer setler "düşüş" sayılmasın.
const kStrengthStablePct = 1.0;

/// Plato: art arda bu kadar haftada en ağır set aynı kiloda (docs/22 §3.3).
const kPlateauWeeks = 3;

/// Tek hareketin e1RM eğilimi. [points] o harekete ve pencereye ait
/// tamamlanmış, ısınma dışı setler (DAO süzer).
///
/// Sıra: plato (son [kPlateauWeeks] ardışık veri haftasında en ağır kilo
/// aynı) → ilk gün ve son günün en iyi e1RM'i karşılaştırılır.
InsightComment interpretStrengthTrend(
  List<ExerciseProgressPoint> points, {
  int weekStart = DateTime.monday,
}) {
  final byDay = <DateTime, double>{};
  final topKgByWeek = <DateTime, double>{};
  for (final p in points) {
    final e1 = p.e1rm;
    if (e1 == null) continue;
    final day = dayOf(p.date);
    if (e1 > (byDay[day] ?? 0)) byDay[day] = e1;
    final wk = startOfWeek(p.date, weekStart);
    if (p.weightKg > (topKgByWeek[wk] ?? 0)) topKgByWeek[wk] = p.weightKg;
  }
  if (byDay.isEmpty) {
    // Süre/mesafe hareketi ya da kg/tekrar girilmemiş: e1RM yok.
    return InsightComment(
      CommentKey.strengthNotApplicable,
      params: {'count': points.length},
    );
  }
  final days = byDay.keys.toList()..sort();
  if (days.length < 2) {
    return InsightComment(
      CommentKey.strengthNotEnoughData,
      params: {'days': days.length},
      basis: CommentBasis.ownHistory,
    );
  }

  final weeks = topKgByWeek.keys.toList()..sort();
  if (weeks.length >= kPlateauWeeks) {
    final last = weeks.sublist(weeks.length - kPlateauWeeks);
    var consecutive = true;
    for (var i = 1; i < last.length; i++) {
      final prev = last[i - 1];
      if (DateTime(prev.year, prev.month, prev.day + 7) != last[i]) {
        consecutive = false;
      }
    }
    final kg = topKgByWeek[last.first]!;
    if (consecutive && last.every((w) => topKgByWeek[w] == kg)) {
      return InsightComment(
        CommentKey.strengthPlateau,
        params: {'topKg': kg, 'weeks': kPlateauWeeks, 'days': days.length},
        basis: CommentBasis.ownHistory,
      );
    }
  }

  final firstE1 = byDay[days.first]!;
  final lastE1 = byDay[days.last]!;
  final pct = (lastE1 - firstE1) / firstE1 * 100;
  return InsightComment(
    pct > kStrengthStablePct
        ? CommentKey.strengthUp
        : pct < -kStrengthStablePct
        ? CommentKey.strengthDown
        : CommentKey.strengthStable,
    params: {
      'firstE1rm': firstE1,
      'lastE1rm': lastE1,
      'deltaE1rm': lastE1 - firstE1,
      'pct': pct,
      'firstDate': days.first,
      'lastDate': days.last,
      'days': days.length,
    },
    basis: CommentBasis.ownHistory,
  );
}

// ─────────────────────── protein_goal / nutrition_summary ───────────────────────

/// Morton 2018: ~1,6 g/kg/gün üstünde ek yağsız kütle kazanımı görülmedi.
/// Iraki 2019: 1,6–2,2 g/kg. Kişisel yeterlilik ya da güvenlik sınırı
/// **değil** — "araştırmada bu düzeyin üstünde ek kazanım görülmedi".
const kProteinBreakpointGPerKg = 1.6;
const kProteinUpperGPerKg = 2.2;

/// Beslenme penceresinin yorumları (sıralı): hedefe göre protein günleri,
/// kalori ortalaması/hedef, protein g/kg. Kayıt yoksa tek
/// [CommentKey.nutritionNoLogs]. [bodyWeightKg] + [bodyWeightDate] verilirse
/// g/kg yorumu eklenir (kullanılan kilo ve tarihi parametrede görünür).
List<InsightComment> interpretNutrition(
  NutritionStats s, {
  double? bodyWeightKg,
  DateTime? bodyWeightDate,
  bool windowComplete = true,
}) {
  if (s.sampleDays == 0) {
    return const [InsightComment(CommentKey.nutritionNoLogs)];
  }
  final soFar = [if (!windowComplete) CommentNote.soFar];
  final out = <InsightComment>[];
  if (s.proteinGoal > 0 && s.completedProteinGoalDays != null) {
    out.add(
      InsightComment(
        CommentKey.proteinGoalDays,
        params: {
          'hitDays': s.proteinGoalDays,
          'loggedDays': s.sampleDays,
          'avgProtein': s.avgProtein,
          'goal': s.proteinGoal,
          'pctOfGoal': (s.avgProtein! * 100 / s.proteinGoal).round(),
        },
        basis: CommentBasis.ownHistory,
        notes: [
          ...soFar,
          s.basis == NutritionBasis.completedDays
              ? CommentNote.completedDaysOnly
              : CommentNote.loggedOnly,
        ],
      ),
    );
  }
  if (s.kcalGoal > 0) {
    out.add(
      InsightComment(
        CommentKey.kcalVsGoal,
        params: {
          'loggedDays': s.sampleDays,
          'avgKcal': s.avgKcal,
          'goal': s.kcalGoal,
          'pctOfGoal': (s.avgKcal! * 100 / s.kcalGoal).round(),
        },
        basis: CommentBasis.ownHistory,
        notes: [
          ...soFar,
          s.basis == NutritionBasis.completedDays
              ? CommentNote.completedDaysOnly
              : CommentNote.loggedOnly,
        ],
      ),
    );
  }
  if (bodyWeightKg != null && bodyWeightKg > 0) {
    final gPerKg = s.avgProtein! / bodyWeightKg;
    out.add(
      InsightComment(
        gPerKg < kProteinBreakpointGPerKg
            ? CommentKey.proteinPerKgBelow
            : gPerKg > kProteinUpperGPerKg
            ? CommentKey.proteinPerKgAbove
            : CommentKey.proteinPerKgInRange,
        params: {
          'gPerKg': gPerKg,
          'avgProtein': s.avgProtein,
          'loggedDays': s.sampleDays,
          'bodyWeightKg': bodyWeightKg,
          'bodyWeightDate': bodyWeightDate,
          'breakpoint': kProteinBreakpointGPerKg,
          'upper': kProteinUpperGPerKg,
        },
        basis: CommentBasis.guideline,
        sources: const [EvidenceSource.morton2018, EvidenceSource.iraki2019],
        notes: [
          ...soFar,
          s.basis == NutritionBasis.completedDays
              ? CommentNote.completedDaysOnly
              : CommentNote.loggedOnly,
          CommentNote.generalGuideline,
          CommentNote.consultProfessional,
        ],
      ),
    );
  }
  return out;
}

// ───────────────────────────── today_remaining ─────────────────────────────

/// Bugünün kalanı. Öneriler [TodayRemaining.suggestions]'ta (kendi geçmişi);
/// boşsa ekran yalnız kalan miktarı yazar.
InsightComment interpretTodayRemaining(TodayRemaining r) {
  final remKcal = r.remainingKcal;
  if (remKcal == null) {
    return InsightComment(
      CommentKey.todayNoGoal,
      params: {'loggedKcal': r.loggedKcal, 'loggedProtein': r.loggedProtein},
    );
  }
  final params = {
    'loggedKcal': r.loggedKcal,
    'loggedProtein': r.loggedProtein,
    'kcalGoal': r.kcalGoal,
    'proteinGoal': r.proteinGoal,
    'remainingKcal': remKcal,
    'remainingProtein': r.remainingProtein,
    'suggestionCount': r.suggestions.length,
  };
  return InsightComment(
    remKcal <= 0 ? CommentKey.todayGoalReached : CommentKey.todayRemaining,
    params: params,
    basis: CommentBasis.ownHistory,
    notes: const [CommentNote.soFar, CommentNote.loggedOnly],
  );
}
