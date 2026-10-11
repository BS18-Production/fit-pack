import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/formatting.dart';
import '../../core/prefs/week_start_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/providers.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/glass.dart';
import 'assistant_contract.dart';
import 'assistant_labels.dart';
import 'assistant_providers.dart';
import 'assistant_quality.dart';

class AssistantQualityScreen extends ConsumerWidget {
  const AssistantQualityScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context), events = ref.watch(assistantQualityProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.assistantQuality)),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            Text(l.assistantQualityInfo),
            AppSpacing.vGapLg,
            events.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Text(l.assistantError),
              data: (list) {
                final s = assistantQualityStats(
                  list,
                  DateTime.now(),
                  weekStart: ref.watch(weekStartProvider),
                );
                String n(num v) => context.numFmt.format(v);
                String query(String id) {
                  for (final q in AssistantQuery.values) {
                    if (q.id == id) return queryLabel(l, q);
                  }
                  return l.assistantNotAvailable;
                }

                String decision(String id) => switch (id) {
                  'auto' => l.assistantDecisionAuto,
                  'clarify' => l.assistantDecisionClarify,
                  'multi' => l.assistantDecisionMulti,
                  'fallback' => l.assistantDecisionFallback,
                  _ => l.assistantDecisionError,
                };
                return GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l.assistantQualityDays,
                        style: context.texts.titleLarge,
                      ),
                      AppSpacing.vGapMd,
                      Text('${l.assistantQualityAuto}: ${n(s.automatic)}'),
                      Text(
                        '${l.assistantQualityCorrections}: ${n(s.corrected)}/${n(s.automatic)}',
                      ),
                      if (s.automatic < 30)
                        Text(
                          l.assistantQualitySmall,
                          style: context.texts.bodySmall,
                        ),
                      if (s.twoWeekWarning)
                        Text(
                          l.assistantQualityWarning,
                          style: context.texts.bodyMedium?.copyWith(
                            color: context.colors.error,
                          ),
                        ),
                      AppSpacing.vGapMd,
                      for (final e in s.decisions.entries)
                        Text('${decision(e.key)}: ${n(e.value)}'),
                      AppSpacing.vGapMd,
                      Text(
                        '${l.assistantQualityLatency}: ${s.medianMs == null ? '—' : n(s.medianMs!)} / ${s.p95Ms == null ? '—' : n(s.p95Ms!)} ms',
                      ),
                      Text(
                        '${l.assistantQualityTokens}: ${n(s.inputTokens)} / ${n(s.outputTokens)}',
                      ),
                      Text(l.assistantQualityFree),
                      AppSpacing.vGapLg,
                      for (final e in s.queries.entries)
                        Text('${query(e.key)}: ${n(e.value)}'),
                      AppSpacing.vGapLg,
                      Text(
                        l.assistantQualityTransitions,
                        style: context.texts.titleMedium,
                      ),
                      for (final e in s.transitions.entries)
                        Text(
                          '${query(e.key.split('→').first)} → ${query(e.key.split('→').last)}: ${n(e.value)}',
                        ),
                    ],
                  ),
                );
              },
            ),
            AppSpacing.vGapLg,
            OutlinedButton(
              onPressed: () async {
                final db = ref.read(databaseProvider);
                final clear = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    content: Text(l.assistantQualityClearConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: Text(l.commonCancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: Text(l.commonDelete),
                      ),
                    ],
                  ),
                );
                if (clear != true) return;
                try {
                  await db.assistantQualityDao.clear();
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.assistantQualityUnavailable)),
                    );
                  }
                }
              },
              child: Text(l.assistantQualityClear),
            ),
          ],
        ),
      ),
    );
  }
}
