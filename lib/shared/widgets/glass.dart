import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Performans Günlüğü yüzeyleri: mat zemin, opak kart, ince üst kenar ve
/// hafif gölge. Canlı bulanıklık varsayılan olarak kapalıdır; eski ortak
/// bileşen API'si korunur. Açık/koyu tema aynı rollerden beslenir.

/// Tema-duyarlı cam renk paleti.
class _GlassPalette {
  final List<Color> fill; // kart dolgu gradyanı
  final Color hairline; // kenarlık
  final Color hairlineTop; // üst kenar parlaması
  final Color shadow;
  const _GlassPalette(this.fill, this.hairline, this.hairlineTop, this.shadow);

  // Renk değerleri tek yerden: [AppGlass] (core/theme/app_colors.dart) —
  // tema (Card/NavigationBar) ile buradaki bileşenler aynı paleti paylaşır.
  static _GlassPalette of(Brightness b) => b == Brightness.dark
      ? const _GlassPalette(
          AppGlass.darkFill,
          AppGlass.darkHairline,
          AppGlass.darkHairlineTop,
          AppGlass.darkShadow,
        )
      : const _GlassPalette(
          AppGlass.lightFill,
          AppGlass.lightHairline,
          AppGlass.lightHairlineTop,
          AppGlass.lightShadow,
        );
}

/// Tüm ekranlar için mat, tema-duyarlı zemin.
class GlassBackground extends StatelessWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Mat zemin: tüm sayfalarda aynı kömür yüzey. Renkli ışıma yalnız
    // gerçek veri işaretlerinde ve kalori halkasında kullanılır.
    return DecoratedBox(
      decoration: BoxDecoration(color: context.colors.surfaceContainerLowest),
      child: child,
    );
  }
}

/// Hafif cam hissi veren opak kart: ince kenarlık, üst ışık ve gölge.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// İsteğe bağlı canlı bulanıklık; listelerde varsayılan kapalıdır.
  final bool blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadius.xl,
    this.onTap,
    this.onLongPress,
    this.blur = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = _GlassPalette.of(Theme.of(context).brightness);
    final br = BorderRadius.circular(radius);

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: p.fill,
        ),
        border: Border.all(color: p.hairline, width: 1),
      ),
      child: Padding(padding: padding, child: child),
    );

    // Üst kenar parlaması (cam hissi) — ince gradyan çizgi.
    surface = Stack(
      children: [
        surface,
        Positioned(
          left: 1,
          right: 1,
          top: 0,
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  p.hairlineTop.withValues(alpha: 0),
                  p.hairlineTop,
                  p.hairlineTop.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    if (onTap != null || onLongPress != null) {
      surface = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: br,
          child: surface,
        ),
      );
    }

    Widget clipped = ClipRRect(
      borderRadius: br,
      child: blur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: surface,
            )
          : surface,
    );

    // Gölge kırpmanın DIŞINDA (ClipRRect gölgeyi keser).
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: br,
          boxShadow: [
            BoxShadow(
              color: p.shadow,
              blurRadius: 24,
              offset: const Offset(0, 12),
              spreadRadius: -6,
            ),
          ],
        ),
        child: clipped,
      ),
    );
  }
}
