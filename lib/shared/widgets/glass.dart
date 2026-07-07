import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Apple "liquid glass" bileşenleri (premium reskin — 2026-07).
///
/// İki parça:
/// 1. [GlassBackground] — ekranın arkasına yumuşak indigo/teal ışıma + baz
///    gradyan koyar. Cam bir şeyi bulanıklaştırmak için ARKADA zemin ister;
///    düz tek renk üstünde cam "çamur" gibi görünür.
/// 2. [GlassCard] — yarı saydam yüzey + arka bulanıklık (backdrop blur) + ince
///    üst kenar parlaması + yumuşak gölge. Açık/koyu temaya göre otomatik.
///
/// PERFORMANS NOTU: `BackdropFilter` GPU-yoğundur. Giriş seviyesi cihazlarda
/// (Samet: SM A075F) çok sayıda canlı blur takılabilir → [GlassCard.blur]
/// ile kapatılabilir; kapalıyken yarı saydam gradyan yine "buzlu" görünür
/// (zemin ışıması yumuşak olduğu için). Gerçek cihazda ölçülüp ayarlanır.

/// Tema-duyarlı cam renk paleti.
class _GlassPalette {
  final List<Color> fill; // kart dolgu gradyanı
  final Color hairline; // kenarlık
  final Color hairlineTop; // üst kenar parlaması
  final Color shadow;
  final List<Color> bgBase; // ekran baz gradyanı
  final Color glowIndigo;
  final Color glowTeal;
  const _GlassPalette(this.fill, this.hairline, this.hairlineTop, this.shadow,
      this.bgBase, this.glowIndigo, this.glowTeal);

  // Renk değerleri tek yerden: [AppGlass] (core/theme/app_colors.dart) —
  // tema (Card/NavigationBar) ile buradaki bileşenler aynı paleti paylaşır.
  static _GlassPalette of(Brightness b) => b == Brightness.dark
      ? const _GlassPalette(
          AppGlass.darkFill,
          AppGlass.darkHairline,
          AppGlass.darkHairlineTop,
          AppGlass.darkShadow,
          AppGlass.darkBgBase,
          AppGlass.darkGlowIndigo,
          AppGlass.darkGlowTeal,
        )
      : const _GlassPalette(
          AppGlass.lightFill,
          AppGlass.lightHairline,
          AppGlass.lightHairlineTop,
          AppGlass.lightShadow,
          AppGlass.lightBgBase,
          AppGlass.lightGlowIndigo,
          AppGlass.lightGlowTeal,
        );
}

/// Ekran arka planı: baz gradyan + iki yumuşak ışıma kümesi. İçeriği [child]
/// olarak üstüne bindirir. Scaffold body'sini sarmak için.
class GlassBackground extends StatelessWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = _GlassPalette.of(Theme.of(context).brightness);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: p.bgBase,
        ),
      ),
      child: Stack(
        children: [
          // Sağ-üst indigo ışıma
          Positioned(
            top: -120,
            right: -90,
            child: _Glow(color: p.glowIndigo, size: 340),
          ),
          // Sol-alt teal ışıma
          Positioned(
            bottom: -140,
            left: -100,
            child: _Glow(color: p.glowTeal, size: 360),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  const _Glow({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            // 3 duraklı yumuşak düşüş: parlak çekirdek + uzun, kenarı
            // belirsiz kuyruk → "ışık sızması" hissi (lineer kenar yok).
            stops: const [0.0, 0.45, 1.0],
            colors: [
              color,
              color.withValues(alpha: color.a * 0.32),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cam yüzey kart. Yarı saydam + arka bulanıklık + ince kenarlık + gölge.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Canlı arka bulanıklık. Kapatılırsa yalnız yarı saydam gradyan (ucuz).
  final bool blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = 22,
    this.onTap,
    this.onLongPress,
    this.blur = true,
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
              gradient: LinearGradient(colors: [
                p.hairlineTop.withValues(alpha: 0),
                p.hairlineTop,
                p.hairlineTop.withValues(alpha: 0),
              ]),
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
