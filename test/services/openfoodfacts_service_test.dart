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

  // searchByName — paketli ürünü adıyla bulma (docs/11).
  group('searchByName', () {
    test('sonuçları eşler, kalorisiz/barkodsuz/tekrarı eler', () async {
      final s = svc(MockClient((req) async {
        expect(req.url.path, contains('search'));
        expect(req.url.query, contains('canga'));
        return http.Response(
          '{"products":['
          '{"code":"111","product_name":"Canga","nutriments":'
          '{"energy-kcal_100g":529,"proteins_100g":13,"carbohydrates_100g":46,"fat_100g":32,"sugars_100g":37}},'
          '{"code":"111","product_name":"Canga (kopya)","nutriments":{"energy-kcal_100g":529}},'
          '{"code":"222","product_name":"Kalorisiz","nutriments":{}},'
          '{"code":"","product_name":"Barkodsuz","nutriments":{"energy-kcal_100g":100}},'
          '{"code":"333","product_name":"Canga Cookie","nutriments":{"energy-kcal_100g":511,"carbohydrates_100g":62}}'
          ']}',
          200,
        );
      }));
      final r = await s.searchByName('canga');
      expect(r, hasLength(2)); // 111 (tekil) + 333; 222 kalorisiz, "" barkodsuz elendi
      expect(r.first.name, 'Canga');
      expect(r.first.barcode, '111');
      expect(r.first.kcalPer100g, 529);
      expect(r.first.carbPer100g, 46);
      expect(r[1].name, 'Canga Cookie');
    });

    test('2 karakterden kısa sorgu → ağ çağrısı yok', () async {
      var called = false;
      final s = svc(MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      }));
      expect(await s.searchByName('c'), isEmpty);
      expect(called, isFalse);
    });

    test('ağ hatası → boş liste (offline-first)', () async {
      final s = svc(MockClient((_) async => http.Response('oops', 500)));
      expect(await s.searchByName('canga'), isEmpty);
    });
  });
}
