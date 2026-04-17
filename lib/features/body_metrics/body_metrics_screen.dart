import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/providers.dart';
import '../../data/database/app_database.dart';

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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMeasurementDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: measurementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (measurements) {
          if (measurements.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monitor_weight_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Henüz ölçüm yok', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('+ butonuyla ilk ölçümünü ekle', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          final latest = measurements.first;
          final oldest = measurements.length > 1 ? measurements.last : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary card
              _SummaryCard(latest: latest, oldest: oldest),
              const SizedBox(height: 16),

              // History
              Text(
                'Geçmiş Ölçümler',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...measurements.map((m) => _MeasurementCard(
                    measurement: m,
                    onDelete: () async {
                      await ref.read(bodyDaoProvider).deleteMeasurement(m.id);
                      ref.invalidate(allMeasurementsProvider);
                    },
                  )),
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

class _SummaryCard extends StatelessWidget {
  final BodyMeasurement latest;
  final BodyMeasurement? oldest;

  const _SummaryCard({required this.latest, required this.oldest});

  @override
  Widget build(BuildContext context) {
    final weightDiff = oldest != null && latest.weightKg != null && oldest!.weightKg != null
        ? latest.weightKg! - oldest!.weightKg!
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Son Ölçümler', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MetricTile(
                  label: 'Kilo',
                  value: latest.weightKg != null ? '${latest.weightKg!.toStringAsFixed(1)} kg' : '--',
                  diff: weightDiff,
                  unit: 'kg',
                ),
                _MetricTile(
                  label: 'Bel',
                  value: latest.waistCm != null ? '${latest.waistCm!.toStringAsFixed(1)} cm' : '--',
                ),
                _MetricTile(
                  label: 'Kol',
                  value: latest.armCm != null ? '${latest.armCm!.toStringAsFixed(1)} cm' : '--',
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
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (diff != null)
          Text(
            '${diff! > 0 ? '+' : ''}${diff!.toStringAsFixed(1)} $unit',
            style: TextStyle(
              fontSize: 11,
              color: diff! < 0 ? Colors.green : Colors.red,
            ),
          ),
      ],
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  final BodyMeasurement measurement;
  final VoidCallback onDelete;

  const _MeasurementCard({required this.measurement, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(DateFormat('d MMM yyyy').format(measurement.date)),
        subtitle: Text(
          [
            if (measurement.weightKg != null) '${measurement.weightKg!.toStringAsFixed(1)} kg',
            if (measurement.waistCm != null) 'Bel: ${measurement.waistCm!.toStringAsFixed(1)}',
            if (measurement.armCm != null) 'Kol: ${measurement.armCm!.toStringAsFixed(1)}',
            if (measurement.chestCm != null) 'Göğüs: ${measurement.chestCm!.toStringAsFixed(1)}',
          ].join(' | '),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
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
  final _weightController = TextEditingController();
  final _waistController = TextEditingController();
  final _chestController = TextEditingController();
  final _armController = TextEditingController();
  final _hipController = TextEditingController();
  final _neckController = TextEditingController();
  final _fatController = TextEditingController();

  Future<void> _save() async {
    await widget.ref.read(bodyDaoProvider).insertMeasurement(
          BodyMeasurementsCompanion(
            date: Value(DateTime.now()),
            weightKg: Value(double.tryParse(_weightController.text)),
            waistCm: Value(double.tryParse(_waistController.text)),
            chestCm: Value(double.tryParse(_chestController.text)),
            armCm: Value(double.tryParse(_armController.text)),
            hipCm: Value(double.tryParse(_hipController.text)),
            neckCm: Value(double.tryParse(_neckController.text)),
            bodyFatPct: Value(double.tryParse(_fatController.text)),
          ),
        );
    widget.ref.invalidate(allMeasurementsProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Yeni Ölçüm',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            _FieldRow(label: 'Kilo (kg)', controller: _weightController),
            _FieldRow(label: 'Bel (cm)', controller: _waistController),
            _FieldRow(label: 'Göğüs (cm)', controller: _chestController),
            _FieldRow(label: 'Kol (cm)', controller: _armController),
            _FieldRow(label: 'Kalça (cm)', controller: _hipController),
            _FieldRow(label: 'Boyun (cm)', controller: _neckController),
            _FieldRow(label: 'Yağ Oranı (%)', controller: _fatController),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _FieldRow({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
