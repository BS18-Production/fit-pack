import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Sekme başına ilk-kullanım koçluğu (docs/15 §B — coach mark).
///
/// Kullanıcı bir ana sekmeye İLK kez girdiğinde, o ekranın birincil
/// aksiyonunun üstünde tek spotlight gösterilir: karartılmış arka plan,
/// hedef parlak, kısa metin + "Anladım". Ekran başına TEK ipucu, bir kez.
/// Paket yok — `OverlayEntry` + `CustomPaint` (~yüz satır, bağımlılık
/// şişirmemek için).
enum FirstRunHint { workout, nutrition, progress }

/// Görülen ipuçları. `shared_preferences` `hint_seen_<id>` anahtarlarında
/// kalıcı. Başlangıç durumu "hepsi görüldü"dür (yüklenene dek yanlış
/// pozitif ipucu flaşlamasın); `_load` gerçek durumu getirir.
class FirstRunHints extends Notifier<Set<FirstRunHint>> {
  static const _initKey = 'hints_initialized';
  static String _key(FirstRunHint h) => 'hint_seen_${h.name}';

  @override
  Set<FirstRunHint> build() {
    _load();
    return FirstRunHint.values.toSet();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = {
      for (final h in FirstRunHint.values)
        if (prefs.getBool(_key(h)) ?? false) h
    };
  }

  Future<void> markSeen(FirstRunHint h) async {
    state = {...state, h};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(h), true);
  }

  /// Doğrudan prefs'ten kontrol — `state`'e güvenmez. Provider tembel
  /// (lazy) olduğundan ilk `ref.read` anında `build()`ün güvenli "hepsi
  /// görüldü" varsayılanı döner ve asenkron `_load` henüz bitmemiş olur;
  /// bu yüzden gösterim kararı buradan verilir.
  Future<bool> isUnseen(FirstRunHint h) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_key(h)) ?? false);
  }

  /// Mevcut kullanıcı koruması (docs/15 §B): uygulama bu özellikle İLK kez
  /// açılırken kullanıcı zaten onboarded ise ipuçları peşinen "görüldü"
  /// yazılır — güncelleme sonrası deneyimli kullanıcıyı rahatsız etmez.
  /// Marker (`hints_initialized`) sayesinde idempotent: onboarding'i yeni
  /// bitirmiş kullanıcının ipuçları ikinci açılışta sıfırlanmaz.
  /// `main.dart` açılışta çağırır.
  static Future<void> initialize({required bool onboarded}) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_initKey) ?? false) return;
    if (onboarded) {
      for (final h in FirstRunHint.values) {
        await prefs.setBool(_key(h), true);
      }
    }
    await prefs.setBool(_initKey, true);
  }
}

final firstRunHintsProvider =
    NotifierProvider<FirstRunHints, Set<FirstRunHint>>(FirstRunHints.new);

/// Hedef widget'ı sarar; ipucu görülmemişse ekran yerleşince spotlight
/// overlay'i açar. Scrim'e ya da "Anladım"a dokunmak kapatır + kalıcı
/// işaretler. Ekrandan çıkılırsa overlay güvenle sökülür.
class CoachMark extends ConsumerStatefulWidget {
  final FirstRunHint hint;

  /// Mesaj build sırasında locale'e göre çözülür.
  final String Function(AppL10n l) message;
  final Widget child;

  const CoachMark({
    super.key,
    required this.hint,
    required this.message,
    required this.child,
  });

  @override
  ConsumerState<CoachMark> createState() => _CoachMarkState();
}

class _CoachMarkState extends ConsumerState<CoachMark> {
  OverlayEntry? _entry;
  Timer? _timer;
  bool _done = false; // bu oturumda gösterildi/kapatıldı — tekrar deneme

  @override
  void initState() {
    super.initState();
    // Ekran otursun + prefs yüklensin diye kısa gecikme. Tek atış: o anda
    // görülmüşse hiç açılmaz (yarış yok — prefs okuma milisaniyeler).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timer = Timer(const Duration(milliseconds: 700), _maybeShow);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  Future<void> _maybeShow() async {
    if (!mounted || _done || _entry != null) return;
    final unseen = await ref
        .read(firstRunHintsProvider.notifier)
        .isUnseen(widget.hint);
    if (!unseen || !mounted || _done || _entry != null) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize || box.size.isEmpty) {
      return;
    }
    final rect = box.localToGlobal(Offset.zero) & box.size;

    _entry = OverlayEntry(
      builder: (overlayCtx) => _CoachMarkOverlay(
        targetRect: rect,
        message: widget.message(AppL10n.of(overlayCtx)),
        onDismiss: _dismiss,
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  void _dismiss() {
    _done = true;
    _entry?.remove();
    _entry = null;
    ref.read(firstRunHintsProvider.notifier).markSeen(widget.hint);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _CoachMarkOverlay extends StatelessWidget {
  final Rect targetRect;
  final String message;
  final VoidCallback onDismiss;

  const _CoachMarkOverlay({
    required this.targetRect,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.colors;
    final screen = MediaQuery.sizeOf(context);
    // Balon, hedefin boş tarafına: hedef alt yarıdaysa üstüne, değilse altına.
    final targetInLowerHalf = targetRect.center.dy > screen.height * 0.55;

    final bubble = Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surfaceContainerHigh,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: c.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: context.texts.bodyMedium),
          AppSpacing.vGapMd,
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onDismiss,
              child: Text(l.hintGotIt),
            ),
          ),
        ],
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDismiss,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _SpotlightPainter(
                  hole: targetRect.inflate(6),
                  ringColor: c.primary,
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              top: targetInLowerHalf ? null : targetRect.bottom + 14,
              bottom: targetInLowerHalf
                  ? screen.height - targetRect.top + 14
                  : null,
              child: bubble,
            ),
          ],
        ),
      ),
    );
  }
}

/// Karartma + hedef deliği + vurgu halkası.
class _SpotlightPainter extends CustomPainter {
  final Rect hole;
  final Color ringColor;
  const _SpotlightPainter({required this.hole, required this.ringColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(hole, const Radius.circular(18));
    final scrim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(rrect),
    );
    canvas.drawPath(
        scrim, Paint()..color = Colors.black.withValues(alpha: 0.55));
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ringColor,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.hole != hole || old.ringColor != ringColor;
}
