import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

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
    );
  }
}
