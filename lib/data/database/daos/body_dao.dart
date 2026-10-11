import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../../core/utils/daily_body.dart';
import '../tables/body_tables.dart';

part 'body_dao.g.dart';

@DriftAccessor(tables: [BodyMeasurements, ProgressPhotos])
class BodyDao extends DatabaseAccessor<AppDatabase> with _$BodyDaoMixin {
  BodyDao(super.db);

  // === Body Measurements ===
  Future<List<BodyMeasurement>> getAllMeasurements() => (select(
    bodyMeasurements,
  )..orderBy([(m) => OrderingTerm.desc(m.date)])).get();

  /// En son **kilosu dolu** ölçüm. Bilerek "en son ölçüm" değildir: ölçüm
  /// formu tek bir alanla kaydetmeye izin veriyor (yalnız bel çevresi gibi), o
  /// satırın `weightKg`'i NULL olur. Kiloyu o sorgudan okumak, dün girilen 87
  /// kg'ı "kilo yok" saydırıyordu — profil ve kalori hesapları çelişiyordu
  /// (dış inceleme 2026-09-15, #11).
  Future<BodyMeasurement?> getLatestWeight() =>
      (select(bodyMeasurements)
            ..where((m) => m.weightKg.isNotNull())
            ..orderBy([(m) => OrderingTerm.desc(m.date)])
            ..limit(1))
          .getSingleOrNull();

  /// [start, end) aralığındaki ölçümler — bitiş HARİÇ (CODE_REVIEW H-01).
  Future<List<BodyMeasurement>> getMeasurementsInRange(
    DateTime start,
    DateTime end,
  ) =>
      (select(bodyMeasurements)
            ..where(
              (m) =>
                  m.date.isBiggerOrEqualValue(start) &
                  m.date.isSmallerThanValue(end),
            )
            ..orderBy([(m) => OrderingTerm.asc(m.date)]))
          .get();

  // --- Günde tek değer (docs/40 W-4): HESAP yapan her yer bunları okur. ---
  // Ham sorgular (yukarıda) yalnız satır listesi gösteren ekran ve dışa
  // aktarma içindir — satır `id`'siyle silme/düzenleme oradadır.

  /// Tüm günler, gün başına tek satır (yeniden eskiye).
  Future<List<BodyMeasurement>> getDailyMeasurements() async =>
      dailyMeasurements(await getAllMeasurements());

  /// En son **kilosu dolu** gün — aynı gün elle giriş tartıyı geçer.
  Future<BodyMeasurement?> getDailyLatestWeight() async {
    for (final m in await getDailyMeasurements()) {
      if (m.weightKg != null) return m;
    }
    return null;
  }

  /// [start, end) aralığı, gün başına tek satır (eskiden yeniye).
  Future<List<BodyMeasurement>> getDailyMeasurementsInRange(
    DateTime start,
    DateTime end,
  ) async => dailyMeasurements(
    await getMeasurementsInRange(start, end),
  ).reversed.toList();

  /// Tartıdan gelen ölçümü içe alır (docs/40 W-2, W-6). Aynı `sourceRef`
  /// zaten varsa (gizlenmiş olsa bile) dokunmaz → tekrar okuma kopya üretmez,
  /// gizlenen geri gelmez. `uid` çağıranın türettiği kalıcı kimliktir.
  /// Dönen: eklendiyse `true`.
  Future<bool> importHealthMeasurement({
    required String uid,
    required String sourceRef,
    required DateTime date,
    double? weightKg,
    double? bodyFatPct,
    String? sourceApp,
    bool Function()? stillAllowed,
  }) => transaction(() async {
    // Kontrol ve yazma AYNI işlemde (Codex P1): hesap temizliği de bir işlem;
    // SQLite ikisini sıraya koyar. Dönem temizlikten ÖNCE artırıldığı için
    // temizlik başladıktan sonra hiçbir içe alma satır yazamaz.
    if (stillAllowed != null && !stillAllowed()) return false;
    final existing = await (select(
      bodyMeasurements,
    )..where((m) => m.sourceRef.equals(sourceRef) | m.uid.equals(uid))).get();
    if (existing.isNotEmpty) return false;
    await into(bodyMeasurements).insert(
      BodyMeasurementsCompanion.insert(
        date: date,
        weightKg: Value(weightKg),
        bodyFatPct: Value(bodyFatPct),
        uid: Value(uid),
        source: const Value('health'),
        sourceRef: Value(sourceRef),
        sourceApp: Value(sourceApp),
      ),
    );
    return true;
  });

  /// İçe alınan satır silinmez, gizlenir (W-6) — senkronlanır, yeniden
  /// içe alınmaz.
  Future<void> hideMeasurement(int id) =>
      (update(bodyMeasurements)..where((m) => m.id.equals(id))).write(
        const BodyMeasurementsCompanion(hidden: Value(true)),
      );

  /// Rıza geri alınınca "içe alınanları da sil" (docs/41 §3): içe alınan tüm
  /// satırlar silinir (senkron mezar taşıyla buluttan da gider).
  Future<int> deleteImportedMeasurements() =>
      (delete(bodyMeasurements)..where((m) => m.source.equals('health'))).go();

  Future<int> insertMeasurement(BodyMeasurementsCompanion entry) =>
      into(bodyMeasurements).insert(entry);

  Future<int> deleteMeasurement(int id) =>
      (delete(bodyMeasurements)..where((m) => m.id.equals(id))).go();

  // === Progress Photos ===
  Future<List<ProgressPhoto>> getAllPhotos() => (select(
    progressPhotos,
  )..orderBy([(p) => OrderingTerm.desc(p.date)])).get();

  Future<int> insertPhoto(ProgressPhotosCompanion entry) =>
      into(progressPhotos).insert(entry);

  Future<int> deletePhoto(int id) =>
      (delete(progressPhotos)..where((p) => p.id.equals(id))).go();
}
