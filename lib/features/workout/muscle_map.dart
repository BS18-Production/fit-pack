import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';

/// Hangi kasın çalıştığını gösteren vücut diyagramı (İçerik Zenginleştirme —
/// docs/11). MIT lisanslı muscle_selector'ın human_body.svg'sini bizim kas
/// verimizle (primaryMuscle + muscleGroups) renklendirir. Birincil = koyu,
/// ikincil = açık. Per-hareket görsel gerekmez; tek diyagram, veriden boyanır.
class MuscleMap extends StatelessWidget {
  final String? primaryMuscle;
  final List<String> muscles;
  const MuscleMap({super.key, this.primaryMuscle, this.muscles = const []});

  // Bizim kas anahtarımız → SVG grup ön ekleri (id prefix'leri).
  static const _map = <String, List<String>>{
    'chest': ['chest'],
    'back': ['lats', 'trapezius', 'upper_back'],
    'lats': ['lats', 'upper_back'],
    'lower_back': ['lower_back'],
    'traps': ['trapezius', 'upper_back'],
    'shoulders': ['shoulder'],
    'biceps': ['biceps'],
    'triceps': ['triceps'],
    'forearms': ['forearm'],
    'core': ['abs', 'obliques'],
    'abs': ['abs'],
    'obliques': ['obliques'],
    'glutes': ['glutes'],
    'quads': ['quads'],
    'hamstrings': ['harmstrings'],
    'legs': ['quads', 'harmstrings', 'calves'],
    'calves': ['calves'],
    'neck': ['neck'],
    'abductors': ['abductor'],
    'adductors': ['adductors'],
  };

  static Set<String> _prefixes(Iterable<String> keys) =>
      {for (final k in keys) ...(_map[k.toLowerCase()] ?? const [])};

  // SVG bir kez yüklenir, sonra bellekten.
  static Future<String>? _svgFuture;
  static Future<String> _loadSvg() =>
      _svgFuture ??= rootBundle.loadString('assets/maps/human_body.svg');

  String _colorize(
      String svg, Color primary, Color secondary, Color base, Color stroke) {
    final pri = _prefixes(primaryMuscle == null ? const [] : [primaryMuscle!]);
    final sec = _prefixes(muscles)..removeAll(pri);
    String hex(Color c) =>
        '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    final pHex = hex(primary), sHex = hex(secondary), bHex = hex(base);
    final stHex = hex(stroke);
    // viewBox yok → ekle (içerik sınırlarına göre).
    svg = svg.replaceFirst(
        RegExp(r'<svg'), '<svg viewBox="-115 -135 415 460"');
    // Her kas path'ine id ön ekine göre fill enjekte et. id'ler alt çizgi
    // içerebilir (upper_back1, lower_back) → [a-zA-Z_].
    return svg.replaceAllMapped(RegExp(r'<path id="([a-zA-Z_]+?)\d*"'), (m) {
      final g = m.group(1)!;
      final fill = pri.contains(g) ? pHex : (sec.contains(g) ? sHex : bHex);
      return '${m.group(0)} fill="$fill" stroke="$stHex" stroke-width="0.6"';
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primary;
    // Çalışmayan kaslar: net görünür açık-orta gri (çok soluk olmasın).
    final base = Color.lerp(
        context.colors.onSurfaceVariant, context.colors.surface, 0.55)!;
    final stroke = context.colors.onSurfaceVariant;
    // İkincil = birincil ile taban arası açık ton (alpha değil; hex'te alpha
    // atıldığı için lerp ile gerçek açık renk üretilir).
    final secondary = Color.lerp(primary, base, 0.5)!;
    return FutureBuilder<String>(
      future: _loadSvg(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(height: 200);
        }
        final colored = _colorize(snap.data!, primary, secondary, base, stroke);
        return SvgPicture.string(
          colored,
          height: 220,
          fit: BoxFit.contain,
        );
      },
    );
  }
}
