import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/database/daos/nutrition_dao.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';

// Beslenme ekranlarının ortak durumu (CR-018). Önceden ekran dosyalarındaydı;
// ekranlar birbirini yalnız bu sağlayıcılar için içe aktarıyordu (dört dosyalı
// döngü). Burada UI yok — ekranlar buradan okur.

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// "Dünü kopyala" sürüyor mu. Düğme yalnız gün boşken görünür ve kopyalama
/// bitene kadar ekran tazelenmez → hızlı iki dokunuş iki kopya başlatabiliyordu
/// (dış inceleme 2026-09-15, #12). DAO tarafında da hedef kontrolü var; bu
/// bayrak kullanıcıya düğmeyi sönük gösterip ikinci dokunuşu hiç başlatmaz.
final copyDayBusyProvider = StateProvider<bool>((ref) => false);

/// Kayıtlar + yemek adı (join). **Reaktif** (H-05): öğün eklenince/silinince
/// kendiliğinden tazelenir. Seçili gün değişince provider yeniden kurulur.
final logsWithFoodProvider = StreamProvider<List<FoodLogWithFood>>((ref) {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedDateProvider);
  return watchTables(db, [
    db.foodLogs,
    db.foods,
  ], () => ref.read(nutritionDaoProvider).getLogsWithFoodForDate(date));
});

final nutritionTotalsProvider = StreamProvider<DailyNutrition>((ref) {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedDateProvider);
  return watchTables(db, [
    db.foodLogs,
    db.foods,
  ], () => ref.read(nutritionDaoProvider).getDailyTotals(date));
});

/// Besin veritabanı (P-1 + P-2, docs/07-nutrition-v2.md).
/// "Yemekler frontend'de değil" → buradan görünür/yönetilir: lokal SQLite
/// `foods` tablosu. Değerleri gör, custom yemekleri düzenle/sil.
/// **Reaktif** (H-05): yemek eklenince/düzenlenince/silinince tazelenir.
final allFoodsProvider = StreamProvider<List<Food>>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [
    db.foods,
  ], () => ref.read(nutritionDaoProvider).getAllFoods());
});

/// Seçili günün "kaydım tamamlandı" durumu (docs/37 §1).
typedef DayCompletion = ({bool complete, bool changedAfter});

/// Reaktif: gün işaretlenince ya da o güne kayıt eklenince/değişince yeniden
/// hesaplanır (gün tablosu + öğün kayıtları izlenir; elle invalidate gerekmez).
final dayCompletionProvider = StreamProvider<DayCompletion>((ref) {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedDateProvider);
  final dao = ref.read(nutritionDaoProvider);
  return watchTables(db, [db.nutritionDays, db.foodLogs], () async {
    final row = await (db.select(
      db.nutritionDays,
    )..where((n) => n.day.equals(_key(date)))).getSingleOrNull();
    final complete = row?.status == 'complete';
    return (
      complete: complete,
      changedAfter: complete && await dao.changedAfterComplete(date),
    );
  });
});

String _key(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
