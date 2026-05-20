import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
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

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? context.colors.error : null,
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final service = ExportService(ref.read(databaseProvider));
      final now = DateTime.now();
      final start = _range.start(now);

      final content = switch (_format) {
        _Format.markdown =>
          await service.exportMarkdown(start, now, scope: _scope),
        _Format.json => await service.exportJson(start, now, scope: _scope),
        _Format.csv => await service.exportCsv(start, now, scope: _scope),
      };

      if (content.trim().isEmpty) {
        _snack('Seçilen aralıkta dışa aktarılacak veri yok');
        return;
      }

      await Share.share(content,
          subject: 'fit_pack_export.${_format.ext}');
    } catch (_) {
      _snack('Paylaşım başarısız oldu, tekrar dene', error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Veri Dışa Aktar')),
      body: Padding(
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.ios_share_rounded,
                    size: AppIconSize.lg, color: context.colors.primary),
              ),
            ),
            AppSpacing.vGapMd,
            Text('Verini dışa aktar, yapay zekâ ile analiz et',
                style: context.texts.titleMedium,
                textAlign: TextAlign.center),
            AppSpacing.vGapXl,
            _Section(
              title: 'Format',
              child: SegmentedButton<_Format>(
                segments: const [
                  ButtonSegment(
                      value: _Format.markdown, label: Text('Markdown')),
                  ButtonSegment(value: _Format.json, label: Text('JSON')),
                  ButtonSegment(value: _Format.csv, label: Text('CSV')),
                ],
                selected: {_format},
                onSelectionChanged: (v) =>
                    setState(() => _format = v.first),
              ),
            ),
            _Section(
              title: 'Tarih Aralığı',
              child: SegmentedButton<_Range>(
                segments: const [
                  ButtonSegment(value: _Range.week, label: Text('1 Hafta')),
                  ButtonSegment(value: _Range.month, label: Text('1 Ay')),
                  ButtonSegment(value: _Range.all, label: Text('Tümü')),
                ],
                selected: {_range},
                onSelectionChanged: (v) => setState(() => _range = v.first),
              ),
            ),
            _Section(
              title: 'Kapsam',
              child: SegmentedButton<ExportScope>(
                segments: const [
                  ButtonSegment(value: ExportScope.all, label: Text('Hepsi')),
                  ButtonSegment(
                      value: ExportScope.workout, label: Text('Antrenman')),
                  ButtonSegment(
                      value: ExportScope.nutrition, label: Text('Beslenme')),
                ],
                selected: {_scope},
                onSelectionChanged: (v) => setState(() => _scope = v.first),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _exporting ? null : _export,
              icon: _exporting
                  ? SizedBox(
                      width: AppIconSize.sm,
                      height: AppIconSize.sm,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colors.onPrimary),
                    )
                  : const Icon(Icons.ios_share_rounded),
              label: Text(_exporting ? 'Hazırlanıyor…' : 'Dışa Aktar & Paylaş'),
            ),
            AppSpacing.vGapXl,
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.texts.titleSmall),
          AppSpacing.vGapSm,
          child,
        ],
      ),
    );
  }
}
