import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

/// Senkron hatasının türü (docs/20 §9). Tür, hatanın **ne yapılacağını**
/// belirler — mesajın kendisi değil.
enum SyncErrorKind {
  /// Sunucuya ulaşılamıyor: ağ yok, DNS, TLS, 5xx, proje duraklatılmış.
  /// Artan beklemeyle yeniden denenir; uzarsa kullanıcı uyarılır.
  unreachable,

  /// Oturum düşmüş (401, süresi dolmuş belirteç). Tur atlanır, kuyruk bekler.
  noSession,

  /// **Kalıcı**: aynı satır kaç kez gönderilse aynı hatayı verir (yetki, RLS,
  /// tekillik). Satır kuyruktan ayrılır (`sync_state = 2`) — yoksa tek bozuk
  /// satır arkasındaki bütün kuyruğu sonsuza kadar kilitler.
  permanent,

  /// Onarılabilir (NOT NULL ihlali): gönderim öncesi onarım geçişleri bunu
  /// zaten düzeltiyor; yeniden denemek yeterli.
  repairable,

  /// Tanınmayan hata. **Geçici sayılır** ve yeniden denenir. Yanlışlıkla
  /// "kalıcı" demek satırı kuyruktan düşürür; yanlışlıkla "geçici" demek
  /// yalnız boşuna bir deneme daha yapar. Belirsizlikte ucuz olan tercih.
  transient,
}

/// Hatanın türünü belirler. Yalnız **emin olunan** kodlar kalıcı sayılır.
SyncErrorKind classifySyncError(Object error) {
  if (error is SocketException ||
      error is HandshakeException ||
      error is TimeoutException ||
      error is http.ClientException) {
    return SyncErrorKind.unreachable;
  }
  if (error is AuthException) return SyncErrorKind.noSession;

  if (error is PostgrestException) {
    final code = error.code ?? '';
    switch (code) {
      // Yetki / RLS ihlali — tekrar denemek sonucu değiştirmez.
      case '42501':
      case '403':
      // Tekillik — aynı veri aynı çakışmayı üretir.
      case '23505':
      case '409':
        return SyncErrorKind.permanent;
      case '23502':
        return SyncErrorKind.repairable;
      // PGRST301: JWT süresi dolmuş/geçersiz.
      case 'PGRST301':
      case '401':
        return SyncErrorKind.noSession;
    }
    final status = int.tryParse(code);
    if (status != null && status >= 500 && status <= 599) {
      return SyncErrorKind.unreachable;
    }
  }
  return SyncErrorKind.transient;
}
