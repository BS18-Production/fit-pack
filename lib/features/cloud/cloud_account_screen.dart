import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../shared/widgets/app_state_views.dart';
import '../settings/backup_service.dart' show RestoreNeedsRestartException;
import 'auth_service.dart';
import 'cloud_backup_service.dart';

/// Bulut hesabı + yedek ekranı (docs/13-cloud-backup.md).
/// Oturum yoksa giriş/kayıt; oturum varsa hesap paneli (Buluta Yedekle /
/// Buluttan Geri Yükle / Çıkış).
class CloudAccountScreen extends ConsumerWidget {
  const CloudAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Bulut Hesabı')),
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
          setState(() => _error =
              'Kayıt alındı. E-postanı doğrulayıp giriş yapabilirsin.');
        }
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Bağlanılamadı: $e');
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
      setState(() => _error =
          'Google girişi henüz yapılandırılmadı ya da iptal edildi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Icon(Icons.cloud_outlined,
            size: AppIconSize.xxl, color: context.colors.primary),
        AppSpacing.vGapMd,
        Text(_isLogin ? 'Giriş yap' : 'Hesap oluştur',
            textAlign: TextAlign.center,
            style: context.texts.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        AppSpacing.vGapSm,
        Text(
          'Verini buluta yedekle, yeni cihazda giriş yapıp geri yükle. '
          'Verin yine öncelikle cihazında tutulur.',
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
          decoration: const InputDecoration(
            labelText: 'E-posta',
            prefixIcon: Icon(Icons.mail_outline_rounded),
            border: OutlineInputBorder(borderRadius: AppRadius.brMd),
          ),
        ),
        AppSpacing.vGapMd,
        TextField(
          controller: _passCtrl,
          obscureText: true,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Şifre (en az 6 karakter)',
            prefixIcon: Icon(Icons.lock_outline_rounded),
            border: OutlineInputBorder(borderRadius: AppRadius.brMd),
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
              : Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol'),
        ),
        AppSpacing.vGapMd,
        OutlinedButton.icon(
          onPressed: _busy ? null : _google,
          style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52)),
          icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
          label: const Text('Google ile devam et'),
        ),
        AppSpacing.vGapLg,
        TextButton(
          onPressed: _busy
              ? null
              : () => setState(() {
                    _isLogin = !_isLogin;
                    _error = null;
                  }),
          child: Text(_isLogin
              ? 'Hesabın yok mu? Kayıt ol'
              : 'Zaten hesabın var mı? Giriş yap'),
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
  DateTime? _lastBackup;
  bool _loadingLast = true;

  @override
  void initState() {
    super.initState();
    _refreshLast();
  }

  Future<void> _refreshLast() async {
    final at = await ref.read(cloudBackupServiceProvider).lastBackupAt();
    if (mounted) {
      setState(() {
        _lastBackup = at;
        _loadingLast = false;
      });
    }
  }

  Future<void> _backup() async {
    setState(() => _busy = true);
    try {
      await ref.read(cloudBackupServiceProvider).backupToCloud();
      await _refreshLast();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Buluta yedeklendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yedeklenemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final ok = await confirmAction(
      context,
      title: 'Buluttan geri yükle',
      message:
          'Cihazdaki tüm verinin yerine bulut yedeği yüklenecek. Bu işlem geri '
          'alınamaz. Devam edilsin mi?',
      confirmLabel: 'Geri Yükle',
      destructive: true,
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await ref.read(cloudBackupServiceProvider).restoreFromCloud();
      if (!mounted) return;
      await showRestartDialog(
        context,
        title: 'Geri yüklendi',
        message:
            'Bulut yedeği yüklendi. Uygulama kapanacak — tekrar açman yeterli.',
      );
    } on FormatException catch (e) {
      // Doğrulama hatası — DB kapanmadan reddedildi, uygulama çalışır durumda.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } on RestoreNeedsRestartException {
      // Kopyalama yarıda kesildi; mevcut veri korundu ama bağlantı kapalı.
      if (mounted) {
        await showRestartDialog(
          context,
          title: 'Geri yükleme başarısız',
          message: 'Bir sorun oluştu, mevcut verin korundu. Uygulama '
              'kapanacak — tekrar açman yeterli.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Geri yükleme başarısız: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lastTxt = _loadingLast
        ? '…'
        : _lastBackup == null
            ? 'Henüz bulut yedeği yok'
            : 'Son bulut yedeği: '
                '${DateFormat('d MMM y · HH:mm', 'tr_TR').format(_lastBackup!)}';

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
                  Text('Giriş yapıldı',
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
        AppSpacing.vGapLg,
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: c.surfaceContainerHighest,
            borderRadius: AppRadius.brMd,
          ),
          child: Row(
            children: [
              Icon(Icons.history_rounded,
                  size: AppIconSize.sm, color: c.onSurfaceVariant),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(lastTxt,
                    style: context.texts.bodySmall
                        ?.copyWith(color: c.onSurfaceVariant)),
              ),
            ],
          ),
        ),
        AppSpacing.vGapLg,
        FilledButton.icon(
          onPressed: _busy ? null : _backup,
          style:
              FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.cloud_upload_rounded),
          label: const Text('Buluta Yedekle'),
        ),
        AppSpacing.vGapMd,
        OutlinedButton.icon(
          onPressed: _busy ? null : _restore,
          style:
              OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          icon: const Icon(Icons.cloud_download_rounded),
          label: const Text('Buluttan Geri Yükle'),
        ),
        AppSpacing.vGapxl_,
        TextButton.icon(
          onPressed: _busy ? null : _signOut,
          icon: Icon(Icons.logout_rounded, color: c.error),
          label: Text('Çıkış Yap', style: TextStyle(color: c.error)),
        ),
      ],
    );
  }
}
