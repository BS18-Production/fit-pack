import '../../data/database/app_database.dart';
import '../../data/database/daos/nutrition_dao.dart';

/// **Beslenme kaydı alışkanlığı** (docs/26) — saf mantık, veritabanı bilmez.
///
/// Araştırmadaki sıra: önce kayıt yükünü azalt (her zamanki öğün tek
/// dokunuş), sonra doğru anda hatırlat (öğün saati, kayıt varsa sessiz),
/// en son dürüst ödül (haftalık hedef — günlük seri DEĞİL; kaçan gün
/// "başarısızlık" sayılmaz, Samet kuralı).

// ─────────────────────────────── Öğün dilimi ───────────────────────────────

/// Günün saatine göre "şu anki" öğün — öneri kartı bunu önerir.
String mealForTime(DateTime now) {
  final m = now.hour * 60 + now.minute;
  if (m < 11 * 60) return 'breakfast';
  if (m < 16 * 60) return 'lunch';
  if (m < 18 * 60) return 'snack';
  return 'dinner';
}

// ───────────────────────────── Her zamanki öğün ─────────────────────────────

/// "Her zamanki kahvaltın" önerisi: aynı içerik (aynı besinler) en az
/// [usualMealMinDays] farklı günde girilmişse. Miktarlar en son günden.
class UsualMeal {
  final String mealType;
  final List<FoodLogWithFood> items;

  /// Bu içeriğin girildiği gün sayısı (son 14 günde).
  final int timesLogged;

  const UsualMeal({
    required this.mealType,
    required this.items,
    required this.timesLogged,
  });

  double get kcal => items.fold(0, (s, i) => s + i.log.computedKcal);
  double get protein => items.fold(0, (s, i) => s + i.log.computedProtein);

  List<MealCopyItem> get copyItems => [
        for (final i in items)
          MealCopyItem(foodId: i.log.foodId, grams: i.log.grams),
      ];
}

/// Tek sefer yenmiş öğün "her zamanki" değildir.
const usualMealMinDays = 2;

/// [days]: aynı öğünün geçmiş günleri, yeniden eskiye (`getMealDays`).
/// En sık tekrar eden içerik seçilir; eşitlikte en yeni. İçerik = besin
/// kümesi (miktar farkı "farklı öğün" sayılmaz — 2 yumurta / 3 yumurta aynı
/// kahvaltı).
UsualMeal? usualMealOf(String mealType, List<MealDay> days) {
  final count = <String, int>{};
  final latest = <String, MealDay>{};
  for (final d in days) {
    if (d.items.isEmpty) continue;
    final ids = d.items.map((i) => i.log.foodId).toSet().toList()..sort();
    final key = ids.join(',');
    count[key] = (count[key] ?? 0) + 1;
    // Liste yeniden eskiye → ilk görülen en yenisi.
    latest.putIfAbsent(key, () => d);
  }
  String? best;
  for (final k in count.keys) {
    if (count[k]! < usualMealMinDays) continue;
    if (best == null ||
        count[k]! > count[best]! ||
        (count[k] == count[best] &&
            latest[k]!.day.isAfter(latest[best]!.day))) {
      best = k;
    }
  }
  if (best == null) return null;
  return UsualMeal(
    mealType: mealType,
    items: latest[best]!.items,
    timesLogged: count[best]!,
  );
}

// ───────────────────────────── Öğün hatırlatıcısı ─────────────────────────────

/// Hatırlatılan öğünler (ara öğün hatırlatılmaz — isteğe bağlı öğün).
const reminderMeals = ['breakfast', 'lunch', 'dinner'];

/// Varsayılan hatırlatma saati (gün içi dakika) — alışkanlık öğrenilemezse.
const defaultReminderMinute = {
  'breakfast': 10 * 60 + 30,
  'lunch': 14 * 60,
  'dinner': 20 * 60 + 30,
};

/// Öğrenilen saat bu pencerenin dışına çıkmaz — gece 02:00'de "öğle yemeği"
/// bildirimi gelmesin.
const _reminderWindow = {
  'breakfast': (9 * 60, 12 * 60),
  'lunch': (12 * 60 + 30, 16 * 60 + 30),
  'dinner': (19 * 60, 22 * 60 + 30),
};

/// Kişinin genelde kaydettiği saatten bu kadar sonra hatırlatılır: normalde
/// kaydettiği anı geçmiş ama hâlâ kayıt yoksa.
const reminderGraceMinutes = 60;

/// Öğrenmek için en az bu kadar örnek (aynı gün girilmiş kayıt) gerekir.
const reminderMinSamples = 3;

/// Öğün başına hatırlatma saati (gün içi dakika). Kaynak: kaydın **eklendiği
/// an** (`updatedAt`, yerel tetikleyici yazar) — yalnız öğünün kendi gününde
/// girilmiş kayıtlar (geçmişe sonradan girilenler alışkanlık değil). Medyan +
/// [reminderGraceMinutes], pencereye kırpılır. Az örnekte varsayılan.
Map<String, int> reminderMinutesFrom(List<FoodLog> logs) {
  final samples = <String, List<int>>{};
  for (final l in logs) {
    final at = l.updatedAt?.toLocal();
    if (at == null) continue;
    if (at.year != l.date.year ||
        at.month != l.date.month ||
        at.day != l.date.day) {
      continue;
    }
    samples.putIfAbsent(l.mealType, () => []).add(at.hour * 60 + at.minute);
  }
  return {
    for (final meal in reminderMeals)
      meal: () {
        final s = samples[meal];
        if (s == null || s.length < reminderMinSamples) {
          return defaultReminderMinute[meal]!;
        }
        s.sort();
        final median = s[s.length ~/ 2];
        final (lo, hi) = _reminderWindow[meal]!;
        return (median + reminderGraceMinutes).clamp(lo, hi);
      }(),
  };
}

/// Kurulacak tek seferlik hatırlatma.
typedef MealReminder = ({String mealType, DateTime at, int dayOffset});

/// Kaç gün ilerisi kurulur. Uygulama her açıldığında/kayıt girildiğinde
/// yeniden kurulduğu için birkaç gün açılmasa da hatırlatma sürer.
const reminderDaysAhead = 3;

/// Bugün + [reminderDaysAhead]−1 gün için hatırlatmalar. **Bugün girilmiş
/// öğün ve saati geçmiş öğün atlanır** — kayıt varsa bildirim gitmez.
List<MealReminder> planMealReminders({
  required DateTime now,
  required Set<String> loggedToday,
  required Map<String, int> minutes,
}) {
  final out = <MealReminder>[];
  for (var d = 0; d < reminderDaysAhead; d++) {
    for (final meal in reminderMeals) {
      if (d == 0 && loggedToday.contains(meal)) continue;
      final m = minutes[meal] ?? defaultReminderMinute[meal]!;
      // Takvim alanıyla: yaz saati geçişinde 24 saat ≠ 1 gün.
      final at = DateTime(now.year, now.month, now.day + d, m ~/ 60, m % 60);
      if (!at.isAfter(now)) continue;
      out.add((mealType: meal, at: at, dayOffset: d));
    }
  }
  return out;
}

// ───────────────────────────── Haftalık kayıt hedefi ─────────────────────────────

/// Haftada kaç gün kayıt hedeflenir. Günlük seri yerine haftalık hedef:
/// 1-2 boş gün "kopma" sayılmaz (araştırma: tek kaçan günde sıfırlanan seri
/// kaygı yaratıp bıraktırıyor).
const weeklyLogGoalDays = 5;

/// Haftalık kayıt satırının türü — metin l10n'da.
enum LogWeekLine {
  /// Bu hafta henüz kayıt yok.
  start,

  /// Hedefe 1 gün kaldı.
  lastOne,

  /// Hedef doldu.
  done,

  /// Yolda; [LogWeek.left] gün kaldı.
  going,
}

typedef LogWeek = ({int done, int goal, int left, LogWeekLine line});

/// [loggedDays]: bu hafta en az bir öğün girilmiş günler (00:00).
LogWeek logWeekOf(Set<DateTime> loggedDays) {
  final done = loggedDays.length;
  final left = done >= weeklyLogGoalDays ? 0 : weeklyLogGoalDays - done;
  final line = done == 0
      ? LogWeekLine.start
      : left == 0
          ? LogWeekLine.done
          : left == 1
              ? LogWeekLine.lastOne
              : LogWeekLine.going;
  return (done: done, goal: weeklyLogGoalDays, left: left, line: line);
}
