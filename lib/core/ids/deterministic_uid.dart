import 'package:uuid/uuid.dart';

/// Fit Pack'in UUIDv5 ad alanı. **Asla değiştirilmez** — değişirse aynı gün /
/// katalog satırı farklı kimlik üretir ve cihazlar arası eşleşme kopar.
const fitPackUuidNamespace = '5b1e7c4a-3f2d-5e8b-9a61-0c4d2f7e9b13';

/// Aynı girdiden hep aynı kimliği üreten UUIDv5 (RFC 4122 §4.3).
///
/// Neden: iki cihaz aynı mantıksal kaydı (ör. aynı beslenme günü) ayrı ayrı
/// oluşturduğunda aynı `uid`'i yazsın; sunucu anahtarı `(user_id, uid)`
/// olduğu için çift satır oluşmaz (docs/37 §2, docs/20 §7.2).
String deterministicUid(String name) =>
    const Uuid().v5(fitPackUuidNamespace, name);

/// Beslenme günü satırının kimliği. [day] `YYYY-MM-DD`.
String nutritionDayUid(String day) =>
    deterministicUid('fitpack:nutrition_day:$day');
