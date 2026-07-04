import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Locale-duyarlı tarih/sayı biçimlendirme (docs/14).
///
/// Önceden kod her yerde `DateFormat(pattern, 'tr_TR')` ve
/// `NumberFormat.decimalPattern('tr_TR')` kullanıyordu → dil ne olursa olsun
/// Türkçe biçim. Artık aktif locale'e göre biçimlenir. `main.dart` hem `en`
/// hem `tr` tarih verisini yükler.
extension L10nFormatting on BuildContext {
  /// Aktif locale adı (`'en'` / `'tr'`) — intl API'lerine verilir.
  String get localeName => Localizations.localeOf(this).toString();

  /// Verilen [pattern] için aktif locale'de [DateFormat].
  DateFormat dateFmt(String pattern) => DateFormat(pattern, localeName);

  /// Aktif locale'de binlik ayraçlı sayı biçimi.
  NumberFormat get numFmt => NumberFormat.decimalPattern(localeName);
}
