import 'dart:io' show Platform;

import 'package:health/health.dart';
import 'package:uuid/uuid.dart';

import '../../data/database/daos/body_dao.dart';

/// **Tartıdan kilo ve yağ oranı — içe aktarma** (docs/40).
///
/// Tek tek tartı markası yok: Withings, Renpho, Xiaomi, Eufy, Garmin… hepsi
/// ölçümü telefonun sağlık deposuna yazar; burada depo okunur (W-1). Satırlar
/// `body_measurements`'a `source = health` ile girer ve senkronlanır (Samet
/// kararı: bulutta). Açık rıza yoksa hiçbir şey okunmaz (W-7, docs/41).

/// Rıza metninin sürümü. Ekrandaki rıza metni değişince ARTIR: kayıtlı sürüm
/// eskiyse rıza yeniden istenir.
const kHealthConsentVersion = 1;

/// İlk okumada geçmiş (W-8). Android'de platform sınırı 30 gün — ek "geçmiş"
/// izni istenmez.
const kBodyImportDaysIos = 90;
const kBodyImportDaysAndroid = 30;

/// Fit Pack'in kendi paket kimlikleri — kendi yazdığımızı geri okumayız (W-3).
const _ownSourceIds = {'com.sametorhan.fitPack', 'com.sametorhan.fit_pack'};

enum BodySampleKind { weight, bodyFat }

/// Platformdan gelen tek ölçüm (birimleri normalize edilmiş).
class BodySample {
  final BodySampleKind kind;

  /// Kilo: kg. Yağ oranı: yüzde (0–100).
  final double value;
  final DateTime measuredAt;

  /// Platform örnek kimliği (HealthKit UUID / Health Connect kayıt kimliği).
  final String ref;
  final String sourceId;
  final String sourceName;

  const BodySample({
    required this.kind,
    required this.value,
    required this.measuredAt,
    required this.ref,
    required this.sourceId,
    required this.sourceName,
  });
}

abstract class BodySource {
  Future<bool> requestAccess();

  /// `[start, end)` aralığındaki kilo + yağ oranı örnekleri.
  Future<List<BodySample>> read(DateTime start, DateTime end);

  /// `ios` / `android` — kalıcı kimlik türetmede kullanılır (W-2).
  String get platform;
}

class HealthBodySource implements BodySource {
  HealthBodySource({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  static const _types = [
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
  ];

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  String get platform => Platform.isIOS ? 'ios' : 'android';

  @override
  Future<bool> requestAccess() async {
    await _ensureConfigured();
    try {
      return await _health.requestAuthorization(_types);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<BodySample>> read(DateTime start, DateTime end) async {
    await _ensureConfigured();
    final List<HealthDataPoint> points;
    try {
      points = await _health.getHealthDataFromTypes(
        types: _types,
        startTime: start,
        endTime: end,
      );
    } catch (_) {
      return const [];
    }
    return [
      for (final p in points)
        if (p.value is NumericHealthValue && p.uuid.isNotEmpty)
          BodySample(
            kind: p.type == HealthDataType.WEIGHT
                ? BodySampleKind.weight
                : BodySampleKind.bodyFat,
            value: (p.value as NumericHealthValue).numericValue.toDouble(),
            measuredAt: p.dateFrom,
            ref: p.uuid,
            sourceId: p.sourceId,
            sourceName: p.sourceName,
          ),
    ];
  }
}

/// Yağ oranını yüzdeye çevirir (W-5): HealthKit `HKUnit.percent()` 0–1 kesir
/// verir, Health Connect yüzde. 1'den küçük değer kesir sayılır (gerçek bir
/// %1'in altı yağ oranı yoktur).
double normalizeBodyFat(double v) => v <= 1.0 ? v * 100 : v;

/// Kalıcı satır kimliği (W-2): aynı örneği iki cihaz alırsa aynı `uid` →
/// sunucu üzerine yazar, kopya olmaz.
String bodySampleUid(String platform, String ref) =>
    const Uuid().v5(Namespace.url.value, 'fitpack:health:$platform:$ref');

/// Okuma + yazma. Dönen: yeni eklenen satır sayısı. Rıza yoksa 0 ve okuma yok.
///
/// [stillAllowed] platform okumasından SONRA ve her satırdan önce sorulur:
/// okuma sürerken rıza geri alındıysa ya da hesap değiştiyse (Codex P1)
/// hiçbir satır yazılmaz. [floor]: bu andan önce ölçülmüş örnekler alınmaz
/// (rıza geri alınıp silinenler yeniden gelmesin).
Future<int> importBodySamples({
  required BodySource source,
  required BodyDao dao,
  required bool consentGiven,
  required DateTime now,
  Future<bool> Function()? stillAllowed,
  bool Function()? epochValid,
  DateTime? floor,
}) async {
  if (!consentGiven) return 0;
  final days = source.platform == 'ios'
      ? kBodyImportDaysIos
      : kBodyImportDaysAndroid;
  var start = DateTime(now.year, now.month, now.day - days);
  if (floor != null && floor.isAfter(start)) start = floor;
  final samples = await source.read(start, now);
  var added = 0;
  for (final s in samples) {
    if (stillAllowed != null && !await stillAllowed()) break;
    if (floor != null && !s.measuredAt.isAfter(floor)) continue;
    if (_ownSourceIds.contains(s.sourceId)) continue; // W-3
    final isWeight = s.kind == BodySampleKind.weight;
    final value = isWeight ? s.value : normalizeBodyFat(s.value);
    if (value <= 0) continue;
    final ok = await dao.importHealthMeasurement(
      uid: bodySampleUid(source.platform, s.ref),
      sourceRef: s.ref,
      date: s.measuredAt,
      weightKg: isWeight ? value : null,
      bodyFatPct: isWeight ? null : value,
      sourceApp: s.sourceName.isEmpty ? null : s.sourceName,
      stillAllowed: epochValid,
    );
    if (ok) added++;
  }
  return added;
}
