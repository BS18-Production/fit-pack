import 'dart:async';

import 'package:drift/drift.dart';

import 'database/app_database.dart';

/// Reaktif okuma katmanı (H-05 — docs/17 iyileştirme analizi).
///
/// **Sorun:** okuma provider'ları `FutureProvider`'dı; veri değişince kendiliğinden
/// tazelenmezdi, her yazma noktasının ilgili provider'ı elle `invalidate` etmesi
/// gerekirdi (74 çağrı). Bir tanesi unutulunca ekran eski veriyi gösterirdi —
/// momentum bug'ının (H-05) kök nedeni buydu.
///
/// **Çözüm:** bu yardımcı, mevcut bir DAO `Future`'ını, dokunduğu tablolar her
/// değiştiğinde yeniden çalışan bir `Stream`'e çevirir. Provider'lar
/// `StreamProvider` olur; tüketici ekranlar değişmez (ikisi de `AsyncValue<T>`).
/// Yazma → Drift `tableUpdates` → stream tazelenir. Elle invalidate gerekmez.
///
/// İlk değeri **hemen** yayınlar (yoksa ekran ilk karede boş kalırdı), sonra
/// yalnız [tables]'daki bir tablo değişince yeniden okur.
///
/// **Önce abone olur, sonra okur** (CR-008): ilk okuma sürerken gelen yazma
/// kaçmaz — okuma bitince bir kez daha okunur. Okuma sürerken gelen birden
/// çok değişiklik tek bir yeniden okumada birleşir; okumalar üst üste binmez.
/// Okuma hatası stream'i kapatmaz, sıradaki değişiklik yeniden dener.
///
/// > Not: Drift, DAO yazmalarını (`into/update/delete`) ve `select().watch()`'ı
/// > izler; ham `customStatement` yazmalarını izlemez. Pull katmanı ham SQL
/// > yazdığı için değişen tabloları `notifyUpdates` ile kendisi bildirir
/// > (docs/20 §6.3).
Stream<T> watchTables<T>(
  AppDatabase db,
  List<ResultSetImplementation<dynamic, dynamic>> tables,
  Future<T> Function() read,
) {
  late final StreamController<T> controller;
  StreamSubscription<Set<TableUpdate>>? updates;
  var reading = false;
  var dirty = false;
  var cancelled = false;

  Future<void> refresh() async {
    if (reading) {
      dirty = true;
      return;
    }
    reading = true;
    try {
      do {
        dirty = false;
        try {
          final value = await read();
          if (!cancelled) controller.add(value);
        } catch (e, st) {
          if (!cancelled) controller.addError(e, st);
        }
      } while (dirty && !cancelled);
    } finally {
      reading = false;
    }
  }

  controller = StreamController<T>(
    onListen: () {
      updates = db
          .tableUpdates(TableUpdateQuery.onAllTables(tables))
          .listen((_) => refresh());
      refresh();
    },
    onCancel: () {
      cancelled = true;
      return updates?.cancel();
    },
  );
  return controller.stream;
}
