import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/units/units.dart';

/// Seans içi kilo ± düğmesinin adımı (Samet'in salon notu, 2026-09-30).
///
/// Adım hareketten harekete değişir (halterde 2,5; dambılda 2; bazı
/// makinelerde 3,5 ya da 1,75). Öncelik sırası:
/// 1. Kullanıcının o hareket için seçtiği adım (cihazda saklanır).
/// 2. Geçmişteki kilolardan tahmin ([inferStepKg]) — ör. 55 → 57,5 → 60.
/// 3. Ekipmana göre varsayılan ([defaultStepKg]).
///
/// Adım bir **cihaz tercihidir**, kayıt verisi değil: şemaya girmez, senkron
/// edilmez (şema v14 + sunucu göçü gerektirmesin diye bilinçli seçim).

/// Seçilebilir adımlar — görüntü biriminde.
const stepOptionsKg = <double>[0.5, 1, 1.25, 1.75, 2, 2.5, 3.5, 4, 5, 10];
const stepOptionsLb = <double>[1, 2.5, 5, 10, 15, 20];

/// Tahminde kabul edilen aralık (kg): daha küçüğü ölçüm/yuvarlama gürültüsü,
/// daha büyüğü setler arası "atlama" (ısınma → çalışma) olabilir.
const _minInferKg = 0.5;
const _maxInferKg = 10.0;

/// Ekipmana göre varsayılan adım (kg). Imperial'de 5 lb.
double defaultStepKg(String? equipment, Units units) {
  if (units.imperial) return units.weightToKg(5);
  return switch (equipment) {
    'dumbbell' => 2,
    'kettlebell' => 4,
    'machine' || 'cable' => 5,
    _ => 2.5, // barbell, smith ve diğerleri
  };
}

/// Kullanılan kilolardan adım tahmini: farklı kilolar arasındaki en küçük
/// fark. İki farklı kilo yoksa ya da fark makul aralıkta değilse null.
double? inferStepKg(Iterable<double> weightsKg) {
  final sorted = weightsKg.where((w) => w > 0).toSet().toList()..sort();
  double? best;
  for (var i = 1; i < sorted.length; i++) {
    // Kayan nokta gürültüsünü (57.5 - 55 = 2.4999…) 0,01'e yuvarla.
    final d = ((sorted[i] - sorted[i - 1]) * 100).round() / 100;
    if (d < _minInferKg || d > _maxInferKg) continue;
    if (best == null || d < best) best = d;
  }
  return best;
}

/// Adımı uygular: [current] (kg) boşsa [base]'den başlar; 0'ın altına inmez.
double applyStepKg({
  required double? current,
  required double? base,
  required double stepKg,
  required int direction,
}) {
  final from = current ?? base ?? 0;
  final next = from + direction * stepKg;
  if (next <= 0) return 0;
  // 55 + 2.5 = 57.49999… gibi değerler kayda öyle girmesin.
  return (next * 1000).round() / 1000;
}

/// Hareket başına kullanıcı seçimi: exerciseId → adım (kg).
class WeightStepPrefs extends Notifier<Map<int, double>> {
  static const _prefix = 'weight_step_kg_';

  @override
  Map<int, double> build() {
    _load();
    return const {};
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final out = <int, double>{};
      for (final k in prefs.getKeys()) {
        if (!k.startsWith(_prefix)) continue;
        final id = int.tryParse(k.substring(_prefix.length));
        final v = prefs.getDouble(k);
        if (id != null && v != null && v > 0) out[id] = v;
      }
      if (out.isNotEmpty) state = {...out, ...state};
    } catch (_) {
      // Tercih okunamazsa tahmin/varsayılan kullanılır — seans etkilenmez.
    }
  }

  Future<void> set(int exerciseId, double stepKg) async {
    state = {...state, exerciseId: stepKg};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('$_prefix$exerciseId', stepKg);
    } catch (_) {
      // Bu seans için bellekte geçerli; kalıcı yazım en iyi çaba.
    }
  }
}

final weightStepPrefsProvider =
    NotifierProvider<WeightStepPrefs, Map<int, double>>(WeightStepPrefs.new);
