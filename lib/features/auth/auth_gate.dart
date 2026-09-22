import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/router/app_routes.dart';
import '../../data/database/app_database.dart';
import '../../data/providers.dart';
import '../sync/sync_controller.dart' show syncLog;
import '../sync/sync_refresh.dart';
import 'account_switch.dart';

/// Zorunlu giriş kapısının durumu (docs/18 §5.1).
///
/// **Kural 1 — kapı AĞI değil, OTURUMU kontrol eder.** Kararda "internet var mı
/// / token geçerli mi" diye sunucuya sorulmaz; cihazda kayıtlı oturuma bakılır
/// (`auth.currentSession`, senkron erişilir). Sorsaydık uçakta ya da sinyalsiz
/// salonda kullanıcı **kendi cihazındaki kendi verisine** giremezdi — yerel
/// öncelikli mimariyi kurma sebebimizin tam tersi. Bayat erişim token'ı içeri
/// almaya engel değildir; yenileme ağ gelince arka planda olur.
///
/// **Kural 2 — kapı kararı gevşek provider'dan okunmaz.** Riverpod'un tembel
/// `Notifier`'ı ilk `ref.read`'de varsayılan state döndürür; kapı buna
/// bırakılsaydı açılışta bir kare yanlış ekran çizilirdi. Bu yüzden `onboarded`
/// `main()`de **bir kez** okunup burada tutulur, oturum ise doğrudan Supabase'in
/// kalıcı oturumundan gelir. `ChangeNotifier` olması GoRouter'ın
/// `refreshListenable`ına bağlanmasını sağlar → çıkışta kapı anında devreye girer.
class AuthGate extends ChangeNotifier {
  AuthGate(this._db, {Future<void> Function(String userId)? pull})
      : _pull = pull {
    try {
      _sub = Supabase.instance.client.auth.onAuthStateChange.listen(_onAuth);
    } catch (_) {
      // Supabase başlatılamadı → oturumsuz sayılır, kapı karşılamada kalır.
    }
  }

  final AppDatabase _db;

  /// Sunucudan veri indirici (docs/18 §6.4). Girişte çalışır; ağ gerektirir ama
  /// kapı KARARI ona bağlı değil (Kural 1) — pull başarısız olsa da yereldeki
  /// veriyle devam edilir. Test edilebilsin diye enjekte edilir.
  final Future<void> Function(String userId)? _pull;

  StreamSubscription<AuthState>? _sub;

  bool _onboarded = false;
  bool _busy = false;
  bool _recovering = false;
  bool _accountError = false;
  int _pendingConflictRows = 0;
  String? _appliedUserId;

  /// Profil kurulumu tamamlandı mı (`user_profile.onboarded`). Hesaba bağlıdır:
  /// telefon değiştiren kullanıcı senkron sonrası onboarding'i tekrar görmez.
  bool get onboarded => _onboarded;

  /// Cihazda açık oturum var mı. Ağa sorulmaz (Kural 1).
  bool get signedIn => currentUserId != null;

  String? get currentUserId {
    try {
      return Supabase.instance.client.auth.currentSession?.user.id;
    } catch (_) {
      return null; // Supabase init edilemedi
    }
  }

  /// Hesap değişimi işleniyor mu. Bu sürede yönlendirme kararı ERTELENİR —
  /// yoksa yerel veri silinirken kullanıcı bir an eski hesabın Ana Sayfa'sını
  /// görür.
  bool get busy => _busy;

  /// Şifre kurtarma oturumu açık mı (docs/18 §14).
  ///
  /// Maildeki sıfırlama bağlantısı Supabase'de **gerçek bir oturum** açar.
  /// Bu bayrak olmasaydı `gateRedirect` "oturum var + onboarded" görüp
  /// kullanıcıyı doğruca Ana Sayfa'ya alırdı ve yeni şifre hiç sorulmazdı —
  /// yani kullanıcı hâlâ eski/unutulmuş şifreyle kalır, bir sonraki cihazda
  /// yine giremezdi. Bayrak açıkken kapı kullanıcıyı yeni şifre ekranına
  /// kilitler.
  bool get recovering => _recovering;

  /// Hesap kontrolü başarısız oldu mu (docs/20 §7.5). Kapı kullanıcıyı İÇERİ
  /// ALMAZ: kontrol yapılamadıysa bir önceki hesabın verisi görünebilir.
  bool get accountError => _accountError;

  /// Başka bir hesap girdi ama cihazda **gönderilmemiş** kayıt var (§7.4).
  /// 0'dan büyükse kullanıcıya seçim ekranı gösterilir; veri SİLİNMEDİ.
  int get pendingConflictRows => _pendingConflictRows;

  /// §7.4 seçimi: "kayıtları silip devam et".
  Future<void> discardPendingAndContinue() async {
    final userId = currentUserId;
    if (userId == null) return;
    _busy = true;
    notifyListeners();
    try {
      await AccountSwitchGuard.wipeAndAdopt(_db, userId);
      _pendingConflictRows = 0;
      _appliedUserId = userId;
      await _runPull(userId);
      await _readOnboarded();
    } catch (e) {
      _accountError = true;
      syncLog('hesap değişimi tamamlanamadı', error: e);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// §7.5: "Tekrar dene" — hesap kontrolünü baştan çalıştırır.
  Future<void> retryAccountCheck() async {
    final userId = currentUserId;
    if (userId == null) return;
    _appliedUserId = null; // kontrol yeniden çalışsın
    await _applyAccount(userId);
  }

  /// Yeni şifre başarıyla yazıldıktan sonra çağrılır — kilit kalkar, kullanıcı
  /// normal akışına (onboarding ya da Ana Sayfa) devam eder.
  void clearRecovery() {
    if (!_recovering) return;
    _recovering = false;
    notifyListeners();
  }

  /// Açılışta bir kez, `runApp` ÖNCESİ çağrılır. **Çevrimdışı-hızlı**: `onboarded`
  /// diskten okunur, ağ BEKLENMEZ (Kural 1 — açılış internete bağlı değil).
  ///
  /// Oturum zaten açıksa (uygulama yeniden başlatıldı) hesap kontrolü + pull
  /// gerekmez; bu kullanıcı zaten uygulanmış sayılır ve arka planda tazeleme
  /// pull'u tetiklenir (bloklamaz). Böylece açılış anında değil de sessizce
  /// sunucudaki değişiklikler (ve varsa junk profilin gerçekle değişmesi) iner.
  Future<void> bootstrap() async {
    final userId = currentUserId;
    // İşaretleme `_readOnboarded` BEKLENMEDEN önce yapılır: o await sürerken
    // gelen `initialSession` olayı hesap kontrolünü tetiklerse `busy` açılır,
    // router kararı ertelenir ve oturum açıkken birkaç saniye Karşılama
    // ekranı görünür (2026-09-16'da emülatörde gözlendi).
    final alreadyApplied = userId != null && userId == _appliedUserId;
    if (userId != null) _appliedUserId = userId;
    // Yerel hesap kontrolü açılışta da çalışır (docs/20 §7.1 madde 2): ağ
    // gerektirmez, aynı kullanıcıda anında döner. Eskiden atlanıyordu — yarım
    // kalmış bir temizlik bir sonraki girişe kadar açıkta kalırdı.
    try {
      await AccountSwitchGuard.resumeIfInterrupted(_db);
      if (userId != null) {
        final outcome = await AccountSwitchGuard.apply(_db, userId);
        if (outcome == AccountSwitch.pendingConflict) {
          _pendingConflictRows = await AccountSwitchGuard.pendingRowCount(_db);
        }
      }
    } catch (e) {
      _accountError = true;
      syncLog('açılışta hesap kontrolü başarısız', error: e);
    }
    await _readOnboarded();
    // Her açılışta pull tekrarlanmasın: olay bizden önce geldiyse zaten başladı.
    if (userId != null && !alreadyApplied) unawaited(_backgroundPull(userId));
  }

  /// Onboarding bitince çağrılır — kapı anında açılır.
  void markOnboarded() {
    if (_onboarded) return;
    _onboarded = true;
    notifyListeners();
  }

  void _onAuth(AuthState state) {
    final userId = state.session?.user.id;
    // Kurtarma bağlantısıyla gelindi → yeni şifre belirlenene kadar içeri
    // alma. Yönlendirme kararından ÖNCE işaretlenmeli, yoksa bir kare Ana
    // Sayfa görünür.
    if (state.event == AuthChangeEvent.passwordRecovery) {
      _recovering = true;
    }
    switch (authActionFor(
      event: state.event,
      userId: userId,
      appliedUserId: _appliedUserId,
    )) {
      // Çıkış → kapı devreye girsin. Kurtarma yarıda bırakıldıysa kilidi de
      // bırak (oturum yokken kilit kullanıcıyı boş ekranda hapsederdi).
      case AuthAction.signedOut:
        _recovering = false;
        notifyListeners();
      case AuthAction.notifyOnly:
        notifyListeners();
      case AuthAction.markApplied:
        _appliedUserId = userId;
        notifyListeners();
        unawaited(_backgroundPull(userId!));
      case AuthAction.applyAccount:
        unawaited(_applyAccount(userId!));
    }
  }

  Future<void> _applyAccount(String userId) async {
    _busy = true;
    notifyListeners();
    try {
      _accountError = false;
      final outcome = await AccountSwitchGuard.apply(_db, userId);
      if (outcome == AccountSwitch.pendingConflict) {
        // Veri SİLİNMEDİ; kullanıcı seçim ekranında karar verecek (§7.4).
        _pendingConflictRows = await AccountSwitchGuard.pendingRowCount(_db);
        return;
      }
      _pendingConflictRows = 0;
      // Sunucudaki veriyi indir (docs/18 §6.4). Bunu onboarding kararından ÖNCE
      // yaparız: sunucuda `onboarded = 1` profil varsa kullanıcı onboarding'i
      // TEKRAR görmez — telefon değiştiren/yeniden kuran kişi verisine kavuşur.
      // Pull başarısızsa (ağ yok) yereldekiyle devam; kapı kararı ağa bağlı değil.
      await _runPull(userId);
      _appliedUserId = userId;
      await _readOnboarded();
    } catch (e) {
      // Kontrol başarısızsa içeri ALMA — sızıntı riskine karşı kapı kapalı
      // kalır, kullanıcı tekrar deneyebilir (§7.5).
      _accountError = true;
      syncLog('hesap kontrolü başarısız', error: e);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Arka plan tazeleme pull'u (yeniden başlatma yolu). Kapı zaten açık;
  /// bittiğinde dinleyicilere haber verir ki ekranlar taze veriyi çeksin.
  Future<void> _backgroundPull(String userId) async {
    final before = _onboarded;
    await _runPull(userId);
    await _readOnboarded();
    if (_onboarded != before) notifyListeners();
  }

  Future<void> _runPull(String userId) async {
    if (_pull == null) return;
    try {
      await _pull(userId);
    } catch (e) {
      // Ağ yok / sunucu hatası → sessiz. Yereldeki veri korunur, gönderim
      // kuyruğu ayakta; kapı kararı buna bağlı değil (Kural 1).
      syncLog('pull başarısız (yerelle devam)', error: e);
    }
  }

  Future<void> _readOnboarded() async {
    final profile = await _db.userProfileDao.getProfile();
    _onboarded = profile?.onboarded ?? false;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Kapı durumu. `main()` `runApp` öncesi `bootstrap()` çağırdığı için ilk
/// okumada gerçek değerler hazırdır (Kural 2).
final authGateProvider = Provider<AuthGate>((ref) {
  final gate = AuthGate(
    ref.watch(databaseProvider),
    // Çekme + okuma önbelleklerinin tazelenmesi `SyncRefresh`'te tek yerde
    // (docs/20 §6.5) — aynı işi öne gelme ve "Şimdi eşitle" de yapıyor.
    pull: (userId) => ref.read(syncRefreshProvider).pullNow(userId),
  );
  ref.onDispose(gate.dispose);
  return gate;
});

/// Oturum olayına verilecek karşılık — saf mantık, [gateRedirect] gibi ayrı
/// tutulur ki test edilebilsin.
enum AuthAction {
  /// Oturum yok → kapı devreye girsin.
  signedOut,

  /// Aynı kullanıcı (token yenileme vb.) → yalnız dinleyicilere haber ver.
  notifyOnly,

  /// Uygulama yeniden açıldı, oturum diskten geldi → uygulanmış say, veriyi
  /// arka planda tazele. **Hesap kontrolü çalıştırma.**
  markApplied,

  /// Gerçekten başka (ya da ilk kez giren) kullanıcı → hesap kontrolü.
  applyAccount,
}

/// [AuthGate] oturum olayını nasıl karşılasın?
///
/// Kritik ayrım: `initialSession` **hesap değişimi değildir** — uygulama
/// yeniden açılırken depodaki oturumun bildirilmesidir. Hesap kontrolü
/// başlatılırsa `busy` açılır, `gateRedirect` kararı erteler ve kullanıcı
/// oturumu açıkken birkaç saniye Karşılama ekranında kalır (2026-09-16).
AuthAction authActionFor({
  required AuthChangeEvent event,
  required String? userId,
  required String? appliedUserId,
}) {
  if (userId == null) return AuthAction.signedOut;
  if (userId == appliedUserId) return AuthAction.notifyOnly;
  if (event == AuthChangeEvent.initialSession) return AuthAction.markApplied;
  return AuthAction.applyAccount;
}

/// Yönlendirme tablosu (docs/18 §5.1) — saf mantık, test edilebilir olsun diye
/// GoRouter'dan ayrı:
///
/// | Oturum | onboarded | Gidilecek yer |
/// |---|---|---|
/// | ✗ | — | ① `/welcome` |
/// | ✓ | ✗ | ③ `/onboarding` |
/// | ✓ | ✓ | ④ `/home` |
///
/// Kurtarma oturumu (`recovering`) bu tablonun ÜSTÜNDEDİR: şifre yenilenene
/// kadar kullanıcı `/reset-password` dışına çıkamaz (docs/18 §14).
///
/// `null` = olduğun yerde kal.
String? gateRedirect({
  required String location,
  required bool signedIn,
  required bool onboarded,
  bool busy = false,
  bool recovering = false,
  bool accountError = false,
  bool pendingConflict = false,
}) {
  // Hesap değişimi sürerken karar verme — veri temizlenirken ekran değişmesin.
  if (busy) return null;

  // docs/20 §7.5: hesap kontrolü yapılamadıysa İÇERİ ALMA. Girilirse önceki
  // hesabın verisi görünebilir; "emin değilsek kapıyı açma" kuralı.
  if (accountError && signedIn) {
    return location == AppRoutes.accountError ? null : AppRoutes.accountError;
  }

  // docs/20 §7.4: gönderilmemiş kayıt varken farklı hesap → veri SİLİNMEDİ,
  // karar kullanıcıya ait. Seçim yapılmadan içeri girilmez.
  if (pendingConflict && signedIn) {
    return location == AppRoutes.accountConflict
        ? null
        : AppRoutes.accountConflict;
  }

  // Şifre kurtarma her şeyin önünde: oturum açık ama kullanıcı yeni şifresini
  // belirlemeden uygulamaya giremez. `signedIn` şartı, oturumu düşen (bağlantı
  // süresi dolmuş) kullanıcının boş ekranda kilitli kalmasını engeller.
  if (recovering && signedIn) {
    return location == AppRoutes.resetPassword ? null : AppRoutes.resetPassword;
  }

  // Nötr açılış ekranı yalnız kapı MEŞGULKEN durur; karar verilir verilmez
  // hedefe gidilir (aşağıdaki kurallar). Boş kalırsa kullanıcı orada asılı
  // kalırdı.
  final atGate = location == AppRoutes.welcome || location == AppRoutes.auth;

  if (!signedIn) {
    return atGate ? null : AppRoutes.welcome;
  }
  if (!onboarded) {
    return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
  }
  // Girişi tamamlamış kullanıcı kapıya/onboarding'e geri dönemez. Kurtarma
  // ekranı da buraya dahil: bayrak kapalıyken orada işi yok.
  if (atGate ||
      location == AppRoutes.splash ||
      location == AppRoutes.onboarding ||
      location == AppRoutes.resetPassword) {
    return AppRoutes.home;
  }
  return null;
}
