import 'package:drift/drift.dart' hide Column;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/formatting.dart';
import '../../core/onboarding/first_run_hints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/providers.dart';
import '../../data/database/app_database.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/app_state_views.dart';
import '../activity/activity_calendar.dart';
import '../home/providers/home_providers.dart';

final allMeasurementsProvider = FutureProvider<List<BodyMeasurement>>((ref) {
  return ref.watch(bodyDaoProvider).getAllMeasurements();
});

class BodyMetricsScreen extends ConsumerWidget {
  const BodyMetricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurementsAsync = ref.watch(allMeasurementsProvider);

    final l = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.navProgress)),
      // İlk-kullanım ipucu (docs/15 §B): sekmeye ilk girişte kilo/ölçüm
      // girmeyi işaret eder; bir kez gösterilir.
      floatingActionButton: CoachMark(
        hint: FirstRunHint.progress,
        message: (l) => l.hintProgress,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddMeasurementDialog(context, ref),
          icon: const Icon(Icons.add_rounded),
          label: Text(l.bmAddMeasurement),
        ),
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          // Aktivite takvimi — ölçüm olsun olmasın her zaman görünür.
          const ActivityCalendar(),
          AppSpacing.vGapLg,
          ..._measurementSection(context, ref, measurementsAsync),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  List<Widget> _measurementSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<BodyMeasurement>> measurementsAsync,
  ) {
    return measurementsAsync.when(
      loading: () => [
        Skeleton.card(height: 120),
        AppSpacing.vGapLg,
        Skeleton.card(height: 72),
      ],
      error: (_, _) => [
        ErrorState(
          message: AppL10n.of(context).bmLoadError,
          onRetry: () => ref.invalidate(allMeasurementsProvider),
        ),
      ],
      data: (measurements) {
        if (measurements.isEmpty) {
          return [
            // Boş hal = öğretmen (docs/15 §C): tek net aksiyonla yönlendir.
            EmptyState(
              icon: Icons.monitor_weight_outlined,
              title: AppL10n.of(context).bmEmptyTitle,
              message: AppL10n.of(context).bmEmptyMsg,
              actionLabel: AppL10n.of(context).bmAddFirst,
              onAction: () => _showAddMeasurementDialog(context, ref),
              compact: true,
            ),
          ];
        }

        final latest = measurements.first;
        final oldest = measurements.length > 1 ? measurements.last : null;
        // Grafik için kilolu ölçümler, eskiden yeniye.
        final weighted = measurements.where((m) => m.weightKg != null).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        final goalWeight =
            ref.watch(userProfileProvider).valueOrNull?.goalWeightKg;

        return [
          _SummaryCard(latest: latest, oldest: oldest),
          AppSpacing.vGapLg,
          if (weighted.length >= 2) ...[
            _WeightChartCard(measurements: weighted, goalWeight: goalWeight),
            AppSpacing.vGapLg,
          ],
          Text(AppL10n.of(context).bmPastMeasurements,
              style: context.texts.titleMedium),
          AppSpacing.vGapSm,
          ...measurements.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _MeasurementCard(
                  measurement: m,
                  onDelete: () async {
                    final ok = await confirmAction(
                      context,
                      title: AppL10n.of(context).bmDeleteTitle,
                      message: AppL10n.of(context).bmDeleteMsg(
                          context.dateFmt('d MMM yyyy').format(m.date)),
                    );
                    if (!ok) return;
                    await ref.read(bodyDaoProvider).deleteMeasurement(m.id);
                    // Kilo verisini okuyan TÜM provider'lar tazelenir (H-05):
                    // Home "Son Kilo", Ayarlar TDEE, seans kalori tahmini.
                    ref.invalidate(allMeasurementsProvider);
                    ref.invalidate(weightTrendProvider);
                    ref.invalidate(latestWeightProvider);
                  },
                ),
              )),
        ];
      },
    );
  }

  void _showAddMeasurementDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _AddMeasurementSheet(),
    );
  }
}

/// Kilo trend grafiği — cut yolculuğunun kanıtı. Hedef kilo profile
/// girilmişse kesikli çizgiyle gösterilir.
class _WeightChartCard extends StatelessWidget {
  final List<BodyMeasurement> measurements; // eskiden yeniye, weightKg dolu
  final double? goalWeight;

  const _WeightChartCard({required this.measurements, this.goalWeight});

  @override
  Widget build(BuildContext context) {
    final color = context.colors.primary;
    final spots = measurements
        .map((m) => FlSpot(
            m.date.millisecondsSinceEpoch.toDouble(), m.weightKg!))
        .toList();

    final weights = measurements.map((m) => m.weightKg!).toList();
    var minY = weights.reduce((a, b) => a < b ? a : b);
    var maxY = weights.reduce((a, b) => a > b ? a : b);
    // Hedef görünür aralıkta kalsın, üst/alt nefes payı.
    if (goalWeight != null) {
      minY = minY < goalWeight! ? minY : goalWeight!;
      maxY = maxY > goalWeight! ? maxY : goalWeight!;
    }
    minY -= 1;
    maxY += 1;

    final firstX = spots.first.x;
    final lastX = spots.last.x;
    final dateFmt = context.dateFmt('d MMM');

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(AppL10n.of(context).bmWeightTrend,
                    style: context.texts.titleSmall),
                const Spacer(),
                if (goalWeight != null)
                  Text(
                      AppL10n.of(context)
                          .bmGoalLine(goalWeight!.toStringAsFixed(0)),
                      style: context.texts.labelSmall?.copyWith(
                          color: context.semantic.success,
                          fontWeight: FontWeight.w600)),
              ],
            ),
            AppSpacing.vGapLg,
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: context.colors.surfaceContainerHighest,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.min || value == meta.max) {
                            return const SizedBox.shrink();
                          }
                          return Text(value.toStringAsFixed(0),
                              style: context.texts.labelSmall?.copyWith(
                                  color:
                                      context.colors.onSurfaceVariant));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: (lastX - firstX) <= 0
                            ? 1
                            : (lastX - firstX),
                        getTitlesWidget: (value, meta) {
                          // Sadece ilk ve son tarih — kalabalık olmasın.
                          if (value != firstX && value != lastX) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding:
                                const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(
                              dateFmt.format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      value.toInt())),
                              style: context.texts.labelSmall?.copyWith(
                                  color:
                                      context.colors.onSurfaceVariant),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  extraLinesData: goalWeight == null
                      ? const ExtraLinesData()
                      : ExtraLinesData(horizontalLines: [
                          HorizontalLine(
                            y: goalWeight!,
                            color: context.semantic.success
                                .withValues(alpha: 0.6),
                            strokeWidth: 1.5,
                            dashArray: [6, 4],
                          ),
                        ]),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touched) => touched
                          .map((t) => LineTooltipItem(
                                '${t.y.toStringAsFixed(1)} kg\n${dateFmt.format(DateTime.fromMillisecondsSinceEpoch(t.x.toInt()))}',
                                context.texts.labelMedium!.copyWith(
                                    color: context.colors.onPrimary),
                              ))
                          .toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      preventCurveOverShooting: true,
                      color: color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, _, index) =>
                            FlDotCirclePainter(
                          radius: index == spots.length - 1 ? 4 : 2.5,
                          color: color,
                          strokeWidth: 0,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withValues(alpha: 0.22),
                            color.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final BodyMeasurement latest;
  final BodyMeasurement? oldest;

  const _SummaryCard({required this.latest, required this.oldest});

  @override
  Widget build(BuildContext context) {
    final weightDiff = oldest != null &&
            latest.weightKg != null &&
            oldest!.weightKg != null
        ? latest.weightKg! - oldest!.weightKg!
        : null;

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppL10n.of(context).bmLatest,
                style: context.texts.titleSmall),
            AppSpacing.vGapMd,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MetricTile(
                  label: AppL10n.of(context).bmWeight,
                  value: latest.weightKg != null
                      ? '${latest.weightKg!.toStringAsFixed(1)} kg'
                      : '—',
                  diff: weightDiff,
                  unit: 'kg',
                ),
                _MetricTile(
                  label: AppL10n.of(context).bmWaist,
                  value: latest.waistCm != null
                      ? '${latest.waistCm!.toStringAsFixed(1)} cm'
                      : '—',
                ),
                _MetricTile(
                  label: AppL10n.of(context).bmArm,
                  value: latest.armCm != null
                      ? '${latest.armCm!.toStringAsFixed(1)} cm'
                      : '—',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final double? diff;
  final String? unit;

  const _MetricTile({
    required this.label,
    required this.value,
    this.diff,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final down = (diff ?? 0) < 0;
    final diffColor =
        down ? context.semantic.success : context.colors.error;
    return Column(
      children: [
        Text(label,
            style: context.texts.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant)),
        AppSpacing.vGapXs,
        Text(value,
            style: context.texts.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        if (diff != null && diff != 0) ...[
          AppSpacing.vGapXs,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                  down
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: 12,
                  color: diffColor),
              Text('${diff!.abs().toStringAsFixed(1)} $unit',
                  style: context.texts.labelSmall?.copyWith(color: diffColor)),
            ],
          ),
        ],
      ],
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  final BodyMeasurement measurement;
  final Future<void> Function() onDelete;

  const _MeasurementCard({required this.measurement, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
            context.dateFmt('d MMM yyyy').format(measurement.date)),
        subtitle: Text(
          [
            if (measurement.weightKg != null)
              '${measurement.weightKg!.toStringAsFixed(1)} kg',
            if (measurement.waistCm != null)
              'Bel ${measurement.waistCm!.toStringAsFixed(1)}',
            if (measurement.armCm != null)
              'Kol ${measurement.armCm!.toStringAsFixed(1)}',
            if (measurement.chestCm != null)
              '${AppL10n.of(context).bmChest} ${measurement.chestCm!.toStringAsFixed(1)}',
          ].join('  ·  '),
        ),
        trailing: IconButton(
          tooltip: AppL10n.of(context).commonDelete,
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

// ConsumerStatefulWidget (M-06): ref parametreyle taşınmaz, sheet kendisi alır.
class _AddMeasurementSheet extends ConsumerStatefulWidget {
  const _AddMeasurementSheet();

  @override
  ConsumerState<_AddMeasurementSheet> createState() =>
      _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends ConsumerState<_AddMeasurementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _waistController = TextEditingController();
  final _chestController = TextEditingController();
  final _armController = TextEditingController();
  final _hipController = TextEditingController();
  final _neckController = TextEditingController();
  final _fatController = TextEditingController();
  bool _saving = false;
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: now, // gelecek tarih kapalı
    );
    if (picked != null) {
      setState(() => _selectedDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _weightController,
      _waistController,
      _chestController,
      _armController,
      _hipController,
      _neckController,
      _fatController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _parse(TextEditingController c) {
    final t = c.text.trim().replaceAll(',', '.');
    return t.isEmpty ? null : double.tryParse(t);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final weight = _parse(_weightController);
    final waist = _parse(_waistController);
    final chest = _parse(_chestController);
    final arm = _parse(_armController);
    final hip = _parse(_hipController);
    final neck = _parse(_neckController);
    final fat = _parse(_fatController);

    if ([weight, waist, chest, arm, hip, neck, fat]
        .every((v) => v == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context).bmNeedOneValue)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(bodyDaoProvider).insertMeasurement(
            BodyMeasurementsCompanion(
              date: Value(_selectedDate),
              weightKg: Value(weight),
              waistCm: Value(waist),
              chestCm: Value(chest),
              armCm: Value(arm),
              hipCm: Value(hip),
              neckCm: Value(neck),
              bodyFatPct: Value(fat),
            ),
          );
      // Kilo verisini okuyan TÜM provider'lar tazelenir (H-05).
      ref.invalidate(allMeasurementsProvider);
      ref.invalidate(weightTrendProvider);
      ref.invalidate(latestWeightProvider);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppL10n.of(context).bmSaveFailed),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(
                title: AppL10n.of(context).bmNewMeasurement,
                subtitle: AppL10n.of(context).bmSheetSubtitle,
              ),
              AppSpacing.vGapLg,
              _DateRow(
                date: _selectedDate,
                onTap: _saving ? null : _pickDate,
              ),
              AppSpacing.vGapMd,
              _Field(
                  label: '${AppL10n.of(context).bmWeight} (kg)',
                  controller: _weightController,
                  min: 30,
                  max: 300),
              _Field(
                  label: '${AppL10n.of(context).bmWaist} (cm)',
                  controller: _waistController,
                  min: 30,
                  max: 250),
              _Field(
                  label: '${AppL10n.of(context).bmChest} (cm)',
                  controller: _chestController,
                  min: 30,
                  max: 250),
              _Field(
                  label: '${AppL10n.of(context).bmArm} (cm)',
                  controller: _armController,
                  min: 10,
                  max: 100),
              _Field(
                  label: '${AppL10n.of(context).bmHip} (cm)',
                  controller: _hipController,
                  min: 30,
                  max: 250),
              _Field(
                  label: '${AppL10n.of(context).bmNeck} (cm)',
                  controller: _neckController,
                  min: 10,
                  max: 100),
              _Field(
                  label: '${AppL10n.of(context).bmBodyFat} (%)',
                  controller: _fatController,
                  min: 1,
                  max: 70),
              AppSpacing.vGapLg,
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? SizedBox(
                        width: AppIconSize.sm,
                        height: AppIconSize.sm,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.colors.onPrimary),
                      )
                    : Text(AppL10n.of(context).commonSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final double min;
  final double max;

  const _Field({
    required this.label,
    required this.controller,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        decoration: InputDecoration(labelText: label),
        validator: (raw) {
          final t = (raw ?? '').trim().replaceAll(',', '.');
          if (t.isEmpty) return null; // opsiyonel alan
          final v = double.tryParse(t);
          if (v == null) return AppL10n.of(context).commonInvalidNumber;
          if (v < min || v > max) {
            return AppL10n.of(context).commonRangeError('$min', '$max');
          }
          return null;
        },
      ),
    );
  }
}

/// Ölçümün hangi güne yazılacağını seçer (geçmişe dönük giriş). Varsayılan bugün.
class _DateRow extends StatelessWidget {
  final DateTime date;
  final VoidCallback? onTap;

  const _DateRow({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final label = isToday
        ? AppL10n.of(context).commonToday
        : context.dateFmt('d MMMM yyyy').format(date);
    return Material(
      color: context.colors.surfaceContainerHighest,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              Icon(Icons.event_rounded,
                  size: AppIconSize.md, color: context.colors.primary),
              AppSpacing.gapMd,
              Text(AppL10n.of(context).commonDate,
                  style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              Text(label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.primary,
                      )),
              AppSpacing.gapXs,
              Icon(Icons.expand_more_rounded,
                  size: AppIconSize.sm, color: context.colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
