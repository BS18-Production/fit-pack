import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/fitpack_icon.dart';
import 'body_providers.dart';

/// Tartıdan kilo — **açık rıza** ekranı (docs/41 §3, KVKK md. 6, GDPR md.
/// 9/2-a). Ne işlenir, nerede, neden, kimle paylaşılmaz, nasıl geri alınır;
/// önceden işaretli kutu yok, "Kabul" ve "Vazgeç" eşit ağırlıkta.
///
/// Metin değişirse `kHealthConsentVersion` artırılır → rıza yeniden istenir.
Future<void> showBodyConsentSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      // Sistem izin penceresi açıkken sheet'in ref'i yaşamaya devam eder.
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const _BodyConsentSheet(),
    );

/// Rızayı geri alma (GDPR md. 7/3 — vermek kadar kolay): içe alınanlar
/// tutulsun mu, silinsin mi?
Future<void> showBodyConsentWithdrawDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final l = AppL10n.of(context);
  final choice = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.healthWithdrawTitle),
      content: Text(l.healthWithdrawMsg),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.healthWithdrawKeep),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.healthWithdrawDelete),
        ),
      ],
    ),
  );
  if (choice == null) return;
  await withdrawHealthConsent(ref, deleteImported: choice);
}

class _BodyConsentSheet extends ConsumerStatefulWidget {
  const _BodyConsentSheet();

  @override
  ConsumerState<_BodyConsentSheet> createState() => _BodyConsentSheetState();
}

class _BodyConsentSheetState extends ConsumerState<_BodyConsentSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _accept() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await grantHealthConsentAndImport(ref);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppL10n.of(context).healthConnectError);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return PopScope(
      canPop: !_busy,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          context.sheetBottomInset + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.healthConsentTitle, style: context.texts.titleLarge),
            AppSpacing.vGapXl,
            _Line(Icons.monitor_weight_outlined, l.healthConsentWhat),
            AppSpacing.vGapLg,
            _Line(Icons.cloud_outlined, l.healthConsentWhere),
            AppSpacing.vGapLg,
            _Line(Icons.insights_rounded, l.healthConsentWhy),
            AppSpacing.vGapLg,
            _Line(Icons.lock_outline_rounded, l.healthConsentNoShare),
            AppSpacing.vGapLg,
            _Line(Icons.undo_rounded, l.healthConsentWithdraw),
            AppSpacing.vGapLg,
            Text(
              l.healthConsentLegal,
              style: context.texts.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            if (_error != null) ...[
              AppSpacing.vGapLg,
              Text(
                _error!,
                style: context.texts.bodyMedium?.copyWith(
                  color: context.colors.error,
                ),
              ),
            ],
            AppSpacing.vGapXl,
            // Eşit ağırlık: iki düğme aynı boyda, biri öne itilmiyor.
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('health.consentDecline'),
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: Text(l.healthConsentDecline),
                  ),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('health.consentAccept'),
                    onPressed: _busy ? null : _accept,
                    child: Text(l.healthConsentAccept),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Line(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FitPackIcon.material(icon, color: context.colors.primary),
      AppSpacing.hGapMd,
      Expanded(child: Text(text, style: context.texts.bodyMedium)),
    ],
  );
}
