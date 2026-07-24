import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/router/app_routes.dart';
import '../../data/database/app_database.dart';
import '../../data/providers.dart';
import '../home/providers/home_providers.dart';
import '../sync/sync_controller.dart' show syncLog;
import '../sync/sync_providers.dart';
import '../workout/routine_providers.dart';
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

  /// Açılışta bir kez, `runApp` ÖNCESİ çağrılır. **Çevrimdışı-hızlı**: `onboarded`
  /// diskten okunur, ağ BEKLENMEZ (Kural 1 — açılış internete bağlı değil).
  ///
  /// Oturum zaten açıksa (uygulama yeniden başlatıldı) hesap kontrolü + pull
  /// gerekmez; bu kullanıcı zaten uygulanmış sayılır ve arka planda tazeleme
  /// pull'u tetiklenir (bloklamaz). Böylece açılış anında değil de sessizce
  /// sunucudaki değişiklikler (ve varsa junk profilin gerçekle değişmesi) iner.
  Future<void> bootstrap() async {
    await _readOnboarded();
    final userId = currentUserId;
    if (userId != null) {
      // Yeniden başlatmadaki `initialSession` olayını "zaten uygulandı" say →
      // her açılışta pull tekrarlanmasın.
      _appliedUserId = userId;
      unawaited(_backgroundPull(userId));
    }
  }

  /// Onboarding bitince çağrılır — kapı anında açılır.
  void markOnboarded() {
    if (_onboarded) return;
    _onboarded = true;
    notifyListeners();
  }

  void _onAuth(AuthState state) {
    final userId = state.session?.user.id;
    // Çıkış → kapı devreye girsin.
    if (userId == null) {
      notifyListeners();
      return;
    }
    // Token yenileme gibi olaylar aynı kullanıcı için tekrar tekrar gelir;
    // hesap kontrolünü yalnız kullanıcı GERÇEKTEN değiştiğinde çalıştır.
    if (userId == _appliedUserId) {
      notifyListeners();
      return;
    }
    unawaited(_applyAccount(userId));
  }

  Future<void> _applyAccount(String userId) async {
    _busy = true;
    notifyListeners();
    try {
      await AccountSwitchGuard.apply(_db, userId);
      // Sunucudaki veriyi indir (docs/18 §6.4). Bunu onboarding kararından ÖNCE
      // yaparız: sunucuda `onboarded = 1` profil varsa kullanıcı onboarding'i
      // TEKRAR görmez — telefon değiştiren/yeniden kuran kişi verisine kavuşur.
      // Pull başarısızsa (ağ yok) yereldekiyle devam; kapı kararı ağa bağlı değil.
      await _runPull(userId);
      _appliedUserId = userId;
      await _readOnboarded();
    } catch (e) {
      // Kontrol başarısızsa içeri ALMA — sızıntı riskine karşı kapı kapalı
      // kalır, kullanıcı tekrar deneyebilir.
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
    pull: (userId) async {
      final result = await ref.read(syncPullProvider).pullAll(userId: userId);
      // Pull yereli değiştirdiyse okuma önbelleklerini tazele. Uygulama henüz
      // tam reaktif değil (H-05 ertelendi) → inen veri ekrana yansısın diye
      // çekirdek provider'lar elle invalidate edilir.
      if (result.changed > 0) {
        ref.invalidate(userProfileProvider);
        ref.invalidate(latestWeightProvider);
        ref.invalidate(weightTrendProvider);
        ref.invalidate(weeklyStreakProvider);
        ref.invalidate(weekWorkoutStatsProvider);
        ref.invalidate(todayNutritionProvider);
        ref.invalidate(todayWaterProvider);
        ref.invalidate(todayRoutineProvider);
      }
    },
  );
  ref.onDispose(gate.dispose);
  return gate;
});

/// Yönlendirme tablosu (docs/18 §5.1) — saf mantık, test edilebilir olsun diye
/// GoRouter'dan ayrı:
///
/// | Oturum | onboarded | Gidilecek yer |
/// |---|---|---|
/// | ✗ | — | ① `/welcome` |
/// | ✓ | ✗ | ③ `/onboarding` |
/// | ✓ | ✓ | ④ `/home` |
///
/// `null` = olduğun yerde kal.
String? gateRedirect({
  required String location,
  required bool signedIn,
  required bool onboarded,
  bool busy = false,
}) {
  // Hesap değişimi sürerken karar verme — veri temizlenirken ekran değişmesin.
  if (busy) return null;

  final atGate = location == AppRoutes.welcome || location == AppRoutes.auth;

  if (!signedIn) return atGate ? null : AppRoutes.welcome;
  if (!onboarded) {
    return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
  }
  // Girişi tamamlamış kullanıcı kapıya/onboarding'e geri dönemez.
  if (atGate || location == AppRoutes.onboarding) return AppRoutes.home;
  return null;
}
