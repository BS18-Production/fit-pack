import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/feedback/feedback_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/format.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/fitpack_icon.dart';

/// Süreli set sayacı (docs/27 F3) — ısınma, plank, kardiyo.
///
/// Hedef süre biliniyorsa (girilmiş değer ya da geçen seansın önerisi) geri
/// sayar ve sıfırda kendiliğinden durup hedef süreyi yazar; bilinmiyorsa
/// ileri sayar, durdurunca geçen süreyi yazar. Seti tamamlamaz — ✓ yine
/// kullanıcıda (öneri ekrana yazılır, set yapılmış sayılmaz kuralı).
///
/// Süre `DateTime` farkından hesaplanır, saat tıkı yalnız ekranı tazeler:
/// uygulama arka planda kalsa da dönüşte doğru süre görünür.
({int shown, bool finished}) timerReading(int? targetSec, int elapsedSec) {
  if (targetSec == null || targetSec <= 0) {
    return (shown: elapsedSec, finished: false);
  }
  final left = targetSec - elapsedSec;
  return (shown: left < 0 ? 0 : left, finished: left <= 0);
}

/// Durdurunca yazılacak süre: geri sayımda hedef aşıldıysa hedef, değilse
/// geçen süre; 0 sn yazılmaz (yanlışlıkla aç-kapa).
int? timerResult(int? targetSec, int elapsedSec) {
  if (targetSec != null && targetSec > 0 && elapsedSec >= targetSec) {
    return targetSec;
  }
  return elapsedSec > 0 ? elapsedSec : null;
}

class SetTimerButton extends ConsumerStatefulWidget {
  /// Geri sayım hedefi (sn); null → ileri sayım.
  final int? targetSec;
  final ValueChanged<int> onDone;

  /// Testlerde zamanı ilerletmek için.
  final DateTime Function() now;

  const SetTimerButton({
    super.key,
    required this.targetSec,
    required this.onDone,
    this.now = DateTime.now,
  });

  @override
  ConsumerState<SetTimerButton> createState() => _SetTimerButtonState();
}

class _SetTimerButtonState extends ConsumerState<SetTimerButton> {
  DateTime? _startedAt;
  int? _target; // başlarken sabitlenir — yazım sırasında hedef değişmesin
  Timer? _tick;

  bool get _running => _startedAt != null;

  int get _elapsed => _startedAt == null
      ? 0
      : widget.now().difference(_startedAt!).inSeconds;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _startedAt = widget.now();
      _target = widget.targetSec;
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    if (!mounted) return;
    if (timerReading(_target, _elapsed).finished) {
      ref.read(feedbackServiceProvider).restDone();
      _stop();
      return;
    }
    setState(() {});
  }

  void _stop() {
    final result = timerResult(_target, _elapsed);
    _tick?.cancel();
    _tick = null;
    setState(() => _startedAt = null);
    if (result != null) widget.onDone(result);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppL10n.of(context);
    if (!_running) {
      return IconButton(
        key: const ValueKey('set-timer-start'),
        tooltip: l.asTimerStart,
        visualDensity: VisualDensity.compact,
        icon: FitPackIcon.material(Icons.play_arrow_rounded, color: c.primary),
        onPressed: _start,
      );
    }
    final r = timerReading(_target, _elapsed);
    return Tooltip(
      message: l.asTimerStop,
      child: Material(
        color: c.primary.withValues(alpha: 0.14),
        borderRadius: AppRadius.brSm,
        child: InkWell(
          key: const ValueKey('set-timer-stop'),
          borderRadius: AppRadius.brSm,
          onTap: _stop,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FitPackIcon.material(Icons.stop_rounded, size: 16, color: c.primary),
                Text(fmtDuration(r.shown),
                    style: context.texts.labelSmall?.copyWith(
                        color: c.primary,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
