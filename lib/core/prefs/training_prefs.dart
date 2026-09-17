import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../units/units.dart';

/// Antrenman tercihleri — ilerleme önerisindeki kilo artışı (docs/21 #3).
///
/// Kayıt kg cinsinden (DB kuralı: hep metrik). `null` = kullanıcı seçmedi →
/// birim sistemine göre varsayılan: metrik 1,25 kg (Samet kararı), imperial
/// 2,5 lb (salonlardaki en küçük yaygın plaka çifti).
class WeightIncrementNotifier extends Notifier<double?> {
  static const _key = 'weight_increment_kg';

  @override
  double? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_key);
    if (saved != null && saved > 0) state = saved;
  }

  Future<void> setIncrementKg(double kg) async {
    state = kg;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, kg);
  }
}

final weightIncrementProvider =
    NotifierProvider<WeightIncrementNotifier, double?>(
      WeightIncrementNotifier.new,
    );

const _defaultIncrementKg = 1.25;
const _defaultIncrementLb = 2.5;

/// Seçenekler — görüntü biriminde (metrik: kg, imperial: lb).
const incrementOptionsKg = <double>[0.5, 1, 1.25, 2, 2.5, 5];
const incrementOptionsLb = <double>[1, 2.5, 5, 10];

/// Geçerli artış (kg): kayıtlı değer ya da birime göre varsayılan.
double effectiveIncrementKg(double? savedKg, Units units) =>
    savedKg ??
    (units.imperial
        ? units.weightToKg(_defaultIncrementLb)
        : _defaultIncrementKg);

final effectiveIncrementKgProvider = Provider<double>(
  (ref) => effectiveIncrementKg(
    ref.watch(weightIncrementProvider),
    ref.watch(unitsProvider),
  ),
);
