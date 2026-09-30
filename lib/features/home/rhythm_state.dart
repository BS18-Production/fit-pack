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

/// Ritim kartı başlığının türü (Samet, 2026-09-30: "1 haftadır ritimdesin"
/// sıkıcı — her hafta farklı, motive eden bir cümle). Metin l10n'da;
/// burada yalnız hangi cümlenin seçileceği — birim testli.
enum RhythmLine {
  // ── Başlangıç
  start, // hiç kayıt yok
  firstWeek, // ilk hafta sürüyor
  firstWeekLastOne, // ilk haftaya 1 antrenman kaldı

  // ── Kilometre taşları (hedef bu hafta doldu; n = seri haftası)
  week1,
  week2,
  week3,
  month1, // 4 hafta
  month2, // 8
  month3, // 12
  halfYear, // 26
  year1, // 52

  // ── Hedef doldu, sıradan hafta — her hafta sırayla döner
  doneA,
  doneB,
  doneC,
  doneD,

  // ── Seri sürüyor, bu hafta devam — sırayla döner
  ongoingA,
  ongoingB,
  ongoingC,
  ongoingLastOne, // hedefe 1 antrenman kaldı (her zaman öncelikli)

  // ── Seri koptu, yeniden başlıyor — sırayla döner
  restartA,
  restartB,
  restartC,
}

/// Seçilen başlık + cümledeki sayı ([n] = seri haftası; "sonraki hafta"
/// cümlelerinde [n] + 1 kullanılır).
typedef RhythmHeadline = ({RhythmLine line, int n});

const _milestones = {
  1: RhythmLine.week1,
  2: RhythmLine.week2,
  3: RhythmLine.week3,
  4: RhythmLine.month1,
  8: RhythmLine.month2,
  12: RhythmLine.month3,
  26: RhythmLine.halfYear,
  52: RhythmLine.year1,
};
const _donePool = [
  RhythmLine.doneA,
  RhythmLine.doneB,
  RhythmLine.doneC,
  RhythmLine.doneD,
];
const _ongoingPool = [
  RhythmLine.ongoingA,
  RhythmLine.ongoingB,
  RhythmLine.ongoingC,
];
const _restartPool = [
  RhythmLine.restartA,
  RhythmLine.restartB,
  RhythmLine.restartC,
];

/// Başlığı seçer. Dönüş **haftaya bağlı ve belirlenimci**: aynı hafta içinde
/// her açılışta aynı cümle (titreşmez), hafta değişince yenisi.
/// [weekIndex]: bu haftanın sırası (ör. yılın haftası) — seri 0 iken dönüş
/// kaynağı.
RhythmHeadline rhythmHeadline(WeeklyStreak s, {required int weekIndex}) {
  final n = s.weeks;
  switch (rhythmStateOf(s)) {
    case RhythmState.empty:
      return (line: RhythmLine.start, n: 0);
    case RhythmState.firstWeek:
      return (
        line: s.remaining == 1
            ? RhythmLine.firstWeekLastOne
            : RhythmLine.firstWeek,
        n: 0,
      );
    case RhythmState.weekDone:
      final m = _milestones[n];
      return (line: m ?? _donePool[n % _donePool.length], n: n);
    case RhythmState.ongoing:
      if (s.remaining == 1) return (line: RhythmLine.ongoingLastOne, n: n);
      return (line: _ongoingPool[n % _ongoingPool.length], n: n);
    case RhythmState.restart:
      return (line: _restartPool[weekIndex % _restartPool.length], n: 0);
  }
}
