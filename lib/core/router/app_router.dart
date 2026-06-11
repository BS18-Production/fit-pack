import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_pack/features/home/home_screen.dart';
import 'package:fit_pack/features/workout/workout_list_screen.dart';
import 'package:fit_pack/features/workout/workout_session_screen.dart';
import 'package:fit_pack/features/workout/workout_preview_screen.dart';
import 'package:fit_pack/features/workout/workout_history_screen.dart';
import 'package:fit_pack/features/nutrition/nutrition_screen.dart';
import 'package:fit_pack/features/nutrition/foods_screen.dart';
import 'package:fit_pack/features/body_metrics/body_metrics_screen.dart';
import 'package:fit_pack/features/export/export_screen.dart';
import 'package:fit_pack/features/settings/settings_screen.dart';
import 'package:fit_pack/shared/widgets/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
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
      path: '/workout/session/:workoutType',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final workoutType = state.pathParameters['workoutType']!;
        return WorkoutSessionScreen(workoutType: workoutType);
      },
    ),
    GoRoute(
      path: '/workout/preview/:workoutType',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final workoutType = state.pathParameters['workoutType']!;
        return WorkoutPreviewScreen(workoutType: workoutType);
      },
    ),
    GoRoute(
      path: '/workout/history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const WorkoutHistoryScreen(),
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
