import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/fitpack_icon.dart';
import 'nutrition_screen.dart' show selectedDateProvider;

/// Seçili günün "kaydım tamamlandı" durumu (docs/37 §1).
typedef DayCompletion = ({bool complete, bool changedAfter});

/// Reaktif: gün işaretlenince ya da o güne kayıt eklenince/değişince yeniden
/// hesaplanır (gün tablosu + öğün kayıtları izlenir; elle invalidate gerekmez).
final dayCompletionProvider = StreamProvider<DayCompletion>((ref) {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedDateProvider);
  final dao = ref.read(nutritionDaoProvider);
  return watchTables(db, [db.nutritionDays, db.foodLogs], () async {
    final row = await (db.select(db.nutritionDays)
          ..where((n) => n.day.equals(_key(date))))
        .getSingleOrNull();
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

/// Beslenme günlüğünün altında tek satır: "Bugünün tüm öğünlerini girdim"
/// (docs/37; sunum docs/45 §6).
///
/// **Ne işe yarar.** Uygulama "hiç yenmedi" ile "girilmedi"yi ayıramaz.
/// İşaretli gün haftalık değerlendirmede ve asistanın protein sorusunda
/// "bilinen gün" sayılır; işaretsiz gün bilinmiyor kalır (eksik sayılmaz).
/// Eski sunum ("Kaydın tamam" kutusu + ayrı düğme + uzun not) bu amacı
/// anlatmıyordu (Samet, 2026-10-11) — artık tek, kendini anlatan onay
/// satırı; iki durumda da aynı yükseklik (sayfa zıplamaz).
class DayCompleteCard extends ConsumerWidget {
  const DayCompleteCard({super.key, required this.date, required this.isToday});

  final DateTime date;
  final bool isToday;

  /// İşaretle / geri aç. Yazma başarısızsa durum değişmez; kullanıcıya kısa
  /// mesaj, gerçek hata loga (CR-019).
  static Future<void> _write(
      BuildContext context, Future<void> Function() write) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppL10n.of(context).commonSaveFailed;
    final errorColor = context.colors.error;
    try {
      await write();
    } catch (e) {
      debugPrint('[fitpack.nutrition] gün durumu yazılamadı | HATA: $e');
      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: errorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final state = ref.watch(dayCompletionProvider);
    final dao = ref.read(nutritionDaoProvider);
    final s = state.valueOrNull;
    if (s == null) return const SizedBox.shrink();
    final c = context.colors;
    final done = s.complete;

    final title = done
        ? l.nutritionDayCompleted
        : (isToday ? l.nutritionDayCompleteToday : l.nutritionDayCompletePast);
    final subtitle = done
        ? (s.changedAfter
            ? l.nutritionDayChangedAfter
            : l.nutritionDayCompletedSub)
        : l.nutritionDayCompleteHint;

    return Material(
      key: ValueKey(done ? 'nutrition.dayCompleted' : 'nutrition.dayComplete'),
      color: done ? c.secondaryContainer : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brControl,
        side: done ? BorderSide.none : BorderSide(color: c.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // İşaretsizken satırın tamamı onay düğmesi; işaretliyken geri alma
        // ayrı düğmede (yanlışlıkla kaldırılmasın).
        onTap: done
            ? null
            : () => _write(context, () => dao.markDayComplete(date)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              FitPackIcon.material(
                done
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: done ? c.secondary : c.onSurfaceVariant,
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.texts.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: context.texts.bodySmall
                          ?.copyWith(color: c.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (done)
                TextButton(
                  key: const ValueKey('nutrition.dayReopen'),
                  onPressed: () => _write(context, () => dao.reopenDay(date)),
                  child: Text(l.nutritionDayReopen),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
