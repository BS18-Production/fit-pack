import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import '../cloud/auth_service.dart';
import 'auth_gate.dart';

/// Şifre kurtarma — maildeki bağlantıdan gelen kullanıcı yeni şifresini burada
/// belirler (docs/18 §14).
///
/// **Neden ayrı ekran:** sıfırlama bağlantısı Supabase'de gerçek bir oturum
/// açar. Bu ekran olmasaydı kullanıcı doğrudan uygulamaya düşer, şifresi
/// değişmemiş olurdu — yani bir sonraki cihazda yine giremezdi.
/// `AuthGate.recovering` açıkken kapı kullanıcıyı burada tutar.
///
/// **Geri düğmesi yok** (kapı zaten dışarı çıkmayı engelliyor), ama çıkış yolu
/// var: vazgeçen kullanıcı oturumu kapatıp karşılamaya döner — yoksa bağlantıyı
/// yanlışlıkla açan kişi ekranda kilitli kalırdı.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _repeatCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _passCtrl.dispose();
    _repeatCtrl.dispose();
    super.dispose();
  }

  /// Şifre iki kez sorulur: tek alanla yazım hatası yapan kullanıcı, kendi
  /// bilmediği bir şifreye geçer ve hesabına bir daha giremezdi.
  bool get _valid =>
      _passCtrl.text.length >= 6 && _repeatCtrl.text.length >= 6;

  Future<void> _save() async {
    final l = AppL10n.of(context);
    if (_passCtrl.text != _repeatCtrl.text) {
      setState(() => _error = l.cloudResetMismatch);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).updatePassword(_passCtrl.text);
      if (!mounted) return;
      // Kilit kalkar → router kullanıcıyı onboarding'e ya da Ana Sayfa'ya taşır.
      ref.read(authGateProvider).clearRecovery();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.cloudResetOk)));
    } on AuthException catch (e) {
      // En olası sebep: bağlantının süresi dolmuş / oturum düşmüş.
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = AppL10n.of(context).cloudConnErr(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).signOut();
      // Çıkış olayı kurtarma bayrağını da düşürür (AuthGate._onAuth).
    } catch (_) {
      // Çıkış ağa bağlı değil; hata olsa da kilidi bırak ki kullanıcı sıkışmasın.
      if (mounted) ref.read(authGateProvider).clearRecovery();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.cloudResetTitle),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text(
              l.cloudResetIntro,
              style: context.texts.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
            AppSpacing.vGapXl,
            TextField(
              controller: _passCtrl,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(
                labelText: l.cloudResetNew,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                border: const OutlineInputBorder(borderRadius: AppRadius.brMd),
              ),
            ),
            AppSpacing.vGapMd,
            TextField(
              controller: _repeatCtrl,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(
                labelText: l.cloudResetRepeat,
                prefixIcon: const Icon(Icons.lock_reset_rounded),
                border: const OutlineInputBorder(borderRadius: AppRadius.brMd),
              ),
            ),
            if (_error != null) ...[
              AppSpacing.vGapMd,
              Text(_error!,
                  style: context.texts.bodySmall
                      ?.copyWith(color: context.colors.error)),
            ],
            AppSpacing.vGapXl,
            FilledButton(
              onPressed: (_busy || !_valid) ? null : _save,
              style:
                  FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l.cloudResetSave),
            ),
            AppSpacing.vGapLg,
            TextButton(
              onPressed: _busy ? null : _cancel,
              child: Text(l.cloudResetCancel),
            ),
          ],
        ),
      ),
    );
  }
}
