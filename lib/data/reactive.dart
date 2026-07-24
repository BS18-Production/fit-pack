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
/// > Not: Drift, DAO yazmalarını (`into/update/delete`) ve `select().watch()`'ı
/// > izler; ham `customStatement` yazmalarını izlemez. Pull katmanı ham SQL
/// > kullandığı için orada tazeleme elle yapılır (auth_gate) — bu yardımcı
/// > normal uygulama yazmalarını kapsar.
Stream<T> watchTables<T>(
  AppDatabase db,
  List<ResultSetImplementation<dynamic, dynamic>> tables,
  Future<T> Function() read,
) async* {
  yield await read();
  yield* db
      .tableUpdates(TableUpdateQuery.onAllTables(tables))
      .asyncMap((_) => read());
}
