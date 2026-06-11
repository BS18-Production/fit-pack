import 'package:drift/drift.dart' hide Column;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/providers.dart';
import '../../data/database/app_database.dart';
import '../../shared/widgets/app_state_views.dart';
import '../home/providers/home_providers.dart';

final allMeasurementsProvider = FutureProvider<List<BodyMeasurement>>((ref) {
  return ref.watch(bodyDaoProvider).getAllMeasurements();
});

class BodyMetricsScreen extends ConsumerWidget {
  const BodyMetricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurementsAsync = ref.watch(allMeasurementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('İlerleme')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMeasurementDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ölçüm Ekle'),
      ),
      body: measurementsAsync.when(
        loading: () => ListView(
          padding: AppSpacing.screen,
          children: [
            Skeleton.card(height: 120),
            AppSpacing.vGapLg,
            Skeleton.card(height: 72),
            AppSpacing.vGapMd,
            Skeleton.card(height: 72),
          ],
        ),
        error: (_, _) => ErrorState(
          message: 'Ölçümler yüklenemedi',
          onRetry: () => ref.invalidate(allMeasurementsProvider),
        ),
        data: (measurements) {
          if (measurements.isEmpty) {
            // Tek CTA: sağ alttaki FAB. İkinci buton kafa karıştırır.
            return const EmptyState(
              icon: Icons.monitor_weight_outlined,
              title: 'Henüz ölçüm yok',
              message: 'İlk vücut ölçümünü ekleyerek ilerlemeni takip et',
            );
          }

          final latest = measurements.first;
          final oldest = measurements.length > 1 ? measurements.last : null;
          // Grafik için kilolu ölçümler, eskiden yeniye.
          final weighted = measurements
              .where((m) => m.weightKg != null)
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));
          final goalWeight =
              ref.watch(userProfileProvider).valueOrNull?.goalWeightKg;

          return ListView(
            padding: AppSpacing.screen,
            children: [
              _SummaryCard(latest: latest, oldest: oldest),
              AppSpacing.vGapLg,
              if (weighted.length >= 2) ...[
                _WeightChartCard(
                    measurements: weighted, goalWeight: goalWeight),
                AppSpacing.vGapLg,
              ],
              Text('Geçmiş Ölçümler', style: context.texts.titleMedium),
              AppSpacing.vGapSm,
              ...measurements.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _MeasurementCard(
                      measurement: m,
                      onDelete: () async {
                        final ok = await confirmAction(
                          context,
                          title: 'Ölçümü sil',
                          message:
                              '${DateFormat('d MMM yyyy', 'tr_TR').format(m.date)} tarihli ölçüm silinsin mi?',
                        );
                        if (!ok) return;
                        await ref
                            .read(bodyDaoProvider)
                            .deleteMeasurement(m.id);
                        ref.invalidate(allMeasurementsProvider);
                      },
                    ),
                  )),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  void _showAddMeasurementDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddMeasurementSheet(ref: ref),
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
    final dateFmt = DateFormat('d MMM', 'tr_TR');

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Kilo Trendi', style: context.texts.titleSmall),
                const Spacer(),
                if (goalWeight != null)
                  Text('Hedef ${goalWeight!.toStringAsFixed(0)} kg',
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
            Text('Son Ölçümler', style: context.texts.titleSmall),
            AppSpacing.vGapMd,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MetricTile(
                  label: 'Kilo',
                  value: latest.weightKg != null
                      ? '${latest.weightKg!.toStringAsFixed(1)} kg'
                      : '—',
                  diff: weightDiff,
                  unit: 'kg',
                ),
                _MetricTile(
                  label: 'Bel',
                  value: latest.waistCm != null
                      ? '${latest.waistCm!.toStringAsFixed(1)} cm'
                      : '—',
                ),
                _MetricTile(
                  label: 'Kol',
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
            DateFormat('d MMM yyyy', 'tr_TR').format(measurement.date)),
        subtitle: Text(
          [
            if (measurement.weightKg != null)
              '${measurement.weightKg!.toStringAsFixed(1)} kg',
            if (measurement.waistCm != null)
              'Bel ${measurement.waistCm!.toStringAsFixed(1)}',
            if (measurement.armCm != null)
              'Kol ${measurement.armCm!.toStringAsFixed(1)}',
            if (measurement.chestCm != null)
              'Göğüs ${measurement.chestCm!.toStringAsFixed(1)}',
          ].join('  ·  '),
        ),
        trailing: IconButton(
          tooltip: 'Sil',
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _AddMeasurementSheet extends StatefulWidget {
  final WidgetRef ref;
  const _AddMeasurementSheet({required this.ref});

  @override
  State<_AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends State<_AddMeasurementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _waistController = TextEditingController();
  final _chestController = TextEditingController();
  final _armController = TextEditingController();
  final _hipController = TextEditingController();
  final _neckController = TextEditingController();
  final _fatController = TextEditingController();
  bool _saving = false;

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
        const SnackBar(content: Text('En az bir değer gir')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.ref.read(bodyDaoProvider).insertMeasurement(
            BodyMeasurementsCompanion(
              date: Value(DateTime.now()),
              weightKg: Value(weight),
              waistCm: Value(waist),
              chestCm: Value(chest),
              armCm: Value(arm),
              hipCm: Value(hip),
              neckCm: Value(neck),
              bodyFatPct: Value(fat),
            ),
          );
      widget.ref.invalidate(allMeasurementsProvider);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kaydedilemedi, tekrar dene'),
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
              const SheetHeader(
                title: 'Yeni Ölçüm',
                subtitle: 'Boş bıraktığın alan kaydedilmez',
              ),
              AppSpacing.vGapLg,
              _Field(label: 'Kilo (kg)', controller: _weightController, min: 30, max: 300),
              _Field(label: 'Bel (cm)', controller: _waistController, min: 30, max: 250),
              _Field(label: 'Göğüs (cm)', controller: _chestController, min: 30, max: 250),
              _Field(label: 'Kol (cm)', controller: _armController, min: 10, max: 100),
              _Field(label: 'Kalça (cm)', controller: _hipController, min: 30, max: 250),
              _Field(label: 'Boyun (cm)', controller: _neckController, min: 10, max: 100),
              _Field(label: 'Yağ Oranı (%)', controller: _fatController, min: 1, max: 70),
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
                    : const Text('Kaydet'),
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
          if (v == null) return 'Geçersiz sayı';
          if (v < min || v > max) {
            return '$min – $max aralığında olmalı';
          }
          return null;
        },
      ),
    );
  }
}
