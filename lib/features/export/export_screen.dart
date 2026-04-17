import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/services/export_service.dart';
import '../../data/providers.dart';

enum _Format { markdown, json, csv }
enum _Range { week, month, all }

extension on _Range {
  DateTime start(DateTime now) {
    switch (this) {
      case _Range.week:
        return now.subtract(const Duration(days: 7));
      case _Range.month:
        return now.subtract(const Duration(days: 30));
      case _Range.all:
        return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }
}

extension on _Format {
  String get ext => switch (this) {
        _Format.markdown => 'md',
        _Format.json => 'json',
        _Format.csv => 'csv',
      };
}

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  _Format _format = _Format.markdown;
  _Range _range = _Range.week;
  ExportScope _scope = ExportScope.all;
  bool _exporting = false;

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final service = ExportService(ref.read(databaseProvider));
      final now = DateTime.now();
      final start = _range.start(now);

      final content = switch (_format) {
        _Format.markdown => await service.exportMarkdown(start, now, scope: _scope),
        _Format.json => await service.exportJson(start, now, scope: _scope),
        _Format.csv => await service.exportCsv(start, now, scope: _scope),
      };

      await Share.share(content, subject: 'fit_pack_export.${_format.ext}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export hatası: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Veri Export')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.file_download, size: 48, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              'Verini export et, LLM ile analiz et',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Text('Format', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<_Format>(
              segments: const [
                ButtonSegment(value: _Format.markdown, label: Text('Markdown')),
                ButtonSegment(value: _Format.json, label: Text('JSON')),
                ButtonSegment(value: _Format.csv, label: Text('CSV')),
              ],
              selected: {_format},
              onSelectionChanged: (v) => setState(() => _format = v.first),
            ),
            const SizedBox(height: 20),

            Text('Tarih Aralığı', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<_Range>(
              segments: const [
                ButtonSegment(value: _Range.week, label: Text('1 Hafta')),
                ButtonSegment(value: _Range.month, label: Text('1 Ay')),
                ButtonSegment(value: _Range.all, label: Text('Tümü')),
              ],
              selected: {_range},
              onSelectionChanged: (v) => setState(() => _range = v.first),
            ),
            const SizedBox(height: 20),

            Text('Kapsam', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<ExportScope>(
              segments: const [
                ButtonSegment(value: ExportScope.all, label: Text('Hepsi')),
                ButtonSegment(value: ExportScope.workout, label: Text('Antrenman')),
                ButtonSegment(value: ExportScope.nutrition, label: Text('Beslenme')),
              ],
              selected: {_scope},
              onSelectionChanged: (v) => setState(() => _scope = v.first),
            ),
            const Spacer(),

            ElevatedButton.icon(
              onPressed: _exporting ? null : _export,
              icon: _exporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share),
              label: Text(_exporting ? 'Hazırlanıyor...' : 'Export & Paylaş'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
