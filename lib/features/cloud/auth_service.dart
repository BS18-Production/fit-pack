import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase hesap/oturum sarmalayıcı (docs/13-cloud-backup.md).
/// E-posta/şifre + Google ile giriş. Yerel-öncelikli mimaride bulut opsiyonel:
/// oturum yoksa uygulama yereldeki veriyle normal çalışır.
class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get onAuthChange => _client.auth.onAuthStateChange;

  Future<void> signUpWithEmail(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Google ile giriş (OAuth). Google sağlayıcı + OAuth client kurulumu gerekir
  /// (docs/13 §5). Kurulmadan çağrılırsa Supabase hata döndürür.
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      // Mobilde deep-link geri dönüşü; AndroidManifest'e intent-filter eklenir.
      redirectTo: 'fitpack://login-callback',
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Oturum durumu akışı — UI buna göre giriş ekranı / hesap paneli gösterir.
final authStateProvider = StreamProvider<AuthState?>((ref) {
  // Supabase init başarısızsa (ağ yok) stream'e erişmeden null dön.
  try {
    return ref.watch(authServiceProvider).onAuthChange;
  } catch (_) {
    return const Stream.empty();
  }
});

/// O anki kullanıcı (oturum yoksa null). authState değişince yeniden okunur.
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  try {
    return ref.watch(authServiceProvider).currentUser;
  } catch (_) {
    return null;
  }
});
