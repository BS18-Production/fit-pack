import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/formatting.dart';
import '../../core/units/units.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/workout_dao.dart';
import '../../data/providers.dart';
import '../../l10n/app_l10n.dart';
import 'record_calc.dart';
import 'workout_ui.dart';
import '../../core/router/app_routes.dart';

/// Antrenman Özeti (Antrenman V2 Faz C). Süre, toplam hacim, set sayısı,
/// hareket bazlı döküm. Seans zaten kaydedildi; bu ekran recap.
class WorkoutSummaryScreen extends ConsumerWidget {
  final int sessionId;
  const WorkoutSummaryScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_summaryProvider(sessionId));
    final units = ref.watch(unitsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.workout);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(AppL10n.of(context).wsTitle),
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              Center(child: Text(AppL10n.of(context).wsLoadError)),
          data: (s) => ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xxxl),
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: context.semantic.success.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded,
                      size: 38, color: context.semantic.success),
                ),
              ),
              AppSpacing.vGapLg,
              Center(
                child: Text(AppL10n.of(context).wsDone,
                    style: context.texts.headlineSmall,
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 5),
              Center(
                child: Text(
                    '${s.title} · ${_relativeDateLabel(context, s.date)}',
                    style: context.texts.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant),
                    textAlign: TextAlign.center),
              ),
              AppSpacing.vGapxl_,
              _StatsCard(
                duration:
                    '${s.durationMin} ${AppL10n.of(context).unitMinShort}',
                volume: () {
                  final v = units.weightFromKg(s.volume).round();
                  return v >= 1000
                      ? '${(v / 1000).toStringAsFixed(1)}k'
                      : '$v';
                }(),
                volumeUnit: units.weightUnit,
                sets: '${s.totalSets}',
              ),
              if (s.records.isNotEmpty) ...[
                AppSpacing.vGapxl_,
                _RecordsCard(records: s.records, units: units),
              ],
              AppSpacing.vGapxl_,
              Text(AppL10n.of(context).wsExercises,
                  style: context.texts.titleMedium),
              AppSpacing.vGapSm,
              ...s.perExercise.map((e) => Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md + 1,
                          vertical: AppSpacing.md + 1),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    e.name ??
                                        AppL10n.of(context).wsUnknownExercise,
                                    style: context.texts.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(
                                    e.volume > 0
                                        ? '${AppL10n.of(context).workoutSetCount(e.sets)} · ${units.weight(e.volume)}'
                                        : AppL10n.of(context)
                                            .workoutSetCount(e.sets),
                                    style: context.texts.bodySmall?.copyWith(
                                        color:
                                            context.colors.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
              AppSpacing.vGapLg,
              GradientButton(
                label: AppL10n.of(context).wsDoneBtn,
                onTap: () => context.go(AppRoutes.workout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String duration, volume, volumeUnit, sets;
  const _StatsCard(
      {required this.duration,
      required this.volume,
      required this.volumeUnit,
      required this.sets});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg + 2),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                  child: _Col(AppL10n.of(context).labelDuration, duration)),
              _div(context),
              Expanded(
                  child: _Col(AppL10n.of(context).labelVolume,
                      '$volume $volumeUnit')),
              _div(context),
              Expanded(child: _Col(AppL10n.of(context).labelSets, sets)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _div(BuildContext context) => VerticalDivider(
      width: 1, thickness: 1, color: context.colors.outlineVariant);
}

/// Bu seansta kırılan kişisel rekorlar — kupa rozetli kutlama kartı.
class _RecordsCard extends StatelessWidget {
  final List<NewRecord> records;
  final Units units;
  const _RecordsCard({required this.records, required this.units});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final warn = context.semantic.warning;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md + 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: warn.withValues(alpha: 0.16),
                    borderRadius: AppRadius.brMd,
                  ),
                  child:
                      Icon(Icons.emoji_events_rounded, size: 19, color: warn),
                ),
                AppSpacing.hGapSm,
                Text(l.wsNewRecords(records.length),
                    style: context.texts.titleMedium),
              ],
            ),
            AppSpacing.vGapSm,
            ...records.map((r) {
              // e1RM rekoru: "Tahmini 1RM 92 kg · 82.5×8" — en ağır: "En ağır
              // set 85 kg". Etiketler Rekorlar sekmesiyle aynı anahtarlar.
              final label = r.isE1rm
                  ? '${l.edBestE1rm} ${units.weight(r.value, frac: 0)}'
                      ' · ${units.weightValue(r.weightKg)}×${r.reps}'
                  : '${l.edHeaviest} ${units.weight(r.value)}';
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(r.name,
                          style: context.texts.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text(label,
                        style: context.texts.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _Col extends StatelessWidget {
  final String label, value;
  const _Col(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.headlineSmall),
        const SizedBox(height: 3),
        Text(label,
            style: context.texts.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ───────── özet hesabı ─────────

class _ExerciseRecap {
  final String? name;
  final int sets;
  final int volume;
  _ExerciseRecap(this.name, this.sets, this.volume);
}

class _Summary {
  final String title;
  final DateTime date;
  final int durationMin;
  final int volume;
  final int totalSets;
  final List<_ExerciseRecap> perExercise;
  final List<NewRecord> records; // bu seansta kırılan kişisel rekorlar
  _Summary(this.title, this.date, this.durationMin, this.volume, this.totalSets,
      this.perExercise, this.records);
}

final _summaryProvider =
    FutureProvider.family<_Summary, int>((ref, sessionId) async {
  final dao = ref.watch(workoutDaoProvider);
  final session = await dao.getSessionById(sessionId);
  if (session == null) {
    throw StateError('Session not found: $sessionId');
  }
  final sets = await dao.getSetsForSession(sessionId);
  final allEx = {for (final e in await dao.getAllExercises()) e.id: e.name};

  int volume = 0;
  final byEx = <int, List<WorkoutSet>>{};
  for (final s in sets) {
    volume += ((s.weightKg ?? 0) * (s.reps ?? 0)).round();
    byEx.putIfAbsent(s.exerciseId, () => []).add(s);
  }
  final recaps = byEx.entries.map((e) {
    final v = e.value
        .fold<int>(0, (a, s) => a + ((s.weightKg ?? 0) * (s.reps ?? 0)).round());
    return _ExerciseRecap(allEx[e.key], e.value.length, v);
  }).toList();

  // Yeni rekorlar (record_calc): hareket başına, seans TARİHİNDEN ÖNCEKİ
  // geçmişin en iyisi vs bu seansın setleri. Tarih filtresi sayesinde
  // deterministik — özet geçmişten tekrar açılsa da aynı sonucu verir ve
  // geçmişe eklenen manuel seanslar sonraki seansları "rekor" göstermez.
  final records = <NewRecord>[];
  for (final e in byEx.entries) {
    final name = allEx[e.key];
    if (name == null) continue;
    final history = await dao.getExerciseHistory(e.key);
    final rec = newRecordFor(
      name: name,
      priorHistory: history.where((p) => p.date.isBefore(session.date)),
      sessionPoints: e.value.where((s) => !s.isWarmup).map((s) =>
          ExerciseSetPoint(
              date: session.date, weightKg: s.weightKg, reps: s.reps)),
    );
    if (rec != null) records.add(rec);
  }

  return _Summary(
    session.workoutType,
    session.date,
    session.durationMin ?? 0,
    volume,
    sets.length,
    recaps,
    records,
  );
});

/// Seans tarihini göreceli/okunur etikete çevirir: Bugün / Dün / "20 Haziran".
String _relativeDateLabel(BuildContext context, DateTime date) {
  final l = AppL10n.of(context);
  final now = DateTime.now();
  final d = DateTime(date.year, date.month, date.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return l.commonToday;
  if (diff == 1) return l.commonYesterday;
  return context.dateFmt('d MMMM').format(date);
}
