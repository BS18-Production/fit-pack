import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: dark ? AppGlass.darkNavFill : AppGlass.lightNavFill,
              borderRadius: AppRadius.brXl,
              border: Border.all(color: context.colors.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: context.colors.shadow.withValues(alpha: .18),
                  blurRadius: AppSpacing.xl,
                  offset: const Offset(0, AppSpacing.sm),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppRadius.brXl,
              child: NavigationBar(
                // Büyük metinde sekme adları birbirine girmez; ikonların
                // erişilebilir adları ve uzun basma açıklamaları korunur.
                labelBehavior:
                    MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                        (MediaQuery.sizeOf(context).width < 360 &&
                            MediaQuery.textScalerOf(context).scale(1) > 1.15)
                    ? NavigationDestinationLabelBehavior.alwaysHide
                    : NavigationDestinationLabelBehavior.alwaysShow,
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (index) {
                  // Sekme değişince açık bildirim şeridi kapanır: "X silindi —
                  // Geri al" başka sekmede anlamsız (geri alma o ekrana ait) ve
                  // ait olmadığı içeriğin üstünde asılı kalıyordu.
                  if (index != navigationShell.currentIndex) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                  }
                  // Aynı sekmeye tekrar dokununca o dalın köküne dön (standart
                  // davranış); farklı sekmede sadece görünen dal değişir.
                  navigationShell.goBranch(
                    index,
                    initialLocation: index == navigationShell.currentIndex,
                  );
                },
                // Phosphor ikonlar (premium set): seçili sekme dolgulu (fill) +
                // lime, seçili değil ince çizgi (regular) + gri → net hiyerarşi.
                destinations: [
                  NavigationDestination(
                    icon: const Icon(PhosphorIconsRegular.house),
                    selectedIcon: const Icon(PhosphorIconsFill.house),
                    label: l.navHome,
                    tooltip: l.navHome,
                  ),
                  NavigationDestination(
                    icon: const Icon(PhosphorIconsRegular.barbell),
                    selectedIcon: const Icon(PhosphorIconsFill.barbell),
                    label: l.navWorkout,
                    tooltip: l.navWorkout,
                  ),
                  NavigationDestination(
                    icon: const Icon(PhosphorIconsRegular.forkKnife),
                    selectedIcon: const Icon(PhosphorIconsFill.forkKnife),
                    label: l.navNutrition,
                    tooltip: l.navNutrition,
                  ),
                  NavigationDestination(
                    icon: const Icon(PhosphorIconsRegular.chartLineUp),
                    selectedIcon: const Icon(PhosphorIconsFill.chartLineUp),
                    label: l.navProgress,
                    tooltip: l.navProgress,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
