import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../../l10n/app_l10n.dart';

String authErrorLabel(AppL10n l, Object error) {
  if (error is! AuthException) return l.expAuthConnection;
  return switch (error.code) {
    'invalid_credentials' => l.expAuthCredentials,
    'email_not_confirmed' => l.expAuthUnconfirmed,
    'user_already_exists' || 'email_exists' => l.expAuthExists,
    'over_email_send_rate_limit' || 'over_request_rate_limit' => l.expAuthRateLimit,
    'weak_password' || 'same_password' => l.expAuthPassword,
    _ => l.expAuthGeneric,
  };
}
