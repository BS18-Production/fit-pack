import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_prefs.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/setting_tiles.dart';

/// Bildirim ayarları (docs/16 §5 — B6): dinlenme sayacı + günlük antrenman/su
/// hatırlatıcıları. Anahtar açılırken izin istenir; hatırlatıcılar açılınca /
/// saati değişince hemen (yeniden) zamanlanır, kapatılınca iptal edilir.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<bool> _ensurePermission(BuildContext context, WidgetRef ref) async {
    final ok =
        await ref.read(notificationServiceProvider).requestPermission();
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context).notifPermissionDenied)),
      );
    }
    return ok;
  }

  Future<void> _setRest(
      BuildContext context, WidgetRef ref, bool enabled) async {
    if (enabled && !await _ensurePermission(context, ref)) return;
    if (enabled) {
      // Dinlenme dakik olmalı — Android 12+ özel izni bir kez iste.
      await ref.read(notificationServiceProvider).requestExactAlarmPermission();
    } else {
      await ref.read(notificationServiceProvider).cancelRestDone();
    }
    final prefs = ref.read(notificationPrefsProvider);
    await ref
        .read(notificationPrefsProvider.notifier)
        .update(prefs.copyWith(restEnabled: enabled));
  }

  Future<void> _setWorkout(
      BuildContext context, WidgetRef ref, bool enabled) async {
    if (enabled && !await _ensurePermission(context, ref)) return;
    final prefs = ref.read(notificationPrefsProvider);
    final next = prefs.copyWith(workoutEnabled: enabled);
    await ref.read(notificationPrefsProvider.notifier).update(next);
    if (!context.mounted) return;
    final svc = ref.read(notificationServiceProvider);
    if (enabled) {
      final l = AppL10n.of(context);
      await svc.scheduleDaily(
        id: NotificationService.idWorkout,
        hour: next.workoutHour,
        minute: next.workoutMinute,
        title: l.notifWorkoutTitle,
        body: l.notifWorkoutBody,
      );
    } else {
      await svc.cancel(NotificationService.idWorkout);
    }
  }

  Future<void> _setWater(
      BuildContext context, WidgetRef ref, bool enabled) async {
    if (enabled && !await _ensurePermission(context, ref)) return;
    final prefs = ref.read(notificationPrefsProvider);
    final next = prefs.copyWith(waterEnabled: enabled);
    await ref.read(notificationPrefsProvider.notifier).update(next);
    if (!context.mounted) return;
    final svc = ref.read(notificationServiceProvider);
    if (enabled) {
      final l = AppL10n.of(context);
      await svc.scheduleDaily(
        id: NotificationService.idWater,
        hour: next.waterHour,
        minute: next.waterMinute,
        title: l.notifWaterTitle,
        body: l.notifWaterBody,
      );
    } else {
      await svc.cancel(NotificationService.idWater);
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref, {
    required bool isWorkout,
  }) async {
    final prefs = ref.read(notificationPrefsProvider);
    final current = isWorkout
        ? TimeOfDay(hour: prefs.workoutHour, minute: prefs.workoutMinute)
        : TimeOfDay(hour: prefs.waterHour, minute: prefs.waterMinute);
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null || !context.mounted) return;

    final next = isWorkout
        ? prefs.copyWith(workoutHour: picked.hour, workoutMinute: picked.minute)
        : prefs.copyWith(waterHour: picked.hour, waterMinute: picked.minute);
    await ref.read(notificationPrefsProvider.notifier).update(next);
    if (!context.mounted) return;

    // Açıksa yeni saatle yeniden kur.
    final l = AppL10n.of(context);
    final svc = ref.read(notificationServiceProvider);
    if (isWorkout && next.workoutEnabled) {
      await svc.scheduleDaily(
        id: NotificationService.idWorkout,
        hour: next.workoutHour,
        minute: next.workoutMinute,
        title: l.notifWorkoutTitle,
        body: l.notifWorkoutBody,
      );
    } else if (!isWorkout && next.waterEnabled) {
      await svc.scheduleDaily(
        id: NotificationService.idWater,
        hour: next.waterHour,
        minute: next.waterMinute,
        title: l.notifWaterTitle,
        body: l.notifWaterBody,
      );
    }
  }

  String _fmt(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final prefs = ref.watch(notificationPrefsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsNotifications)),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.timer_outlined),
            title: Text(l.notifRestTimer),
            subtitle: Text(l.notifRestTimerSub),
            value: prefs.restEnabled,
            onChanged: (v) => _setRest(context, ref, v),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.fitness_center_rounded),
            title: Text(l.notifWorkout),
            value: prefs.workoutEnabled,
            onChanged: (v) => _setWorkout(context, ref, v),
          ),
          if (prefs.workoutEnabled)
            SettingTile(
              icon: Icons.schedule_rounded,
              title: l.notifTime,
              value: _fmt(prefs.workoutHour, prefs.workoutMinute),
              onTap: () => _pickTime(context, ref, isWorkout: true),
            ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.water_drop_outlined),
            title: Text(l.notifWater),
            value: prefs.waterEnabled,
            onChanged: (v) => _setWater(context, ref, v),
          ),
          if (prefs.waterEnabled)
            SettingTile(
              icon: Icons.schedule_rounded,
              title: l.notifTime,
              value: _fmt(prefs.waterHour, prefs.waterMinute),
              onTap: () => _pickTime(context, ref, isWorkout: false),
            ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
