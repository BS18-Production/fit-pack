import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_prefs.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/providers.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/fitpack_icon.dart';

/// İlk antrenman bitti mi (öneri yalnız o anda gösterilir — docs/51 karar 4).
final _isFirstWorkoutProvider = FutureProvider.autoDispose<bool>(
    (ref) async => await ref.read(workoutDaoProvider).getSessionCount() == 1);

/// **"Sıradaki antrenmanını hatırlatayım mı?"** — antrenman özetinde, İLK
/// antrenmandan sonra bir kez (docs/51 karar 4). İzin kurulumda ya da ilk
/// açılışta istenmez: iOS izni bir kez sorar, "hayır" denirse uygulama tekrar
/// soramaz. Sistem izni yalnız "Evet" denince istenir.
///
/// Mola bildirimi için izin zaten alındıysa soru sorulmaz: hatırlatıcı açılır,
/// kullanıcıya bilgi verilir (docs/51 "İzin zamanı").
///
/// [onboarding]: kurulumun son sayfasında da bir kez sorulur (Samet,
/// 2026-10-18) — yoksa ilk hafta hatırlatması izin gelmeden zamanı geçer.
/// Orada "ilk antrenman" koşulu aranmaz; cevap (evet/hayır) ortak
/// `recallPrompted` bayrağına yazılır, soru özet ekranında tekrar çıkmaz.
class RecallOffer extends ConsumerStatefulWidget {
  const RecallOffer({super.key, this.onboarding = false});

  final bool onboarding;

  @override
  ConsumerState<RecallOffer> createState() => _RecallOfferState();
}

class _RecallOfferState extends ConsumerState<RecallOffer> {
  bool _busy = false;
  bool _closed = false;
  bool _autoTried = false;

  Future<void> _answer(bool yes) async {
    final l = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(notificationPrefsProvider.notifier);
    setState(() => _busy = true);
    try {
      await notifier.update(
          ref.read(notificationPrefsProvider).copyWith(recallPrompted: true));
      if (!yes) return;
      final prefs = ref.read(notificationPrefsProvider);
      if (!prefs.restEnabled) {
        final ok =
            await ref.read(notificationServiceProvider).requestPermission();
        if (!ok) {
          messenger.showSnackBar(
              SnackBar(content: Text(l.notifPermissionDenied)));
          return;
        }
      }
      // Kurulum uygulama kökündeki tercih dinleyicisinde (app.dart).
      await notifier.update(
          ref.read(notificationPrefsProvider).copyWith(workoutEnabled: true));
      messenger.showSnackBar(SnackBar(content: Text(l.recallOfferEnabled)));
    } catch (e) {
      debugPrint('[fitpack.recall] hatırlatıcı açılamadı | HATA: $e');
      messenger.showSnackBar(SnackBar(content: Text(l.commonSaveFailed)));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _closed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(notificationPrefsProvider);
    final first = widget.onboarding ||
        (ref.watch(_isFirstWorkoutProvider).valueOrNull ?? false);
    if (_closed || !first || !prefs.shouldOfferRecall) {
      return const SizedBox.shrink();
    }
    // İzin zaten var (mola bildirimi açık) → sormadan aç, bilgi ver.
    if (prefs.restEnabled) {
      if (!_autoTried) {
        _autoTried = true;
        WidgetsBinding.instance
            .addPostFrameCallback((_) => mounted ? _answer(true) : null);
      }
      return const SizedBox.shrink();
    }
    final l = AppL10n.of(context);
    return Card(
      key: const ValueKey('recall.offer'),
      margin: const EdgeInsets.only(top: AppSpacing.xl),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: .16),
                    borderRadius: AppRadius.brMd,
                  ),
                  child: FitPackIcon.material(
                      Icons.notifications_active_rounded,
                      size: 20,
                      color: context.colors.primary),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Text(
                      widget.onboarding
                          ? l.recallOfferOnbTitle
                          : l.recallOfferTitle,
                      style: context.texts.titleSmall),
                ),
              ],
            ),
            AppSpacing.vGapSm,
            Text(widget.onboarding ? l.recallOfferOnbBody : l.recallOfferBody,
                style: context.texts.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
            AppSpacing.vGapMd,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: const ValueKey('recall.no'),
                  onPressed: _busy ? null : () => _answer(false),
                  child: Text(l.recallOfferNo),
                ),
                AppSpacing.hGapSm,
                FilledButton(
                  key: const ValueKey('recall.yes'),
                  onPressed: _busy ? null : () => _answer(true),
                  child: Text(l.recallOfferYes),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
