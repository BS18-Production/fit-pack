import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/formatting.dart';
import '../../core/onboarding/first_run_hints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/units/units.dart';
import '../../data/database/app_database.dart';
import '../../data/providers.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/app_state_views.dart';
import '../explore/explore_section.dart';
import '../explore/program_catalog.dart';
import '../explore/program_labels.dart';
import 'history_card.dart';
import 'history_providers.dart';
import 'routine_providers.dart';
import 'workout_draft.dart';
import 'workout_ui.dart';
import '../../core/router/app_routes.dart';
import '../../shared/widgets/fitpack_icon.dart';

/// Antrenman ana ekranı (Antrenman V2 — Claude Design reskin).
/// Özel header (tarih + başlık + geçmiş/kütüphane), Bu Hafta istatistik kartı,
/// "Boş Antrenman Başlat" gradient CTA, Rutinlerim + kesik çizgili "Yeni Rutin".
class WorkoutListScreen extends ConsumerWidget {
  const WorkoutListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(activeRoutinesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeRoutinesProvider);
          ref.invalidate(weekWorkoutStatsProvider);
        },
        child: ListView(
          // Alt boşluk: içerik buzlu gezinme çubuğunun altından akar.
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            context.bottomScrollInset,
          ),
          children: [
            const _Header(),
            AppSpacing.vGapLg,
            const _ResumeBanner(),
            const _WeekStatsCard(),
            AppSpacing.vGapxl_,
            routinesAsync.when(
              loading: () => Column(
                children: [
                  _routinesHeader(context, null),
                  AppSpacing.vGapSm,
                  Skeleton.card(height: 92),
                  AppSpacing.vGapMd,
                  Skeleton.card(height: 92),
                ],
              ),
              error: (_, _) => ErrorState(
                message: AppL10n.of(context).workoutLoadRoutinesError,
                onRetry: () => ref.invalidate(activeRoutinesProvider),
              ),
              data: (routines) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _routinesHeader(context, routines.length),
                    AppSpacing.vGapSm,
                    if (routines.isEmpty) ...[
                      // Boş halde tek aksiyon yeter (EmptyState kendi
                      // butonunu içeriyor) — altına ayrıca "Yeni Rutin"
                      // eklemek aynı işi iki kez gösterirdi.
                      _NoRoutines(
                        onCreate: () => context.push(AppRoutes.routineNew),
                      ),
                      AppSpacing.vGapSm,
                      const Center(child: _FreeWorkoutButton()),
                    ] else ...[
                      ..._groupedRoutines(context, routines),
                      AppSpacing.vGapXs,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _NewRoutineButton(
                            onTap: () => context.push(AppRoutes.routineNew),
                          ),
                          AppSpacing.vGapSm,
                          const _FreeWorkoutButton(),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
            // İlk-kullanım ipucu (docs/15 §B): sekmeye ilk girişte hazır
            // programları işaret eder; bir kez gösterilir.
            CoachMark(
              hint: FirstRunHint.workout,
              message: (l) => l.hintWorkout,
              child: const ExploreSection(),
            ),
            const _RecentWorkouts(),
            const _ArchivedRoutines(),
          ],
        ),
      ),
    );
  }

  /// Rutinler program adıyla gruplanır (docs/28, Samet'in kararı): önce
  /// kullanıcının kendi rutinleri, sonra her hazır program kendi başlığıyla.
  /// Hiç program yoksa başlık çizilmez — liste eskisi gibi düz.
  List<Widget> _groupedRoutines(BuildContext context, List<Routine> routines) {
    final l = AppL10n.of(context);
    final own = [
      for (final r in routines)
        if (r.programKey == null) r,
    ];
    final byProgram = <String, List<Routine>>{};
    for (final r in routines) {
      final k = r.programKey;
      if (k != null) byProgram.putIfAbsent(k, () => []).add(r);
    }
    Widget card(Routine r) => Padding(
      key: ValueKey('routine-${r.id}'),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: _RoutineCard(routine: r),
    );
    Widget header(String text) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.sm),
      child: Text(
        context.upper(text),
        style: context.texts.labelMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
    return [
      if (byProgram.isNotEmpty && own.isNotEmpty) header(l.workoutOwnRoutines),
      ...own.map(card),
      for (final e in byProgram.entries) ...[
        header(
          programByKey(e.key) == null
              ? e.key
              : l.programTitle(programByKey(e.key)!),
        ),
        ...e.value.map(card),
      ],
    ];
  }

  Widget _routinesHeader(BuildContext context, int? count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppL10n.of(context).workoutMyRoutines,
          style: context.texts.titleMedium,
        ),
        if (count != null && count > 0)
          Text(
            AppL10n.of(context).workoutRoutineCount(count),
            style: context.texts.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────────── Header

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final today = context.dateFmt('EEEE, d MMMM').format(DateTime.now());
    final dateLabel = context.upper(today);
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateLabel,
          style: context.texts.labelSmall?.copyWith(
            color: context.colors.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        AppSpacing.vGapXs,
        Text(l.navWorkout, maxLines: 1, style: context.texts.headlineMedium),
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l.workoutLibrary,
          icon: const FitPackIcon.material(Icons.menu_book_rounded),
          onPressed: () => context.push(AppRoutes.exercises),
        ),
        AppSpacing.hGapXs,
        IconButton(
          tooltip: l.workoutAddPast,
          icon: const FitPackIcon.material(Icons.edit_calendar_rounded),
          onPressed: () => context.push(AppRoutes.workoutLogPast),
        ),
        AppSpacing.hGapXs,
        IconButton(
          tooltip: l.workoutHistory,
          icon: const FitPackIcon.material(Icons.history_rounded),
          onPressed: () => context.push(AppRoutes.workoutHistory),
        ),
      ],
    );
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Büyük metinde başlık kesilmez; üç eylem ayrı satıra geçer.
            if (constraints.maxWidth < AppNavigation.headerInlineWidth ||
                MediaQuery.textScalerOf(context).scale(1) > 1.15) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [heading, AppSpacing.vGapMd, actions],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: heading),
                AppSpacing.hGapSm,
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────── Bu Hafta kartı

class _WeekStatsCard extends ConsumerWidget {
  const _WeekStatsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(weekWorkoutStatsProvider).valueOrNull;
    final sessions = stats?.sessions ?? 0;
    final units = ref.watch(unitsProvider);
    final volume = units.weightFromKg(stats?.volumeKg ?? 0).round();
    final l = AppL10n.of(context);
    final volumeStr = context.numFmt.format(volume);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _Stat(
                  label: l.workoutThisWeekCaps,
                  value: '$sessions',
                  unit: l.homeStatWorkouts,
                ),
              ),
              VerticalDivider(
                width: AppSpacing.lg,
                thickness: 1,
                color: context.colors.outlineVariant,
              ),
              Expanded(
                child: _Stat(
                  label: l.workoutTotalVolumeCaps,
                  value: volumeStr,
                  unit: units.weightUnit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value, unit;
  const _Stat({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.texts.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        AppSpacing.vGapSm,
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.headlineSmall,
              ),
            ),
            AppSpacing.hGapXs,
            Text(
              unit,
              style: context.texts.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────── Boş Antrenman Başlat (CTA)

/// Serbest (rutinsiz) antrenman — eskiden sekmenin en büyük düğmesiydi
/// ("Boş Antrenman Başlat"). Samet sordu: gerekli mi? Kullanım senaryosu var
/// (rutini olmayan yeni kullanıcı, plansız seans, yalnız kardiyo) ama birincil
/// aksiyon değil → ikinci planda küçük düğme; yeri Keşfet'e verildi (docs/28).
class _FreeWorkoutButton extends StatelessWidget {
  const _FreeWorkoutButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.push(AppRoutes.workoutActive),
      icon: const FitPackIcon.material(
        Icons.bolt_rounded,
        size: AppIconSize.sm,
      ),
      label: Text(AppL10n.of(context).exFreeWorkout),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md + 2,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brControl),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── Yeni Rutin (dashed)

// ─────────────────────────────────────────────────────── Son antrenmanlar

/// Son antrenmanlar (docs/31): geçmiş yalnız başlıktaki küçük ikondaydı,
/// "belirgin değil" (Samet, 2026-10-07). Son [_recentCount] seans kartı +
/// "Tümünü gör". Hiç seans yoksa çizilmez.
class _RecentWorkouts extends ConsumerWidget {
  const _RecentWorkouts();

  static const _recentCount = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = ref.watch(workoutHistoryProvider).valueOrNull;
    if (h == null || h.entries.isEmpty) return const SizedBox.shrink();
    final l = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l.whRecentTitle, style: context.texts.titleMedium),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.workoutHistory),
                child: Text(l.whSeeAll),
              ),
            ],
          ),
          AppSpacing.vGapXs,
          for (final e in h.entries.take(_recentCount))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: HistoryCard(
                key: ValueKey('recent-${e.session.id}'),
                entry: e,
                exercisesById: h.exercisesById,
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────── Arşiv

/// Arşivdeki rutinler — listenin altında kapalı duran bölüm. Arşivlenen rutin
/// önceden uygulamada hiçbir yerde görünmüyordu (Samet, 2026-10-07); burada
/// görülür ve tek dokunuşla geri alınır. Arşiv boşsa hiç çizilmez.
class _ArchivedRoutines extends ConsumerWidget {
  const _ArchivedRoutines();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archived =
        ref.watch(archivedRoutinesProvider).valueOrNull ?? const [];
    if (archived.isEmpty) return const SizedBox.shrink();
    final l = AppL10n.of(context);
    final muted = context.colors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Theme(
        // ExpansionTile'ın açılınca çizdiği ayraç çizgileri olmasın.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const ValueKey('archived-routines'),
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          leading: FitPackIcon.material(
            Icons.archive_outlined,
            color: muted,
            size: AppIconSize.md,
          ),
          title: Text(
            l.workoutArchiveSection(archived.length),
            style: context.texts.titleSmall?.copyWith(color: muted),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  l.workoutArchiveHint,
                  style: context.texts.bodySmall?.copyWith(color: muted),
                ),
              ),
            ),
            for (final r in archived)
              ListTile(
                key: ValueKey('archived-${r.id}'),
                contentPadding: EdgeInsets.zero,
                title: Text(r.name, style: context.texts.bodyLarge),
                trailing: TextButton.icon(
                  onPressed: () => _restore(context, ref, r),
                  icon: const FitPackIcon.material(
                    Icons.unarchive_outlined,
                    size: AppIconSize.sm,
                  ),
                  label: Text(l.workoutArchiveRestore),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref, Routine r) async {
    final l = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(workoutDaoProvider).unarchiveRoutine(r.id);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.rbSaveError)));
      return;
    }
    // Rutin provider'ları reaktif (H-05) → liste ve arşiv kendiliğinden yenilenir.
    messenger.showSnackBar(
      SnackBar(content: Text(l.workoutArchiveRestored(r.name))),
    );
  }
}

class _NewRoutineButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NewRoutineButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const FitPackIcon(FitPackGlyph.plus, size: AppIconSize.sm),
      label: Text(AppL10n.of(context).workoutNewRoutine),
    );
  }
}

// ─────────────────────────────────────────────────────────── Rutin kartı

class _NoRoutines extends StatelessWidget {
  final VoidCallback onCreate;
  const _NoRoutines({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    // Boş hal = öğretmen (docs/15 §C): onCreate zaten geliyordu ama
    // kullanılmıyordu — tek net aksiyon bağlandı.
    final l = AppL10n.of(context);
    return EmptyState(
      icon: Icons.list_alt_rounded,
      title: l.workoutNoRoutines,
      message: l.workoutNoRoutinesMsg,
      actionLabel: l.workoutCreateRoutine,
      onAction: onCreate,
      compact: true,
    );
  }
}

class _RoutineCard extends ConsumerWidget {
  final Routine routine;
  const _RoutineCard({required this.routine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exAsync = ref.watch(routineExercisesProvider(routine.id));
    final exercises = exAsync.valueOrNull ?? [];
    final dayShort = routine.scheduledWeekday != null
        ? context.weekdayShort(routine.scheduledWeekday!)
        : null;

    // Hareketlerden farklı kas gruplarını (İngilizce) topla.
    final muscles = <String>[];
    for (final re in exercises) {
      final m = re.exercise.primaryMuscle;
      if (m != null && m.isNotEmpty && !muscles.contains(m)) muscles.add(m);
    }

    return Card(
      child: InkWell(
        onTap: () => context.push(AppRoutes.routinePreview(routine.id)),
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md + 3,
            AppSpacing.sm,
            AppSpacing.md + 3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.12),
                      borderRadius: AppRadius.brMd,
                    ),
                    child: FitPackIcon.material(
                      Icons.fitness_center_rounded,
                      color: context.colors.primary,
                      size: 21,
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                routine.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.texts.titleSmall,
                              ),
                            ),
                            if (dayShort != null) ...[
                              AppSpacing.hGapSm,
                              WorkoutChip(
                                dayShort,
                                color: context.colors.primary,
                                soft: true,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppL10n.of(
                            context,
                          ).workoutExerciseCount(exercises.length),
                          style: context.texts.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: AppL10n.of(context).commonEdit,
                    visualDensity: VisualDensity.compact,
                    icon: FitPackIcon.material(
                      Icons.edit_outlined,
                      size: AppIconSize.sm,
                      color: context.colors.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    onPressed: () =>
                        context.push(AppRoutes.routineEdit(routine.id)),
                  ),
                ],
              ),
              if (muscles.isNotEmpty) ...[
                AppSpacing.vGapMd,
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: muscles
                        .take(4)
                        .map((m) => WorkoutChip(WorkoutUi.muscleLabel(m)))
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "Devam eden antrenman" banner'ı (docs/12). Kaydedilmiş canlı seans taslağı
/// varsa en üstte gösterilir; arka planda öldürülmüş seansa kaldığı yerden döner.
class _ResumeBanner extends ConsumerWidget {
  const _ResumeBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftAsync = ref.watch(activeDraftProvider);
    final draft = draftAsync.valueOrNull;
    if (draft == null) return const SizedBox.shrink();

    final c = context.colors;
    final setCount = draft.exercises.fold<int>(
      0,
      (n, e) => n + e.sets.where((s) => s.done).length,
    );
    final mins = DateTime.now().difference(draft.startedAt).inMinutes;
    final l = AppL10n.of(context);
    final sub =
        l.workoutResumeSub(draft.exercises.length, setCount) +
        (mins > 0 && mins < 600 ? ' · $mins ${l.unitMinShort}' : '');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Material(
        color: c.primaryContainer,
        borderRadius: AppRadius.brLg,
        child: InkWell(
          borderRadius: AppRadius.brLg,
          onTap: () => context
              .push(AppRoutes.workoutActiveResume)
              .then((_) => ref.invalidate(activeDraftProvider)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: AppRadius.brMd,
                  ),
                  child: FitPackIcon.material(
                    Icons.play_arrow_rounded,
                    color: c.onPrimary,
                    size: 26,
                  ),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.workoutResumeTitle,
                        style: context.texts.titleSmall?.copyWith(
                          color: c.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${draft.title} · $sub',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodySmall?.copyWith(
                          color: c.onPrimaryContainer.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: FitPackIcon.material(
                    Icons.close_rounded,
                    color: c.onPrimaryContainer.withValues(alpha: 0.7),
                    size: AppIconSize.md,
                  ),
                  tooltip: l.workoutDraftDelete,
                  onPressed: () async {
                    final ok = await confirmAction(
                      context,
                      title: l.workoutDraftDelete,
                      message: l.workoutDraftDeleteMsg,
                      confirmLabel: l.commonDelete,
                      destructive: true,
                    );
                    if (ok) {
                      await ref.read(workoutDraftServiceProvider).clear();
                      ref.invalidate(activeDraftProvider);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
