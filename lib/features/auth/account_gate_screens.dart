import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import 'auth_gate.dart';

/// Kapının iki "dur" ekranı (docs/20 §7.4, §7.5). İkisi de kullanıcıyı
/// uygulamanın içine ALMAZ: veri sızıntısı ya da veri kaybı riski varken
/// sessizce devam etmek en kötü seçenek.

/// Hesap doğrulanamadı (§7.5). Hesap kontrolü başarısızsa içeri girilirse
/// **önceki hesabın verisi** görünebilir — o yüzden kapı kapalı kalır.
class AccountErrorScreen extends ConsumerStatefulWidget {
  const AccountErrorScreen({super.key});

  @override
  ConsumerState<AccountErrorScreen> createState() => _AccountErrorScreenState();
}

class _AccountErrorScreenState extends ConsumerState<AccountErrorScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final gate = ref.read(authGateProvider);
    return _GateScaffold(
      icon: Icons.shield_outlined,
      title: l.accountErrorTitle,
      message: l.accountErrorBody,
      actions: [
        FilledButton(
          onPressed: _busy ? null : () => _run(gate.retryAccountCheck),
          child: Text(l.commonRetry),
        ),
        TextButton(
          onPressed: _busy
              ? null
              : () => _run(() => Supabase.instance.client.auth.signOut()),
          child: Text(l.cloudSignOut),
        ),
      ],
    );
  }
}

/// Gönderilmemiş kayıt + farklı hesap (§7.4). Varsayılan seçenek **geri
/// dönmek**: silme geri alınamaz, çıkış alınabilir.
class AccountConflictScreen extends ConsumerStatefulWidget {
  const AccountConflictScreen({super.key});

  @override
  ConsumerState<AccountConflictScreen> createState() =>
      _AccountConflictScreenState();
}

class _AccountConflictScreenState extends ConsumerState<AccountConflictScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDiscard(AuthGate gate) async {
    final l = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.accountConflictDiscardTitle),
        content: Text(l.accountConflictDiscardBody(gate.pendingConflictRows)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ctx.colors.error,
              foregroundColor: ctx.colors.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.accountConflictDiscard),
          ),
        ],
      ),
    );
    if (ok == true) await _run(gate.discardPendingAndContinue);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final gate = ref.read(authGateProvider);
    return _GateScaffold(
      icon: Icons.cloud_upload_outlined,
      title: l.accountConflictTitle,
      message: l.accountConflictBody(gate.pendingConflictRows),
      actions: [
        // Öne çıkan seçenek geri dönmek — kayıp geri alınamaz.
        FilledButton(
          onPressed: _busy
              ? null
              : () => _run(() => Supabase.instance.client.auth.signOut()),
          child: Text(l.accountConflictGoBack),
        ),
        TextButton(
          onPressed: _busy ? null : () => _confirmDiscard(gate),
          style: TextButton.styleFrom(foregroundColor: context.colors.error),
          child: Text(l.accountConflictDiscard),
        ),
      ],
    );
  }
}

class _GateScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final List<Widget> actions;
  const _GateScaffold({
    required this.icon,
    required this.title,
    required this.message,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppIconSize.xxl, color: context.colors.primary),
              AppSpacing.vGapLg,
              Text(title,
                  textAlign: TextAlign.center,
                  style: context.texts.headlineSmall),
              AppSpacing.vGapMd,
              Text(message,
                  textAlign: TextAlign.center,
                  style: context.texts.bodyMedium
                      ?.copyWith(color: context.colors.onSurfaceVariant)),
              AppSpacing.vGapXl,
              ...actions,
            ],
          ),
        ),
      ),
    ),
  );
}
