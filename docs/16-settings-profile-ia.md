# 16 — Profil + Ayarlar Bilgi Mimarisi (IA)

> **Durum:** ✅ TÜM BATCH'LER UYGULANDI — B1-B4 (2026-07-05) + B5 birim
> sistemi + B6 bildirimler (2026-07-06). analyze 0 · test 137/137 ·
> emülatörde doğrulandı (imperial uçtan uca + bildirim izin/alarm/teslim).
> B3'ün Supabase SQL adımı Samet'te (aşağıda §4).
> **Karar:** Ayrı **Profil** ekranı + sadeleştirilmiş **Ayarlar** (Samet seçti)
> **İlgili:** [docs/03-ux-flows.md](03-ux-flows.md),
> [docs/12-session-resilience.md](12-session-resilience.md) (BMR/TDEE, şema v8),
> [docs/13-cloud-backup.md](13-cloud-backup.md), [docs/14-localization.md](14-localization.md),
> [docs/11-content-enrichment.md](11-content-enrichment.md) §C-6 (atıf)

Mevcut **Ayarlar** ekranı tek başına üç işi birden yapıyor: kişisel veri
(hedefler + vücut + kimlik), uygulama konfigürasyonu (tema/dil) ve veri araçları
(bulut/yedek/dışa aktar). Best practice bunları ayırır: sık düzenlenen **kişisel
veri = Profil**, nadir değişen **konfigürasyon = Ayarlar**, **veri araçları**
kendi grubunda. Kaynak: Apple HIG ("infrequently changed app-wide config"),
Material guidance, ve referans uygulamalar (Hevy/Strong/MyFitnessPal/Cronometer
— hepsinde Profil hub'ı → içinde Ayarlar dişlisi).

---

## 1. Mevcut durum + tespit edilen sorunlar

**Mevcut Ayarlar bölümleri:** Hedefler (kcal, protein) · Vücut (boy, hedef kilo,
cinsiyet, doğum, aktiflik, TDEE kartı) · Görünüm (tema, dil) · Beslenme
(yemekler) · Verilerim (bulut, yedek, geri yükle, dışa aktar) · Hakkında
(ad+sürüm). Erişim: yalnız Ana Sayfa sağ üst dişli ikonu.

| # | Sorun | Önem |
|---|-------|------|
| S1 | Vücut verisi **iki ekrana bölünmüş**: boy/hedef kilo/cinsiyet/doğum/aktiflik Ayarlar'da; kilo/bel/kol ölçümleri İlerleme'de | Yüksek |
| S2 | **Ayrı Profil yok** — Ayarlar profil taklidi yapıyor; sık düzenlenen veri dişli ardında gömülü | Yüksek |
| S3 | **Birim ayarı YOK** — her şey hardcoded kg/cm; i18n ile uluslararası kitleye açılırken lb/ft-in beklenir | Yüksek (kitle) |
| S4 | **Hesap silme YOK** — bulut auth var, sadece "Çıkış"; Google Play + Apple uygulama içi hesap+veri silmeyi zorunlu tutar | Yüksek (mağaza reddi) |
| S5 | **Bildirim ayarları yok** — alışkanlık odaklı uygulama (seri/su/antrenman) ama bildirim altyapısı+evi yok | Orta |
| S6 | **Hakkında yasal olarak eksik** — gizlilik, şartlar, açık kaynak lisansları/atıf yok. OFF (ODbL) atfı yasal zorunluluk (C-6). `showLicensePage` kullanılmıyor | Orta (yasal) |
| S7 | Puanla / Geri bildirim / Destek yok | Düşük |
| S8 | Haftanın ilk günü (Pzt/Paz) ayarı yok (haftalık takvim var) | Düşük |

**Yeşiller (korunacak):** section başlıklı gruplama, ikon rozetli `_SettingTile`,
aralık/validasyonlu `_NumberEditDialog`, `_pickOption` dialog'u, TDEE kartı
mantığı. İskelet iyi — sadece içerik dağılımı yeniden konumlanacak.

---

## 2. Hedef Bilgi Mimarisi

### 2.1 PROFİL (yeni ekran — `/profile`)
Kullanıcının "kim olduğu" ve hedefleri. Sık bakılır/düzenlenir.

```
PROFİL
├── (üst) Kimlik özeti: ad-yer-tutucu/avatar + (opsiyonel) e-posta (bulutta ise)
├── Hedefler
│     • Kalori hedefi        (kcal)
│     • Protein hedefi       (g)
├── Vücut
│     • Boy
│     • Hedef kilo
│     • → Ölçümler (kilo/bel/kol…)  [İlerleme'deki ölçüm ekranına köprü]
├── Kimlik / Enerji
│     • Cinsiyet
│     • Doğum tarihi
│     • Aktiflik seviyesi
│     • Tahmini Günlük Harcama (TDEE kartı)  [taşınır, aynen]
└── (app bar sağ üst) ⚙️ → Ayarlar
```

**Not (S1):** güncel kilo/ölçümler İlerleme'de kalır (girişin doğal yeri orası).
Profil'den oraya **köprü** verilir; ters yönde İlerleme "Son Ölçümler" kartından
Profil'e köprü opsiyonel. Böylece "fiziksel kimlik" tek zihinsel modelde toplanır
ama ölçüm-girişi tek yerde kalır (çift kaynak yok).

### 2.2 AYARLAR (sadeleşmiş — `/settings`)
Yalnız uygulama konfigürasyonu + veri araçları + yasal.

```
AYARLAR
├── Tercihler
│     • Birim         (Metrik / İmperial)      ⭐ YENİ  → §3
│     • Tema          (Sistem/Açık/Koyu)       [taşınır]
│     • Dil           (Sistem/EN/TR)           [taşınır]
│     • Bildirimler   (…)                       ⭐ YENİ (altyapı gelince) → §5
│     • Haftanın ilk günü (Pzt/Paz)            ⭐ YENİ (küçük) → S8
├── Beslenme
│     • Yemekler                                [taşınır]
├── Veri & Gizlilik
│     • Bulut Hesabı                            [taşınır]
│     • Yedekle / Geri Yükle                    [taşınır]
│     • Dışa Aktar (rapor)                      [taşınır]
│     • Hesabı Sil                              ⭐ YENİ → §4
└── Hakkında
      • Sürüm → Açık Kaynak Lisansları          ⭐ (showLicensePage) → §6
      • Gizlilik Politikası (link)              ⭐ → §6
      • Kullanım Şartları (link)                ⭐ → §6
      • Açık Veri Kaynakları / Atıf             ⭐ C-6 → §6
      • Uygulamayı Puanla · Geri Bildirim       ⭐ → S7
```

### 2.3 Navigasyon (bottom nav'a 5. sekme EKLENMEZ)
4 sekme (Home/Workout/Nutrition/Progress) korunur — 5. sekme kalabalık yapar ve
uygulama kimliği 4 çekirdek aktivite etrafında. Bunun yerine referans desen:

- **Ana Sayfa app bar**: mevcut "tune" (dişli) ikonu → **kişi/profil ikonu** olur,
  `/profile`'a gider. (Paylaş ikonu kalır.)
- **Profil app bar sağ üst**: ⚙️ dişli → `/settings`.
- Yani hub = Profil; Ayarlar onun içinden. (Hevy/Strong/MFP deseni.)

---

## 3. Birim Sistemi (⭐ en kritik eksik) — YAKLAŞIM

**Depolama kuralı:** DB'de her şey **her zaman metrik (kanonik)** tutulur (kg, cm,
km). Birim yalnız **görüntüleme + giriş sınırında** dönüştürülür. → **Şema
değişikliği YOK**, migration gerekmez. Mevcut tüm veri kg/cm olarak kalır.

- Tercih: `unitSystem` = `metric | imperial`, tema/dil gibi kalıcı
  (`shared_preferences` + Riverpod provider; şema değil).
- Dönüşüm katmanı: `core/i18n/units.dart` — `context.weight(kg)`,
  `context.height(cm)`, `context.distance(km)` gibi format yardımcıları +
  ters (giriş parse) yardımcıları. Etiketler locale değil birim tercihine bağlı.
- Etki alanı: kg/cm/km yazan **tüm** görüntüleme+giriş yerleri (Beslenme birim
  değil — o gramla; ama vücut kilo/boy, antrenman ağırlık/mesafe, hedef kilo,
  grafikler, özetler). Geniş ama mekanik.
- **Karar gereken:** ağırlık imperial'de `lb`, boy `ft-in` mi yoksa `in` mi;
  antrenman ağırlık artışları (2.5 kg vs 5 lb). Ayrı mini-karar.

> **Kapsam notu:** Birim sistemi tek başına büyük bir dilim (i18n Faz B gibi).
> Profil/Ayarlar ayrımıyla **aynı batch'te yapılmaz**. Ayarlar'a "Birim" satırı
> + provider iskeleti bu iş kapsamında; tüm ekranların dönüşümü ayrı batch/PRD.

---

## 4. Hesap Silme Akışı (⭐ mağaza zorunluluğu)

Bulut auth (Supabase) olan uygulamada Google Play (Data safety) + Apple
(5.1.1(v)) uygulama içi **hesap + veri silme** yolu ister.

- Yer: Bulut Hesabı ekranı (Ayarlar → Veri & Gizlilik → Bulut Hesabı), oturum
  açık görünümünde "Çıkış Yap" altında **Hesabı Sil** (kırmızı, çift onay).
  Oturum yoksa satır görünmez — hesap yokken silme anlamsız.
- Akış (uygulandı): çift onay → bulut yedeği sil (`deleteCloudBackup`, storage
  objesi auth kullanıcısıyla cascade OLMAZ, önce silinmeli) →
  `rpc('delete_user')` → `signOut`. Yerel veri etkilenmez (local-first).
- **Supabase tarafı (Samet'in işi — SQL Editor'de bir kez çalıştır):**
  anon/authenticated key ile `auth.admin.deleteUser` çağrılamaz; çözüm
  security-definer RPC:

```sql
create or replace function public.delete_user()
returns void
language sql
security definer
set search_path = ''
as $$
  delete from auth.users where id = auth.uid();
$$;

revoke execute on function public.delete_user() from anon, public;
grant execute on function public.delete_user() to authenticated;
```

  Fonksiyon kurulmadan butona basılırsa PostgrestException → UI "Hesap
  silinemedi" gösterir, oturum açık kalır (güvenli başarısızlık).

---

## 5. Bildirimler (⭐ altyapı gelince)

P-11 (dinlenme sayacı bildirimi) ertelenmiş. `flutter_local_notifications` +
izinler geldiğinde Ayarlar → Tercihler → **Bildirimler** evi hazır olacak:
antrenman hatırlatıcı, su hatırlatıcı, dinlenme sayacı biter bildirimi
(aç/kapa + saat). Bu iş kapsamında **sadece yer ayrılır**; bildirim motoru ayrı.

---

## 6. Yasal / Hakkında (⭐ + C-6)

- **Açık kaynak lisansları:** Flutter'ın hazır `showLicensePage` (bedava, tüm
  paket lisanslarını listeler). "Sürüm" satırı → bu sayfa.
- **Açık veri kaynakları / atıf (C-6):** OFF (ODbL — **yasal atıf zorunlu**),
  free-exercise-db (public domain), muscle_selector (MIT). Ayrı basit ekran ya da
  lisans sayfasına ek bölüm.
- **Gizlilik Politikası + Kullanım Şartları:** `url_launcher` ile dış link
  (metinler ayrıca yazılacak — yayın öncesi şart). Şimdilik yer-tutucu URL.
- **Puanla / Geri bildirim:** Puanla → mağaza linki; Geri bildirim → e-posta
  (`mailto:` samet.orhan@…) veya form.

---

## 7. Uygulama Sırası (batch'ler)

Küçük, doğrulanabilir dilimler (her biri: analyze 0 · test yeşil · emülatör):

- **B1 — Profil ekranı + Ayarlar ayrımı** (bu işin çekirdeği):
  `/profile` route + Ana Sayfa app bar kişi ikonu + Profil app bar ⚙️. Kişisel
  tile'lar (Hedefler/Vücut/Kimlik/TDEE) Profil'e taşınır; Ayarlar'da Tercihler/
  Beslenme/Veri/Hakkında kalır. İçerik taşıma — düşük risk. ARB anahtarları
  yeniden gruplanır (yeni ekran başlığı `profileTitle` vb.).
- **B2 — Yasal/Hakkında:** `showLicensePage` bağlama + atıf ekranı (C-6) +
  gizlilik/şartlar link yer-tutucu + puanla/geri bildirim. Küçük.
- **B3 — Hesap silme:** Supabase silme yolu (Edge Function araştırması) + UI +
  onay. Orta (backend dokunuşu).
- **B4 — Haftanın ilk günü:** küçük tercih + takvim/hafta hesaplarına bağlama.
- **B5 — Birim sistemi (AYRI PRD, en büyük):** `unitSystem` provider + dönüşüm
  katmanı + tüm ekranların migrasyonu. Kendi doc'u olabilir (17-units).
- **B6 — Bildirimler:** P-11 ile birlikte; bu doc yalnız yeri tanımlar.

**Sıra önerisi:** B1 → B2 → (B4) → B3 → B5 → B6. B1+B2 hızlı kazanım; B5 en ağır,
sona; B3 mağaza için gerekli ama yayın yaklaşınca.

---

## 8. Açık kararlar (Samet onayı)

1. **Profil erişimi:** Ana Sayfa dişli ikonu → kişi ikonu (profil), Ayarlar profil
   içinden ⚙️ ile. Onay? (Alternatif: iki ikon — kişi + dişli yan yana.)
2. **Ölçümler nerede:** İlerleme'de kalsın + Profil'den köprü (öneri) mi, yoksa
   ölçümler de Profil'e mi taşınsın? (Öneri: İlerleme'de kalsın.)
3. **Birim (B5) ayrı PRD olarak sonra mı** yoksa bu işe dahil mi? (Öneri: ayrı,
   sonra — çok büyük.)
4. **imperial detayları:** ağırlık `lb`, boy `ft-in`, artış `5 lb`? (B5'te.)
