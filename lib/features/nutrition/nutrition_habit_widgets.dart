import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/providers.dart';
import '../../l10n/app_l10n.dart';
import '../settings/notifications_screen.dart' show setMealReminders;
import 'meal_types.dart';
import 'nutrition_habit_providers.dart';
import 'nutrition_habits.dart';

String _usualTitle(AppL10n l, String meal) => switch (meal) {
      'breakfast' => l.nhUsualBreakfast,
      'lunch' => l.nhUsualLunch,
      'dinner' => l.nhUsualDinner,
      _ => l.nhUsualSnack,
    };

/// **"Her zamanki öğün" — tek dokunuş** (docs/26). Son 14 günde en az 2 kez
/// aynı içerikle girilmiş öğünü, saatine uygun olarak önerir. Öneri yoksa
/// ya da o öğün bugün girildiyse hiç yer kaplamaz.
///
/// Eklemek bir kullanıcı eylemi (onay) — kendiliğinden kayıt YOK. "Geri al"
/// tam eklenen satırları siler.
class UsualMealCard extends ConsumerStatefulWidget {
  const UsualMealCard({super.key});

  @override
  ConsumerState<UsualMealCard> createState() => _UsualMealCardState();
}

class _UsualMealCardState extends ConsumerState<UsualMealCard> {
  bool _busy = false;

  Future<void> _add(UsualMeal u) async {
    if (_busy) return;
    setState(() => _busy = true);
    // SnackBar ekrandan uzun yaşar (M-06): DAO ve messenger önceden alınır.
    final dao = ref.read(nutritionDaoProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l = AppL10n.of(context);
    try {
      final ids = await dao.addFoodsToMealIds(
          DateTime.now(), u.mealType, u.copyItems);
      HapticFeedback.lightImpact();
      messenger.clearSnackBars();
      messenger.showSnackBar(SnackBar(
        content: Text(l.nhUsualAdded(mealName(l, u.mealType))),
        persist: false, // düğmeli SnackBar varsayılanda kapanmıyor (3.41)
        action: SnackBarAction(
          label: l.commonUndo,
          onPressed: () => dao.deleteFoodLogs(ids),
        ),
      ));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.nutritionAddFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _later(UsualMeal u) {
    final now = DateTime.now();
    final key = usualMealDismissKey(
        DateTime(now.year, now.month, now.day), u.mealType);
    ref.read(usualMealDismissedProvider.notifier).update((s) => {...s, key});
  }

  @override
  Widget build(BuildContext context) {
    final u = ref.watch(usualMealProvider).valueOrNull;
    if (u == null) return const SizedBox.shrink();
    final l = AppL10n.of(context);
    final c = context.colors;
    final names = u.items.map((i) => i.food.name).join(', ');
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
      decoration: BoxDecoration(
        color: c.secondary.withValues(alpha: 0.10),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: c.secondary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: c.secondary.withValues(alpha: 0.16),
                  borderRadius: AppRadius.brSm,
                ),
                child: Icon(mealIcon(u.mealType),
                    size: AppIconSize.sm, color: c.secondary),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_usualTitle(l, u.mealType),
                        style: context.texts.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(names,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodySmall),
                    Text(
                        l.nhUsualSub(u.items.length, u.kcal.round(),
                            u.protein.round()),
                        style: context.texts.bodySmall
                            ?.copyWith(color: c.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _busy ? null : () => _later(u),
                child: Text(l.nhUsualLater),
              ),
              AppSpacing.hGapXs,
              FilledButton.icon(
                onPressed: _busy ? null : () => _add(u),
                style: FilledButton.styleFrom(
                  backgroundColor: c.secondary,
                  foregroundColor: c.onSecondary,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.add_rounded, size: AppIconSize.sm),
                label: Text(l.nhUsualAdd),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Haftalık kayıt hedefi satırı: "Bu hafta 3/5 gün kayıt · 2 gün daha".
/// Günlük seri değil — boş gün kopma sayılmaz (docs/26).
class LogWeekLineText extends ConsumerWidget {
  const LogWeekLineText({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = ref.watch(logWeekProvider).valueOrNull;
    if (w == null) return const SizedBox.shrink();
    final l = AppL10n.of(context);
    final c = context.colors;
    final text = switch (w.line) {
      LogWeekLine.start => l.nhWeekStart(w.goal),
      LogWeekLine.going => l.nhWeekGoing(w.done, w.goal, w.left),
      LogWeekLine.lastOne => l.nhWeekLastOne(w.done, w.goal),
      LogWeekLine.done => l.nhWeekDone(w.done, w.goal),
    };
    final done = w.line == LogWeekLine.done;
    final color = done ? context.semantic.success : c.onSurfaceVariant;
    return Row(
      children: [
        // Hedef kadar nokta: dolan günler dolu — tek bakışta ilerleme.
        for (var i = 0; i < w.goal; i++)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < w.done
                  ? (done ? context.semantic.success : c.secondary)
                  : c.onSurface.withValues(alpha: 0.12),
            ),
          ),
        AppSpacing.hGapSm,
        Expanded(
          child: Text(text,
              maxLines: 2,
              style: context.texts.bodySmall?.copyWith(
                  color: color,
                  fontWeight: done ? FontWeight.w700 : FontWeight.w500)),
        ),
      ],
    );
  }
}

/// "Öğün hatırlatıcısını aç" önerisi — izni **bağlam içinde** ister (ekran
/// açılır açılmaz değil). Açılınca ya da kapatılınca bir daha görünmez.
class MealReminderCta extends ConsumerWidget {
  const MealReminderCta({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPrefsProvider);
    if (prefs.mealEnabled || prefs.mealCtaDismissed) {
      return const SizedBox.shrink();
    }
    final l = AppL10n.of(context);
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
      decoration: BoxDecoration(
        color: c.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: AppRadius.brLg,
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active_outlined,
              size: AppIconSize.sm, color: c.primary),
          AppSpacing.hGapSm,
          Expanded(
            child: Text(l.nhReminderCta, style: context.texts.bodySmall),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final on = await setMealReminders(context, ref, true);
              if (on) {
                messenger.showSnackBar(
                    SnackBar(content: Text(l.nhReminderEnabled)));
              }
            },
            child: Text(l.nhReminderEnable),
          ),
          IconButton(
            tooltip: l.commonClose,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded,
                size: AppIconSize.sm, color: c.onSurfaceVariant),
            onPressed: () => ref
                .read(notificationPrefsProvider.notifier)
                .update(prefs.copyWith(mealCtaDismissed: true)),
          ),
        ],
      ),
    );
  }
}
