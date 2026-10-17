import 'package:drift/drift.dart' show Value;
import 'package:fit_pack/core/utils/daily_body.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/health/body_import.dart';
import 'package:fit_pack/features/health/body_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

/// docs/40 — tartıdan kilo: W-2…W-7 ve günde tek değer (W-4/W-5).
class _FakeBody implements BodySource {
  _FakeBody(this.samples, {this.platform = 'ios'});
  final List<BodySample> samples;
  @override
  final String platform;
  int reads = 0;

  @override
  Future<bool> requestAccess() async => true;
  @override
  Future<List<BodySample>> read(DateTime start, DateTime end) async {
    reads++;
    return [
      for (final s in samples)
        if (!s.measuredAt.isBefore(start) && s.measuredAt.isBefore(end)) s,
    ];
  }
}

BodySample _kilo(
  String ref,
  DateTime t,
  double kg, {
  String src = 'com.withings.wiScaleNG',
  String name = 'Health Mate',
}) => BodySample(
  kind: BodySampleKind.weight,
  value: kg,
  measuredAt: t,
  ref: ref,
  sourceId: src,
  sourceName: name,
);

BodySample _yag(String ref, DateTime t, double v) => BodySample(
  kind: BodySampleKind.bodyFat,
  value: v,
  measuredAt: t,
  ref: ref,
  sourceId: 'com.withings.wiScaleNG',
  sourceName: 'Health Mate',
);

void main() {
  late AppDatabase db;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = newTestDatabase();
  });
  tearDown(() => db.close());

  final now = DateTime(2026, 10, 11, 20);
  final bugun7 = DateTime(2026, 10, 11, 7);

  Future<int> iceAl(BodySource s, {bool riza = true}) => importBodySamples(
    source: s,
    dao: db.bodyDao,
    consentGiven: riza,
    now: now,
  );

  // Kayıt zamanını (changed_at_ms) ekleme tetikleyicisi milisaniyeyle
  // damgalar; art arda iki elle giriş aynı milisaniyeye düşmesin diye kısa
  // bekleme (gerçekte iki elle giriş arasında saniyeler olur).
  Future<void> elle(DateTime t, {double? kg, double? fat, double? bel}) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await db.bodyDao.insertMeasurement(
      BodyMeasurementsCompanion.insert(
        date: t,
        weightKg: Value(kg),
        bodyFatPct: Value(fat),
        waistCm: Value(bel),
      ),
    );
  }

  group('W-7 rıza kapısı', () {
    test('rıza yoksa platform okunmaz, satır yazılmaz', () async {
      final src = _FakeBody([_kilo('a', bugun7, 80)]);
      expect(await iceAl(src, riza: false), 0);
      expect(src.reads, 0);
      expect(await db.bodyDao.getAllMeasurements(), isEmpty);
    });

    test('runBodyImport rızayı profilden okur; sürüm eskiyse okumaz', () async {
      final src = _FakeBody([_kilo('a', bugun7, 80)]);
      await db.userProfileDao.setHealthConsent(kHealthConsentVersion - 1);
      expect(
        await runBodyImport(
          profiles: db.userProfileDao,
          body: db.bodyDao,
          source: src,
        ),
        0,
      );
      await db.userProfileDao.setHealthConsent(kHealthConsentVersion);
      final p = await db.userProfileDao.getProfile();
      expect(p!.healthConsentAt, isNotNull, reason: 'rıza zamanı kayıtlı');
      // runBodyImport gerçek "şimdi"yi kullanır → örnek bugünün içinde olsun.
      final src2 = _FakeBody([
        _kilo('b', DateTime.now().subtract(const Duration(hours: 1)), 80),
      ]);
      expect(
        await runBodyImport(
          profiles: db.userProfileDao,
          body: db.bodyDao,
          source: src2,
        ),
        1,
      );
    });
  });

  group('W-2 / W-3 / W-5 içe alma', () {
    test(
      'aynı örnek iki kez → tek satır; uid kalıcı (iki cihaz aynı)',
      () async {
        final src = _FakeBody([_kilo('hk-1', bugun7, 80.4)]);
        expect(await iceAl(src), 1);
        expect(await iceAl(src), 0);
        final rows = await db.bodyDao.getAllMeasurements();
        expect(rows, hasLength(1));
        expect(rows.single.source, 'health');
        expect(rows.single.sourceApp, 'Health Mate');
        expect(rows.single.uid, bodySampleUid('ios', 'hk-1'));
        expect(bodySampleUid('ios', 'hk-1'), bodySampleUid('ios', 'hk-1'));
        expect(
          bodySampleUid('ios', 'hk-1'),
          isNot(bodySampleUid('android', 'hk-1')),
        );
      },
    );

    test("Fit Pack'in kendi yazdığı örnek geri okunmaz (yankı)", () async {
      final src = _FakeBody([
        _kilo(
          'own',
          bugun7,
          80,
          src: 'com.sametorhan.fitPack',
          name: 'Fit Pack',
        ),
      ]);
      expect(await iceAl(src), 0);
    });

    test(
      'yağ oranı: iOS kesri yüzdeye; Health Connect yüzdesi aynen',
      () async {
        expect(normalizeBodyFat(0.215), closeTo(21.5, 1e-9));
        expect(normalizeBodyFat(21.5), 21.5);
        await iceAl(_FakeBody([_yag('f-1', bugun7, 0.2)]));
        expect(
          (await db.bodyDao.getAllMeasurements()).single.bodyFatPct,
          closeTo(20, 1e-9),
        );
      },
    );

    test('pencere: iOS 90 gün, Android 30 gün', () async {
      final eski = DateTime(2026, 8, 1, 7); // ~71 gün önce
      expect(await iceAl(_FakeBody([_kilo('i', eski, 82)])), 1);
      expect(
        await iceAl(_FakeBody([_kilo('a', eski, 82)], platform: 'android')),
        0,
      );
    });
  });

  group('W-6 gizleme', () {
    test('gizlenen satır hesapta yok, yeniden içe alınmaz', () async {
      final src = _FakeBody([_kilo('hk-1', bugun7, 80)]);
      await iceAl(src);
      final row = (await db.bodyDao.getAllMeasurements()).single;
      await db.bodyDao.hideMeasurement(row.id);
      expect(await iceAl(src), 0);
      expect(await db.bodyDao.getDailyLatestWeight(), isNull);
    });

    test('rıza geri alınıp silinince yalnız içe alınanlar gider', () async {
      await elle(DateTime(2026, 10, 10), kg: 81);
      await iceAl(_FakeBody([_kilo('hk-1', bugun7, 80)]));
      await db.bodyDao.deleteImportedMeasurements();
      final kalan = await db.bodyDao.getAllMeasurements();
      expect(kalan.single.weightKg, 81);
    });
  });

  group('W-4 / W-5 günde tek değer', () {
    test('aynı gün elle + iki tartı → son elle giriş', () async {
      await iceAl(
        _FakeBody([
          _kilo('t1', bugun7, 80.0),
          _kilo('t2', DateTime(2026, 10, 11, 19), 81.2),
        ]),
      );
      await elle(DateTime(2026, 10, 11, 9), kg: 79.0);
      await elle(DateTime(2026, 10, 11, 9, 5), kg: 79.5); // düzeltme
      final gun = await db.bodyDao.getDailyMeasurements();
      expect(gun, hasLength(1));
      expect(gun.single.weightKg, 79.5);
    });

    test('elle giriş yoksa günün İLK tartı ölçümü', () async {
      await iceAl(
        _FakeBody([
          _kilo('t2', DateTime(2026, 10, 11, 19), 81.2),
          _kilo('t1', bugun7, 80.0),
        ]),
      );
      expect((await db.bodyDao.getDailyLatestWeight())!.weightKg, 80.0);
    });

    test('yalnız bel girilmiş elle satır tartıyı engellemez', () async {
      await elle(DateTime(2026, 10, 11, 9), bel: 88);
      await iceAl(_FakeBody([_kilo('t1', bugun7, 80.0)]));
      expect((await db.bodyDao.getDailyLatestWeight())!.weightKg, 80.0);
    });

    test('yağ oranı kilodan bağımsız seçilir', () async {
      await elle(DateTime(2026, 10, 11, 9), kg: 79.0);
      await iceAl(_FakeBody([_yag('f1', bugun7, 0.21)]));
      final g = (await db.bodyDao.getDailyMeasurements()).single;
      expect(g.weightKg, 79.0);
      expect(g.bodyFatPct, closeTo(21, 1e-9));
    });

    test('haftalık seri günde bir nokta; aralık eskiden yeniye', () async {
      await elle(DateTime(2026, 10, 5, 8), kg: 82);
      await elle(DateTime(2026, 10, 5, 21), kg: 83); // aynı gün
      await elle(DateTime(2026, 10, 8, 8), kg: 81);
      final r = await db.bodyDao.getDailyMeasurementsInRange(
        DateTime(2026, 10, 5),
        DateTime(2026, 10, 12),
      );
      expect(r.map((m) => m.weightKg), [83, 81]);
    });

    test('saf fonksiyon: gizlenen satır sayılmaz', () {
      final m = BodyMeasurement(
        id: 1,
        date: bugun7,
        weightKg: 80,
        source: 'health',
        hidden: true,
      );
      expect(dailyMeasurements([m]), isEmpty);
    });
  });

  group('Codex P1/P2 düzeltmeleri', () {
    test(
      'tarih sınırı: rıza geri alınıp silinince eski örnekler gelmez',
      () async {
        final floor = DateTime(2026, 10, 11, 12);
        final src = _FakeBody([
          _kilo('eski', bugun7, 80), // sınırdan önce
          _kilo('yeni', DateTime(2026, 10, 11, 18), 79.6),
        ]);
        final n = await importBodySamples(
          source: src,
          dao: db.bodyDao,
          consentGiven: true,
          now: now,
          floor: floor,
        );
        expect(n, 1);
        expect(
          (await db.bodyDao.getAllMeasurements()).single.sourceRef,
          'yeni',
        );
      },
    );

    test('okuma sürerken izin düşerse hiçbir satır yazılmaz', () async {
      final src = _FakeBody([_kilo('a', bugun7, 80), _kilo('b', bugun7, 81)]);
      final n = await importBodySamples(
        source: src,
        dao: db.bodyDao,
        consentGiven: true,
        now: now,
        stillAllowed: () async => false,
      );
      expect(n, 0);
      expect(await db.bodyDao.getAllMeasurements(), isEmpty);
    });

    test('tartıdan kilo + aynı gün elle bel → özette ikisi de var', () async {
      await iceAl(_FakeBody([_kilo('t1', bugun7, 80.0)]));
      await elle(DateTime(2026, 10, 11, 9), bel: 88);
      final g = (await db.bodyDao.getDailyMeasurements()).single;
      expect(g.weightKg, 80.0);
      expect(g.waistCm, 88);
    });

    test(
      'geri alma rızayı zamanla yazar (sunucu zamana göre ilerletir)',
      () async {
        await db.userProfileDao.setHealthConsent(kHealthConsentVersion);
        final t = DateTime(2026, 10, 12, 9);
        await db.userProfileDao.setHealthConsent(null, now: t);
        final p = await db.userProfileDao.getProfile();
        expect(p!.healthConsentVersion, isNull);
        expect(p.healthConsentAt, t);
      },
    );
  });

  test('hesap temizliği başladıysa (dönem değişti) içe alma yazmaz', () async {
    final n = await importBodySamples(
      source: _FakeBody([_kilo('a', bugun7, 80)]),
      dao: db.bodyDao,
      consentGiven: true,
      now: now,
      epochValid: () => false,
    );
    expect(n, 0);
    expect(await db.bodyDao.getAllMeasurements(), isEmpty);
  });
}
