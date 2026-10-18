import 'package:fit_pack/core/theme/app_theme.dart';
import 'package:fit_pack/features/auth/auth_screen.dart';
import 'package:fit_pack/features/auth/auth_errors.dart';
import 'package:fit_pack/features/cloud/auth_service.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeAuth extends AuthService {
  int sends = 0;
  bool fail = false;
  @override
  User? get currentUser => null;
  @override
  Stream<AuthState> get onAuthChange => const Stream.empty();
  @override
  Future<void> signUpWithEmail(String email, String password) async {}
  @override
  Future<void> resendConfirmation(String email) async {
    sends++;
    if (fail) throw const AuthException('raw English secret', code: 'over_email_send_rate_limit');
  }
}
void main() {
  test('sunucu hata kodları yerelleşir, bilinmeyen ham mesaj sızmaz', () {
    final tr = lookupAppL10n(const Locale('tr'));
    for (final code in ['invalid_credentials', 'email_not_confirmed', 'user_already_exists',
      'over_email_send_rate_limit', 'weak_password', 'unknown']) {
      expect(authErrorLabel(tr, AuthException('raw English secret', code: code)),
        isNot(contains('raw English')));
    }
    expect(authErrorLabel(tr, const AuthException('bad', code: 'invalid_credentials')),
      'E-posta veya şifre yanlış.');
  });
  testWidgets('kayıt sonrası adres, yardım ve yeniden gönder; hatada kilit açılır', (tester) async {
    final auth = FakeAuth();
    await tester.pumpWidget(ProviderScope(overrides: [authServiceProvider.overrideWithValue(auth)],
      child: MaterialApp(theme: AppTheme.dark, locale: const Locale('tr'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales, home: const AuthScreen(signUp: true))));
    await tester.enterText(find.byType(TextField).first, 'test@example.com');
    await tester.enterText(find.byType(TextField).last, 'password');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Kayıt Ol'));
    await tester.pumpAndSettle();
    expect(tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Kayıt Ol')).onPressed, isNotNull);
    await tester.tap(find.text('Kayıt Ol'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('E-postanı doğrula'), findsOneWidget, reason: tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).join(' | '));
    expect(find.widgetWithText(SelectableText, 'test@example.com'), findsOneWidget);
    expect(find.textContaining('spam'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('auth.resend')));
    auth.fail = true;
    await tester.tap(find.byKey(const ValueKey('auth.resend')));
    await tester.pumpAndSettle();
    expect(auth.sends, 1);
    await tester.drag(find.byType(ListView), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.textContaining('Çok sık'), findsOneWidget);
    expect(tester.widget<TextButton>(find.byKey(const ValueKey('auth.resend'))).onPressed, isNotNull);
    auth.fail = false;
    await tester.ensureVisible(find.byKey(const ValueKey('auth.resend')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('auth.resend')));
    await tester.pumpAndSettle();
    expect(auth.sends, 2);
  });
}
