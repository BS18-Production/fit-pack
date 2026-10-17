import 'package:fit_pack/features/legal/privacy_policy_sheet.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// docs/41 P-1: politika metni iki dilde paketli ve zorunlu başlıkları içeriyor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dil yoksa İngilizce', () {
    expect(privacyAssetFor('tr'), 'assets/legal/privacy_tr.md');
    expect(privacyAssetFor('de'), 'assets/legal/privacy_en.md');
  });

  for (final (lang, basliklar) in [
    ('tr', ['Veri sorumlusu', 'Hakların', 'açık rıza', 'Almanya', 'Hesabı sil']),
    ('en', ['Controller', 'Your rights', 'explicit consent', 'Germany', 'Delete account']),
  ]) {
    test('$lang metni paketli ve zorunlu bölümleri içeriyor', () async {
      final s = await rootBundle.loadString(privacyAssetFor(lang));
      for (final b in basliklar) {
        expect(s, contains(b), reason: b);
      }
      // Fotoğraf ve adım sunucuya gitmez — metin bunu söylemeli.
      expect(s.toLowerCase(), anyOf(contains('adım'), contains('step')));
    });
  }
}
