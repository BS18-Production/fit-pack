import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/feedback/feedback_service.dart';
import '../../core/feedback/rest_sound.dart';
import '../../core/notifications/notification_prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/fitpack_icon.dart';

/// Ses seçeneğinin görünen adı ve kısa tarifi (docs/45 §3).
String restSoundName(AppL10n l, RestSound s) => switch (s) {
      RestSound.digitalBeep => l.restSoundDigitalBeep,
      RestSound.classicBell => l.restSoundClassicBell,
      RestSound.boxingBell => l.restSoundBoxingBell,
      RestSound.softChime => l.restSoundSoftChime,
      RestSound.strongAlert => l.restSoundStrongAlert,
    };

String restSoundHint(AppL10n l, RestSound s) => switch (s) {
      RestSound.digitalBeep => l.restSoundDigitalBeepHint,
      RestSound.classicBell => l.restSoundClassicBellHint,
      RestSound.boxingBell => l.restSoundBoxingBellHint,
      RestSound.softChime => l.restSoundSoftChimeHint,
      RestSound.strongAlert => l.restSoundStrongAlertHint,
    };

/// Mola sesi seçimi: satıra dokunmak sesi seçer ve bir kez çalar; oynat
/// düğmesi yalnız dinletir. Seçim hemen kalıcı (tercih) — kapatınca kaybolmaz.
Future<void> showRestSoundPicker(BuildContext context) => showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _RestSoundSheet(),
    );

class _RestSoundSheet extends ConsumerStatefulWidget {
  const _RestSoundSheet();

  @override
  ConsumerState<_RestSoundSheet> createState() => _RestSoundSheetState();
}

class _RestSoundSheetState extends ConsumerState<_RestSoundSheet> {
  late final FeedbackService _feedback = ref.read(feedbackServiceProvider);
  RestSound? _playing;

  @override
  void dispose() {
    _feedback.stopPreview();
    super.dispose();
  }

  void _play(RestSound s) {
    setState(() => _playing = s);
    _feedback.preview(s);
  }

  Future<void> _select(RestSound s) async {
    final notifier = ref.read(notificationPrefsProvider.notifier);
    await notifier.update(ref.read(notificationPrefsProvider).copyWith(restSound: s));
    _play(s);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final selected = ref.watch(notificationPrefsProvider).restSound;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.restSoundTitle, style: context.texts.titleLarge),
            AppSpacing.vGapXs,
            Text(l.restSoundSheetSub,
                style: context.texts.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
            AppSpacing.vGapMd,
            RadioGroup<RestSound>(
              groupValue: selected,
              onChanged: (s) {
                if (s != null) _select(s);
              },
              child: Column(
                children: [
                  for (final s in RestSound.values)
                    ListTile(
                      key: ValueKey('restSound.${s.id}'),
                      contentPadding: EdgeInsets.zero,
                      leading: Radio<RestSound>(value: s),
                      title: Text(restSoundName(l, s)),
                      subtitle: Text(restSoundHint(l, s)),
                      onTap: () => _select(s),
                      trailing: IconButton(
                        key: ValueKey('restSound.play.${s.id}'),
                        tooltip: l.restSoundPreview,
                        icon: FitPackIcon.material(
                          _playing == s
                              ? Icons.graphic_eq_rounded
                              : Icons.play_circle_outline_rounded,
                          color: context.colors.primary,
                        ),
                        onPressed: () => _play(s),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
