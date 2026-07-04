# 15 — Onboarding V2 (Karşılama + Öğretme)

> **Durum:** ✅ UYGULANDI (2026-07-05, aynı gün) — analyze 0 · test 123/123 ·
> sıfır kurulum emülatörde EN + TR uçtan uca doğrulandı
> **İlgili:** [docs/03-ux-flows.md](03-ux-flows.md) §3 (eski P-10),
> [docs/08-design-brief.md](08-design-brief.md), [docs/14-localization.md](14-localization.md)

Mevcut onboarding (P-10) yalnız **veri toplar** (kilo/boy/faz → kalori/protein).
Kullanıcıya uygulamanın **ne yapabildiğini ve her sekmede ne yapılacağını
öğretmez**; görsel olarak da cam (glass) temaya taşınmadı. V2 üç parça:

| Parça | Ne | Nerede öğretir |
|-------|----|----|
| **A** | Kurulum akışı: glass reskin + değer projeksiyonu + "İçeride ne var" | Genel resim (ne nerede) |
| **B** | Bağlamsal ilk-kullanım koçluğu (coach mark) | Nasıl yapılır (ihtiyaç anında) |
| **C** | Boş hal (empty state) güçlendirme | Ekran boşken sıradaki adım |

**Araştırma dayanağı (özet):** Baştan uzun tanıtım turu/carousel anti-pattern —
kullanıcı görevle karşılaşmadan gösterilen soyut slaytları hatırlamıyor (NN/g,
Appcues). Kazanan: kişiselleştirme + değer projeksiyonu ("aha" anı) + ekranda
**ilk karşılaşma anında** tek ipucu (coach mark) + öğreten boş haller. İlk
oturumda anlamlı aksiyon (ilk antrenman/öğün) tamamlayan kullanıcıda kalıcılık
2-3 kat. Kaynaklar: nngroup.com/articles/onboarding-tutorials,
appcues.com/blog/choosing-the-right-onboarding-ux-pattern,
amalgama.co/the-psychology-behind-fitness-apps-onboarding.

---

## A — Kurulum Akışı (glass reskin + değer)

4 sayfa (`PageView`, mevcut iskelet korunur; 3→4):

### A1. Karşılama
- `GlassBackground` + ortada `GlassCard`: uygulama ikonu, başlık, tek cümle
  duygusal kanca ("Antrenmanını, beslenmeni ve gelişimini tek yerde topla").
- Alt metin: "Birkaç soruyla planını kuralım — 1 dakikadan az."
- Görsel dil: Ana Sayfa ile birebir (Manrope w800 başlık, indigo/teal glow,
  `AppColors` token'ları). Ham Material görünümü kalkar.

### A2. Seni tanıyalım (mevcut adım 2, reskin)
- Alanlar aynı: kilo (zorunlu), boy, hedef kilo, cinsiyet, doğum tarihi
  (opsiyoneller "günlük enerji tahmini için" alt notuyla).
- Faz seçimi (Kilo Ver / Koru / Kütle Al) `_PhaseTile` → glass seçim kartı.
- Girdi alanları `GlassCard` içinde gruplanır; klavye davranışı korunur.

### A3. Planın hazır ✨ (YENİ — "aha" anı)
- Büyük `GlassCard`: önerilen **günlük kalori + protein** (düzenlenebilir,
  mevcut `_GoalsPage` mantığı buraya gömülür, `_goalsEdited` korunur).
- **Değer projeksiyonu** (yalnız veriler tutarlıysa gösterilir — sahte vaat yok):
  - cut + hedef kilo < mevcut kilo: günlük açık = **bakım − kullanıcının
    girdiği kalori** (düzenledikçe dürüstçe güncellenir; girilmemişse faz
    varsayılanı %20) → haftalık ≈ `açık×7/7700` kg → "~{hafta} haftada
    {hedef} kg hedefine ulaşabilirsin" (7700 kcal ≈ 1 kg yağ).
  - bulk + hedef > mevcut: aynı hesap fazlalıkla.
  - maintenance, hedef kilo boş/yönü ters ya da açık/fazla ≤ 0: gizlenir.
- Projeksiyon metni her zaman "tahmini" der; hesap saf fonksiyon olarak
  `onboarding_calc.dart`'a eklenir + birim testi.

### A4. İçeride ne var (YENİ — genel resim, slayt turu DEĞİL)
Tek ekran, 4 kompakt satır (ikon + sekme adı + tek satır fayda):
- 🏠 **Ana Sayfa** — Günün özeti: seri, plan, beslenme, su
- 🏋️ **Antrenman** — Rutin kur, seti kaydet, geçmişe bak
- 🍽️ **Beslenme** — Öğün ekle: ara, barkod okut, makroları izle
- 📈 **İlerleme** — Kilo/ölçüm gir, grafikte gelişimi gör
Alt buton: **"Başlayalım"** → `_finish()` (profil yazımı aynen korunur:
transaction, ilk kilo ölçümü, `onboarded=1`, invalidate'ler, hata yakalama).

Sıra notu: "İçeride ne var" **plan ekranından sonra** gelir — önce değer,
sonra harita. Geri navigasyonu ve `_canAdvance` mantığı 4 sayfaya uyarlanır.

---

## B — Bağlamsal İlk-Kullanım Koçluğu (coach marks)

### Davranış
- Kullanıcı bir ana sekmeye **ilk kez** girdiğinde, o ekranın birincil
  aksiyonunun üstünde tek spotlight: karartılmış arka plan (scrim ~%60),
  hedef widget parlak bırakılır, kısa metin + **"Anladım"**.
- Ekran başına **tek** ipucu (zincir yok — bilişsel yük araştırması).
- Kapatınca kalıcı işaretlenir; scrim'e dokunmak da kapatır.

| Ekran | Hedef | Metin (TR) |
|-------|-------|-----------|
| Antrenman | "Boş Antrenman Başlat" / "Yeni Rutin Oluştur" | "İlk rutinini buradan kur — ya da hemen boş antrenman başlat." |
| Beslenme | "Yemek Ekle" FAB | "İlk öğününü ekle: yaz, ara ya da barkod okut." |
| İlerleme | Kilo/ölçüm ekle butonu | "İlk kilonu gir — grafik buradan başlar." |

Ana Sayfa'ya ipucu **yok**: onboarding zaten oradan çıkarır ve A4 tanıttı.

### Teknik
- `lib/core/onboarding/first_run_hints.dart`:
  - `FirstRunHints` Notifier — `shared_preferences` `hint_seen_<id>` anahtarları.
  - `CoachMarkOverlay` widget'ı: hedefe `GlobalKey`, konumu `RenderBox`'tan;
    `OverlayEntry` + `CustomPaint` scrim (hedef deliği yuvarlatılmış dikdörtgen).
    Paket eklenmez (bağımlılık şişirmemek için; ihtiyaç ~80 satır).
- **Mevcut kullanıcı koruması:** uygulama açılışında `onboarded == true` ve
  hiç `hint_seen_*` anahtarı yoksa hepsi "görüldü" yazılır → Samet'in
  telefonunda güncelleme sonrası ipuçları rahatsız etmez. İpuçları yalnız
  V2 onboarding'i tamamlayan yeni kullanıcıya akar.
- Şema değişikliği YOK (yalnız `shared_preferences`).

---

## C — Boş Hal Güçlendirme

Denetim listesi (her boş hal: ne bu + tek net aksiyon):
- [ ] Antrenman: "Henüz rutin yok" — mevcut, metin CTA'yla hizalanır
- [ ] Beslenme (boş gün): "Bugün öğün yok → Yemek Ekle" doğrudan açar
- [ ] İlerleme (ölçüm yok): "İlk kilonu gir" butonu formu doğrudan açar
- [ ] Geçmiş (seans yok): "İlk antrenmanını bitirince burada görünür"
- [ ] Ana Sayfa boş metrikler: davet dili (Sprint P'de kısmen yapıldı, kontrol)

---

## i18n Notu (docs/14 ile kesişim)

Onboarding henüz ARB'ye taşınmadı. **V2 doğrudan ARB ile yazılır**
(`onb_*`, `hint_*` anahtarları, EN kaynak + TR) — eski metinleri önce migrate
edip sonra yeniden yazma israfı yapılmaz. `OnboardingPhase.label/description`
enum'dan çıkar → `enum_labels.dart`'a `phaseLabel/phaseDescription(l, phase)`.

## Uygulama Sırası (sonraki oturum, batch'ler)

1. **O-1:** A1+A2 glass reskin (akış/kayıt mantığına dokunmadan) — ARB'li
2. **O-2:** A3 plan ekranı + projeksiyon hesabı (`onboarding_calc` + test)
3. **O-3:** A4 "İçeride ne var" + 4 sayfa navigasyon uyarlaması
4. **O-4:** B coach mark altyapısı + 3 ipucu + mevcut-kullanıcı koruması
5. **O-5:** C boş hal denetimi
6. Her batch: analyze 0 · test · **sıfır kurulumda** emülatör doğrulaması
   (DB silinmiş cihazda uçtan uca: onboarding → ipuçları → ilk aksiyonlar),
   EN + TR ekran görüntüsü.

**"Bitti" tanımı:** Yeni kullanıcı kurulumdan çıktığında (1) planını görmüş,
(2) 4 sekmenin ne işe yaradığını okumuş, (3) her sekmeye ilk girişte tek
ipucuyla ilk aksiyona yönlendirilmiş olur; mevcut kullanıcı hiçbir ipucu görmez.
