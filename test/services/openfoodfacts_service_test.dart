import 'package:fit_pack/data/services/openfoodfacts_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// OpenFoodFacts JSON → OffProduct eşleme (docs/07-nutrition-v2.md §7, §8).
/// http MockClient ile — gerçek ağ yok, deterministik.
void main() {
  OpenFoodFactsService svc(MockClient c) => OpenFoodFactsService(c);

  test('geçerli ürün → Türkçe ad + /100g makro doğru eşlenir', () async {
    final s = svc(MockClient((req) async {
      expect(req.headers['User-Agent'], isNotNull); // OFF zorunlu
      expect(req.url.path, contains('8690000000001'));
      return http.Response(
        '{"status":1,"product":{"product_name":"Biscuit",'
        '"product_name_tr":"Bisküvi","nutriments":{'
        '"energy-kcal_100g":450,"proteins_100g":7.5,'
        '"carbohydrates_100g":60,"fat_100g":20}}}',
        200,
      );
    }));

    final p = await s.fetchByBarcode('8690000000001');
    expect(p, isNotNull);
    expect(p!.name, 'Bisküvi'); // tr adı öncelikli
    expect(p.barcode, '8690000000001');
    expect(p.kcalPer100g, 450);
    expect(p.proteinPer100g, 7.5);
    expect(p.carbPer100g, 60);
    expect(p.fatPer100g, 20);
  });

  test('ürün yok (status:0) → null', () async {
    final s = svc(MockClient((_) async =>
        http.Response('{"status":0,"status_verbose":"not found"}', 200)));
    expect(await s.fetchByBarcode('0000000000000'), isNull);
  });

  test('kalori yoksa → null (loglanamaz, işe yaramaz)', () async {
    final s = svc(MockClient((_) async => http.Response(
        '{"status":1,"product":{"product_name":"X","nutriments":{}}}',
        200)));
    expect(await s.fetchByBarcode('123'), isNull);
  });

  test('ağ/sunucu hatası → null (offline-first, uygulama bozulmaz)',
      () async {
    final s = svc(MockClient((_) async => http.Response('oops', 500)));
    expect(await s.fetchByBarcode('123'), isNull);
  });

  test('boş barkod → ağ çağrısı yapmadan null', () async {
    var called = false;
    final s = svc(MockClient((_) async {
      called = true;
      return http.Response('{}', 200);
    }));
    expect(await s.fetchByBarcode('  '), isNull);
    expect(called, isFalse);
  });
}
