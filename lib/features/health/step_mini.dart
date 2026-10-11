import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/formatting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/fitpack_icon.dart';
import '../../shared/widgets/glass.dart';
import 'step_providers.dart';
import 'step_sheets.dart';
import 'step_stats.dart';

/// Ana Sayfa'nın su/kilo hücreleriyle aynı yüzey ve ikon dili (docs/39).
class StepMini extends ConsumerStatefulWidget {
  final StepLinkState link;
  const StepMini({super.key, required this.link});

  @override
  ConsumerState<StepMini> createState() => _StepMiniState();
}

class _StepMiniState extends ConsumerState<StepMini> {
  bool _installing = false;

  Future<void> _install() async {
    if (_installing) return;
    setState(() => _installing = true);
    try {
      await ref.read(stepSourceProvider).openInstall();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppL10n.of(context).healthInstallError)),
        );
      }
    } finally {
      if (mounted) setState(() => _installing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.link == StepLinkState.unavailable) {
      return const SizedBox.shrink();
    }
    final l = AppL10n.of(context);
    final c = context.colors;
    final week = widget.link == StepLinkState.connected
        ? ref.watch(stepWeekProvider)
        : null;
    final data = week?.valueOrNull;
    final progress = data?.todayProgress;
    final VoidCallback? onTap = switch (widget.link) {
      StepLinkState.unavailable => null,
      StepLinkState.needsInstall => _installing ? null : _install,
      StepLinkState.notConnected => () => showStepPermissionSheet(context),
      StepLinkState.connected => () => showStepWeekSheet(context),
    };

    return GlassCard(
      key: const ValueKey('health.stepMini'),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppIconSize.md + AppSpacing.sm + 2,
                height: AppIconSize.md + AppSpacing.sm + 2,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: .16),
                  borderRadius: AppRadius.brSm,
                ),
                child: FitPackIcon.material(
                  Icons.directions_walk_rounded,
                  color: c.primary,
                  size: AppIconSize.sm,
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(l.healthSteps, style: context.texts.titleSmall),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          if (widget.link == StepLinkState.needsInstall)
            Text(
              l.healthInstall,
              style: context.texts.titleSmall?.copyWith(color: c.primary),
            )
          else if (widget.link == StepLinkState.notConnected)
            Text(
              l.healthSeeSteps,
              style: context.texts.titleSmall?.copyWith(color: c.primary),
            )
          else ...[
            Text(
              data?.today == null ? '—' : context.numFmt.format(data!.today),
              key: const ValueKey('health.today'),
              style: context.texts.headlineSmall,
            ),
            if (data?.state == StepWeekState.noData) ...[
              AppSpacing.vGapXs,
              Text(
                l.healthNoData,
                style: context.texts.bodySmall?.copyWith(
                  color: c.onSurfaceVariant,
                ),
              ),
            ] else if (week?.hasError ?? false) ...[
              AppSpacing.vGapXs,
              Text(
                l.healthReadError,
                style: context.texts.bodySmall?.copyWith(
                  color: c.onSurfaceVariant,
                ),
              ),
            ],
            if (progress != null) ...[
              AppSpacing.vGapMd,
              ClipRRect(
                borderRadius: AppRadius.brSm,
                child: LinearProgressIndicator(
                  key: const ValueKey('health.progress'),
                  value: progress.clamp(0.0, 1.0),
                  minHeight: AppSpacing.xs,
                  backgroundColor: c.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(c.primary),
                  semanticsLabel: l.healthStepGoal,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
