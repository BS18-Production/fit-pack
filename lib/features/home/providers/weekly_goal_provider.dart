import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/prefs/week_start_provider.dart';
import '../../../core/utils/current_day.dart';
import '../../../data/providers.dart';
import '../../cloud/auth_service.dart';
import '../../goals/weekly_target_history.dart';
import '../../workout/routine_providers.dart';
import '../weekly_goal.dart';

export '../../goals/weekly_target_history.dart';

/// Hesap kimliği bağımlılığı testte de aynı sınırla değiştirilir.
final weeklyGoalAccountProvider = Provider<String?>(
  (ref) => ref.watch(currentUserProvider)?.id,
);

/// Testte saati sabitlemek, eski haftaların yeni hedefle yeniden
/// yorumlanmadığını gerçekten sınamayı sağlar.
final weeklyTargetTodayProvider = Provider<DateTime>(
  (ref) => ref.watch(currentDayProvider),
);

typedef WeeklyTargetWrite =
    Future<bool> Function(SharedPreferences prefs, String key, String value);

/// Disk başarısızlığını iş verisi/hesap katmanını taklit etmeden sınamak
/// için tek yazma sınırı. Başarı dönmeden sağlayıcı yeni hedef yayımlamaz.
final weeklyTargetWriteProvider = Provider<WeeklyTargetWrite>(
  (ref) =>
      (prefs, key, value) => prefs.setString(key, value),
);

class WeeklyTargetHistoryController
    extends AsyncNotifier<WeeklyTargetHistory?> {
  Future<void> _pending = Future.value();
  int _accountGeneration = 0;

  static String storageKey(String account) =>
      'weekly_target_history_v1_$account';

  @override
  Future<WeeklyTargetHistory?> build() async {
    _accountGeneration++;
    final id = ref.watch(weeklyGoalAccountProvider);
    if (id == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey(id));
    return raw == null ? null : WeeklyTargetHistory.fromJson(jsonDecode(raw));
  }

  Future<void> _update(
    Future<WeeklyTargetHistory> Function(WeeklyTargetHistory?, String)
    transform, {
    String? expectedAccount,
  }) {
    final id = ref.read(weeklyGoalAccountProvider);
    if (id == null) throw StateError('Haftalık hedef için oturum gerekli');
    if (expectedAccount != null && expectedAccount != id) {
      throw StateError('Hedefi düzenlediğin hesap değişti');
    }
    final generation = _accountGeneration;
    final operation = _pending.then((_) async {
      if (ref.read(weeklyGoalAccountProvider) != id ||
          generation != _accountGeneration) {
        throw StateError('Hedef kaydedilirken hesap değişti');
      }
      final current = await future;
      final next = await transform(current, id);
      if (ref.read(weeklyGoalAccountProvider) != id ||
          generation != _accountGeneration) {
        throw StateError('Hedef kaydedilirken hesap değişti');
      }
      final encoded = jsonEncode(next.toJson());
      if (current != null && jsonEncode(current.toJson()) == encoded) return;
    final prefs = await SharedPreferences.getInstance();
      if (ref.read(weeklyGoalAccountProvider) != id ||
          generation != _accountGeneration) {
        throw StateError('Hedef kaydedilirken hesap değişti');
      }
      final write = ref.read(weeklyTargetWriteProvider);
      if (!await write(prefs, storageKey(id), encoded)) {
      throw StateError('Haftalık hedef kaydedilemedi');
    }
      if (ref.read(weeklyGoalAccountProvider) == id &&
          generation == _accountGeneration) {
        state = AsyncData(next);
      }
    });
    // Başarısız bir yazma sonraki tekrar denemeleri kilitlemez.
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  /// Kurulumun açık seçimini ilk kez bu haftadan başlatır. Tarihçe varsa
  /// bu API onu yeniden yazamaz; sonraki seçim scheduleGoal ile yapılır.
  Future<void> initialize(
    int goal, {
    String? expectedAccount,
    bool allowIncompleteOnboardingRetry = false,
  }) {
    validateWeeklyTarget(goal);
    return _update((history, _) async {
      final today = ref.read(weeklyTargetTodayProvider);
      final week = startOfWeek(today, ref.read(weekStartProvider));
      if (history != null && history.revisions.isNotEmpty) {
        if (history.targetFor(today) == goal) return history;
        if (allowIncompleteOnboardingRetry) {
          final profile = await ref.read(userProfileDaoProvider).getProfile();
          final active = history.revisionFor(today);
          final hasFuture = history.revisions.any(
            (revision) =>
                revision.effectiveWeekStart.isAfter(targetDate(today)),
          );
          if (profile?.onboarded != true && !hasFuture) {
            // Profili tamamlayamayan kurulumun düzeltmesi. Geçmiş hafta
            // revizyonları korunur; aynı haftadaki ilk kayıt yerinde düzelir.
            final replaceDate =
                active != null && !active.effectiveWeekStart.isBefore(week)
                ? active.effectiveWeekStart
                : week;
            return WeeklyTargetHistory([
              for (final revision in history.revisions)
                if (revision.effectiveWeekStart != replaceDate) revision,
              WeeklyTargetRevision(
                effectiveWeekStart: replaceDate,
                targetDays: goal,
              ),
            ]);
          }
        }
        throw StateError(
          'Mevcut hedef yalnız gelecek hafta için değiştirilebilir',
        );
      }
      return WeeklyTargetHistory([
        WeeklyTargetRevision(effectiveWeekStart: week, targetDays: goal),
      ]);
    }, expectedAccount: expectedAccount);
  }

  Future<void> scheduleGoal(int goal, {String? expectedAccount}) {
    validateWeeklyTarget(goal);
    return _update((history, id) async {
      final week = startOfWeek(
        ref.read(weeklyTargetTodayProvider),
        ref.read(weekStartProvider),
      );
      var current = history ?? WeeklyTargetHistory([]);
      if (current.targetFor(ref.read(weeklyTargetTodayProvider)) == null) {
        final prefs = await SharedPreferences.getInstance();
        final routines = await ref.read(activeRoutinesProvider.future);
        // Yalnız bugün bilinen eski seçimin/programın anlık görüntüsü;
        // daha eski haftalar hakkında hiçbir iddia yaratmaz.
        final legacy = resolveKnownWeeklyGoal(
          selected: prefs.getInt('weekly_goal_v1_$id'),
          routines: routines,
        );
        if (legacy != null) {
          current = WeeklyTargetHistory([
            ...current.revisions,
            WeeklyTargetRevision(effectiveWeekStart: week, targetDays: legacy),
          ]);
        }
      }
      return current.schedule(
        currentWeekStart: week,
        effectiveWeekStart: DateTime(week.year, week.month, week.day + 7),
        targetDays: goal,
      );
    }, expectedAccount: expectedAccount);
  }
}

final weeklyTargetHistoryProvider =
    AsyncNotifierProvider<WeeklyTargetHistoryController, WeeklyTargetHistory?>(
      WeeklyTargetHistoryController.new,
    );

class SelectedWeeklyGoal extends AsyncNotifier<int?> {
  @override
  Future<int?> build() async {
    final id = ref.watch(weeklyGoalAccountProvider);
    if (id == null) return null;
    final historyFuture = ref.watch(weeklyTargetHistoryProvider.future);
    final today = ref.watch(weeklyTargetTodayProvider);
    final history = await historyFuture;
    final target = history?.targetFor(today);
    if (target != null) return target;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('weekly_goal_v1_$id');
  }

  void _checkOwner(String? expectedAccount) {
    final id = ref.read(weeklyGoalAccountProvider);
    if (id == null || (expectedAccount != null && id != expectedAccount)) {
      throw StateError('Hedefi düzenlediğin hesap değişti');
    }
  }

  Future<void> setGoal(
    int goal, {
    String? expectedAccount,
    bool allowIncompleteOnboardingRetry = false,
  }) async {
    _checkOwner(expectedAccount);
    await ref
        .read(weeklyTargetHistoryProvider.notifier)
        .initialize(
          goal,
          expectedAccount: expectedAccount,
          allowIncompleteOnboardingRetry: allowIncompleteOnboardingRetry,
        );
  }

  Future<void> scheduleGoal(int goal, {String? expectedAccount}) async {
    _checkOwner(expectedAccount);
    await ref
        .read(weeklyTargetHistoryProvider.notifier)
        .scheduleGoal(goal, expectedAccount: expectedAccount);
  }
}

final selectedWeeklyGoalProvider =
    AsyncNotifierProvider<SelectedWeeklyGoal, int?>(SelectedWeeklyGoal.new);

final weeklyGoalProvider = FutureProvider<int>((ref) async {
  final selected = ref.watch(selectedWeeklyGoalProvider.future);
  final routines = ref.watch(activeRoutinesProvider.future);
  return resolveWeeklyGoal(selected: await selected, routines: await routines);
});

final weeklyTargetForPeriodProvider =
    FutureProvider.family<WeeklyTargetPeriod, DateTime>((
      ref,
      periodStart,
    ) async {
      final history = ref.watch(weeklyTargetHistoryProvider.future);
      final selected = ref.watch(selectedWeeklyGoalProvider.future);
      final routines = ref.watch(activeRoutinesProvider.future);
      final today = ref.watch(weeklyTargetTodayProvider);
      final current = startOfWeek(today, ref.watch(weekStartProvider));
      return resolveWeeklyTargetPeriod(
        periodStart: periodStart,
        currentWeekStart: current,
        currentDate: today,
        history: await history,
        legacyCurrentGoal: resolveKnownWeeklyGoal(
          selected: await selected,
          routines: await routines,
        ),
      );
    });

final currentWeeklyTargetProvider = FutureProvider<WeeklyTargetPeriod>((ref) {
  final week = startOfWeek(
    ref.watch(weeklyTargetTodayProvider),
    ref.watch(weekStartProvider),
  );
  return ref.watch(weeklyTargetForPeriodProvider(week).future);
});

final nextWeeklyTargetProvider = FutureProvider<WeeklyTargetPeriod>((ref) {
  final week = startOfWeek(
    ref.watch(weeklyTargetTodayProvider),
    ref.watch(weekStartProvider),
  );
  return ref.watch(
    weeklyTargetForPeriodProvider(
      DateTime(week.year, week.month, week.day + 7),
    ).future,
  );
});
