import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/formatting.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/fitpack_icon.dart';
import '../../shared/widgets/setting_tiles.dart';
import 'body_consent_sheet.dart';
import 'body_providers.dart';
import 'health_prefs.dart';
import 'step_providers.dart';
import 'step_sheets.dart';

/// Sağlık bağlantısı ve isteğe bağlı hedef; platform yoksa bölüm de yok.
class HealthSettingsSection extends ConsumerStatefulWidget {
  const HealthSettingsSection({super.key});

  @override
  ConsumerState<HealthSettingsSection> createState() =>
      _HealthSettingsSectionState();
}

class _HealthSettingsSectionState extends ConsumerState<HealthSettingsSection> {
  bool _busy = false;

  Future<void> _changeConnection({required bool install}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (install) {
        await ref.read(stepSourceProvider).openInstall();
      } else {
        await disconnectSteps(ref);
      }
    } catch (_) {
      if (mounted) {
        final l = AppL10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              install ? l.healthInstallError : l.healthDisconnectError,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final link = ref.watch(stepLinkStateProvider).valueOrNull;
    if (link == null || link == StepLinkState.unavailable) {
      return const SizedBox.shrink();
    }
    final goal = ref.watch(healthPrefsProvider).stepGoal;
    final connected = link == StepLinkState.connected;
    return SettingsSection(
      key: const ValueKey('health.settings'),
      title: l.healthSection,
      children: [
        SettingTile(
          icon: Icons.directions_walk_rounded,
          title: l.healthConnection,
          subtitle: switch (link) {
            StepLinkState.connected => l.healthConnected,
            StepLinkState.notConnected => l.healthNotConnected,
            StepLinkState.needsInstall => l.healthInstall,
            StepLinkState.unavailable => null,
          },
          trailing: const FitPackIcon.material(Icons.chevron_right_rounded),
          onTap: _busy
              ? null
              : () {
                  if (link == StepLinkState.needsInstall) {
                    _changeConnection(install: true);
                  } else if (connected) {
                    showStepWeekSheet(context);
                  } else {
                    showStepPermissionSheet(context);
                  }
                },
        ),
        if (connected)
          SettingTile(
            key: const ValueKey('health.disconnect'),
            icon: Icons.link_off_rounded,
            title: l.healthDisconnect,
            subtitle: l.healthDisconnectNote,
            onTap: _busy ? null : () => _changeConnection(install: false),
          ),
        // Tartıdan kilo + yağ oranı (docs/40): açık rıza ile açılır, tek
        // dokunuşla geri alınır (docs/41 §3).
        if (link != StepLinkState.needsInstall)
          SettingTile(
            key: const ValueKey('health.weightConsent'),
            icon: Icons.monitor_weight_outlined,
            title: l.healthWeightRow,
            subtitle: ref.watch(healthConsentProvider)
                ? l.healthWeightOn
                : l.healthWeightOff,
            trailing: const FitPackIcon.material(Icons.chevron_right_rounded),
            onTap: _busy
                ? null
                : () => ref.read(healthConsentProvider)
                      ? showBodyConsentWithdrawDialog(context, ref)
                      : showBodyConsentSheet(context),
          ),
        if (link != StepLinkState.needsInstall)
          SettingTile(
            key: const ValueKey('health.writeWorkouts'),
            icon: Icons.fitness_center_rounded,
            title: l.healthWriteWorkouts,
            subtitle: l.healthWriteWorkoutsNote,
            trailing: Switch(
              value: ref.watch(healthPrefsProvider).writeWorkouts,
              onChanged: _busy
                  ? null
                  : (v) async {
                      // Açarken yazma izni istenir (docs/44 H-4).
                      if (v) {
                        await ref.read(workoutSinkProvider).requestWriteAccess();
                      }
                      await ref
                          .read(healthPrefsProvider.notifier)
                          .setWriteWorkouts(v);
                    },
            ),
          ),
        SettingTile(
          key: const ValueKey('health.goalSetting'),
          icon: Icons.flag_outlined,
          title: l.healthStepGoal,
          // Uzun değer sağda sıkışmaz; dar/büyük metinde de sarılır.
          subtitle: goal == null
              ? l.healthNoGoal
              : l.healthStepCount(context.numFmt.format(goal)),
          trailing: const FitPackIcon.material(Icons.chevron_right_rounded),
          onTap: () => showStepGoalSheet(context),
        ),
      ],
    );
  }
}
