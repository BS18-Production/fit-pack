import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/database/app_database.dart';
import '../../shared/widgets/app_state_views.dart';
import 'routine_providers.dart';
import 'workout_draft.dart';
import 'workout_ui.dart';

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
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
          children: [
            const _Header(),
            AppSpacing.vGapLg,
            const _ResumeBanner(),
            const _WeekStatsCard(),
            AppSpacing.vGapLg,
            _EmptyWorkoutButton(),
            AppSpacing.vGapxl_,
            routinesAsync.when(
              loading: () => Column(children: [
                _routinesHeader(context, null),
                AppSpacing.vGapSm,
                Skeleton.card(height: 92),
                AppSpacing.vGapMd,
                Skeleton.card(height: 92),
              ]),
              error: (_, _) => ErrorState(
                message: 'Rutinler yüklenemedi',
                onRetry: () => ref.invalidate(activeRoutinesProvider),
              ),
              data: (routines) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _routinesHeader(context, routines.length),
                    AppSpacing.vGapSm,
                    if (routines.isEmpty)
                      _NoRoutines(
                        onCreate: () => context.push('/workout/routine/new'),
                      )
                    else
                      ...routines.map((r) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _RoutineCard(routine: r),
                          )),
                    AppSpacing.vGapXs,
                    _NewRoutineButton(
                      onTap: () => context.push('/workout/routine/new'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _routinesHeader(BuildContext context, int? count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Rutinlerim', style: context.texts.titleMedium),
        if (count != null && count > 0)
          Text('$count rutin',
              style: context.texts.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant
                    .withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              )),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────────── Header

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d MMMM', 'tr_TR').format(DateTime.now());
    final dateLabel = (today[0].toUpperCase() + today.substring(1)).toUpperCase();
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateLabel,
                      style: context.texts.labelSmall?.copyWith(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      )),
                  const SizedBox(height: 5),
                  Text('Antrenman', style: context.texts.headlineMedium),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Hareket Kütüphanesi',
              icon: const Icon(Icons.menu_book_rounded),
              color: context.colors.onSurfaceVariant,
              onPressed: () => context.push('/exercises'),
            ),
            IconButton(
              tooltip: 'Geçmiş Antrenman Ekle',
              icon: const Icon(Icons.edit_calendar_rounded),
              color: context.colors.onSurfaceVariant,
              onPressed: () => context.push('/workout/log-past'),
            ),
            IconButton(
              tooltip: 'Antrenman Geçmişi',
              icon: const Icon(Icons.history_rounded),
              color: context.colors.onSurfaceVariant,
              onPressed: () => context.push('/workout/history'),
            ),
          ],
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
    final volume = stats?.volumeKg ?? 0;
    final volumeStr = NumberFormat.decimalPattern('tr_TR').format(volume);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'BU HAFTA',
                  value: '$sessions',
                  unit: 'antrenman',
                ),
              ),
              VerticalDivider(
                width: AppSpacing.lg,
                thickness: 1,
                color: context.colors.outlineVariant,
              ),
              Expanded(
                child: _Stat(
                  label: 'TOPLAM HACİM',
                  value: volumeStr,
                  unit: 'kg',
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
        Text(label,
            style: context.texts.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            )),
        AppSpacing.vGapSm,
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.headlineSmall),
            ),
            AppSpacing.hGapXs,
            Text(unit,
                style: context.texts.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────── Boş Antrenman Başlat (CTA)

class _EmptyWorkoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.brXl,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.indigo, AppColors.indigoDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigoDeep.withValues(alpha: 0.26),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.brXl,
        child: InkWell(
          onTap: () => context.push('/workout/active'),
          borderRadius: AppRadius.brXl,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg + 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                AppSpacing.hGapSm,
                Text('Boş Antrenman Başlat',
                    style: context.texts.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── Yeni Rutin (dashed)

class _NewRoutineButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NewRoutineButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.brLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brLg,
        child: DottedBorderBox(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded,
                    color: context.colors.primary, size: AppIconSize.sm),
                AppSpacing.hGapSm,
                Text('Yeni Rutin Oluştur',
                    style: context.texts.labelLarge?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── Rutin kartı

class _NoRoutines extends StatelessWidget {
  final VoidCallback onCreate;
  const _NoRoutines({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.list_alt_rounded,
      title: 'Henüz rutin yok',
      message: 'Kendi antrenman rutinini oluştur — hareketleri seç, '
          'hedef set ve tekrarları belirle.',
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
        ? _weekdayShort[routine.scheduledWeekday]
        : null;

    // Hareketlerden farklı kas gruplarını (İngilizce) topla.
    final muscles = <String>[];
    for (final re in exercises) {
      final m = re.exercise.primaryMuscle;
      if (m != null && m.isNotEmpty && !muscles.contains(m)) muscles.add(m);
    }

    return Card(
      child: InkWell(
        onTap: () => context.push('/workout/routine/${routine.id}/preview'),
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md + 3, AppSpacing.sm, AppSpacing.md + 3),
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
                    child: Icon(Icons.fitness_center_rounded,
                        color: context.colors.primary, size: 21),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(routine.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.texts.titleSmall),
                            ),
                            if (dayShort != null) ...[
                              AppSpacing.hGapSm,
                              WorkoutChip(dayShort,
                                  color: context.colors.primary, soft: true),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('${exercises.length} hareket',
                            style: context.texts.bodySmall?.copyWith(
                                color: context.colors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Düzenle',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.edit_outlined,
                        size: AppIconSize.sm,
                        color: context.colors.onSurfaceVariant
                            .withValues(alpha: 0.7)),
                    onPressed: () =>
                        context.push('/workout/routine/${routine.id}/edit'),
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

const _weekdayShort = {
  1: 'Pzt',
  2: 'Sal',
  3: 'Çar',
  4: 'Per',
  5: 'Cum',
  6: 'Cmt',
  7: 'Paz',
};

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
    final setCount = draft.exercises
        .fold<int>(0, (n, e) => n + e.sets.where((s) => s.done).length);
    final mins = DateTime.now().difference(draft.startedAt).inMinutes;
    final sub = '${draft.exercises.length} hareket · $setCount set'
        '${mins > 0 && mins < 600 ? ' · $mins dk' : ''}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Material(
        color: c.primaryContainer,
        borderRadius: AppRadius.brLg,
        child: InkWell(
          borderRadius: AppRadius.brLg,
          onTap: () => context
              .push('/workout/active/resume')
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
                  child: Icon(Icons.play_arrow_rounded,
                      color: c.onPrimary, size: 26),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Devam eden antrenman',
                          style: context.texts.titleSmall?.copyWith(
                              color: c.onPrimaryContainer,
                              fontWeight: FontWeight.w800)),
                      Text('${draft.title} · $sub',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.texts.bodySmall?.copyWith(
                              color: c.onPrimaryContainer
                                  .withValues(alpha: 0.75))),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      color:
                          c.onPrimaryContainer.withValues(alpha: 0.7),
                      size: AppIconSize.md),
                  tooltip: 'Taslağı sil',
                  onPressed: () async {
                    final ok = await confirmAction(
                      context,
                      title: 'Taslağı sil',
                      message:
                          'Devam eden antrenman taslağı silinsin mi? Girdiğin setler kaydedilmeyecek.',
                      confirmLabel: 'Sil',
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
