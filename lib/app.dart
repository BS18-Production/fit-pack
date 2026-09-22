import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'shared/widgets/glass.dart';
import 'core/i18n/locale_provider.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'l10n/app_l10n.dart';
import 'features/home/providers/home_providers.dart';
import 'features/nutrition/nutrition_screen.dart' show selectedDateProvider;
import 'features/workout/routine_providers.dart';
import 'features/sync/sync_providers.dart';
import 'features/sync/sync_refresh.dart';
import 'features/update/update_providers.dart';
import 'features/auth/auth_gate.dart';

class FitPackApp extends ConsumerStatefulWidget {
  const FitPackApp({super.key});

  @override
  ConsumerState<FitPackApp> createState() => _FitPackAppState();
}

class _FitPackAppState extends ConsumerState<FitPackApp> {
  // Router'ı bir kez kur — rebuild'lerde GoRouter state'i korunsun. Kapı
  // (oturum + onboarding) durumunu router'ın kendisi `redirect`te okur;
  // `main()` `bootstrap()`u çağırdığı için değerler burada hazırdır.
  late final GoRouter _router =
      createAppRouter(
        gate: ref.read(authGateProvider),
        updateGate: ref.read(updateGateProvider),
      );

  // ── Bildirime dokununca ilgili ekrana git (haftalık değerlendirme, docs/22
  // §5). İki yol: uygulama AÇIKKEN dokunma (`taps` akışı) ve uygulama
  // KAPALIYKEN bildirimle açılma (`launchPayload`).
  StreamSubscription<String>? _notifTaps;

  /// Soğuk açılışta kapı henüz karar vermemişken gelen hedef. Kapı hazır
  /// olunca işlenir — önce gidilseydi yönlendirme (redirect) onu yutardı.
  String? _pendingPayload;

  /// `dispose`'ta `ref` kullanılamaz; dinleyiciyi kaldırmak için saklanır.
  late final AuthGate _gate = ref.read(authGateProvider);

  @override
  void initState() {
    super.initState();
    final svc = ref.read(notificationServiceProvider);
    _notifTaps = svc.taps.listen(_openFromNotification);
    _gate.addListener(_flushPending);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final p = await svc.launchPayload();
        if (p != null) {
          _pendingPayload = p;
          _flushPending();
        }
      } catch (_) {
        // Bildirim eklentisi yok (test, desteklenmeyen platform) — sessiz geç.
      }
    });
  }

  @override
  void dispose() {
    _notifTaps?.cancel();
    _gate.removeListener(_flushPending);
    super.dispose();
  }

  bool get _gateReady {
    final g = _gate;
    return g.signedIn &&
        g.onboarded &&
        !g.busy &&
        !g.recovering &&
        !g.accountError &&
        g.pendingConflictRows == 0;
  }

  void _openFromNotification(String payload) {
    if (!_gateReady) {
      _pendingPayload = payload;
      return;
    }
    if (payload == NotificationService.payloadWeeklyReview) {
      _router.push(AppRoutes.weeklyReview);
    }
  }

  void _flushPending() {
    final p = _pendingPayload;
    if (p == null || !_gateReady) return;
    _pendingPayload = null;
    // Soğuk açılışta yığın açılış ekranında: önce ana sayfaya otur ki
    // geri tuşu açılış ekranına dönmesin.
    _router.go(AppRoutes.home);
    _openFromNotification(p);
  }

  @override
  Widget build(BuildContext context) {
    // Senkron yaşam döngüsü: oturum açıldığında giden kutusu işlemeye başlar,
    // çıkışta durur (docs/18 §6). Burada `watch` edilmesi provider'ı canlı
    // tutar — ekran değişimlerinden etkilenmez.
    ref.watch(syncLifecycleProvider);
    // Uygulama öne geldiğinde gönder + (bayatsa) çek — docs/20 §6.5.
    ref.watch(syncForegroundProvider);
    // Kullanıcı tema tercihi (Sistem/Açık/Koyu) — Ayarlar'dan değişir.
    final themeMode = ref.watch(themeModeProvider);
    // Dil tercihi (docs/14). null = cihazı takip et; supportedLocales'te
    // `en` ilk olduğundan desteklenmeyen diller İngilizce'ye düşer.
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'Fit Pack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      routerConfig: _router,
      // GlassBackground BURADA, navigator'ın altında bir kez çizilir →
      // her ekran (tab + push'lu) aynı zemini paylaşır; scaffold'lar
      // transparan (app_theme). Ekranlar kendi zeminini KURMAZ.
      // AnnotatedRegion: AppBar'sız ekranlarda da sistem çubukları transparan
      // kalsın (edge-to-edge) — yalnız main()'deki tek seferlik çağrıya
      // güvenmek yetmez, ilk kare sonrası ezilebiliyor.
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: (brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark)
              .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
          ),
          child: GlassBackground(
            child: _DayRolloverGuard(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
    );
  }
}

/// Gün değişimi bekçisi (CODE_REVIEW M-02). "Bugün" verileri (beslenme, su,
/// günün rutini, seri) provider önbelleğinde kurulduğu günün DateTime.now()
/// değeriyle yaşar. Uygulama gece açık kalır ya da ertesi gün arka plandan
/// dönerse dünün verisi "bugün" diye görünürdü. Bu bekçi, uygulama öne her
/// geldiğinde takvim günü değişmişse güne bağlı provider'ları tazeler.
class _DayRolloverGuard extends ConsumerStatefulWidget {
  final Widget child;
  const _DayRolloverGuard({required this.child});

  @override
  ConsumerState<_DayRolloverGuard> createState() => _DayRolloverGuardState();
}

class _DayRolloverGuardState extends ConsumerState<_DayRolloverGuard>
    with WidgetsBindingObserver {
  late DateTime _day = _today();

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final today = _today();
    if (today == _day) return;
    _day = today;
    // Güne bağlı tüm önbellekler tazelenir; beslenmede seçili gün yeni
    // "bugün"e çekilir (dün gece bakılan gün artık geçmiş).
    ref.invalidate(todayNutritionProvider);
    ref.invalidate(todayWaterProvider);
    ref.invalidate(todayRoutineProvider);
    ref.invalidate(weeklyStreakProvider);
    ref.invalidate(weekWorkoutStatsProvider);
    ref.read(selectedDateProvider.notifier).state = DateTime.now();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
