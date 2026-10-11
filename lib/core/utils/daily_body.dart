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
    final base = weight ?? fat;
    if (base == null) {
      // Yalnız çevre ölçüsü olan gün: en son elle satır aynen kalır.
      out.add(_latest(dayRows));
      continue;
    }
    out.add(
      fat == null || identical(fat, base)
          ? base
          : base.copyWith(bodyFatPct: Value(fat.bodyFatPct)),
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
  return withValue.reduce((a, b) {
    final c = a.date.compareTo(b.date);
    if (c != 0) return c < 0 ? a : b;
    return a.id <= b.id ? a : b;
  });
}

/// En son kaydedilen: önce ölçüm zamanı, eşitse yerel kayıt sırası (`id`).
BodyMeasurement _latest(List<BodyMeasurement> rows) => rows.reduce((a, b) {
  final c = a.date.compareTo(b.date);
  if (c != 0) return c > 0 ? a : b;
  return a.id >= b.id ? a : b;
});
