import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/formatting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/format.dart';
import '../../data/database/daos/nutrition_dao.dart';
import '../../data/providers.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/app_state_views.dart';
import 'meal_types.dart';

/// "Başka günden kopyala" (docs/21 #2 küçük sürüm): geçmiş bir günün AYNI
/// öğünü, miktarları düzenlenebilir bir listeyle bugünkü öğüne eklenir.
///
/// "Dünü kopyala"dan farkı: o, boş bir günün tamamını doldurur; bu, tek
/// öğüne **ekler** ve eklemeden önce her miktar değiştirilebilir/çıkarılabilir.

/// Geriye kaç gün bakılır. Tek yerde (§5) — hem sorgu hem "kayıt yok" metni
/// aynı sayıyı kullansın.
const int mealCopyWindowDays = 14;

/// Sorgu anahtarı: hangi öğün, hangi güne kopyalanıyor. Hedef gün listeden
/// düşer (kullanıcı zaten oraya kopyalıyor) — bu yüzden anahtarın parçası.
typedef MealCopyQuery = ({String mealType, DateTime targetDay});

/// Seçilebilecek geçmiş günler. `autoDispose`: panel kapanınca sorgu da düşer,
/// bir sonraki açılışta taze liste gelir (araya eklenen öğün görünsün).
final mealCopyDaysProvider =
    FutureProvider.autoDispose.family<List<MealDay>, MealCopyQuery>((ref, q) {
  return ref.watch(nutritionDaoProvider).getMealDays(
        q.mealType,
        exclude: q.targetDay,
        days: mealCopyWindowDays,
      );
});

/// Panelden dönen sonuç. `added` 0 ve `failed` false olamaz — düğme liste
/// boşken zaten pasif.
class MealCopyResult {
  final int added;
  final bool failed;
  const MealCopyResult({this.added = 0, this.failed = false});
}

/// Paneli açar ve sonucu bildiren SnackBar'ı gösterir. Messenger **çağıran
/// ekrandan** alınır (M-06): panel kapandıktan sonra kendi context'i ölür.
Future<void> showMealCopySheet(
  BuildContext context, {
  required String mealType,
  required DateTime targetDay,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l = AppL10n.of(context);
  final result = await showModalBottomSheet<MealCopyResult>(
    context: context,
    // Kök navigator (C-1): sekme navigator'ında açılan panel buzlu alt
    // çubuğun arkasında kalıyor.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.colors.surface,
    builder: (_) => MealCopySheet(mealType: mealType, targetDay: targetDay),
  );
  if (result == null) return; // kullanıcı kapattı — mesaj yok
  messenger.clearSnackBars();
  messenger.showSnackBar(SnackBar(
    content: Text(result.failed || result.added == 0
        ? l.nutritionCopyFailed
        : l.nutritionCopied(result.added)),
  ));
}

// ConsumerStatefulWidget (M-06): panel kendi ref'ini alır, üst ekranın
// ref'ini parametre olarak taşımaz.
class MealCopySheet extends ConsumerStatefulWidget {
  final String mealType;
  final DateTime targetDay;

  const MealCopySheet({
    super.key,
    required this.mealType,
    required this.targetDay,
  });

  @override
  ConsumerState<MealCopySheet> createState() => _MealCopySheetState();
}

class _MealCopySheetState extends ConsumerState<MealCopySheet> {
  /// Seçilen gün — null ise gün listesi (1. adım) gösterilir.
  MealDay? _picked;

  /// Satır başına düzenlenen gram (log id → gram). Kullanıcı değiştirebilir.
  final Map<int, double> _grams = {};

  /// Listeden çıkarılan satırlar (log id). Kaynak kayıtlara dokunulmaz.
  final Set<int> _removed = {};

  bool _saving = false;

  /// Gram alanları `TextFormField.initialValue` kullanır — controller yok,
  /// dolayısıyla dispose edilecek kaynak da yok (§8). Satırlar `ValueKey` ile
  /// anahtarlı (H-02): bir satır çıkarılınca kalan kutular kaymaz.
  void _pick(MealDay day) {
    setState(() {
      _picked = day;
      _grams
        ..clear()
        ..addEntries(day.items.map((i) => MapEntry(i.log.id, i.log.grams)));
      _removed.clear();
    });
  }

  List<FoodLogWithFood> get _kalanlar => [
        for (final i in _picked?.items ?? const <FoodLogWithFood>[])
          if (!_removed.contains(i.log.id)) i,
      ];

  /// Canlı toplam — kullanıcı gramı değiştirdikçe güncellenir. Kaydın hazır
  /// kalorisi değil, gramdan yeniden hesap (DAO da aynısını yapar).
  double get _toplamKcal => _kalanlar.fold<double>(
      0, (sum, i) => sum + i.food.kcalPer100g * (_grams[i.log.id] ?? 0) / 100);

  Future<void> _add() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final added = await ref.read(nutritionDaoProvider).addFoodsToMeal(
            widget.targetDay,
            widget.mealType,
            [
              for (final i in _kalanlar)
                MealCopyItem(
                    foodId: i.log.foodId, grams: _grams[i.log.id] ?? 0),
            ],
          );
      if (!mounted) return;
      // Kilit burada çözülmez, panel kapanıyor (§6'nın amacı "sonsuza dek
      // dönen düğme" — kapanan panelde düğme kalmıyor). Hata yolunda çözülür.
      Navigator.of(context).pop(MealCopyResult(added: added));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.of(context).pop(const MealCopyResult(failed: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final picked = _picked;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: EdgeInsets.only(
          bottom: context.sheetBottomInset,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
        ),
        child: Column(
          children: [
            SheetHeader(
              title: l.nutritionCopyMealTitle(mealName(l, widget.mealType)),
              subtitle: picked == null
                  ? l.nutritionCopyPickDay
                  : l.nutritionCopyEditHint,
            ),
            AppSpacing.vGapSm,
            Expanded(
              child: picked == null
                  ? _DayList(
                      mealType: widget.mealType,
                      targetDay: widget.targetDay,
                      scrollController: scrollController,
                      onPick: _pick,
                    )
                  : ListView(
                      controller: scrollController,
                      children: [
                        for (final item in _kalanlar)
                          _CopyItemRow(
                            key: ValueKey(item.log.id),
                            item: item,
                            grams: _grams[item.log.id] ?? 0,
                            onGrams: (g) =>
                                setState(() => _grams[item.log.id] = g),
                            onRemove: () =>
                                setState(() => _removed.add(item.log.id)),
                          ),
                      ],
                    ),
            ),
            if (picked != null) _footer(context, l),
          ],
        ),
      ),
    );
  }

  Widget _footer(BuildContext context, AppL10n l) {
    final kalan = _kalanlar.length;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      // İkonsuz düğmeler + esneyen toplam: dar telefonda (≈334 dp) üç öğe
      // yan yana sığsın, satır taşmasın.
      child: Row(
        children: [
          Expanded(
            child: Text('${_toplamKcal.round()} kcal',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.titleSmall?.copyWith(
                    color: context.semantic.macroCalories,
                    fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: _saving ? null : () => setState(() => _picked = null),
            child: Text(l.commonBack),
          ),
          AppSpacing.hGapSm,
          FilledButton(
            onPressed: kalan == 0 || _saving ? null : _add,
            child: Text(l.nutritionCopyAddCount(kalan)),
          ),
        ],
      ),
    );
  }
}

/// 1. adım — kopyalanacak günün seçimi.
class _DayList extends ConsumerWidget {
  final String mealType;
  final DateTime targetDay;
  final ScrollController scrollController;
  final void Function(MealDay) onPick;

  const _DayList({
    required this.mealType,
    required this.targetDay,
    required this.scrollController,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final query = (mealType: mealType, targetDay: targetDay);
    return ref.watch(mealCopyDaysProvider(query)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => ErrorState(
            message: l.nutritionLoadError,
            onRetry: () => ref.invalidate(mealCopyDaysProvider(query)),
          ),
          data: (days) => days.isEmpty
              ? EmptyState(
                  icon: mealIcon(mealType),
                  title: l.nutritionCopyNoHistory(mealCopyWindowDays),
                  compact: true,
                )
              : ListView.builder(
                  controller: scrollController,
                  itemCount: days.length,
                  itemBuilder: (context, i) => _DayTile(
                    key: ValueKey(days[i].day),
                    day: days[i],
                    onTap: () => onPick(days[i]),
                  ),
                ),
        );
  }
}

class _DayTile extends StatelessWidget {
  final MealDay day;
  final VoidCallback onTap;

  const _DayTile({super.key, required this.day, required this.onTap});

  /// "Bugün" / "Dün" / "Pazartesi · 15 Eylül" — tarih biçimi aktif locale'de
  /// (§5b: `'tr_TR'` sabiti yok).
  String _label(BuildContext context) {
    final l = AppL10n.of(context);
    final now = DateTime.now();
    if (DateUtils.isSameDay(day.day, now)) return l.commonToday;
    if (DateUtils.isSameDay(day.day, DateTime(now.year, now.month, now.day - 1))) {
      return l.commonYesterday;
    }
    return '${context.dateFmt('EEEE').format(day.day)} · '
        '${context.dateFmt('d MMMM').format(day.day)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        onTap: onTap,
        title: Text(_label(context), style: context.texts.titleSmall),
        subtitle: Text(
          day.items.map((i) => i.food.name).join(', '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.texts.bodySmall
              ?.copyWith(color: context.colors.onSurfaceVariant),
        ),
        trailing: Text('${day.totalKcal.round()} kcal',
            style: context.texts.labelMedium
                ?.copyWith(color: context.colors.onSurfaceVariant)),
      ),
    );
  }
}

/// 2. adım — eklenecek besin satırı: miktar değiştirilebilir, satır çıkarılır.
class _CopyItemRow extends StatelessWidget {
  final FoodLogWithFood item;
  final double grams;
  final ValueChanged<double> onGrams;
  final VoidCallback onRemove;

  const _CopyItemRow({
    super.key,
    required this.item,
    required this.grams,
    required this.onGrams,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final kcal = item.food.kcalPer100g * grams / 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.food.name,
                    style: context.texts.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                AppSpacing.vGapXs,
                Text('${kcal.round()} kcal',
                    style: context.texts.labelMedium?.copyWith(
                        color: context.colors.onSurfaceVariant)),
              ],
            ),
          ),
          AppSpacing.hGapSm,
          SizedBox(
            width: 92,
            child: TextFormField(
              initialValue: fmtNum(grams),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                suffixText: 'g',
                isDense: true,
              ),
              // Boş/geçersiz giriş 0 sayılır → satır DAO'da atlanır; kullanıcı
              // "0 g" yazarak da çıkarabilir, hata mesajına gerek yok.
              onChanged: (raw) => onGrams(
                  double.tryParse(raw.trim().replaceAll(',', '.')) ?? 0),
            ),
          ),
          IconButton(
            tooltip: l.nutritionCopyRemove,
            icon: const Icon(Icons.close_rounded),
            color: context.colors.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
