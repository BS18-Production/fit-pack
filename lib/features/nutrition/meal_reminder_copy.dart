import 'nutrition_habits.dart';

/// **Öğün hatırlatıcısı metni** — saf mantık, metinler l10n'da.
///
/// Problem (Samet, 2026-10-07): her gün aynı "Kahvaltını ekledin mi? —
/// Eklemek 10 saniye sürer." bildirimi geliyor, insanı bayıyordu. Beklenen:
/// dikkat çeken ve olabildiğince çeşitli metin.
///
/// Kural:
/// - **Başlık** öğün başına [mealTitleVariants] çeşit; güne göre döner →
///   art arda iki gün aynı başlık gelmez.
/// - **Gövde** bugün için kişiye özel olabilir: "her zamanki" öğün (tek
///   dokunuşla eklenir) ya da haftalık kayıt hedefi. Kişisel metin günaşırı
///   gelir; arada genel havuzdan ([mealBodyVariants] çeşit) döner.
/// - İleri günlerin (yarın, öbür gün) gövdesi hep genel: o günün verisi
///   bugünden bilinmez — uygulama açılınca zaten yeniden kurulur.
/// - Seçim tarihten türetilir (rastgele değil): aynı gün yeniden kurulumda
///   metin zıplamaz, test edilebilir.

/// Öğün başına başlık çeşidi (l10n'da `notifMeal<Öğün>Title1..3`).
const mealTitleVariants = 3;

/// Genel gövde havuzu (l10n'da `notifMealBody1..6`).
const mealBodyVariants = 6;

/// "Her zamanki" metninde gösterilen en fazla besin adı.
const usualFoodsShown = 2;

/// Seçilen gövde türü — metne `meal_reminders.dart` çevirir.
sealed class MealReminderBody {
  const MealReminderBody();
}

/// Genel havuzdan [index]. metin (0 tabanlı).
class GenericBody extends MealReminderBody {
  final int index;
  const GenericBody(this.index);
}

/// "Her zamanki kahvaltın: Yulaf, Muz. Tek dokunuşla ekle."
class UsualBody extends MealReminderBody {
  final String foods;
  const UsualBody(this.foods);
}

/// "Bu hafta 3/5 gün. Bugünü eklersen 4/5." — [done] bugünsüz.
class WeekProgressBody extends MealReminderBody {
  final int done, goal;
  const WeekProgressBody(this.done, this.goal);
}

/// Haftalık hedef doldu — kayıt yine teşvik edilir, baskısız.
class WeekGoalMetBody extends MealReminderBody {
  const WeekGoalMetBody();
}

typedef MealReminderCopy = ({int title, MealReminderBody body});

/// Bugünün bildirimi için bilinenler (yalnız `dayOffset == 0`'da kullanılır).
typedef MealReminderFacts = ({
  /// Bu öğünün "her zamanki" içeriği (yoksa null).
  UsualMeal? usual,

  /// Bu hafta kayıt girilmiş gün sayısı (bugün dahil, girildiyse).
  int weekDays,

  /// Bugün başka bir öğün girildi mi (bugün zaten sayılıyor mu).
  bool todayCounted,
});

/// Gün sırası: yerel takvim günü, yaz saatinden etkilenmez.
int _dayIndex(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

/// [at] anındaki [mealType] bildiriminin metni. [usedToday]: bugün başka
/// öğünde kullanılmış kişisel gövde türleri — aynı gün tekrarlanmaz.
MealReminderCopy pickMealReminderCopy({
  required String mealType,
  required DateTime at,
  required int dayOffset,
  MealReminderFacts? facts,
  Set<Type> usedToday = const {},
}) {
  final meal = reminderMeals.indexOf(mealType).clamp(0, reminderMeals.length);
  final day = _dayIndex(at);
  final title = (day + meal) % mealTitleVariants;
  // Öğünler aynı gün farklı genel metin alsın (3 öğün × 2 adım kaydırma).
  final generic = GenericBody((day + meal * 2) % mealBodyVariants);

  if (dayOffset != 0 || facts == null) return (title: title, body: generic);

  final personal = <MealReminderBody>[
    if (facts.usual != null) UsualBody(_foodsLine(facts.usual!)),
    if (facts.weekDays >= weeklyLogGoalDays)
      const WeekGoalMetBody()
    else if (!facts.todayCounted)
      WeekProgressBody(facts.weekDays, weeklyLogGoalDays),
  ]
    // Haftalık metin aynı gün iki öğünde tekrar etmesin ([usedToday]).
    ..removeWhere((b) => b is! UsualBody && usedToday.contains(b.runtimeType));
  // Günaşırı kişisel metin; kişiseller kendi aralarında da döner.
  if (personal.isEmpty || day.isOdd) return (title: title, body: generic);
  return (title: title, body: personal[(day ~/ 2 + meal) % personal.length]);
}

String _foodsLine(UsualMeal usual) {
  final names = [
    for (final i in usual.items) i.food.name,
  ];
  final shown = names.take(usualFoodsShown).join(', ');
  // "Yulaf, Muz +1": cümle noktası üç noktayla çakışmasın.
  final more = names.length - usualFoodsShown;
  return more > 0 ? '$shown +$more' : shown;
}
