# 41 — Kişisel veri uyumu: KVKK (Türkiye) + GDPR (global)

> **Durum:** Uygulanıyor (2026-10-11) — P-1 kısmen, P-2 ✅ (tartı), P-3 metin ✅,
> hesap silme düzeltmesi Dev ✅ / üretim onayda. Envanter + eksikler + iş listesi. **Hukuki görüş değildir;**
> "⚖️" işaretli her madde bir KVKK/GDPR hukukçusuna doğrulatılmalı.
> **Tarih:** 2026-10-11 · **Sahip:** Claude-2
> **Samet kararı (2026-10-11):** "Ne yapıyorsak Türkiye'de KVKK'ya, globalde
> GDPR'a göre yapmalıyız."

---

## 0. Karar özeti

Fit Pack **sağlık verisi** işliyor (kilo, yağ oranı, vücut ölçüleri, adım,
yakında tartı verisi). Bu veri KVKK md. 6'da ve GDPR md. 9'da **özel
nitelikli**; fitness uygulaması için gerçekçi hukuki dayanak **açık rıza**.
Bugün uygulamada **gizlilik politikası / aydınlatma metni yok**, sağlık
verisi için **açık rıza alınmıyor**, veri **Almanya'daki** sunucuya (Supabase,
Frankfurt) ve asistanda soru metni **Google'a** gidiyor. Kullanıcı sayısı 2
(Samet + Alper); büyümeden önce kapatılmalı.

**Önerilen sıra:** (1) gizlilik politikası + aydınlatma metni, (2) sağlık
verisi için açık rıza ekranı + rıza kaydı (docs/40 tartı işiyle birlikte),
(3) yurt dışı aktarım dayanağı ve işleyen sözleşmeleri, (4) ⚖️ hukukçu
kontrolü, (5) mağaza beyanları.

## 1. Veri envanteri (koddan, 2026-10-11)

| Veri | Nerede | Özel nitelikli mi | Not |
|---|---|---|---|
| E-posta, hesap kimliği | Supabase Auth (Frankfurt) | Hayır | Google ile giriş de var |
| Profil: doğum tarihi, cinsiyet, boy, hedefler | Cihaz + Supabase | Hayır (⚖️ boy/kilo hedefi sınırda) | |
| Kilo, yağ oranı, vücut çevreleri | Cihaz + Supabase | **Evet (sağlık)** | docs/40 ile tartıdan da gelecek |
| Antrenman, set, RPE, notlar | Cihaz + Supabase | ⚖️ Notlar sağlık bilgisi içerebilir (ör. diz durumu — `kneeStatus` alanı var) | |
| Öğün kayıtları, su | Cihaz + Supabase | ⚖️ Beslenme tek başına genelde değil | |
| İlerleme fotoğrafları | **Cihaz** (+ telefonun kendi yedeği) | Evet (beden görüntüsü) | Sunucumuza gitmez; iCloud/Google yedeğine girer (docs/19 §6, Samet kararı b) |
| Adım | **Yalnız cihaz** | Evet (sağlık) | docs/39 |
| Asistan soru metni | Google Gemini (ücretsiz katman) | Soruya göre | Saklanmıyor (docs/38 §8); ⚠️ §2.4 |
| Asistan kota sayacı | Supabase | Hayır | |

## 2. Eksikler

1. **Gizlilik politikası / aydınlatma metni yok** (KVKK md. 10, GDPR md. 13).
   App Store ve Google Play de sağlık verisi işleyen uygulamadan politika
   bağlantısı istiyor; Health Connect'teki politika bağlantısı mağazadakiyle
   aynı olmalı (docs/39).
2. **Sağlık verisi için açık rıza yok.** Kayıt olurken ya da ilk ölçümde
   ayrı, özgür iradeyle verilen, geri alınabilir rıza gerekir (KVKK md. 3 ve
   6; GDPR md. 7 ve 9/2-a). Rızanın verildiği an ve metin sürümü kaydedilmeli
   (ispat yükü bizde).
3. **Yurt dışı aktarım (KVKK md. 9, 2024 değişikliği).** Supabase Almanya'da;
   Türkiye için yeterlilik kararı ⚖️ yok bilgimizce → **standart sözleşme**
   (Kurul'un ilan ettiği metin) + imzadan sonra **5 iş günü** içinde Kurul'a
   bildirim gerekebilir. GDPR açısından AB içinde, sorun yok.
4. **Asistan / Google Gemini ücretsiz katmanı.** Google ücretsiz katmanda
   içeriği ürün geliştirmede kullanabiliyor; ⚖️ Google'ın Gemini API
   koşulları AB/İsviçre/Birleşik Krallık kullanıcılarına hizmet veren
   uygulamalarda **ücretli** katmanı şart koşuyor olabilir — doğrulanmalı.
   Ayrıca İngilizce izin metni ("records stay on your device") yanlış:
   ölçümler buluta senkronlanıyor → düzeltilmeli.
5. **İşleyen (processor) sözleşmeleri:** Supabase DPA (veri işleme ek
   sözleşmesi), Google — imzalı/kabul edilmiş mi kontrol.
6. **Saklama süresi** tanımlı değil (hesap silinene kadar mı? silinen
   hesabın yedekleri?).
7. **İhlal bildirimi prosedürü** yok (KVKK: Kurul'a en kısa sürede, uygulamada
   72 saat; GDPR md. 33: 72 saat).
8. ⚖️ **VERBİS** kaydı: ana faaliyeti özel nitelikli veri işlemek olan veri
   sorumluları muafiyetten yararlanamayabilir.
9. **Yaş sınırı:** GDPR md. 8 (çocuk rızası 13–16 yaş, ülkeye göre);
   onboarding'de doğum tarihi var ama alt sınır yok.

10. **Hesap silme çalışmıyordu (2026-10-11 tespit):** uygulama
    `rpc('delete_user')` çağırıyor; fonksiyon docs/16 §4'te yazılmış ama
    üretimde **hiç kurulmamış** → "Hesap silinemedi". Göç
    `20261011190000_delete_user.sql`: Dev'de kuruldu ve geri alınan işlemle
    denendi (kullanıcı + verisi silindi, diğerleri durdu); 14 kullanıcı tablosu
    `on delete cascade`. Üretime Samet onayıyla.
11. **Destek e-postası iş adresi** (`AppConstants.supportEmail` =
    samet.orhan@inveon.com): kişisel projede iş adresi; politikadaki iletişim
    adresi de bekliyor (Samet: "şimdilik es geç").

**Zaten var olanlar:** hesap silme düğmesi (sunucu fonksiyonu yukarıda, madde 10), dışa aktarma motoru (CSV/JSON — erişim ve
taşınabilirlik hakkı; uygulama içi ekran yalnız premium olacak, şimdilik
yok → herkes için talep iletişim adresiyle, 30 gün — Samet kararı 2026-10-17), fotoğraf ve adımın cihazda kalması, asistanda
gönderim öncesi onay, metinsiz kalite paneli.

## 3. Sağlık verisi açık rıza tasarımı (docs/40 ile birlikte uygulanır)

- **Ne zaman:** tartı / Sağlık bağlantısı açılırken (ve ileride elle sağlık
  ölçümünün ilk kaydında — ayrı iş).
- **Ekran:** ne işlenir (kilo, yağ oranı), nerede (Fit Pack bulutu, AB —
  Almanya), neden (ilerleme ve kilo yorumları), kimle paylaşılmaz (reklam,
  üçüncü taraf yok), nasıl geri alınır (Ayarlar → Sağlık). Önceden işaretli
  kutu **yok**; "Kabul ediyorum" ve "Vazgeç" eşit görünür.
- **Kayıt:** `user_profile.health_consent_at` (zaman) +
  `health_consent_version` (metin sürümü) — senkronlanır (ispat). Metin
  değişince sürüm artar, rıza yeniden istenir.
- **Geri alma:** tek dokunuş; içe aktarma durur; "içe alınan ölçümleri de
  sil" seçeneği. Rıza geri alınınca o ana kadarki işleme hukuka uygun kalır
  (GDPR md. 7/3).

## 4. İş listesi

| # | İş | Kim | Öncelik |
|---|---|---|---|
| P-1 | Gizlilik politikası + aydınlatma metni (TR/EN) — ✅ uygulama içinde (Ayarlar, giriş, rıza ekranı; `assets/legal/`). Bekleyen: iletişim adresi, web bağlantısı (mağaza öncesi), ⚖️ hukukçu | Claude taslak → ⚖️ hukukçu | Yüksek |
| P-2 | Sağlık açık rıza ekranı + kayıt (§3) — ✅ tartı verisi için. ⚖️ **Elle girilen kilo/ölçüm için rıza: Samet kararı (2026-10-11) hukukçuya sorulana kadar bekliyor**; politika metni (sürüm 2) elle girişte rıza iddia etmiyor. Seçenekler: tek seferlik sağlık rızası (önerilen) / elle ölçümler yalnız cihazda | ⚖️ hukukçu → Samet | Yüksek |
| P-3 | ✅ Asistan İngilizce izin metni düzeltildi. Bekleyen: Gemini koşullarını doğrula, gerekirse ücretli katman / AB kullanıcılarına kapat | Claude + Samet kararı | Yüksek |
| P-4 | Supabase DPA + KVKK standart sözleşme / Kurul bildirimi | Samet (⚖️) | Orta |
| P-5 | Saklama süresi + hesap silme — sunucu fonksiyonu eksikti, düzeltildi (madde 10); üretim onayda | Claude | **Yüksek** |
| P-6 | İhlal bildirimi kısa prosedürü | Claude taslak | Orta |
| P-7 | Yaş alt sınırı (onboarding) | Claude | Orta |
| P-8 | VERBİS gerekliliği | ⚖️ hukukçu | Orta |
| P-9 | App Store gizlilik etiketleri / Play veri güvenliği formu | Yayın öncesi | Yayınla birlikte |

## 4b. Codex incelemesi düzeltmeleri (2026-10-11)

- Rıza zamana göre ilerler (sunucu `health_consent_monotonic`); geri alma da
  zamanla yazılır. Gizleme kalıcı (`health_hidden_sticky`).
- Geri almada içe alınan ölçümler **her zaman** silinir ("tut" seçeneği
  kaldırıldı — rızayla alınan veri rıza gidince başka dayanakla işlenmez);
  yeniden rızada yalnız yeni örnekler (Samet kararı).
- Hesap değişimi / geri alma "sağlık dönemi"ni artırır: süren içe aktarma ve
  antrenman yazma eski hesaba ait veriyi yeni hesaba yazamaz.
- `delete_user` asistan kota sayaçlarını da siler (`20261011200000`).

## 5. Kaynaklar

- KVKK değişiklikleri özeti (7499 s. Kanun, 1 Haziran 2024):
  https://www.erdem-erdem.av.tr/bilgi-bankasi/kisisel-verilerin-korunmasi-kanununda-neler-degisti
- App Store İnceleme Kuralları 5.1.3: https://developer.apple.com/app-store/review/guidelines/
- Google Play / Health Connect yayın şartları:
  https://developer.android.com/health-and-fitness/health-connect/publish
- GDPR metni: https://eur-lex.europa.eu/eli/reg/2016/679/oj
