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
import 'package:fit_pack/features/settings/settings_screen.dart';
import 'package:fit_pack/features/onboarding/onboarding_screen.dart';
import 'package:fit_pack/shared/widgets/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Router'ı kurar. Başlangıç konumu, ilk açılış (P-10) durumuna göre seçilir:
/// onboarding tamamlanmamışsa `/onboarding`, aksi halde `/home`. Tek kullanıcı
/// pilot için yeterli — onboarding bittiğinde `context.go('/home')` çağrılır.
GoRouter createAppRouter({required bool onboarded}) => GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: onboarded ? '/home' : '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OnboardingScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/workout',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: WorkoutListScreen(),
          ),
        ),
        GoRoute(
          path: '/nutrition',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: NutritionScreen(),
          ),
        ),
        GoRoute(
          path: '/progress',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BodyMetricsScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/workout/history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const WorkoutHistoryScreen(),
    ),
    // Antrenman V2 (docs/09-workout-v2.md) — rutinler + aktif seans.
    GoRoute(
      path: '/workout/routine/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RoutineBuilderScreen(),
    ),
    GoRoute(
      path: '/workout/routine/:id/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => RoutineBuilderScreen(
          routineId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/workout/routine/:id/preview',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => RoutinePreviewScreen(
          routineId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/workout/active',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ActiveSessionScreen(),
    ),
    GoRoute(
      path: '/workout/active/:routineId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ActiveSessionScreen(
          routineId: int.parse(state.pathParameters['routineId']!)),
    ),
    // Geçmiş antrenman ekle (H-B) — kronometresiz, tarih seçilir.
    GoRoute(
      path: '/workout/log-past',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          ActiveSessionScreen(manualDate: DateTime.now()),
    ),
    GoRoute(
      path: '/workout/summary/:sessionId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => WorkoutSummaryScreen(
          sessionId: int.parse(state.pathParameters['sessionId']!)),
    ),
    GoRoute(
      path: '/exercises',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ExerciseLibraryScreen(),
    ),
    GoRoute(
      path: '/exercises/select',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          const ExerciseLibraryScreen(selectionMode: true),
    ),
    GoRoute(
      path: '/exercise/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ExerciseDetailScreen(
          exerciseId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/foods',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FoodsScreen(),
    ),
    GoRoute(
      path: '/export',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ExportScreen(),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

