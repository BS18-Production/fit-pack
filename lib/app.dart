import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/home/providers/home_providers.dart';
import 'features/nutrition/nutrition_screen.dart' show selectedDateProvider;
import 'features/workout/routine_providers.dart';

class FitPackApp extends StatefulWidget {
  /// İlk açılış (P-10) tamamlandı mı? Router başlangıç konumunu belirler.
  final bool onboarded;

  const FitPackApp({super.key, required this.onboarded});

  @override
  State<FitPackApp> createState() => _FitPackAppState();
}

class _FitPackAppState extends State<FitPackApp> {
  // Router'ı bir kez kur — rebuild'lerde GoRouter state'i korunsun.
  late final GoRouter _router =
      createAppRouter(onboarded: widget.onboarded);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fit Pack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      builder: (context, child) =>
          _DayRolloverGuard(child: child ?? const SizedBox.shrink()),
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
    ref.invalidate(workoutStreakProvider);
    ref.invalidate(weekWorkoutStatsProvider);
    ref.read(selectedDateProvider.notifier).state = DateTime.now();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
