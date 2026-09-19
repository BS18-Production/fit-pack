import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/database/daos/body_dao.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';
import '../../data/services/photo_storage.dart';

/// Fotoğraf açıları (docs/19 §2). Veritabanında İngilizce anahtar durur;
/// ekran çeviriyi l10n'dan alır.
const photoAngles = <String>['front', 'side', 'back'];

final photoStorageProvider =
    Provider<PhotoStorage>((ref) => PhotoStorage.appDocuments());

/// Fotoğraf klasörü — bir kez çözülür, kareler eşzamanlı yol kurar.
final photoDirProvider = FutureProvider<Directory>(
    (ref) => ref.watch(photoStorageProvider).rootDir());

/// Bütün fotoğraflar, yeniden eskiye. Reaktif (watchTables, H-05): ekleme ve
/// silme kendiliğinden yansır.
final progressPhotosProvider =
    StreamProvider.autoDispose<List<ProgressPhoto>>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(
      db, [db.progressPhotos], () => ref.read(bodyDaoProvider).getAllPhotos());
});

/// Fotoğraf ekleme/silme — satır ve dosya BİRLİKTE (docs/19 K-3).
class ProgressPhotoActions {
  final BodyDao dao;
  final PhotoStorage storage;

  ProgressPhotoActions(this.dao, this.storage);

  /// Görseli klasöre kopyalar, sonra satırı yazar. Satır yazılamazsa kopya
  /// geri silinir — yoksa kimsenin göremediği bir vücut fotoğrafı diskte
  /// kalırdı.
  Future<void> add(File source, DateTime date, String angle) async {
    final name = await storage.save(source, date, angle);
    try {
      await dao.insertPhoto(ProgressPhotosCompanion.insert(
        date: date,
        angle: angle,
        imagePath: name,
      ));
    } catch (_) {
      await storage.delete(name);
      rethrow;
    }
  }

  /// ÖNCE satır, SONRA dosya. Arada uygulama kapanırsa dosya yetim kalır ve
  /// [sweep] onu temizler. Ters sırada galeride dosyası olmayan kırık bir
  /// kare kalırdı.
  Future<void> remove(ProgressPhoto photo) async {
    await dao.deletePhoto(photo.id);
    await storage.delete(photo.imagePath);
  }

  /// Veritabanında karşılığı olmayan dosyaları siler (docs/19 K-3). Galeri
  /// her açıldığında çalışır — yerel ve ucuz.
  Future<int> sweep() async {
    final all = await dao.getAllPhotos();
    return storage.sweepOrphans({for (final p in all) p.imagePath});
  }
}

final progressPhotoActionsProvider = Provider<ProgressPhotoActions>((ref) =>
    ProgressPhotoActions(
        ref.watch(bodyDaoProvider), ref.watch(photoStorageProvider)));
