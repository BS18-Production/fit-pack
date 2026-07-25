import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Hareketin form gösterimi — **iki kareli canlandırma** (docs/11 + içerik
/// zenginleştirme turu, 2026-07-25).
///
/// free-exercise-db her hareket için **iki kare** tutar: `0.jpg` başlangıç,
/// `1.jpg` bitiş pozisyonu (873/873 harekette ikisi de var). Uygulama uzun süre
/// yalnız `0.jpg`'yi gösterdi — yani hareketi anlatan iki kareden biri
/// kullanılmıyordu. İkisini dönüşümlü göstermek hareketi "canlandırır":
///
/// - **Ek lisans yok** — public domain, zaten kullandığımız kaynak
/// - **Ek maliyet yok** — satın alınan animasyon kütüphanesi gerekmiyor
/// - **Ek indirme** hareket başına tek görsel (~52 KB), o da yalnız açılınca
///
/// Kareler CDN'den gelir ve `cached_network_image` ile cihazda saklanır; ilk
/// görüntülemeden sonra tekrar indirilmez.
class ExerciseDemoImage extends StatefulWidget {
  /// Veritabanındaki `imagePath` — `assets/exercise_img/<Ad>/0.jpg` biçiminde.
  final String? imagePath;

  /// Görsel yüklenemezse gösterilecek yer tutucu ikon (ekipman ikonu).
  final IconData fallbackIcon;

  final double aspectRatio;

  const ExerciseDemoImage({
    super.key,
    required this.imagePath,
    required this.fallbackIcon,
    this.aspectRatio = 4 / 3,
  });

  /// `imagePath`'ten [frame] numaralı karenin CDN adresini üretir.
  /// free-exercise-db jsDelivr üzerinden servis edilir (public domain).
  /// Beklenen önek dışındaki yollar için `null` (kullanıcının eklediği özel
  /// hareketlerde imagePath boştur).
  static String? frameUrl(String? imagePath, int frame) {
    const prefix = 'assets/exercise_img/';
    if (imagePath == null || !imagePath.startsWith(prefix)) return null;
    final rel = imagePath.substring(prefix.length);
    final slash = rel.lastIndexOf('/');
    if (slash < 0) return null;
    final dir = rel.substring(0, slash);
    return 'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/$dir/$frame.jpg';
  }

  @override
  State<ExerciseDemoImage> createState() => _ExerciseDemoImageState();
}

class _ExerciseDemoImageState extends State<ExerciseDemoImage> {
  /// Kare süresi — pozisyonun okunmasına yetecek kadar uzun, hareket hissini
  /// kaybettirmeyecek kadar kısa.
  static const _hold = Duration(milliseconds: 1100);

  /// Geçiş KISA tutulur (emülatör doğrulaması, 2026-07-25). İki kare aynı
  /// kamera açısından çekildiği için arka plan sabittir, yalnız gövde değişir;
  /// uzun bir çapraz geçişte iki gövde üst üste binip **çift pozlama hayaleti**
  /// oluşuyordu (350 ms'de döngünün üçte biri hayaletli geçiyordu). Gerçek
  /// egzersiz GIF'leri de dissolve değil, sert kesme kullanır. 160 ms kesmenin
  /// sertliğini alır ama hayalet süresini göz fark etmeden geçecek kadar kısar.
  static const _fade = Duration(milliseconds: 160);

  Timer? _timer;
  bool _showEnd = false;

  /// Bitiş karesi indirilip önbelleğe alındı mı. Alınmadan döngü BAŞLAMAZ —
  /// yoksa kullanıcı boş/hata karesine geçiş görürdü.
  bool _endReady = false;
  bool _precacheStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precacheStarted) return;
    _precacheStarted = true;
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    final endUrl = ExerciseDemoImage.frameUrl(widget.imagePath, 1);
    if (endUrl == null) return;
    try {
      await precacheImage(CachedNetworkImageProvider(endUrl), context);
    } catch (_) {
      return; // bitiş karesi yok/inmedi → tek kare olarak kalır, hata gösterme
    }
    if (!mounted) return;
    setState(() => _endReady = true);
    _startLoop();
  }

  void _startLoop() {
    _timer?.cancel();
    _timer = Timer.periodic(_hold, (_) {
      if (!mounted) return;
      setState(() => _showEnd = !_showEnd);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _placeholder({required bool spinner}) => Container(
        color: context.colors.surfaceContainerHighest,
        child: Center(
          child: spinner
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(widget.fallbackIcon,
                  size: AppIconSize.xxl, color: context.colors.onSurfaceVariant),
        ),
      );

  Widget _frame(String url) => CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, _) => _placeholder(spinner: true),
        errorWidget: (_, _, _) => _placeholder(spinner: false),
      );

  @override
  Widget build(BuildContext context) {
    final startUrl = ExerciseDemoImage.frameUrl(widget.imagePath, 0);
    if (startUrl == null) return const SizedBox.shrink();
    final endUrl = ExerciseDemoImage.frameUrl(widget.imagePath, 1);

    // Erişilebilirlik: sistemde animasyon kapalıysa döngü çalışmaz, başlangıç
    // karesi sabit durur (hareket duyarlılığı olan kullanıcılar için).
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) _timer?.cancel();

    final animate = _endReady && endUrl != null && !reduceMotion;

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: ClipRRect(
        borderRadius: AppRadius.brLg,
        child: animate
            ? AnimatedCrossFade(
                duration: _fade,
                firstChild: _frame(startUrl),
                secondChild: _frame(endUrl),
                crossFadeState: _showEnd
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                // İki kare üst üste durur → geçişte yeniden yükleme/titreme yok.
                layoutBuilder: (top, topKey, bottom, bottomKey) => Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(key: bottomKey, child: bottom),
                    Positioned.fill(key: topKey, child: top),
                  ],
                ),
              )
            : _frame(startUrl),
      ),
    );
  }
}
