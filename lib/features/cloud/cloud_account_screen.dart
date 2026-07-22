import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/app_state_views.dart';
import 'auth_service.dart';

/// Hesap ekranı (docs/18-auth-and-sync.md).
/// Oturum yoksa giriş/kayıt; oturum varsa hesap paneli (Çıkış / Hesabı Sil).
///
/// **Elle bulut yedekleme KALDIRILDI (2026-07-21, docs/18 §1).** Veriler
/// hesaba otomatik senkron edilir (outbox deseni, docs/18 §6) — kullanıcının
/// "yedekle"/"geri yükle" düğmelerine basmasına gerek yok. Senkron durumu
/// göstergesi Aşama G'de bu ekrana eklenecek.
class CloudAccountScreen extends ConsumerWidget {
  const CloudAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppL10n.of(context).settingsCloudAccount)),
      body: user == null
          ? const _AuthForm()
          : _AccountPanel(email: user.email ?? '—'),
    );
  }
}

// ───────────────────────────── Giriş / Kayıt ─────────────────────────────

class _AuthForm extends ConsumerStatefulWidget {
  const _AuthForm();
  @override
  ConsumerState<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<_AuthForm> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLogin = true; // true: giriş, false: kayıt
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool get _valid =>
      _emailCtrl.text.contains('@') && _passCtrl.text.length >= 6;

  Future<void> _submitEmail() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(authServiceProvider);
    try {
      final email = _emailCtrl.text.trim();
      final pass = _passCtrl.text;
      if (_isLogin) {
        await auth.signInWithEmail(email, pass);
      } else {
        await auth.signUpWithEmail(email, pass);
        if (mounted && ref.read(currentUserProvider) == null) {
          // E-posta doğrulama açıksa oturum hemen açılmaz.
          setState(
              () => _error = AppL10n.of(context).cloudSignupOk);
        }
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = AppL10n.of(context).cloudConnErr(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() => _error = AppL10n.of(context).cloudGoogleErr);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Icon(Icons.cloud_outlined,
            size: AppIconSize.xxl, color: context.colors.primary),
        AppSpacing.vGapMd,
        Text(_isLogin ? l.cloudSignIn : l.cloudCreateAccount,
            textAlign: TextAlign.center,
            style: context.texts.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        AppSpacing.vGapSm,
        Text(
          l.cloudIntro,
          textAlign: TextAlign.center,
          style: context.texts.bodyMedium
              ?.copyWith(color: context.colors.onSurfaceVariant),
        ),
        AppSpacing.vGapXl,
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: l.cloudEmail,
            prefixIcon: const Icon(Icons.mail_outline_rounded),
            border: const OutlineInputBorder(borderRadius: AppRadius.brMd),
          ),
        ),
        AppSpacing.vGapMd,
        TextField(
          controller: _passCtrl,
          obscureText: true,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: l.cloudPassword,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            border: const OutlineInputBorder(borderRadius: AppRadius.brMd),
          ),
        ),
        if (_error != null) ...[
          AppSpacing.vGapMd,
          Text(_error!,
              style: context.texts.bodySmall
                  ?.copyWith(color: context.colors.error)),
        ],
        AppSpacing.vGapLg,
        FilledButton(
          onPressed: (_busy || !_valid) ? null : _submitEmail,
          style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52)),
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_isLogin ? l.cloudSignInBtn : l.cloudSignUpBtn),
        ),
        AppSpacing.vGapMd,
        OutlinedButton.icon(
          onPressed: _busy ? null : _google,
          style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52)),
          icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
          label: Text(l.cloudGoogle),
        ),
        AppSpacing.vGapLg,
        TextButton(
          onPressed: _busy
              ? null
              : () => setState(() {
                    _isLogin = !_isLogin;
                    _error = null;
                  }),
          child:
              Text(_isLogin ? l.cloudNoAccount : l.cloudHaveAccount),
        ),
      ],
    );
  }
}

// ───────────────────────────── Hesap paneli ─────────────────────────────

class _AccountPanel extends ConsumerStatefulWidget {
  final String email;
  const _AccountPanel({required this.email});
  @override
  ConsumerState<_AccountPanel> createState() => _AccountPanelState();
}

class _AccountPanelState extends ConsumerState<_AccountPanel> {
  bool _busy = false;

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (mounted) Navigator.of(context).maybePop();
  }

  /// Hesabı kalıcı sil (docs/16 §4) — çift onay.
  /// Sunucudaki veriler `on delete cascade` ile hesapla birlikte silinir
  /// (docs/18 §7). Cihazdaki yerel veri etkilenmez.
  Future<void> _deleteAccount() async {
    final l = AppL10n.of(context);
    final ok1 = await confirmAction(
      context,
      title: l.cloudDeleteTitle,
      message: l.cloudDeleteMsg,
      confirmLabel: l.commonDelete,
      destructive: true,
    );
    if (!ok1 || !mounted) return;
    final ok2 = await confirmAction(
      context,
      title: l.cloudDeleteConfirm2Title,
      message: l.cloudDeleteConfirm2Msg,
      confirmLabel: l.cloudDeleteAccount,
      destructive: true,
    );
    if (!ok2 || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).deleteAccount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.cloudDeleted)),
        );
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.cloudDeleteFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppL10n.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        // hesap başlığı
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: c.primaryContainer,
              child: Icon(Icons.person_rounded, color: c.onPrimaryContainer),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.settingsCloudSignedInFallback,
                      style: context.texts.labelMedium
                          ?.copyWith(color: c.onSurfaceVariant)),
                  Text(widget.email,
                      style: context.texts.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        AppSpacing.vGapxl_,
        TextButton.icon(
          onPressed: _busy ? null : _signOut,
          icon: Icon(Icons.logout_rounded, color: c.error),
          label: Text(l.cloudSignOut, style: TextStyle(color: c.error)),
        ),
        AppSpacing.vGapSm,
        TextButton.icon(
          onPressed: _busy ? null : _deleteAccount,
          icon: Icon(Icons.delete_forever_rounded, color: c.error),
          label: Text(l.cloudDeleteAccount, style: TextStyle(color: c.error)),
        ),
      ],
    );
  }
}
