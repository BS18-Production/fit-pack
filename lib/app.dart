import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'shared/widgets/glass.dart';
import 'core/i18n/locale_provider.dart';
import 'package:drift/drift.dart' show TableUpdateQuery;
import 'core/notifications/notification_prefs.dart';
import 'core/prefs/week_start_provider.dart';
import 'core/utils/current_day.dart';
import 'core/notifications/notification_service.dart';
import 'data/providers.dart';
import 'features/nutrition/meal_reminders.dart';
import 'features/workout/recall_reminders.dart';
import 'features/workout/recall_first_week.dart';
import 'features/home/first_week.dart' show accountCreatedProvider;
import 'features/insights/weekly_review_reminder.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'l10n/app_l10n.dart';
import 'features/nutrition/nutrition_providers.dart' show selectedDateProvider;
import 'features/sync/sync_providers.dart';
import 'features/sync/sync_refresh.dart';
import 'features/update/update_providers.dart';
import 'features/auth/auth_gate.dart';
import 'features/health/body_providers.dart';
import 'features/health/step_providers.dart';
import 'features/analytics/analytics_lifecycle.dart';

class FitPackApp extends ConsumerStatefulWidget {
  const FitPackApp({super.key});

  @override
  ConsumerState<FitPackApp> createState() => _FitPackAppState();
}

class _FitPackAppState extends ConsumerState<FitPackApp> {
  // Router'ı bir kez kur — rebuild'lerde GoRouter state'i korunsun. Kapı
  // (oturum + onboarding) durumunu router'ın kendisi `redirect`te okur;
  // `main()` `bootstrap()`u çağırdığı için değerler burada hazırdır.
  late final GoRouter _router = createAppRouter(
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
    } else if (payload == NotificationService.payloadNutrition) {
      _router.go(AppRoutes.nutrition); // öğün hatırlatıcısı (docs/26)
    } else if (payload == NotificationService.payloadRecall) {
      // Geri çağırma (docs/51): "Sıradaki antrenman" kartı Ana Sayfa'da.
      // Dokunma tepki sayılır → tepkisiz sayaç sıfırlanır.
      unawaited(RecallLedger.markTapped());
      _router.go(AppRoutes.home);
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
          value:
              (brightness == Brightness.dark
                      ? SystemUiOverlayStyle.light
                      : SystemUiOverlayStyle.dark)
                  .copyWith(
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor: Colors.transparent,
                    systemNavigationBarContrastEnforced: false,
                  ),
          child: GlassBackground(
            child: AnalyticsLifecycle(
              child: _DayRolloverGuard(child: child ?? const SizedBox.shrink())),
          ),
        );
      },
    );
  }
}

/// Gün değişimi bekçisi (CODE_REVIEW M-02, CR-010). "Bugün" verileri
/// (beslenme, su, günün rutini, seri, son 30 gün…) güne bağlı provider'larda
/// yaşar. Uygulama gece açık kalır ya da ertesi gün arka plandan dönerse
/// dünün verisi "bugün" diye görünürdü. Bekçi takvim günü değişince
/// [currentDayProvider]'ı ilerletir; güne bağlı provider'lar onu izlediği
/// için kendiliğinden yeniden kurulur. İki tetik: ön planda gece yarısı
/// zamanlayıcısı ve uygulamanın öne gelişi.
class _DayRolloverGuard extends ConsumerStatefulWidget {
  final Widget child;
  const _DayRolloverGuard({required this.child});

  @override
  ConsumerState<_DayRolloverGuard> createState() => _DayRolloverGuardState();
}

class _DayRolloverGuardState extends ConsumerState<_DayRolloverGuard>
    with WidgetsBindingObserver {
  late final _midnight = MidnightTimer(onMidnight: () => _rollDay());

  // ── Öğün hatırlatıcıları (docs/26): kayıt değişince, öne gelince ve ayar
  // değişince yeniden kurulur — girilen öğünün bildirimi böyle iptal olur.
  StreamSubscription<void>? _foodLogChanges;
  Timer? _mealSyncDebounce;

  // ── Geri çağırma (docs/51): antrenman/rutin değişince, öne gelince ve ayar
  // değişince yeniden kurulur — girilen antrenman bildirimi böyle iptal eder.
  StreamSubscription<void>? _workoutChanges;
  Timer? _recallSyncDebounce;

  void _scheduleRecallSync() {
    _recallSyncDebounce?.cancel();
    _recallSyncDebounce = Timer(const Duration(seconds: 1), _syncRecall);
  }

  Future<void> _syncRecall() async {
    if (!mounted) return;
    final prefs = ref.read(notificationPrefsProvider);
    final l = AppL10n.of(context);
    try {
      await syncRecallReminders(
        service: ref.read(notificationServiceProvider),
        dao: ref.read(workoutDaoProvider),
        l: l,
        enabled: prefs.workoutEnabled,
        fallbackHour: prefs.workoutHour,
        fallbackMinute: prefs.workoutMinute,
      );
      // İlk hafta (docs/51 ikinci tur): ilk antrenman yoksa tek hatırlatma.
      await syncFirstWeekReminder(
        service: ref.read(notificationServiceProvider),
        dao: ref.read(workoutDaoProvider),
        l: l,
        enabled: prefs.workoutEnabled,
        accountCreated: ref.read(accountCreatedProvider),
      );
    } catch (_) {
      // Bildirim eklentisi yok (test) ya da zamanlama reddedildi: hatırlatma
      // en iyi çaba — uygulamanın akışını bozmaz.
    }
  }

  /// Haftalık değerlendirme açıksa bildirimini (yeniden) kurar. Yeni hesapta
  /// ayar izin istenmeden açık başlar (docs/50 karar 3); izin sonradan
  /// gelince bir sonraki öne gelişte bildirim takvimde olur. Aynı kimlikle
  /// kurulduğu için tekrar çağırmak zararsız.
  Future<void> _syncWeekly() async {
    if (!mounted || !ref.read(notificationPrefsProvider).weeklyReviewEnabled) {
      return;
    }
    try {
      await scheduleWeeklyReviewReminder(
        service: ref.read(notificationServiceProvider),
        l: AppL10n.of(context),
        weekStart: ref.read(weekStartProvider),
      );
    } catch (_) {
      // İzin yok ya da eklenti yok (test) — en iyi çaba.
    }
  }

  void _scheduleMealSync() {
    _mealSyncDebounce?.cancel();
    // Çoklu yazım (öğün kopyalama, senkron çekme) tek kuruluma insin.
    _mealSyncDebounce = Timer(const Duration(seconds: 1), _syncMeals);
  }

  Future<void> _syncMeals() async {
    if (!mounted) return;
    try {
      await syncMealReminders(
        service: ref.read(notificationServiceProvider),
        dao: ref.read(nutritionDaoProvider),
        l: AppL10n.of(context),
        enabled: ref.read(notificationPrefsProvider).mealEnabled,
        weekStart: startOfWeek(DateTime.now(), ref.read(weekStartProvider)),
      );
    } catch (_) {
      // Bildirim eklentisi yok (test) ya da zamanlama reddedildi: hatırlatma
      // en iyi çaba — uygulamanın akışını bozmaz.
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final db = ref.read(databaseProvider);
    _foodLogChanges = db
        .tableUpdates(TableUpdateQuery.onTable(db.foodLogs))
        .listen((_) => _scheduleMealSync());
    _workoutChanges = db
        .tableUpdates(TableUpdateQuery.onAllTables(
            [db.workoutSessions, db.routines]))
        .listen((_) => _scheduleRecallSync());
    ref.listenManual(notificationPrefsProvider, (prev, next) {
      if (prev?.mealEnabled != next.mealEnabled) _scheduleMealSync();
      if (prev?.weeklyReviewEnabled != next.weeklyReviewEnabled &&
          next.weeklyReviewEnabled) {
        unawaited(_syncWeekly());
      }
      if (prev?.workoutEnabled != next.workoutEnabled ||
          prev?.workoutHour != next.workoutHour ||
          prev?.workoutMinute != next.workoutMinute) {
        _scheduleRecallSync();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleMealSync();
      _scheduleRecallSync();
      unawaited(_syncWeekly());
      unawaited(runBodyImportFrom(ref)); // docs/40: açılışta da
    });
    _midnight.arm();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _foodLogChanges?.cancel();
    _mealSyncDebounce?.cancel();
    _workoutChanges?.cancel();
    _recallSyncDebounce?.cancel();
    _midnight.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _scheduleMealSync();
    _scheduleRecallSync();
    unawaited(_syncWeekly());
    // Adımlar her öne gelişte tazelenir (docs/39 S-9); izin Ayarlar'dan
    // kaldırıldıysa bağlantı durumu da yeniden hesaplanır.
    ref.invalidate(stepLinkStateProvider);
    // Tartıdan kilo (docs/40): rıza varsa son günler içe alınır. Satırlar
    // body_measurements'a yazılır → kilo okuyan ekranlar kendiliğinden tazelenir.
    unawaited(runBodyImportFrom(ref));
    unawaited(flushWorkoutOutbox(ref).catchError((_) {})); // docs/44 H-5
    // Arka planda zamanlayıcı bekletilmiş olabilir: günü kontrol et, yeniden kur.
    _rollDay(resumed: true);
    _midnight.arm();
  }

  /// Takvim günü değiştiyse [currentDayProvider]'ı ilerletir.
  ///
  /// Beslenmede seçili gün: öne gelişte her zaman yeni "bugün"e çekilir (dün
  /// gece bakılan gün artık geçmiş). Ön planda gece yarısında ise yalnız seçili
  /// gün eski "bugün"se kayar — kullanıcının bilerek açtığı geçmiş gün
  /// ekranın altından değişmez.
  void _rollDay({bool resumed = false}) {
    if (!mounted) return;
    final today = dayStart(DateTime.now());
    final previous = ref.read(currentDayProvider);
    if (today == previous) return;
    ref.read(currentDayProvider.notifier).state = today;
    final selected = ref.read(selectedDateProvider.notifier);
    if (resumed || dayStart(selected.state) == previous) {
      selected.state = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
