import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Antrenman planı (assets/data/workout_plan.json) — tüm fazlar.
final workoutPlanProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final jsonStr =
      await rootBundle.loadString('assets/data/workout_plan.json');
  return json.decode(jsonStr) as Map<String, dynamic>;
});

/// Antrenman tipi → görünen ad (FullA → "Full Body A"). Tüm fazları kapsar;
/// geçmiş ekranı eski fazlardan seans gösterebilir.
final workoutDisplayNamesProvider =
    FutureProvider<Map<String, String>>((ref) async {
  final plan = await ref.watch(workoutPlanProvider.future);
  final names = <String, String>{};
  for (final phase in plan['phases'] as List<dynamic>) {
    for (final workout in phase['workouts'] as List<dynamic>) {
      names[workout['type'] as String] = workout['name'] as String;
    }
  }
  return names;
});

/// Tipin görünen adı — harita yüklenmediyse ham tipe düşer.
String workoutDisplayName(Map<String, String>? names, String type) =>
    names?[type] ?? type;

/// Bugünün antrenman durumu — Home'un durum-duyarlı kartı için.
/// Plan günleri Türkçe (Pazartesi..Cumartesi). Bugün plana uyuyorsa
/// [today] dolu (antrenman günü); değilse null (dinlenme) + [next] sıradaki.
class TodayWorkout {
  final Map<String, dynamic>? today; // bugünün antrenmanı (yoksa dinlenme)
  final Map<String, dynamic>? next; // sıradaki antrenman (dinlenme günü için)
  const TodayWorkout({this.today, this.next});

  bool get isRestDay => today == null;
}

/// DateTime.weekday (1=Pzt..7=Paz) → plan JSON'daki Türkçe gün adı.
const _weekdayToTr = {
  1: 'Pazartesi',
  2: 'Sali',
  3: 'Carsamba',
  4: 'Persembe',
  5: 'Cuma',
  6: 'Cumartesi',
  7: 'Pazar',
};

/// Aktif fazın bugünkü / sıradaki antrenmanını çözer.
final todayWorkoutProvider = FutureProvider.family<TodayWorkout, int>(
    (ref, currentPhase) async {
  final plan = await ref.watch(workoutPlanProvider.future);
  final phases = plan['phases'] as List<dynamic>;
  final phase = phases.firstWhere(
    (p) => p['phase'] == currentPhase,
    orElse: () => phases.first,
  );
  final workouts = (phase['workouts'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  if (workouts.isEmpty) return const TodayWorkout();

  // Gün adı → antrenman haritası.
  final byDay = <String, Map<String, dynamic>>{
    for (final w in workouts) (w['day'] as String): w,
  };

  final todayName = _weekdayToTr[DateTime.now().weekday];
  final today = byDay[todayName];

  // Sıradaki: bugünden sonraki ilk antrenman günü (hafta döngüsel).
  Map<String, dynamic>? next;
  for (var i = 1; i <= 7; i++) {
    final wd = (DateTime.now().weekday - 1 + i) % 7 + 1;
    final name = _weekdayToTr[wd];
    if (byDay.containsKey(name)) {
      next = byDay[name];
      break;
    }
  }

  return TodayWorkout(today: today, next: next);
});
