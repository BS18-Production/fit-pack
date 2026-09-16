import 'package:drift/drift.dart' hide Column;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/formatting.dart';
import '../../core/onboarding/first_run_hints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/units/units.dart';
import '../../core/utils/weight_goal.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';
import '../../data/database/app_database.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/app_state_views.dart';
import '../activity/activity_calendar.dart';
import '../home/providers/home_providers.dart';

/// **Reaktif** (H-05): ölçüm eklenince/silinince kendiliğinden tazelenir.
final allMeasurementsProvider = StreamProvider<List<BodyMeasurement>>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [db.bodyMeasurements],
      () => ref.read(bodyDaoProvider).getAllMeasurements());
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
      // Alt boşluk: içerik buzlu gezinme çubuğunun altından aktığı için
      // (extendBody) iç Scaffold FAB'ı çubuğun arkasına koyar — yukarı kaldır.
      floatingActionButton: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: CoachMark(
          hint: FirstRunHint.progress,
          message: (l) => l.hintProgress,
          child: FloatingActionButton.extended(
            // Beslenme + İlerleme FAB'ları sekme yığınında birlikte canlı
            // (IndexedStack) — varsayılan ortak hero etiketi sayfa geçişinde
            // "multiple heroes share the same tag" hatası veriyordu.
            heroTag: null,
            onPressed: () => _showAddMeasurementDialog(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: Text(l.bmAddMeasurement),
          ),
        ),
      ),
      body: ListView(
        // Alt boşluk: çubuk + nefes + FAB payı (fabScrollInset).
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg,
            AppSpacing.lg, context.fabScrollInset),
        children: [
          // Aktivite takvimi — ölçüm olsun olmasın her zaman görünür.
          const ActivityCalendar(),
          AppSpacing.vGapLg,
          ..._measurementSection(context, ref, measurementsAsync),
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
        // Grafik için kilolu ölçümler, eskiden yeniye.
        final weighted = measurements.where((m) => m.weightKg != null).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        final goalWeight =
            ref.watch(userProfileProvider).valueOrNull?.goalWeightKg;
        final units = ref.watch(unitsProvider);

        return [
          _SummaryCard(
            latest: latest,
            // Fark, kilosu olan İLK ölçüme göre (C-31) — kilosuz satır
            // (yalnız bel/kol) karşılaştırmayı düşürmesin.
            baseline: weighted.length >= 2 ? weighted.first : null,
            goalKg: goalWeight,
            units: units,
          ),
          AppSpacing.vGapLg,
          if (weighted.length >= 2) ...[
            _WeightChartCard(
                measurements: weighted, goalWeight: goalWeight, units: units),
            AppSpacing.vGapLg,
          ],
          Text(AppL10n.of(context).bmPastMeasurements,
              style: context.texts.titleMedium),
          AppSpacing.vGapSm,
          ...measurements.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _MeasurementCard(
                  measurement: m,
                  units: units,
                  onDelete: () async {
                    final ok = await confirmAction(
                      context,
                      title: AppL10n.of(context).bmDeleteTitle,
                      message: AppL10n.of(context).bmDeleteMsg(
                          context.dateFmt('d MMM yyyy').format(m.date)),
                    );
                    if (!ok) return;
                    await ref.read(bodyDaoProvider).deleteMeasurement(m.id);
                    // Kilo okuyan provider'lar reaktif (H-05) → silme sonrası
                    // Home "Son Kilo", TDEE, kalori tahmini kendiliğinden güncel.
                  },
                ),
              )),
        ];
      },
    );
  }

  void _showAddMeasurementDialog(BuildContext context, WidgetRef ref) {
    showAddMeasurementSheet(context);
  }
}

/// Ölçüm giriş formunu (kilo/bel/kol…) herhangi bir ekrandan açar. Profil'deki
/// "Ölçümler" köprüsü de bunu kullanır — tek giriş noktası (aynı form + aynı
/// DAO) korunur, kullanıcı tab'a fırlatılmadan yerinde giriş yapar (docs/16
/// §2.1, S1). Kaydedince ilgili tüm provider'lar tazelenir (bkz. _save).
Future<void> showAddMeasurementSheet(BuildContext context) {
  // Kök navigator (C-1): İlerleme sekmesinden açılınca panel buzlu alt
  // çubuğun arkasında kalıyor, "Kaydet" görünmüyordu.
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (ctx) => const _AddMeasurementSheet(),
  );
}

/// Kilo trend grafiği — cut yolculuğunun kanıtı. Hedef kilo profile
/// girilmişse kesikli çizgiyle gösterilir.
class _WeightChartCard extends StatelessWidget {
  final List<BodyMeasurement> measurements; // eskiden yeniye, weightKg dolu
  final double? goalWeight;
  final Units units;

  const _WeightChartCard(
      {required this.measurements, this.goalWeight, required this.units});

  @override
  Widget build(BuildContext context) {
    final color = context.colors.primary;
    // Grafik görüntü biriminde çizilir (DB kg — docs/16 §3).
    final spots = measurements
        .map((m) => FlSpot(m.date.millisecondsSinceEpoch.toDouble(),
            units.weightFromKg(m.weightKg!)))
        .toList();

    final weights =
        measurements.map((m) => units.weightFromKg(m.weightKg!)).toList();
    var minY = weights.reduce((a, b) => a < b ? a : b);
    var maxY = weights.reduce((a, b) => a > b ? a : b);
    // Hedef görünür aralıkta kalsın, üst/alt nefes payı.
    final goalDisplay =
        goalWeight == null ? null : units.weightFromKg(goalWeight!);
    if (goalDisplay != null) {
      minY = minY < goalDisplay ? minY : goalDisplay;
      maxY = maxY > goalDisplay ? maxY : goalDisplay;
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
                      AppL10n.of(context).bmGoalLine(units.weight(goalWeight!)),
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
                  extraLinesData: goalDisplay == null
                      ? const ExtraLinesData()
                      : ExtraLinesData(horizontalLines: [
                          HorizontalLine(
                            y: goalDisplay,
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
                                '${t.y.toStringAsFixed(1)} ${units.weightUnit}\n${dateFmt.format(DateTime.fromMillisecondsSinceEpoch(t.x.toInt()))}',
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
  final BodyMeasurement? baseline; // farkın karşılaştırıldığı ilk kilolu ölçüm
  final double? goalKg;
  final Units units;

  const _SummaryCard({
    required this.latest,
    required this.baseline,
    required this.goalKg,
    required this.units,
  });

  @override
  Widget build(BuildContext context) {
    final from = baseline?.weightKg;
    final to = latest.weightKg;
    final weightDiff = from != null && to != null
        ? units.weightFromKg(to) - units.weightFromKg(from)
        : null;
    final tone = from != null && to != null
        ? weightChangeTone(fromKg: from, toKg: to, goalKg: goalKg)
        : WeightChangeTone.neutral;
    final sinceDate = baseline == null
        ? null
        : context
            .dateFmt(baseline!.date.year == DateTime.now().year
                ? 'd MMM'
                : 'd MMM y')
            .format(baseline!.date);

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
                      ? units.weight(latest.weightKg!)
                      : '—',
                  diff: weightDiff,
                  diffTone: tone,
                  diffCaption: sinceDate == null
                      ? null
                      : AppL10n.of(context).bmDiffSince(sinceDate),
                  unit: units.weightUnit,
                ),
                _MetricTile(
                  label: AppL10n.of(context).bmWaist,
                  value: latest.waistCm != null
                      ? units.length(latest.waistCm!)
                      : '—',
                ),
                _MetricTile(
                  label: AppL10n.of(context).bmArm,
                  value: latest.armCm != null
                      ? units.length(latest.armCm!)
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
  final WeightChangeTone diffTone;
  final String? diffCaption; // farkın neye göre olduğu ("12 Tem ölçümüne göre")
  final String? unit;

  const _MetricTile({
    required this.label,
    required this.value,
    this.diff,
    this.diffTone = WeightChangeTone.neutral,
    this.diffCaption,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final down = (diff ?? 0) < 0;
    // C-31: artış otomatik kırmızı değil — hedefe doğruysa yeşil, değilse nötr.
    final diffColor = diffTone == WeightChangeTone.good
        ? context.semantic.success
        : context.colors.onSurfaceVariant;
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
          if (diffCaption != null)
            Text(diffCaption!,
                style: context.texts.labelSmall
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
        ],
      ],
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  final BodyMeasurement measurement;
  final Units units;
  final Future<void> Function() onDelete;

  const _MeasurementCard(
      {required this.measurement, required this.units, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Card(
      child: ListTile(
        title: Text(
            context.dateFmt('d MMM yyyy').format(measurement.date)),
        subtitle: Text(
          [
            if (measurement.weightKg != null)
              units.weight(measurement.weightKg!),
            if (measurement.waistCm != null)
              '${l.bmWaist} ${units.length(measurement.waistCm!)}',
            if (measurement.armCm != null)
              '${l.bmArm} ${units.length(measurement.armCm!)}',
            if (measurement.chestCm != null)
              '${l.bmChest} ${units.length(measurement.chestCm!)}',
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
      // Girişler görüntü biriminde — DB'ye metrik yazılır (docs/16 §3).
      final u = ref.read(unitsProvider);
      double? kg(double? v) => v == null ? null : u.weightToKg(v);
      double? cm(double? v) => v == null ? null : u.lengthToCm(v);
      await ref.read(bodyDaoProvider).insertMeasurement(
            BodyMeasurementsCompanion(
              date: Value(_selectedDate),
              weightKg: Value(kg(weight)),
              waistCm: Value(cm(waist)),
              chestCm: Value(cm(chest)),
              armCm: Value(cm(arm)),
              hipCm: Value(cm(hip)),
              neckCm: Value(cm(neck)),
              bodyFatPct: Value(fat),
            ),
          );
      // Kilo okuyan provider'lar reaktif (H-05) → ekleme kendiliğinden yansır.
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
    final units = ref.watch(unitsProvider);
    double w(num kg) => double.parse(units.weightFromKg(kg).toStringAsFixed(0));
    double c(num cm) => double.parse(units.lengthFromCm(cm).toStringAsFixed(0));
    return Padding(
      padding: EdgeInsets.only(
        bottom: context.sheetBottomInset + AppSpacing.lg,
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
                  label:
                      '${AppL10n.of(context).bmWeight} (${units.weightUnit})',
                  controller: _weightController,
                  min: w(30),
                  max: w(300)),
              _Field(
                  label: '${AppL10n.of(context).bmWaist} (${units.lengthUnit})',
                  controller: _waistController,
                  min: c(30),
                  max: c(250)),
              _Field(
                  label: '${AppL10n.of(context).bmChest} (${units.lengthUnit})',
                  controller: _chestController,
                  min: c(30),
                  max: c(250)),
              _Field(
                  label: '${AppL10n.of(context).bmArm} (${units.lengthUnit})',
                  controller: _armController,
                  min: c(10),
                  max: c(100)),
              _Field(
                  label: '${AppL10n.of(context).bmHip} (${units.lengthUnit})',
                  controller: _hipController,
                  min: c(30),
                  max: c(250)),
              _Field(
                  label: '${AppL10n.of(context).bmNeck} (${units.lengthUnit})',
                  controller: _neckController,
                  min: c(10),
                  max: c(100)),
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
