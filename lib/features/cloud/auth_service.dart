import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';

/// Supabase hesap/oturum sarmalayıcı (docs/13-cloud-backup.md).
/// E-posta/şifre + Google ile giriş. Yerel-öncelikli mimaride bulut opsiyonel:
/// oturum yoksa uygulama yereldeki veriyle normal çalışır.
class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get onAuthChange => _client.auth.onAuthStateChange;

  /// Kayıt. `emailRedirectTo` **şart**: verilmezse Supabase doğrulama
  /// bağlantısını projenin **Site URL**'ine yollar, o da varsayılan
  /// `http://localhost:3000` olduğu için kullanıcı "This site can't be
  /// reached" hatasına düşer (hesap onaylanır ama kullanıcı bunu göremez).
  /// Deep link verilince bağlantı doğrudan uygulamayı açar.
  Future<void> signUpWithEmail(String email, String password) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: _deepLink,
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Google ile giriş. Platformun yerel akışı hazırsa **yerel (native)** akış
  /// (cihazın hesap seçicisi, tek dokunuş, izin ekranında ham `supabase.co`
  /// YOK); değilse **tarayıcı** akışı (docs/18 §5.2.1 D).
  ///
  /// Hazırlık platform başına ayrıdır: her platform Google'da kendi OAuth
  /// client'ını ister (iOS bundle kimliğiyle, Android SHA-1 imzasıyla). Bu
  /// yüzden tek bayrak yerine platform bayrağı okunur — biri hazır diye
  /// diğerinde yerel akış denenirse giriş çalışma zamanında patlar.
  ///
  /// Dönüş: kullanıcı iptal ettiyse `false`, giriş başladıysa/başarılıysa
  /// `true`. Tarayıcı akışı asenkron döndüğü için hep `true` sayılır (sonucu
  /// `onAuthStateChange` bildirir).
  Future<bool> signInWithGoogle() async {
    const webClientId = SupabaseConfig.googleWebClientId;
    if (webClientId.isEmpty || !_nativeGoogleReady) {
      await _signInWithGoogleBrowser();
      return true;
    }
    return _signInWithGoogleNative(webClientId);
  }

  bool get _nativeGoogleReady => switch (defaultTargetPlatform) {
        TargetPlatform.iOS => SupabaseConfig.googleNativeOnIos,
        TargetPlatform.android => SupabaseConfig.googleNativeOnAndroid,
        _ => false,
      };

  /// Tarayıcı/özel sekme akışı — yalnız Web OAuth client gerekir. Supabase deep
  /// link'i `fitpack://login-callback` ile geri döner (manifest intent-filter).
  Future<void> _signInWithGoogleBrowser() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _deepLink,
    );
  }

  /// Yerel akış: cihazın Google hesap seçicisi açılır, alınan `idToken`
  /// doğrudan Supabase'e verilir (`signInWithIdToken`). Tarayıcı hiç açılmaz.
  ///
  /// `serverClientId` = **Web** client ID: Google, token'ı bu `aud` için imzalar
  /// ve Supabase'in provider'ında tanımlı client ile eşleşmesi gerekir.
  Future<bool> _signInWithGoogleNative(String webClientId) async {
    final googleSignIn = GoogleSignIn(serverClientId: webClientId);
    final account = await googleSignIn.signIn();
    if (account == null) return false; // kullanıcı iptal etti
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw const AuthException('Google kimlik doğrulaması eksik (idToken yok)');
    }
    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: auth.accessToken,
    );
    return true;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Hesabı kalıcı olarak siler (docs/16 §4 — mağaza zorunluluğu).
  /// Supabase tarafında `delete_user()` security-definer RPC fonksiyonu
  /// kurulu olmalı (SQL: docs/16 §4). Fonksiyon yoksa PostgrestException
  /// fırlar → UI hata gösterir, oturum açık kalır.
  Future<void> deleteAccount() async {
    await _client.rpc('delete_user');
    await _client.auth.signOut();
  }

  /// Şifre sıfırlama bağlantısı gönderir (docs/18 §14).
  ///
  /// **Zorunlu hesap mimarisinde bu bir veri kurtarma yoludur:** şifresini
  /// unutan kullanıcının hesabı = antrenman geçmişinin tek anahtarı.
  ///
  /// `redirectTo` Google girişiyle **aynı** deep link'i kullanır
  /// (`fitpack://login-callback`, manifest intent-filter). Maildeki bağlantı
  /// uygulamayı açar, Supabase kurtarma oturumu kurar ve
  /// `AuthChangeEvent.passwordRecovery` yayar → `AuthGate` kullanıcıyı yeni
  /// şifre ekranına kilitler.
  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: _deepLink,
    );
  }

  /// Kurtarma oturumundayken yeni şifreyi yazar. Oturum yoksa
  /// `AuthException` fırlar (bağlantının süresi dolmuş olabilir).
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }
}

/// OAuth ve şifre sıfırlamanın ortak dönüş adresi. Tek yerde durur ki
/// Supabase panelindeki "Redirect URLs" listesiyle ayrışmasın.
const _deepLink = 'fitpack://login-callback';

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
