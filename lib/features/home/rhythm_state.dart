import 'streak_calc.dart';

/// Ritim kartının hangi metni göstereceği (docs/24 §2) — saf mantık.
enum RhythmState {
  /// Hiç antrenman kaydı yok.
  empty,

  /// Bu hafta başlandı, öncesinde kayıt yok.
  firstWeek,

  /// Seri sürüyor, bu haftanın hedefi henüz dolmadı (hafta devam — kırmaz).
  ongoing,

  /// Seri sürüyor ve bu haftanın hedefi doldu.
  weekDone,

  /// Geçmişte kayıt var ama seri 0 — önceki hafta hedef kaçtı.
  restart,
}

RhythmState rhythmStateOf(WeeklyStreak s) {
  if (s.weeks > 0) {
    return s.thisWeekComplete ? RhythmState.weekDone : RhythmState.ongoing;
  }
  if (s.hasEarlierSessions) return RhythmState.restart;
  return s.thisWeekDone > 0 ? RhythmState.firstWeek : RhythmState.empty;
}
