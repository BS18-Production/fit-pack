import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Kapının "dur" ekranlarının ortak iskeleti (docs/20 §7.4-7.5, docs/23 §3).
///
/// Üç ekran aynı görünüyor: hesap doğrulanamadı, hesap çakışması, zorunlu
/// güncelleme. Hepsi kullanıcıyı uygulamanın içine ALMIYOR ve aynı düzeni
/// kullanıyor — iskelet kopyalansaydı biri değişince ötekiler ayrışırdı.
class GateScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final List<Widget> actions;

  const GateScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppIconSize.xxl, color: context.colors.primary),
              AppSpacing.vGapLg,
              Text(title,
                  textAlign: TextAlign.center,
                  style: context.texts.headlineSmall),
              AppSpacing.vGapMd,
              Text(message,
                  textAlign: TextAlign.center,
                  style: context.texts.bodyMedium
                      ?.copyWith(color: context.colors.onSurfaceVariant)),
              AppSpacing.vGapXl,
              ...actions,
            ],
          ),
        ),
      ),
    ),
  );
}
