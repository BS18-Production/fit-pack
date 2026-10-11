import '../../data/database/app_database.dart';
import 'insight_window.dart';

export 'nutrition_summary.dart';

/// **"Verime sor" — yeni hesaplar** (docs/36 §1).
///
/// Saf Dart: veritabanı bilmez, metin üretmez; sonuç tipleri döner (docs/22
/// `weekly_review.dart` kalıbı). Girdiyi sağlayıcı DAO'lardan toplar.
///
/// - `today_remaining`: [computeTodayRemaining]
/// - `top_exercises`: [topExercises]
/// - 30 günlük / haftalık beslenme özeti: [nutritionStats]

// ───────────────────────────── today_remaining ─────────────────────────────

/// Kendi geçmişinden bir öneri: o öğünde daha önce yenmiş bir yemek ve
/// **her zamanki porsiyonu**. Yeni yemek önerilmez (docs/36 §5.3).
class MealSuggestion {
  final int foodId;

  /// Her zamanki porsiyon: geçmiş kayıtların medyan gramajlı olanı.
  final double grams;
  final double kcal;
  final double protein;

  /// Son 30 günde o öğünde kaç kez yendi.
  final int timesEaten;

  const MealSuggestion({
    required this.foodId,
    required this.grams,
    required this.kcal,
    required this.protein,
    required this.timesEaten,
  });
}

class TodayRemaining {
  final int kcalGoal;
  final int proteinGoal;

  /// Bugün kaydedilenler. "Yenen" değil "kaydedilen" — kayıt eksik olabilir.
  final double loggedKcal;
  final double loggedProtein;

  /// Hedef − kaydedilen. Negatif = hedef aşıldı (ekran yargısız yazar).
  /// Hedef yoksa (0) `null`.
  final double? remainingKcal;
  final double? remainingProtein;

  /// Kalan kaloriye sığan, en çok [computeTodayRemaining.maxSuggestions]
  /// geçmiş yemek. Kayıt yoksa ya da kalan yoksa boş → yalnız kalan miktar.
  final List<MealSuggestion> suggestions;

  const TodayRemaining({
    required this.kcalGoal,
    required this.proteinGoal,
    required this.loggedKcal,
    required this.loggedProtein,
    required this.remainingKcal,
    required this.remainingProtein,
    required this.suggestions,
  });
}

/// Bugün hedefe ne kaldı + kalan kaloriye sığan geçmiş yemekler.
///
/// [logs]: bugün ve önceki 30 günün öğün kayıtları (fazlası süzülür).
/// [mealType]: önerinin öğünü (`breakfast`/`lunch`/`dinner`/`snack`);
/// `null` = öğün ayırmadan tüm geçmiş.
///
/// Sıra (deterministik): o öğünde en sık yenen → porsiyon proteini yüksek →
/// `foodId` küçük.
TodayRemaining computeTodayRemaining({
  required DateTime now,
  required List<FoodLog> logs,
  required int kcalGoal,
  required int proteinGoal,
  String? mealType,
  int maxSuggestions = 3,
}) {
  final today = DateWindow(
    start: dayOf(now),
    end: DateTime(now.year, now.month, now.day + 1),
    isComplete: false,
  );
  final history = DateWindow(
    start: DateTime(now.year, now.month, now.day - 30),
    end: dayOf(now),
    isComplete: true,
  );

  var kcal = 0.0;
  var protein = 0.0;
  final byFood = <int, List<FoodLog>>{};
  for (final l in logs) {
    if (today.contains(l.date)) {
      kcal += l.computedKcal;
      protein += l.computedProtein;
    } else if (history.contains(l.date) &&
        (mealType == null || l.mealType == mealType)) {
      byFood.putIfAbsent(l.foodId, () => []).add(l);
    }
  }

  final remKcal = kcalGoal > 0 ? kcalGoal - kcal : null;
  final remProtein = proteinGoal > 0 ? proteinGoal - protein : null;

  final suggestions = <MealSuggestion>[];
  if (remKcal != null && remKcal > 0) {
    byFood.forEach((foodId, entries) {
      final p = _medianPortion(entries);
      if (p.computedKcal > remKcal) return;
      suggestions.add(
        MealSuggestion(
          foodId: foodId,
          grams: p.grams,
          kcal: p.computedKcal,
          protein: p.computedProtein,
          timesEaten: entries.length,
        ),
      );
    });
    suggestions.sort((a, b) {
      final t = b.timesEaten.compareTo(a.timesEaten);
      if (t != 0) return t;
      final pr = b.protein.compareTo(a.protein);
      if (pr != 0) return pr;
      return a.foodId.compareTo(b.foodId);
    });
  }

  return TodayRemaining(
    kcalGoal: kcalGoal,
    proteinGoal: proteinGoal,
    loggedKcal: kcal,
    loggedProtein: protein,
    remainingKcal: remKcal,
    remainingProtein: remProtein,
    suggestions: suggestions.take(maxSuggestions).toList(),
  );
}

/// Medyan gramajlı kayıt (çift sayıda kayıtta alttaki). Gerçek bir kayıt
/// döner — uydurma porsiyon yok.
FoodLog _medianPortion(List<FoodLog> entries) {
  final sorted = [...entries]
    ..sort((a, b) {
      final g = a.grams.compareTo(b.grams);
      return g != 0 ? g : a.date.compareTo(b.date);
    });
  return sorted[(sorted.length - 1) ~/ 2];
}

// ────────────────────────────── top_exercises ──────────────────────────────

class TopExercise {
  final int exerciseId;

  /// Hareket kaydı bulunamazsa (silinmiş/eksik) `null`.
  final String? name;

  /// Tamamlanmış, ısınma dışı set sayısı (sıralama ölçütü).
  final int sets;

  /// Hareketin geçtiği seans sayısı (eşitlikte ikinci ölçüt).
  final int sessions;

  const TopExercise({
    required this.exerciseId,
    required this.name,
    required this.sets,
    required this.sessions,
  });
}

/// Set sayısına göre en çok yapılan [limit] hareket. Pencere dışı seanslar
/// süzülür. Sıra: set ↓ → seans ↓ → `exerciseId` ↑.
List<TopExercise> topExercises({
  required DateWindow window,
  required List<WorkoutSession> sessions,
  required Map<int, List<WorkoutSet>> setsBySession,
  Map<int, Exercise> exercises = const {},
  int limit = 5,
}) {
  final sets = <int, int>{};
  final sessionIds = <int, Set<int>>{};
  for (final s in sessions) {
    if (!window.contains(s.date)) continue;
    for (final st in setsBySession[s.id] ?? const <WorkoutSet>[]) {
      if (!st.isComplete || st.isWarmup) continue;
      sets[st.exerciseId] = (sets[st.exerciseId] ?? 0) + 1;
      sessionIds.putIfAbsent(st.exerciseId, () => {}).add(s.id);
    }
  }
  final out =
      [
        for (final e in sets.entries)
          TopExercise(
            exerciseId: e.key,
            name: exercises[e.key]?.name,
            sets: e.value,
            sessions: sessionIds[e.key]!.length,
          ),
      ]..sort((a, b) {
        final s = b.sets.compareTo(a.sets);
        if (s != 0) return s;
        final n = b.sessions.compareTo(a.sessions);
        if (n != 0) return n;
        return a.exerciseId.compareTo(b.exerciseId);
      });
  return out.take(limit).toList();
}
