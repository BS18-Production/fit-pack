import 'package:flutter/widgets.dart';

/// Tasarım token'ları — boşluk, köşe yarıçapı, ikon boyutu, süre.
///
/// KURAL: Ekranlarda çıplak sayı (padding: 16, radius: 12) KULLANILMAZ.
/// 8pt tabanlı ölçek; ritim tutarlı olsun.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // Hazır EdgeInsets'ler (en sık kullanılanlar)
  static const EdgeInsets screen = EdgeInsets.all(lg);
  static const EdgeInsets card = EdgeInsets.all(lg);
  static const EdgeInsets cardCompact = EdgeInsets.all(md);

  // Dikey boşluk widget'ları
  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);
  static const SizedBox vGapXs = SizedBox(height: xs);
  static const SizedBox vGapSm = SizedBox(height: sm);
  static const SizedBox vGapMd = SizedBox(height: md);
  static const SizedBox vGapLg = SizedBox(height: lg);
  static const SizedBox vGapXl = SizedBox(height: xl);
  // Bloklar arası nefes (Apple Fitness ferahlığı — tasarımda ~26px).
  static const SizedBox vGapxl_ = SizedBox(height: 26);
  static const SizedBox hGapXs = SizedBox(width: xs);
  static const SizedBox hGapSm = SizedBox(width: sm);
  static const SizedBox hGapMd = SizedBox(width: md);
  static const SizedBox hGapLg = SizedBox(width: lg);
  static const SizedBox hGapXl = SizedBox(width: xl);
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;

  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brPill = BorderRadius.all(Radius.circular(pill));
}

class AppIconSize {
  AppIconSize._();

  static const double sm = 18;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 48;
  static const double xxl = 64;
}

class AppDuration {
  AppDuration._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}

/// Erişilebilirlik: minimum dokunma hedefi (Material/WCAG → 48dp).
class AppA11y {
  AppA11y._();
  static const double minTapTarget = 48;
}

/// Kaydırma içeriği için güvenli alt boşluk.
///
/// Sekme ekranlarında içerik buzlu gezinme çubuğunun ALTINDAN akar
/// (AppShell `extendBody: true`) → scroll sonunda son kart çubuğun altında
/// kaybolmasın diye ListView `padding.bottom`'ı bu değeri kullanır:
/// çubuk yüksekliği (MediaQuery.padding.bottom'a yansır) + nefes payı.
extension AppInsetsX on BuildContext {
  double get bottomScrollInset =>
      MediaQuery.paddingOf(this).bottom + AppSpacing.xl;

  /// Yüzen işlem düğmesi (FAB) olan sekmelerde liste sonu boşluğu (C-2):
  /// çubuk + nefes + FAB payı — son kart düğmenin altında kalmasın.
  double get fabScrollInset => bottomScrollInset + AppFab.clearance;

  /// Alt panel (bottom sheet) içeriğinin alt boşluğu: klavye açıksa klavye,
  /// kapalıysa cihazın alt güvenli alanı (iPhone ana ekran çizgisi). Panel
  /// kök navigator'da açıldığı için alt çubuk payı gerekmez (C-1).
  double get sheetBottomInset {
    final mq = MediaQuery.of(this);
    final keyboard = mq.viewInsets.bottom;
    return keyboard > 0 ? keyboard : mq.viewPadding.bottom;
  }
}

/// Genişletilmiş FAB (56) + üstünde bırakılan nefes.
class AppFab {
  AppFab._();
  static const double clearance = 80;
}
