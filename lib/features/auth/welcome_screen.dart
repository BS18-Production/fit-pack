import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';

/// ① Karşılama — zorunlu giriş kapısının ilk ekranı (docs/18 §5.1).
///
/// Çıplak giriş formuyla açılmıyoruz: kullanıcı **ne için hesap açtığını**
/// bilmeli, premium ürün önce ne sattığını söyler. Bu sayfa docs/15'teki A1
/// "Karşılama" sayfasının giriş öncesine taşınmış hâlidir — onboarding artık
/// 3 sayfa. **"Atla" YOK.**
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final muted = context.colors.onSurfaceVariant;
    // Zemin (GlassBackground) app.dart'ta tüm ekranlara bir kez verilir.
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSpacing.vGapxl_,
                      // Marka rozeti — Ana Sayfa CTA'sıyla aynı gradient dil.
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.brXl,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.indigo, AppColors.indigoDeep],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.indigoDeep.withValues(alpha: 0.30),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.fitness_center_rounded,
                            size: 40, color: AppColors.onGradient),
                      ),
                      AppSpacing.vGapXl,
                      Text(l.authWelcomeTitle,
                          style:
                              context.texts.displaySmall?.copyWith(height: 1.1)),
                      AppSpacing.vGapMd,
                      Text(l.authWelcomeTagline,
                          style:
                              context.texts.bodyLarge?.copyWith(color: muted)),
                      AppSpacing.vGapxl_,
                      _ValueRow(
                          icon: Icons.fitness_center_rounded,
                          tint: context.colors.primary,
                          text: l.authValueWorkout),
                      AppSpacing.vGapLg,
                      _ValueRow(
                          icon: Icons.restaurant_rounded,
                          tint: context.colors.secondary,
                          text: l.authValueNutrition),
                      AppSpacing.vGapLg,
                      _ValueRow(
                          icon: Icons.trending_up_rounded,
                          tint: context.semantic.success,
                          text: l.authValueProgress),
                    ],
                  ),
                ),
              ),
              AppSpacing.vGapLg,
              FilledButton(
                onPressed: () =>
                    context.push(AppRoutes.authMode(signUp: true)),
                style:
                    FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: Text(l.cloudCreateAccount),
              ),
              AppSpacing.vGapSm,
              TextButton(
                onPressed: () =>
                    context.push(AppRoutes.authMode(signUp: false)),
                child: Text(l.cloudHaveAccount),
              ),
              AppSpacing.vGapSm,
              Text(
                l.authWhyAccount,
                textAlign: TextAlign.center,
                style: context.texts.bodySmall?.copyWith(color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.icon, required this.tint, required this.text});

  final IconData icon;
  final Color tint;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.16),
            borderRadius: AppRadius.brMd,
          ),
          child: Icon(icon, color: tint, size: AppIconSize.md),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: Text(text, style: context.texts.bodyLarge),
        ),
      ],
    );
  }
}
