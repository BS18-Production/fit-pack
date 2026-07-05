import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';

/// Barkod tarama ekranı (docs/07-nutrition-v2.md §6.3).
/// İlk geçerli barkodu okuyunca `String` ile pop eder. "Elle gir" → null pop;
/// çağıran tarafı custom yemek diyaloğuna düşürür.
class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    unawaited(_controller.start());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.trim().isNotEmpty,
            orElse: () => null);
    if (raw == null) return;
    _handled = true;
    Navigator.of(context).pop(raw.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    // Kamera vizörü: doğası gereği tema-bağımsız siyah zemin + beyaz metin.
    // Tema token'ı bilinçli kullanılmıyor (L-03 istisnası).
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l.scanTitle),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (_, state, _) {
              final on = state.torchState == TorchState.on;
              return IconButton(
                tooltip: on ? l.scanTorchOff : l.scanTorchOn,
                icon: Icon(on
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded),
                onPressed: () => _controller.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _ScanError(
              message: switch (error.errorCode) {
                MobileScannerErrorCode.permissionDenied =>
                  l.scanPermissionDenied,
                _ => l.scanCameraError,
              },
            ),
          ),
          // Tarama çerçevesi (görsel ipucu).
          IgnorePointer(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.85),
                      width: 2),
                  borderRadius: AppRadius.brLg,
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.xxl,
            child: Column(
              children: [
                Text(
                  l.scanFrameHint,
                  textAlign: TextAlign.center,
                  style: context.texts.bodyMedium
                      ?.copyWith(color: Colors.white),
                ),
                AppSpacing.vGapMd,
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: Text(l.scanManualAdd),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanError extends StatelessWidget {
  final String message;
  const _ScanError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography_rounded,
              color: Colors.white70, size: AppIconSize.xl),
          AppSpacing.vGapLg,
          Text(message,
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium
                  ?.copyWith(color: Colors.white)),
          AppSpacing.vGapLg,
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppL10n.of(context).scanManualAdd),
          ),
        ],
      ),
    );
  }
}
