import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Bekçi: Flutter 3.41'de `action`'lı SnackBar varsayılan olarak kendiliğinden
/// kapanmıyor (`persist = action != null`). Beslenmede "Menemen silindi —
/// Geri al" şeridi bu yüzden ekranda sonsuza kadar kaldı (2026-10-04).
/// Düğmeli her SnackBar `persist: false` vermeli.
void main() {
  test("lib/ içindeki action'lı her SnackBar persist: false veriyor", () {
    final ihlal = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      var i = 0;
      while ((i = src.indexOf('SnackBar(', i)) != -1) {
        // `showSnackBar(` gibi daha uzun adların parçasıysa atla — ama
        // içindeki asıl SnackBar'ı kaçırmamak için yalnız bir karakter.
        if (i > 0 && RegExp(r'[A-Za-z_]').hasMatch(src[i - 1])) {
          i++;
          continue;
        }
        // Bu SnackBar çağrısının parantez bloğunu bul.
        var depth = 0, j = i + 'SnackBar('.length - 1;
        for (; j < src.length; j++) {
          if (src[j] == '(') depth++;
          if (src[j] == ')' && --depth == 0) break;
        }
        final block = src.substring(i, j);
        if (block.contains('action:') &&
            !block.contains('persist: false')) {
          ihlal.add('${f.path}:${'\n'.allMatches(src.substring(0, i)).length + 1}');
        }
        i = j;
      }
    }
    expect(ihlal, isEmpty,
        reason: 'Düğmeli SnackBar persist: false olmadan ekranda kalır');
  });
}
