import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_l10n.dart';

/// Alt sekmeli kabuk. `StatefulShellRoute.indexedStack` ile beslenir: 4 sekme
/// ekranı `IndexedStack` içinde canlı kalır → sekme geçişinde yeniden inşa ve
/// (autoDispose) provider yeniden-fetch olmaz, geçiş pürüzsüz + scroll korunur.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      // İçerik buzlu gezinme çubuğunun ALTINDAN akar (liquid glass).
      // Sekme ekranları alt boşluğu MediaQuery.padding.bottom'dan alır.
      extendBody: true,
      body: navigationShell,
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
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) {
                // Aynı sekmeye tekrar dokununca o dalın köküne dön (standart
                // davranış); farklı sekmede sadece görünen dal değişir.
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
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
