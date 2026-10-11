import 'package:drift/drift.dart' show Value;

import '../../data/database/app_database.dart';

/// **Günde tek ölçüm** (docs/40 W-4, W-5, W-6) — saf, test edilebilir.
///
/// `body_measurements` artık elle girilen ve tartıdan (Apple Sağlık / Health
/// Connect) içe alınan satırları birlikte tutuyor. Hesaplar (son kilo, kilo
/// eğilimi, haftalık değerlendirme, TDEE, asistan) satır başına okursa aynı
/// gün iki değer ortalamayı kaydırır. Bu fonksiyon her gün için tek satır
/// üretir:
///
/// - Gizlenen satırlar (`hidden`) hiç sayılmaz.
/// - **Kilo:** o gün kilosu dolu **elle** giriş varsa en son kaydedileni
///   (kullanıcı düzeltme girebilir); yoksa günün **ilk** tartı ölçümü.
/// - **Yağ oranı:** aynı kural, kilodan **bağımsız** seçilir.
/// - Dönen satır, kilosu seçilen gerçek satırdır (yağ oranı gerekirse başka
///   satırdan); vücut çevreleri o satırınkidir. Kilo yoksa yağ oranını
///   taşıyan satır döner.
///
/// Sonuç yeniden eskiye sıralıdır (ham sorgularla aynı).
List<BodyMeasurement> dailyMeasurements(List<BodyMeasurement> rows) {
  final byDay = <DateTime, List<BodyMeasurement>>{};
  for (final r in rows) {
    if (r.hidden == true) continue;
    final day = DateTime(r.date.year, r.date.month, r.date.day);
    byDay.putIfAbsent(day, () => []).add(r);
  }
  final out = <BodyMeasurement>[];
  for (final dayRows in byDay.values) {
    final weight = _pick(dayRows, (r) => r.weightKg);
    final fat = _pick(dayRows, (r) => r.bodyFatPct);
    final base = weight ?? fat ?? _latest(dayRows);
    // Çevre ölçüleri: her alan için o günün en son ELLE girilmiş değeri —
    // kilo tartıdan, bel elle ayrı girildiyse ikisi de özette kalır (Codex P2).
    double? lastManual(double? Function(BodyMeasurement) f) {
      final m = [
        for (final r in dayRows)
          if (isManualMeasurement(r) && f(r) != null) r,
      ];
      return m.isEmpty ? f(base) : f(_latest(m));
    }

    out.add(
      base.copyWith(
        bodyFatPct: Value(fat?.bodyFatPct),
        waistCm: Value(lastManual((r) => r.waistCm)),
        chestCm: Value(lastManual((r) => r.chestCm)),
        armCm: Value(lastManual((r) => r.armCm)),
        hipCm: Value(lastManual((r) => r.hipCm)),
        neckCm: Value(lastManual((r) => r.neckCm)),
      ),
    );
  }
  out.sort((a, b) => b.date.compareTo(a.date));
  return out;
}

bool isManualMeasurement(BodyMeasurement r) =>
    r.source == null || r.source == 'manual';

BodyMeasurement? _pick(
  List<BodyMeasurement> rows,
  double? Function(BodyMeasurement) value,
) {
  final withValue = [
    for (final r in rows)
      if (value(r) != null) r,
  ];
  final manual = withValue.where(isManualMeasurement).toList();
  if (manual.isNotEmpty) return _latest(manual);
  if (withValue.isEmpty) return null;
  // Tartı: günün İLK ölçümü (ölçüm saati); eşitlikte cihazdan bağımsız uid.
  return withValue.reduce((a, b) {
    final c = a.date.compareTo(b.date);
    if (c != 0) return c < 0 ? a : b;
    return _uidOf(a).compareTo(_uidOf(b)) <= 0 ? a : b;
  });
}

/// "En son kaydedilen" (Codex P2): ölçüm saati değil KAYIT zamanı —
/// `changedAtMs` (ekleme/düzenlemede tetikleyici damgalar, milisaniye,
/// senkronla taşınır); yoksa `updatedAt`, o da yoksa ölçüm tarihi.
int _recordedMs(BodyMeasurement r) =>
    r.changedAtMs ?? (r.updatedAt ?? r.date).millisecondsSinceEpoch;

BodyMeasurement _latest(List<BodyMeasurement> rows) => rows.reduce((a, b) {
  final c = _recordedMs(a).compareTo(_recordedMs(b));
  if (c != 0) return c > 0 ? a : b;
  // Aynı milisaniye (pratikte yalnız aynı cihazda art arda kayıt): yerel
  // ekleme sırası — son eklenen kazanır.
  return a.id >= b.id ? a : b;
});

String _uidOf(BodyMeasurement r) => r.uid ?? r.id.toString().padLeft(12, '0');
