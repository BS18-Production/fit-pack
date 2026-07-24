import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import '../cloud/auth_service.dart';

/// Hangi giriş yolu çalışıyor — doğru butonda yükleniyor göstergesi için.
enum _Busy { none, email, google }

/// ② Giriş / Kayıt — zorunlu kapının ikinci adımı (docs/18 §5.1).
///
/// Bu ekran Ayarlar'dan açılan bir alt sayfa değil, **tam ekran kapıdır**:
/// geçilmeden uygulamaya girilemez. Başarılı girişten sonra yönlendirmeyi
/// ekran değil **router** yapar (`gateRedirect` + `refreshListenable`) — oturum
/// açılınca kapı kendiliğinden onboarding'e ya da Ana Sayfa'ya geçer.
///
/// **Google birincil (docs/18 §13 kararı):** e-posta doğrulama açık kalıyor,
/// sürtünmeyi Google'ı öne çıkararak çözüyoruz — Google zaten doğrulanmış gelir,
/// tek dokunuş. E-posta/şifre ikincil yol olarak ayırıcının altında durur.
class AuthScreen extends ConsumerStatefulWidget {
  /// Karşılamadaki hangi düğmeye basıldı: "Hesap oluştur" → kayıt sekmesi.
  final bool signUp;

  const AuthScreen({super.key, this.signUp = false});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  late bool _isLogin = !widget.signUp;
  _Busy _busy = _Busy.none;
  String? _error;

  /// Nötr bilgi mesajı (hata DEĞİL) — kayıt sonrası "e-postanı doğrula".
  /// Kırmızı hata rengiyle gösterilmez.
  String? _info;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool get _valid => _emailCtrl.text.contains('@') && _passCtrl.text.length >= 6;

  Future<void> _submitEmail() async {
    setState(() {
      _busy = _Busy.email;
      _error = null;
      _info = null;
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
          // E-posta doğrulama açık (Supabase "Confirm email"): oturum hemen
          // açılmaz. Kullanıcıyı GİRİŞ sekmesine al ve nötr bilgi göster —
          // "kayıt oldun, e-postanı doğrulayıp giriş yap". Hata DEĞİL, o yüzden
          // kırmızı gösterme.
          setState(() {
            _isLogin = true;
            _info = AppL10n.of(context).cloudSignupOk;
          });
        }
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = AppL10n.of(context).cloudConnErr(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
    }
  }

  Future<void> _google() async {
    setState(() {
      _busy = _Busy.google;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) setState(() => _error = AppL10n.of(context).cloudGoogleErr);
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? l.cloudSignIn : l.cloudCreateAccount),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text(
              _isLogin ? l.cloudIntro : l.cloudIntroSignUp,
              style: context.texts.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
            AppSpacing.vGapXl,
            // Birincil yol: Google — tek dokunuş, zaten doğrulanmış (docs/18 §13).
            FilledButton.icon(
              onPressed: _busy != _Busy.none ? null : _google,
              style:
                  FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              icon: _busy == _Busy.google
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.g_mobiledata_rounded, size: 28),
              label: Text(l.cloudGoogle),
            ),
            if (_error != null) ...[
              AppSpacing.vGapMd,
              Text(_error!,
                  style: context.texts.bodySmall
                      ?.copyWith(color: context.colors.error)),
            ],
            AppSpacing.vGapLg,
            // Ayırıcı: "ya da e-posta ile devam et".
            Row(
              children: [
                const Expanded(child: Divider()),
                AppSpacing.hGapMd,
                Text(
                  l.cloudOrEmail,
                  style: context.texts.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
                AppSpacing.hGapMd,
                const Expanded(child: Divider()),
              ],
            ),
            AppSpacing.vGapLg,
            // İkincil yol: e-posta / şifre.
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
            if (_info != null) ...[
              AppSpacing.vGapMd,
              Row(
                children: [
                  Icon(Icons.mark_email_read_outlined,
                      size: AppIconSize.sm, color: context.colors.primary),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Text(_info!,
                        style: context.texts.bodySmall
                            ?.copyWith(color: context.colors.primary)),
                  ),
                ],
              ),
            ],
            AppSpacing.vGapLg,
            OutlinedButton(
              onPressed:
                  (_busy != _Busy.none || !_valid) ? null : _submitEmail,
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              child: _busy == _Busy.email
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isLogin ? l.cloudSignInBtn : l.cloudSignUpBtn),
            ),
            AppSpacing.vGapLg,
            TextButton(
              onPressed: _busy != _Busy.none
                  ? null
                  : () => setState(() {
                        _isLogin = !_isLogin;
                        _error = null;
                        _info = null;
                      }),
              child: Text(_isLogin ? l.cloudNoAccount : l.cloudHaveAccount),
            ),
          ],
        ),
      ),
    );
  }
}
