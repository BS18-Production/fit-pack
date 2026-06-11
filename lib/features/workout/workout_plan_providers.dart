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
