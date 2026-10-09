import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import 'program_catalog.dart';
import 'program_install.dart';
import 'program_labels.dart';
import '../../shared/widgets/fitpack_icon.dart';

/// Keşfet (docs/28): Antrenman sekmesinde hazır programlar — seviye çipiyle
/// süzülen yatay kart şeridi. Karta dokununca program detayı açılır.
class ExploreSection extends ConsumerStatefulWidget {
  const ExploreSection({super.key});

  @override
  ConsumerState<ExploreSection> createState() => _ExploreSectionState();
}

class _ExploreSectionState extends ConsumerState<ExploreSection> {
  static const _cardHeight = 160.0;
  ProgramLevel _level = ProgramLevel.beginner;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final installed = ref.watch(installedProgramsProvider).valueOrNull ?? {};
    final programs =
        programCatalog.where((p) => p.level == _level).toList();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              FitPackIcon.material(Icons.explore_rounded,
                  size: AppIconSize.md, color: context.colors.primary),
              AppSpacing.hGapSm,
              Text(l.exploreTitle, style: context.texts.titleMedium),
            ],
          ),
          AppSpacing.vGapXs,
          Text(l.exSubtitle,
              style: context.texts.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant)),
          AppSpacing.vGapMd,
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final lv in ProgramLevel.values)
                ChoiceChip(
                  label: Text(l.programLevel(lv)),
                  selected: _level == lv,
                  onSelected: (_) => setState(() => _level = lv),
                ),
            ],
          ),
          AppSpacing.vGapMd,
          SizedBox(
            // Büyük metinde kart taşmasın: yükseklik metin ölçeğiyle büyür.
            height: MediaQuery.textScalerOf(context).scale(_cardHeight),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: programs.length,
              separatorBuilder: (_, _) => AppSpacing.hGapMd,
              itemBuilder: (context, i) => _ProgramCard(
                key: ValueKey(programs[i].key),
                program: programs[i],
                installed: installed.contains(programs[i].key),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final CatalogProgram program;
  final bool installed;
  const _ProgramCard(
      {super.key, required this.program, required this.installed});

  static const _width = 220.0;

  IconData get _icon => switch (program.split) {
        ProgramSplit.fullBody => Icons.accessibility_new_rounded,
        ProgramSplit.upperLower => Icons.swap_vert_rounded,
        ProgramSplit.ppl => Icons.view_week_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.colors;
    return SizedBox(
      width: _width,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(AppRoutes.program(program.key)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.14),
                        borderRadius: AppRadius.brMd,
                      ),
                      child: FitPackIcon.material(_icon,
                          color: c.primary, size: AppIconSize.md),
                    ),
                    const Spacer(),
                    if (installed)
                      Tooltip(
                        message: l.exInList,
                        child: FitPackIcon.material(Icons.check_circle_rounded,
                            size: AppIconSize.sm,
                            color: context.semantic.success),
                      ),
                  ],
                ),
                AppSpacing.vGapMd,
                Text(l.programSplit(program.split),
                    style: context.texts.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(l.programLevel(program.level),
                    style: context.texts.bodySmall?.copyWith(
                        color: c.primary, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(
                  '${l.exDaysPerWeek(program.daysPerWeek)} · '
                  '${l.exRoutineCount(program.routines.length)}',
                  style: context.texts.bodySmall
                      ?.copyWith(color: c.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
