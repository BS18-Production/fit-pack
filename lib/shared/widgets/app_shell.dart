import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_l10n.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.workout)) return 1;
    if (location.startsWith(AppRoutes.nutrition)) return 2;
    if (location.startsWith(AppRoutes.progress)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      // İçerik buzlu gezinme çubuğunun ALTINDAN akar (liquid glass).
      // Sekme ekranları alt boşluğu MediaQuery.padding.bottom'dan alır.
      extendBody: true,
      body: child,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: dark ? AppGlass.darkNavFill : AppGlass.lightNavFill,
              border: Border(
                top: BorderSide(
                  color:
                      dark ? AppGlass.darkHairline : AppGlass.lightHairline,
                  width: 1,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex(context),
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go(AppRoutes.home);
                  case 1:
                    context.go(AppRoutes.workout);
                  case 2:
                    context.go(AppRoutes.nutrition);
                  case 3:
                    context.go(AppRoutes.progress);
                }
              },
              // Phosphor ikonlar (premium set): seçili sekme dolgulu (fill) +
              // indigo, seçili değil ince çizgi (regular) + gri → net hiyerarşi.
              destinations: [
                NavigationDestination(
                  icon: const Icon(PhosphorIconsRegular.house),
                  selectedIcon: const Icon(PhosphorIconsFill.house),
                  label: l.navHome,
                ),
                NavigationDestination(
                  icon: const Icon(PhosphorIconsRegular.barbell),
                  selectedIcon: const Icon(PhosphorIconsFill.barbell),
                  label: l.navWorkout,
                ),
                NavigationDestination(
                  icon: const Icon(PhosphorIconsRegular.forkKnife),
                  selectedIcon: const Icon(PhosphorIconsFill.forkKnife),
                  label: l.navNutrition,
                ),
                NavigationDestination(
                  icon: const Icon(PhosphorIconsRegular.chartLineUp),
                  selectedIcon: const Icon(PhosphorIconsFill.chartLineUp),
                  label: l.navProgress,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
