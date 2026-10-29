import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/setting_tiles.dart';
import '../cloud/auth_service.dart';
import 'analytics_providers.dart';

/// Açık tercih yalnız ürün ölçümü içindir; bildirim/pazarlama izni değildir.
class AnalyticsSettingsSection extends ConsumerWidget {
  const AnalyticsSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final analytics = ref.watch(analyticsControllerProvider);
    return SettingsSection(
      title: l.analyticsSectionTitle,
      children: [
        SwitchListTile.adaptive(
          key: const ValueKey('analytics.optIn'),
          title: Text(l.analyticsSwitchTitle),
          subtitle: Text(
            analytics.available
                ? l.analyticsSwitchDescription
                : l.analyticsNotAvailable,
          ),
          value: analytics.enabled,
          onChanged:
              analytics.busy || (!analytics.available && !analytics.enabled)
              ? null
              : (enabled) async {
                  final owner = analytics.ownerId;
                  final messenger = ScaffoldMessenger.of(context);
                  if (enabled) {
                    final accepted = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: Text(l.analyticsConsentTitle),
                        content: SingleChildScrollView(
                          child: Text(l.analyticsConsentDescription),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: Text(l.commonCancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: Text(l.analyticsConsentAccept),
                          ),
                        ],
                      ),
                    );
                    if (accepted != true) return;
                  }
                  if (!context.mounted ||
                      owner == null ||
                      analytics.ownerId != owner ||
                      ref.read(currentUserProvider)?.id != owner) {
                    return;
                  }
                  final ok = await analytics.setEnabled(enabled);
                  if (!context.mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? (enabled
                                  ? l.analyticsEnabled
                                  : l.analyticsDisabled)
                            : l.analyticsPreferenceError,
                      ),
                    ),
                  );
                },
        ),
        if (!analytics.available && analytics.ownerId != null)
          TextButton(
            key: const ValueKey('analytics.withdraw'),
            onPressed: analytics.busy
                ? null
                : () async {
                    final owner = analytics.ownerId;
                    if (owner == null ||
                        ref.read(currentUserProvider)?.id != owner) {
                      return;
                    }
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await analytics.setEnabled(false);
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          ok ? l.analyticsDisabled : l.analyticsPreferenceError,
                        ),
                      ),
                    );
                  },
            child: Text(l.analyticsWithdraw),
          ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            l.analyticsPurposeBoundary,
            style: context.texts.bodySmall,
          ),
        ),
      ],
    );
  }
}
