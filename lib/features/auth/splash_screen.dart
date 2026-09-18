import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Nötr açılış ekranı (docs/20 §7.1 madde 4).
///
/// Kapı henüz karar vermediyse (hesap kontrolü sürüyor) kullanıcıya
/// **Karşılama** ekranı gösterilmemeli: oturumu açık olan biri bir an
/// "çıkış yapmışım" sanıyor, hesap değişiminde ise bir kare eski hesabın
/// ekranı görünebiliyordu. Marka işareti nötr bir bekleme yüzeyidir.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded,
              size: AppIconSize.xxl, color: context.colors.primary),
          AppSpacing.vGapLg,
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.colors.primary,
            ),
          ),
        ],
      ),
    ),
  );
}
