import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// İlerleme fotoğraflarının **dosya** tarafı (docs/19 §3–§4).
///
/// Veritabanı bilmez, arayüz bilmez. Kök dizin parametre — böylece testler
/// geçici bir dizinle koşar; uygulama [PhotoStorage.appDocuments] kullanır.
///
/// **Kural K-1:** veritabanına yalnız DOSYA ADI yazılır, mutlak yol ASLA.
/// iOS'ta uygulama konteynerinin yolu her güncellemede değişir; mutlak yol
/// saklansaydı güncellemeden sonra bütün fotoğraflar kırılırdı. Tam yol her
/// okumada [resolve] ile çözülür.
///
/// **Gizlilik (§6):** dosyalar uygulama konteynerinde durur, cihaz galerisine
/// yazılmaz — galeriye yazmak onları bulut yedeğine ve öteki uygulamalara
/// açardı.
class PhotoStorage {
  final Future<Directory> Function() _root;

  PhotoStorage(this._root);

  /// `<uygulama belgeleri>/progress_photos/`.
  factory PhotoStorage.appDocuments() => PhotoStorage(() async {
        final docs = await getApplicationDocumentsDirectory();
        return Directory(p.join(docs.path, 'progress_photos'));
      });

  static const _uzanti = '.jpg';

  /// Dosya adı: `2026-08-02T19-30-12-345_front.jpg`. Milisaniye dahil —
  /// aynı saniyede iki fotoğraf birbirinin üstüne yazmasın. İki nokta üst
  /// üste yok (bazı dosya sistemleri kabul etmez).
  static String fileNameFor(DateTime taken, String angle) {
    String iki(int v) => v.toString().padLeft(2, '0');
    final d = taken;
    final ms = d.millisecond.toString().padLeft(3, '0');
    return '${d.year}-${iki(d.month)}-${iki(d.day)}'
        'T${iki(d.hour)}-${iki(d.minute)}-${iki(d.second)}-${ms}_$angle$_uzanti';
  }

  /// Dosya adı güvenli mi? Yalnız bu klasörün içindeki düz bir ad kabul
  /// edilir — `../` ya da `/` içeren bir değer (bozuk ya da kötü niyetli bir
  /// satır) klasör dışına çıkıp başka dosyaya dokunamasın.
  static bool isSafeName(String name) =>
      name.isNotEmpty &&
      !name.contains('/') &&
      !name.contains(r'\') &&
      name != '.' &&
      name != '..' &&
      p.basename(name) == name;

  Future<Directory> _dir() async {
    final d = await _root();
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// [source]'u fotoğraf klasörüne KOPYALAR ve dosya adını döndürür.
  ///
  /// Kopya — taşıma değil: seçici (kamera/galeri) geçici bir dosya verir; onu
  /// taşımak platforma göre başarısız olabilir, kopya her yerde çalışır.
  Future<String> save(File source, DateTime taken, String angle) async {
    final dir = await _dir();
    var name = fileNameFor(taken, angle);
    // Çok düşük olasılıklı çakışma: yine de üstüne yazma.
    var i = 1;
    while (await File(p.join(dir.path, name)).exists()) {
      name = fileNameFor(taken, angle).replaceFirst(_uzanti, '-$i$_uzanti');
      i++;
    }
    await source.copy(p.join(dir.path, name));
    return name;
  }

  /// Kök klasör (yoksa oluşturmadan). Galeri bunu bir kez çözüp her kare
  /// için eşzamanlı [fileIn] kullanır.
  Future<Directory> rootDir() => _root();

  /// [dir] içindeki dosya — eşzamanlı yol çözümü. Güvensiz ad → `null`.
  static File? fileIn(Directory dir, String name) =>
      isSafeName(name) ? File(p.join(dir.path, name)) : null;

  /// Dosya adından tam yolu çözer. Güvensiz ad → `ArgumentError`.
  Future<File> resolve(String name) async {
    if (!isSafeName(name)) {
      throw ArgumentError.value(name, 'name', 'güvensiz fotoğraf adı');
    }
    final dir = await _root();
    return File(p.join(dir.path, name));
  }

  /// Dosyayı siler; yoksa sessizce geçer (silme idempotent olmalı — satır
  /// silindikten sonra dosya silinemediyse süpürme onu yakalar).
  Future<void> delete(String name) async {
    if (!isSafeName(name)) return;
    final f = await resolve(name);
    if (await f.exists()) await f.delete();
  }

  /// Veritabanında karşılığı OLMAYAN dosyaları siler, sayısını döner.
  ///
  /// Yetim dosya iki yoldan doğar: satır silindi ama dosya silinemedi (uygulama
  /// arada kapandı), ya da dosya kopyalandı ama satır yazılamadı. İkisinde de
  /// dosya kullanıcıya görünmez ama diskte — ve silinmiş sanılan hassas bir
  /// görsel olarak — yaşamaya devam eder.
  Future<int> sweepOrphans(Set<String> known) async {
    final dir = await _root();
    if (!await dir.exists()) return 0;
    var n = 0;
    await for (final e in dir.list()) {
      if (e is! File) continue;
      if (known.contains(p.basename(e.path))) continue;
      await e.delete();
      n++;
    }
    return n;
  }

  /// Klasörü tamamen boşaltır (hesap değişimi — §6 kural 4).
  Future<void> deleteAll() async {
    final dir = await _root();
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
