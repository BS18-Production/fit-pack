import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/current_day.dart';
import '../../data/database/app_database.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';
import '../workout/routine_providers.dart';
import '../workout/workout_draft.dart';

/// Ana sayfanın TEK birincil görevi (docs/54 §2). Öncelik tablosu yukarıdan
/// aşağı okunur, ilk eşleşen kazanır. "Haftan hazır" ve "İlk hafta" bu
/// listede yok — birincilin altında ikincil kart olarak kalırlar.
enum TodayTaskKind {
  loading, // taslak ya da rutin okunuyor — yeni "Başlat" sunulmaz
  draftError, // taslak okunamadı (Faz 1a) — tekrar dene
  resume, // süren seans
  finishedToday, // bugün antrenman bitti → özet (D1)
  routineError, // rutinler okunamadı — tekrar dene
  plannedToday, // bugüne planlı rutin
  restDay, // planlı dinlenme günü
  upNext, // güne bağlı rutin yok, döngüde sıradaki
  noRoutine, // hiç rutin yok → program seç / rutin kur
}

class TodayTask {
  final TodayTaskKind kind;
  final WorkoutDraft? draft;
  final WorkoutSession? session;
  final Routine? routine;
  final String? nextName; // dinlenme gününde sıradaki planlı rutin
  const TodayTask(this.kind,
      {this.draft, this.session, this.routine, this.nextName});
}

/// Saf karar fonksiyonu — widget ve sağlayıcıdan bağımsız test edilir.
TodayTask todayTask({
  required bool draftLoading,
  required bool draftError,
  required WorkoutDraft? draft,
  required WorkoutSession? finishedToday,
  required bool routineLoading,
  required bool routineError,
  required TodayRoutine? routine,
}) {
  if (draftLoading) return const TodayTask(TodayTaskKind.loading);
  if (draftError) return const TodayTask(TodayTaskKind.draftError);
  if (draft != null) return TodayTask(TodayTaskKind.resume, draft: draft);
  if (finishedToday != null) {
    return TodayTask(TodayTaskKind.finishedToday, session: finishedToday);
  }
  if (routineLoading) return const TodayTask(TodayTaskKind.loading);
  if (routineError) return const TodayTask(TodayTaskKind.routineError);
  final tr = routine;
  if (tr == null) return const TodayTask(TodayTaskKind.noRoutine);
  if (tr.today != null) {
    return TodayTask(TodayTaskKind.plannedToday, routine: tr.today);
  }
  if (tr.next != null) {
    return TodayTask(TodayTaskKind.restDay, nextName: tr.next!.name);
  }
  if (tr.upNext != null) {
    return TodayTask(TodayTaskKind.upNext, routine: tr.upNext);
  }
  return const TodayTask(TodayTaskKind.noRoutine);
}

/// Bugün kaydedilmiş en son seans (yoksa null) — "bugün tamam" görevi için.
/// Tarih aralığı `[bugün, yarın)` (CONVENTIONS §3).
final todayFinishedSessionProvider = StreamProvider<WorkoutSession?>((ref) {
  final db = ref.watch(databaseProvider);
  final day = ref.watch(currentDayProvider);
  return watchTables(db, [db.workoutSessions], () async {
    final start = DateTime(day.year, day.month, day.day);
    final sessions = await ref
        .read(workoutDaoProvider)
        .getSessionsByDateRange(start, start.add(const Duration(days: 1)));
    return sessions.isEmpty ? null : sessions.first;
  });
});

/// Ekrandaki birincil görev: [todayTask]'ı canlı sağlayıcılarla besler.
final todayTaskProvider = Provider.autoDispose<TodayTask>((ref) {
  final draft = ref.watch(activeDraftProvider);
  final done = ref.watch(todayFinishedSessionProvider);
  final routine = ref.watch(todayRoutineProvider);
  return todayTask(
    // Yenilemede eski değer dururken iskelete düşme — kart titremesin.
    draftLoading: draft.isLoading && !draft.hasValue,
    draftError: draft.hasError,
    draft: draft.valueOrNull,
    finishedToday: done.valueOrNull,
    routineLoading: routine.isLoading && !routine.hasValue,
    routineError: routine.hasError,
    routine: routine.valueOrNull,
  );
});
