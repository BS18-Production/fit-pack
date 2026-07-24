import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'shared/widgets/glass.dart';
import 'core/i18n/locale_provider.dart';
import 'core/router/app_router.dart';
import 'l10n/app_l10n.dart';
import 'features/home/providers/home_providers.dart';
import 'features/nutrition/nutrition_screen.dart' show selectedDateProvider;
import 'features/workout/routine_providers.dart';
import 'features/sync/sync_providers.dart';
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
      createAppRouter(gate: ref.read(authGateProvider));

  @override
  Widget build(BuildContext context) {
    // Senkron yaşam döngüsü: oturum açıldığında giden kutusu işlemeye başlar,
    // çıkışta durur (docs/18 §6). Burada `watch` edilmesi provider'ı canlı
    // tutar — ekran değişimlerinden etkilenmez.
    ref.watch(syncLifecycleProvider);
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
