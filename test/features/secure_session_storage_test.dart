import 'package:fit_pack/core/auth/secure_session_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Oturum belirteci artık cihazın anahtar kasasında (iOS Keychain / Android
/// Keystore). Bu testlerin bekçilik ettiği kural: **güvenlik iyileştirmesi
/// kullanıcıyı oturumundan etmesin.** Kasa çalışmazsa eski davranışa düşülür.
void main() {
  const url = 'https://jkviihbyogktwboreydn.supabase.co';
  final key = sessionStorageKey(url);
  const session = '{"access_token":"abc","refresh_token":"def"}';

  Future<SharedPreferences> prefs() => SharedPreferences.getInstance();

  SecureSessionStorage storage(_FakeStore store) => SecureSessionStorage(
    persistSessionKey: key,
    store: store,
    prefs: prefs,
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('anahtar cihazdaki ile aynı biçimde türetilir', () {
    expect(key, 'sb-jkviihbyogktwboreydn-auth-token');
  });

  group('göç', () {
    test('düz metindeki oturum kasaya taşınır ve eskisi silinir', () async {
      SharedPreferences.setMockInitialValues({key: session});
      final store = _FakeStore();
      final s = storage(store);

      await s.initialize();

      expect(store.values[key], session, reason: 'kasaya yazılmalı');
      expect((await prefs()).getString(key), isNull, reason: 'düz metin gitmeli');
      expect(await s.accessToken(), session);
    });

    test('eski sürümün anahtarı da taşınır', () async {
      SharedPreferences.setMockInitialValues({
        legacySessionStorageKeys.first: session,
      });
      final store = _FakeStore();

      await storage(store).initialize();

      expect(store.values[key], session);
      expect((await prefs()).getString(legacySessionStorageKeys.first), isNull);
    });

    test('kasa yazamıyorsa oturum düz metinde KALIR (çıkış olmaz)', () async {
      SharedPreferences.setMockInitialValues({key: session});
      final store = _FakeStore(failWrites: true);
      final s = storage(store);

      await s.initialize();

      expect((await prefs()).getString(key), session,
          reason: 'taşınamadıysa eski değer korunmalı');
      expect(await s.accessToken(), session, reason: 'oturum hâlâ okunabilmeli');
    });

    test('kasa okunamıyorsa düz metne düşülür', () async {
      SharedPreferences.setMockInitialValues({key: session});
      final s = storage(_FakeStore(failReads: true));

      await s.initialize();

      expect(await s.accessToken(), session);
      expect(await s.hasAccessToken(), isTrue);
    });

    test('taşınacak oturum yoksa sessizce geçilir', () async {
      final store = _FakeStore();
      final s = storage(store);

      await s.initialize();

      expect(store.values, isEmpty);
      expect(await s.accessToken(), isNull);
      expect(await s.hasAccessToken(), isFalse);
    });

    test('kasada değer varsa düz metin yeniden okunmaz', () async {
      SharedPreferences.setMockInitialValues({key: 'ESKİ'});
      final store = _FakeStore()..values[key] = session;

      final s = storage(store);
      await s.initialize();

      expect(await s.accessToken(), session, reason: 'kasa önceliklidir');
    });
  });

  group('günlük kullanım', () {
    test('yeni oturum kasaya yazılır, düz metne sızmaz', () async {
      final store = _FakeStore();
      final s = storage(store);
      await s.initialize();

      await s.persistSession(session);

      expect(store.values[key], session);
      expect((await prefs()).getString(key), isNull);
    });

    test('çıkışta her iki yerden de silinir', () async {
      SharedPreferences.setMockInitialValues({key: session});
      final store = _FakeStore()..values[key] = session;
      final s = storage(store);

      await s.removePersistedSession();

      expect(store.values[key], isNull);
      expect((await prefs()).getString(key), isNull);
      expect(await s.accessToken(), isNull);
    });
  });
}

/// Bellek-içi anahtar kasası; istenirse okuma/yazmada patlar.
class _FakeStore implements SecureStore {
  _FakeStore({this.failReads = false, this.failWrites = false});

  final Map<String, String?> values = {};
  final bool failReads;
  final bool failWrites;

  @override
  Future<String?> read(String key) async {
    if (failReads) throw Exception('kasa okunamadı');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw Exception('kasaya yazılamadı');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (failWrites) throw Exception('kasadan silinemedi');
    values.remove(key);
  }
}
