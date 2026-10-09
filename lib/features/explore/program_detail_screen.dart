import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/providers.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/app_state_views.dart';
import 'program_catalog.dart';
import 'program_install.dart';
import 'program_labels.dart';
import '../../shared/widgets/fitpack_icon.dart';

/// Hazır program detayı (docs/28): ne olduğu, kime uygun, rutinler ve
/// hareketler (set × tekrar). "Programı ekle" rutinleri kullanıcının
/// rutinlerine kopyalar; ikinci kez eklemede açıkça sorar.
class ProgramDetailScreen extends ConsumerStatefulWidget {
  final String programKey;
  const ProgramDetailScreen({super.key, required this.programKey});

  @override
  ConsumerState<ProgramDetailScreen> createState() =>
      _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends ConsumerState<ProgramDetailScreen> {
  bool _adding = false;

  Future<void> _add(CatalogProgram p, bool installed) async {
    final l = AppL10n.of(context);
    if (installed) {
      final again = await confirmAction(
        context,
        title: l.exAddAgainTitle,
        message: l.exAddAgainMsg,
        confirmLabel: l.exAddAgain,
      );
      if (!again || !mounted) return;
    }
    setState(() => _adding = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await installCatalogProgram(ref.read(workoutDaoProvider), l, p);
    } catch (_) {
      if (mounted) setState(() => _adding = false);
      messenger.showSnackBar(SnackBar(content: Text(l.exAddError)));
      return;
    }
    // Rutin listesi reaktif (H-05) → yeni rutinler kendiliğinden görünür.
    messenger.showSnackBar(
        SnackBar(content: Text(l.exAdded(l.programTitle(p)))));
    if (mounted) context.go(AppRoutes.workout);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final p = programByKey(widget.programKey);
    if (p == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.exploreTitle)),
        body: ErrorState(message: l.exAddError),
      );
    }
    final installed =
        ref.watch(installedProgramsProvider).valueOrNull?.contains(p.key) ??
            false;
    final c = context.colors;
    final muted = c.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: Text(l.programTitle(p))),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
          child: FilledButton.icon(
            onPressed: _adding ? null : () => _add(p, installed),
            icon: _adding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : FitPackIcon.material(installed
                    ? Icons.check_circle_rounded
                    : Icons.add_rounded),
            label: Text(installed ? l.exInList : l.exAddProgram),
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _Pill(Icons.signal_cellular_alt_rounded, l.programLevel(p.level)),
              _Pill(Icons.calendar_today_rounded,
                  l.exDaysPerWeek(p.daysPerWeek)),
              _Pill(Icons.list_alt_rounded,
                  l.exRoutineCount(p.routines.length)),
            ],
          ),
          AppSpacing.vGapLg,
          Text(l.programSplitDesc(p.split), style: context.texts.bodyLarge),
          AppSpacing.vGapSm,
          Text(l.programLevelDesc(p.level),
              style: context.texts.bodyMedium?.copyWith(color: muted)),
          AppSpacing.vGapMd,
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.08),
              borderRadius: AppRadius.brMd,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FitPackIcon.material(Icons.lightbulb_outline_rounded,
                    size: AppIconSize.sm, color: c.primary),
                AppSpacing.hGapSm,
                Expanded(
                    child: Text(l.exHowTo, style: context.texts.bodySmall)),
              ],
            ),
          ),
          AppSpacing.vGapLg,
          for (final r in p.routines)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.catalogRoutineName(r.name),
                        style: context.texts.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    AppSpacing.vGapSm,
                    for (final e in r.exercises)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 72,
                              child: Text(
                                  '${e.sets} × ${e.repsMin}–${e.repsMax}',
                                  style: context.texts.bodySmall?.copyWith(
                                      color: c.primary,
                                      fontWeight: FontWeight.w700,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ])),
                            ),
                            Expanded(
                              child: Text(e.name,
                                  style: context.texts.bodyMedium),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Pill(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: context.colors.onSurface.withValues(alpha: 0.06),
        borderRadius: AppRadius.brLg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FitPackIcon.material(icon, size: AppIconSize.sm, color: context.colors.primary),
          AppSpacing.hGapXs,
          Text(text,
              style: context.texts.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
