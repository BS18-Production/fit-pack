import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// OpenFoodFacts barkod sorgusu (docs/07-nutrition-v2.md §7).
///
/// Offline-first KORUNUR: hata / timeout / çevrimdışı / eksik veri → `null`.
/// Uygulama internetsiz de tam çalışır; bu yalnızca bir zenginleştirme.
/// Yalnızca barkod numarası gönderilir, kişisel veri gitmez (açık veri).
class OffProduct {
  final String name;
  final String barcode;
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbPer100g;
  final double fatPer100g;

  OffProduct({
    required this.name,
    required this.barcode,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbPer100g,
    required this.fatPer100g,
  });
}

class OpenFoodFactsService {
  final http.Client _client;
  OpenFoodFactsService([http.Client? client])
      : _client = client ?? http.Client();

  // OFF, tanımlayıcı bir User-Agent zorunlu kılar.
  static const _ua = 'FitPack/2.0 (Android; sametorhan@gmail.com)';

  Future<OffProduct?> fetchByBarcode(String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty) return null;
    final uri = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$code.json'
      '?fields=product_name,product_name_tr,brands,nutriments',
    );
    try {
      final res = await _client
          .get(uri, headers: {'User-Agent': _ua})
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final body = json.decode(res.body) as Map<String, dynamic>;
      if (body['status'] != 1) return null; // ürün yok
      final p = body['product'] as Map<String, dynamic>?;
      if (p == null) return null;

      final name = _firstStr(p, ['product_name_tr', 'product_name', 'brands']);
      if (name == null) return null;

      final n = (p['nutriments'] as Map<String, dynamic>?) ?? const {};
      final kcal = _firstNum(n, ['energy-kcal_100g', 'energy-kcal']);
      if (kcal == null) return null; // kalori yoksa loglanamaz → işe yaramaz

      return OffProduct(
        name: name,
        barcode: code,
        kcalPer100g: kcal,
        proteinPer100g: _firstNum(n, ['proteins_100g', 'proteins']) ?? 0,
        carbPer100g:
            _firstNum(n, ['carbohydrates_100g', 'carbohydrates']) ?? 0,
        fatPer100g: _firstNum(n, ['fat_100g', 'fat']) ?? 0,
      );
    } on TimeoutException {
      return null;
    } catch (_) {
      return null; // ağ/parse hatası → sessiz; UI Türkçe mesaj gösterir
    }
  }

  String? _firstStr(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  double? _firstNum(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is num) return v.toDouble();
      if (v is String) {
        final d = double.tryParse(v);
        if (d != null) return d;
      }
    }
    return null;
  }

  void dispose() => _client.close();
}
