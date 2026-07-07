import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_pack/features/home/home_screen.dart';
import 'package:fit_pack/features/workout/workout_list_screen.dart';
import 'package:fit_pack/features/workout/workout_history_screen.dart';
import 'package:fit_pack/features/workout/exercise_library_screen.dart';
import 'package:fit_pack/features/workout/exercise_detail_screen.dart';
import 'package:fit_pack/features/workout/routine_builder_screen.dart';
import 'package:fit_pack/features/workout/routine_preview_screen.dart';
import 'package:fit_pack/features/workout/active_session_screen.dart';
import 'package:fit_pack/features/workout/workout_summary_screen.dart';
import 'package:fit_pack/features/nutrition/nutrition_screen.dart';
import 'package:fit_pack/features/nutrition/foods_screen.dart';
import 'package:fit_pack/features/body_metrics/body_metrics_screen.dart';
import 'package:fit_pack/features/export/export_screen.dart';
import 'package:fit_pack/features/cloud/cloud_account_screen.dart';
import 'package:fit_pack/features/profile/profile_screen.dart';
import 'package:fit_pack/features/settings/attribution_screen.dart';
import 'package:fit_pack/features/settings/notifications_screen.dart';
import 'package:fit_pack/features/settings/settings_screen.dart';
import 'package:fit_pack/features/onboarding/onboarding_screen.dart';
import 'package:fit_pack/shared/widgets/app_shell.dart';
import 'package:fit_pack/shared/widgets/glass.dart';
import 'app_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Push edilen (root navigator) sayfaları kendi OPAK cam zeminiyle sarar.
/// Global GlassBackground navigator'ın ALTINDA olduğundan ve tüm scaffold'lar
/// transparan olduğundan, push kaydırma geçişinde üstteki sayfanın arkasından
/// alttaki sayfanın elementleri sızıyordu (bleed-through). Sayfaya kendi opak
/// zeminini vermek geçiş sırasında altını kapatır; palet tek kaynak (AppGlass)
/// olduğundan görsel birebir aynı (dikiş yok). Sekmeler global zemini kullanır
/// ve NoTransitionPage ile geçtiğinden bu sarmalayıcıya ihtiyaç duymaz.
Widget _glass(Widget child) => GlassBackground(child: child);

/// Router'ı kurar. Başlangıç konumu, ilk açılış (P-10) durumuna göre seçilir:
/// onboarding tamamlanmamışsa `/onboarding`, aksi halde `/home`. Tek kullanıcı
/// pilot için yeterli — onboarding bittiğinde `context.go('/home')` çağrılır.
GoRouter createAppRouter({required bool onboarded}) => GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: onboarded ? AppRoutes.home : AppRoutes.onboarding,
  routes: [
    GoRoute(
      path: AppRoutes.onboarding,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => _glass(const OnboardingScreen()),
    ),
    // Alt sekmeler: her dal kendi navigator'ında, IndexedStack ile canlı kalır
    // → sekme geçişinde ekran yeniden inşa/yeniden-fetch olmaz (pürüzsüz geçiş).
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomeScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.workout,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: WorkoutListScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.nutrition,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: NutritionScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.progress,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: BodyMetricsScreen(),
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.workoutHistory,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => _glass(const WorkoutHistoryScreen()),
    ),
    // Antrenman V2 (docs/09-workout-v2.md) — rutinler + aktif seans.
    GoRoute(
      path: AppRoutes.routineNew,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => _glass(const RoutineBuilderScreen()),
    ),
    GoRoute(
      path: AppRoutes.routineEditPath,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => _glass(RoutineBuilderScreen(
          routineId: int.parse(state.pathParameters['id']!))),
    ),
    GoRoute(
      path: AppRoutes.routinePreviewPath,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => _glass(RoutinePreviewScreen(
          routineId: int.parse(state.pathParameters['id']!))),
    ),
    GoRoute(
      path: AppRoutes.workoutActive,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => _glass(const ActiveSessionScreen()),
    ),
    // Kaydedilmiş taslaktan devam (docs/12). :routineId'den ÖNCE gelmeli.
    GoRoute(
      path: AppRoutes.workoutActiveResume,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => _glass(const ActiveSessionScreen(resume: true)),
    ),
    GoRoute(
      path: AppRoutes.workoutActiveRoutinePath,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => _glass(ActiveSessionScreen(
          routineId: int.parse(state.pathParameters['routineId']!))),
    ),
    // Geçmiş antrenman ekle (H-B) — kronometresiz, tarih seçilir.
    GoRoute(
      path: AppRoutes.workoutLogPast,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          _glass(ActiveSessionScreen(manualDate: DateTime.now())),
    ),
    GoRoute(
      path: AppRoutes.summaryPath,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => _glass(WorkoutSummaryScreen(
          sessionId: int.parse(state.pathParameters['sessionId']!))),
    ),
    GoRoute(
      path: AppRoutes.exercises,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => _glass(const ExerciseLibraryScreen()),
    ),
    GoRoute(
      path: AppRoutes.exercisesSelect,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          _glass(const ExerciseLibraryScreen(selectionMode: true)),
    ),
    GoRoute(
      path: AppRoutes.exerciseDetailPath,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => _glass(ExerciseDetailScreen(
          exerciseId: int.parse(state.pathParameters['id']!))),
    ),
    GoRoute(
      path: AppRoutes.foods,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => _glass(const FoodsScreen()),
    ),
    GoRoute(
      path: AppRoutes.export,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => _glass(const ExportScreen()),
    ),
    GoRoute(
      path: AppRoutes.cloud,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => _glass(const CloudAccountScreen()),
    ),
    GoRoute(
      path: AppRoutes.profile,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => _glass(const ProfileScreen()),
    ),
    GoRoute(
      path: AppRoutes.settings,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => _glass(const SettingsScreen()),
    ),
    GoRoute(
      path: AppRoutes.attribution,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => _glass(const AttributionScreen()),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => _glass(const NotificationsScreen()),
    ),
  ],
);

