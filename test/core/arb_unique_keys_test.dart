import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ARB'de aynı anahtar iki kez yazılırsa JSON sessizce birini ezer —
/// 2026-10-08'de Keşfet başlığı "Veri Dışa Aktar" çıktı (`exTitle` çakışması).
void main() {
  for (final path in ['lib/l10n/app_tr.arb', 'lib/l10n/app_en.arb']) {
    test('$path: anahtarlar tekil', () {
      final keys = RegExp(r'^  "([^"]+)":', multiLine: true)
          .allMatches(File(path).readAsStringSync())
          .map((m) => m.group(1)!)
          .toList();
      final seen = <String>{};
      final dupes = [for (final k in keys) if (!seen.add(k)) k];
      expect(dupes, isEmpty);
    });
  }
}
