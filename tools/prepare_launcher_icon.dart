// Seçilen görseli yeniden tasarlamadan başlatıcı ikon kaynaklarını hazırlar.
// Çalıştır: dart run tools/prepare_launcher_icon.dart
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  const directory = 'assets/icon';
  const size = 1024;
  final master = img.decodePng(
    File('$directory/icon_master.png').readAsBytesSync(),
  );
  if (master == null || master.width != master.height) {
    throw StateError('İkon kaynağı kare bir PNG olmalı.');
  }
  final full = img.copyResize(
    master,
    width: size,
    height: size,
    interpolation: img.Interpolation.average,
  );
  final background = img.Image(width: size, height: size, numChannels: 3);
  img.fill(background, color: img.ColorRgb8(204, 255, 0));
  final foreground = img.Image(width: size, height: size, numChannels: 4);
  for (final pixel in full) {
    // Kaynak iki renkten oluşur: nötr siyah işaret ve lime zemin.
    // Yeşil-mavi farkı zeminin payını verir; kenar yumuşaklığı korunur.
    final alpha = (1 - (pixel.g - pixel.b) / 255).clamp(0.0, 1.0);
    if (alpha < 0.02) continue;
    final dark = (pixel.b / alpha).round().clamp(0, 255);
    foreground.setPixelRgba(
      pixel.x,
      pixel.y,
      dark,
      dark,
      dark,
      (alpha * 255).round(),
    );
  }
  for (final entry in {
    'icon_full.png': full,
    'icon_bg.png': background,
    'icon_fg.png': foreground,
  }.entries) {
    File(
      '$directory/${entry.key}',
    ).writeAsBytesSync(img.encodePng(entry.value));
  }
  stdout.writeln('1024 px ikon ve Android katmanları hazır.');
}
