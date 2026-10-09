import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'velocity_navigation.dart';
import '../../core/theme/app_dimens.dart';

/// Alt sekmeli kabuk. `StatefulShellRoute.indexedStack` ile beslenir: 4 sekme
/// ekranı `IndexedStack` içinde canlı kalır → sekme geçişinde yeniden inşa ve
/// (autoDispose) provider yeniden-fetch olmaz, geçiş pürüzsüz + scroll korunur.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // İçerik yüzen gezinme çubuğunun altından akar.
      // Sekme ekranları alt boşluğu MediaQuery.padding.bottom'dan alır.
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: VelocityNavigation(
            selectedIndex: navigationShell.currentIndex,
            onSelected: (index) {
              if (index != navigationShell.currentIndex) {
                ScaffoldMessenger.of(context).clearSnackBars();
              }
              // Aynı sekme köküne döner; diğer dalın scroll/durumu korunur.
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
          ),
        ),
      ),
    );
  }
}
