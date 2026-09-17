import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Birim sistemi (docs/16 §3 — B5).
///
/// KURAL: Veritabanı HER ZAMAN metrik tutar (kg, cm, m). Dönüşüm yalnız
/// görüntüleme + giriş SINIRINDA yapılır — şema değişmez, mevcut veri aynen
/// kalır. Ekranlar ham sayı yazmaz; [Units] yardımcılarından geçirir.
enum UnitSystem { metric, imperial }

class UnitSystemNotifier extends Notifier<UnitSystem> {
  static const _key = 'unit_system';

  @override
  UnitSystem build() {
    _load();
    return UnitSystem.metric; // varsayılan: metrik (TR)
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_key) == 'imperial') state = UnitSystem.imperial;
  }

  Future<void> setSystem(UnitSystem system) async {
    state = system;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, system.name);
  }
}

final unitSystemProvider =
    NotifierProvider<UnitSystemNotifier, UnitSystem>(UnitSystemNotifier.new);

/// Ekranların kullandığı dönüşüm/format yüzeyi. `ref.watch(unitsProvider)`
/// ile alınır — tercih değişince izleyen ekranlar yeniden çizilir.
final unitsProvider =
    Provider<Units>((ref) => Units(ref.watch(unitSystemProvider)));

class Units {
  final UnitSystem system;
  const Units(this.system);

  static const double _lbPerKg = 2.2046226218;
  static const double _cmPerIn = 2.54;

  bool get imperial => system == UnitSystem.imperial;

  // ── Ağırlık (DB: kg) ─────────────────────────────────────────────
  String get weightUnit => imperial ? 'lb' : 'kg';

  /// kg → görüntü birimi (sayı).
  double weightFromKg(num kg) =>
      imperial ? kg * _lbPerKg : kg.toDouble();

  /// Girişteki görüntü birimi → kg (DB'ye yazılacak değer).
  double weightToKg(num display) =>
      imperial ? display / _lbPerKg : display.toDouble();

  /// "84.7 kg" / "186.7 lb". [frac] ondalık basamak; tam sayıysa kırpılır.
  String weight(num kg, {int frac = 1}) =>
      '${_fmt(weightFromKg(kg), frac)} $weightUnit';

  /// Birimsiz sayı ("84.7" / "186.7") — birimin ayrı yazıldığı yerler için.
  String weightValue(num kg, {int frac = 1}) => _fmt(weightFromKg(kg), frac);

  /// Antrenman kilosu: metrikte 1,25 kg'lık plakalar için iki ondalık
  /// ("61.25"), imperial'de bir ondalık ("135.5"). Sondaki sıfırlar atılır.
  String liftValue(num kg) => _fmt(weightFromKg(kg), imperial ? 1 : 2);
  String lift(num kg) => '${liftValue(kg)} $weightUnit';

  // ── Uzunluk: çevre ölçüleri (DB: cm) ─────────────────────────────
  String get lengthUnit => imperial ? 'in' : 'cm';
  double lengthFromCm(num cm) => imperial ? cm / _cmPerIn : cm.toDouble();
  double lengthToCm(num display) =>
      imperial ? display * _cmPerIn : display.toDouble();
  String length(num cm, {int frac = 1}) =>
      '${_fmt(lengthFromCm(cm), frac)} $lengthUnit';

  // ── Boy (DB: cm; imperial görüntü: ft-in) ────────────────────────
  /// "180 cm" / "5'11"". İmperial'de inç en yakına yuvarlanır (12→ft artar).
  String height(num cm) {
    if (!imperial) return '${_fmt(cm, 1)} cm';
    final (ft, inch) = heightToFtIn(cm);
    return '$ft\'$inch"';
  }

  /// cm → (ft, in). in 0..11 aralığına normalize edilir.
  static (int, int) heightToFtIn(num cm) {
    final totalIn = (cm / _cmPerIn).round();
    return (totalIn ~/ 12, totalIn % 12);
  }

  static double ftInToCm(int ft, num inch) => (ft * 12 + inch) * _cmPerIn;

  // ── Mesafe (DB: metre; kardiyo) ──────────────────────────────────
  String get distanceUnit => imperial ? 'mi' : 'km';
  double distanceFromM(num meters) =>
      imperial ? meters / 1609.344 : meters / 1000.0;
  double distanceToM(num display) =>
      imperial ? display * 1609.344 : display * 1000.0;

  /// Birimsiz, yuvarlanmış mesafe sayısı ("5.2" / "3.2"). Dönüşümden gelen
  /// uzun ondalıkları kırpar — görüntüleme bunun üzerinden yapılır.
  String distanceValue(num meters, {int frac = 1}) =>
      _fmt(distanceFromM(meters), frac);

  static String _fmt(num v, int frac) {
    final r = double.parse(v.toStringAsFixed(frac));
    if (r == r.roundToDouble()) return '${r.round()}';
    // "62.50" → "62.5" (iki ondalıkta gereksiz sıfır kalmasın)
    return r.toStringAsFixed(frac).replaceFirst(RegExp(r'0+$'), '');
  }
}
