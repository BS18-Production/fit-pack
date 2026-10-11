import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../home/providers/home_providers.dart' show userProfileProvider;
import '../../data/database/daos/body_dao.dart';
import '../../data/database/daos/user_profile_dao.dart';
import 'body_import.dart';

/// Tartıdan kilo sağlayıcıları (docs/40, docs/41 §3). Satırlar
/// `body_measurements`'a yazıldığı için kiloyu okuyan reaktif sağlayıcılar
/// (`watchTables`) kendiliğinden tazelenir — ayrıca `invalidate` gerekmez.

final bodySourceProvider = Provider<BodySource>((ref) => HealthBodySource());

/// Geçerli açık rıza var mı: zaman kayıtlı ve metin sürümü güncel.
final healthConsentProvider = Provider<bool>((ref) {
  final p = ref.watch(userProfileProvider).valueOrNull;
  return p?.healthConsentAt != null &&
      p?.healthConsentVersion == kHealthConsentVersion;
});

/// Öne gelişte / bağlanınca: rıza varsa son günleri içe alır (W-7, W-8).
/// Bağımlılıklar açıkça verilir: yaşam döngüsünden çağrılınca bir sağlayıcı
/// iş ortasında atılmasın. Hata kullanıcıyı durdurmaz — bir sonraki öne
/// gelişte yeniden denenir.
Future<int> runBodyImport({
  required UserProfileDao profiles,
  required BodyDao body,
  required BodySource source,
}) async {
  try {
    final p = await profiles.getProfile();
    return await importBodySamples(
      source: source,
      dao: body,
      consentGiven:
          p?.healthConsentAt != null &&
          p?.healthConsentVersion == kHealthConsentVersion,
      now: DateTime.now(),
    );
  } catch (_) {
    return 0;
  }
}

/// `ref`'ten bağımlılıkları eşzamanlı yakalayıp [runBodyImport]'u çalıştırır.
Future<int> runBodyImportFrom(WidgetRef ref) => runBodyImport(
  profiles: ref.read(userProfileDaoProvider),
  body: ref.read(bodyDaoProvider),
  source: ref.read(bodySourceProvider),
);

/// Rıza ekranında "Kabul ediyorum": önce rıza kaydı (ispat), sonra platform
/// izni, sonra ilk içe aktarma. İzin penceresi kapanırsa rıza kalır ama veri
/// gelmez; kullanıcı Ayarlar'dan geri alabilir.
Future<void> grantHealthConsentAndImport(WidgetRef ref) async {
  // Bağımlılıklar ilk await'ten ÖNCE: sayfa kapanırsa ref geçersizleşir.
  final source = ref.read(bodySourceProvider);
  final profiles = ref.read(userProfileDaoProvider);
  final body = ref.read(bodyDaoProvider);
  await profiles.setHealthConsent(kHealthConsentVersion);
  await source.requestAccess();
  await runBodyImport(profiles: profiles, body: body, source: source);
}

/// Rızayı geri al (GDPR md. 7/3 — vermek kadar kolay): içe aktarma durur;
/// [deleteImported] ise içe alınmış tüm ölçümler silinir (buluttan da).
Future<void> withdrawHealthConsent(
  WidgetRef ref, {
  required bool deleteImported,
}) async {
  final profiles = ref.read(userProfileDaoProvider);
  final body = ref.read(bodyDaoProvider);
  await profiles.setHealthConsent(null);
  if (deleteImported) await body.deleteImportedMeasurements();
}
