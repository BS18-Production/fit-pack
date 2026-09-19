import 'dart:io';

import 'package:fit_pack/data/services/photo_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// `PhotoStorage` (docs/19 §7 "bitti tanımı"): ad üretimi, yol çözümü,
/// silme, yetim süpürme. Gerçek dosya sistemi, geçici dizin.
void main() {
  late Directory tmp;
  late Directory kok;
  late PhotoStorage store;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('fitpack_photos');
    kok = Directory(p.join(tmp.path, 'progress_photos'));
    store = PhotoStorage(() async => kok);
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  File kaynak(String ad, [String icerik = 'jpeg']) =>
      File(p.join(tmp.path, ad))..writeAsStringSync(icerik);

  group('dosya adı', () {
    test('tarih + açı, iki nokta üst üste YOK', () {
      final ad = PhotoStorage.fileNameFor(
          DateTime(2026, 8, 2, 19, 30, 12, 345), 'front');
      expect(ad, '2026-08-02T19-30-12-345_front.jpg');
      expect(ad.contains(':'), isFalse);
    });

    test('güvensiz adlar reddedilir (klasör dışına çıkılamaz)', () {
      expect(PhotoStorage.isSafeName('a.jpg'), isTrue);
      for (final kotu in ['../etc/passwd', '/tmp/x.jpg', 'a/b.jpg', '..', '',
          r'a\b.jpg']) {
        expect(PhotoStorage.isSafeName(kotu), isFalse, reason: kotu);
      }
    });
  });

  test('kaydet: kopyalar, yalnız dosya ADI döner (mutlak yol değil — K-1)',
      () async {
    final src = kaynak('gecici.jpg', 'foto');
    final ad = await store.save(src, DateTime(2026, 9, 19, 8), 'side');

    expect(ad.contains('/'), isFalse, reason: 'veritabanına yalnız ad yazılır');
    final f = await store.resolve(ad);
    expect(await f.readAsString(), 'foto');
    expect(await src.exists(), isTrue, reason: 'kaynak taşınmaz, kopyalanır');
  });

  test('aynı an ve açıda iki kayıt birbirinin üstüne yazmaz', () async {
    final t = DateTime(2026, 9, 19, 8);
    final a = await store.save(kaynak('1.jpg', 'bir'), t, 'front');
    final b = await store.save(kaynak('2.jpg', 'iki'), t, 'front');
    expect(a, isNot(b));
    expect(await (await store.resolve(a)).readAsString(), 'bir');
    expect(await (await store.resolve(b)).readAsString(), 'iki');
  });

  test('yol çözümü kökle birleşir; güvensiz ad hata verir', () async {
    final f = await store.resolve('x.jpg');
    expect(f.path, p.join(kok.path, 'x.jpg'));
    expect(() => store.resolve('../x.jpg'), throwsArgumentError);
  });

  test('sil: dosya gider; olmayan dosya sessiz geçer (idempotent)', () async {
    final ad = await store.save(kaynak('s.jpg'), DateTime(2026, 9, 19), 'back');
    await store.delete(ad);
    expect(await (await store.resolve(ad)).exists(), isFalse);
    await store.delete(ad); // ikinci kez — hata yok
    await store.delete('../disarida.jpg'); // güvensiz — dokunulmaz
  });

  test('yetim süpürme: veritabanında olmayan dosyalar silinir', () async {
    final tut = await store.save(kaynak('a.jpg'), DateTime(2026, 9, 1), 'front');
    final yetim =
        await store.save(kaynak('b.jpg'), DateTime(2026, 9, 2), 'front');

    final silinen = await store.sweepOrphans({tut});

    expect(silinen, 1);
    expect(await (await store.resolve(tut)).exists(), isTrue);
    expect(await (await store.resolve(yetim)).exists(), isFalse,
        reason: 'silinmiş sanılan hassas görsel diskte yaşamamalı');
  });

  test('klasör hiç yoksa süpürme ve toplu silme sorunsuz', () async {
    expect(await store.sweepOrphans({}), 0);
    await store.deleteAll();
  });

  test('toplu silme klasörü boşaltır (hesap değişimi)', () async {
    await store.save(kaynak('a.jpg'), DateTime(2026, 9, 1), 'front');
    await store.deleteAll();
    expect(await kok.exists(), isFalse);
  });
}
