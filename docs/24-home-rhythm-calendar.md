# Fit Pack — Ana Sayfa yenilemesi: haftalık ritim + takvim gezintisi

> 2026-09-23 · Kaynak: [docs/23 UI/UX incelemesi](23-ui-ux-audit-proposal.md) ·
> Figma "UI keşfi 03 / Ritim + Takvim" (node 11-422; dışa aktarım:
> [ana ekran](assets/home-v2/figma-home.png), [ay görünümü](assets/home-v2/figma-month.png)).
> Figma **görsel hiyerarşi ve akış referansıdır**, birebir özellik listesi değil;
> içindeki sayılar örnektir.

## 0. Karar özeti

**Ne değişiyor, neden.** Ana Sayfa'da bugünün eylemi (antrenman kartı)
büyük seri kartının ve dört kutulu "Bu Hafta" ızgarasının arasında kalıyor;
haftayı ve geçmiş günleri görmek için İlerleme sekmesine gitmek gerekiyor.
Yeni sıra: **başlık → haftalık şerit → bugünün eylemi → ritim → günün kaydı**.
Haftalık şerit oklarla haftalar arasında gezer, başlığına dokununca ay
görünümü açılır, bir güne dokununca o günün kayıt özeti açılır.

**Önerilen seçenek.** Yalnız arayüz değişir; hesaplar mevcut
sağlayıcılardan gelir (`weeklyStreakProvider`, `last30WorkoutStatsProvider`,
`monthActivityProvider`, `todayRoutineProvider`, `activeDraftProvider`).
Elenen: takvimi İlerleme'deki halkalı takvimle birleştirmek (halkalar
hedef uyumu anlatıyor, ana sayfa takvimi "ne yaptım" anlatıyor — iki ayrı iş;
İlerleme'deki takvim olduğu gibi kalır).

**Gerçek veriye etkisi.** Yok. Şema, tablo, senkron değişmez. Geri dönüş:
kod geri alınırsa eski ekran döner, veri etkilenmez.

**Samet'ten gereken kararlar.** Yok — kapsam ve kurallar 2026-09-22 ürün
kararında verildi (seri/haftalık hedef/son 30 gün kalır; seri haftalık hedef;
dinlenme günü seriyi bozmaz; geçmiş gün bugünün eylemini değiştirmez).
Bilinçli farklar §4'te; beğenilmeyen olursa tek tek geri alınır.

**Nasıl doğrulanacak.** Saf hesaplar için birim testi (hafta günleri,
gün işareti, seri durumları); şerit için widget testi (geri git → "Bugüne dön"
görünür, eylem kartı değişmez). iOS simülatöründe ve Android telefonda
önce/sonra ekran görüntüsü; boş veri · dinlenme günü · aktif seans · geçmiş
hafta durumları tek tek görülür.

## 1. Ekran / bileşen eşlemesi

| Figma bölümü | Bugün (kod) | Yeni | Veri kaynağı |
|---|---|---|---|
| Başlık "SALI · 22 EYLÜL / Bugün" + profil | `_Header` (BUGÜN + tarih) | `_Header` — üstte gün/tarih, altta "Bugün"; sağda profil düğmesi | — |
| Haftalık şerit ‹ 21–27 Eylül › | yok | `WeekStrip` (yeni, `features/calendar/`) | `monthActivityProvider` (hafta iki aya taşarsa iki ay) |
| Ay görünümü (TAKVİM / Eylül 2026) | İlerleme'de halkalı `ActivityCalendar` | `CalendarScreen` — yeni rota `AppRoutes.calendar` | `monthActivityProvider` |
| Seçili gün kayıtları | `_DaySummarySheet` (özel sınıf) | `DayRecords` — hem ay görünümünde hem şeritten açılan panelde | `DayActivity` |
| "SIRADAKİ ANTRENMAN" kartı | `_PrimaryActionCard` | aynı, **önüne "Seansa dön"** durumu eklenir | `activeDraftProvider`, `todayRoutineProvider` |
| "RİTMİN" kartı | `_MomentumHero` + `_WeekDashboard` (2×2) | `_RhythmCard` — seri, bu haftanın ilerleme çubuğu, son 30 gün üçlüsü, "Haftalık değerlendirme" bağlantısı | `weeklyStreakProvider`, `last30WorkoutStatsProvider` |
| "Günün kaydı / Beslenme ›" | `_CompactNutrition` | aynı kart, üstüne bölüm başlığı | `todayNutritionProvider` |
| (Figma'da yok) | İçgörü, Su + Kilo | **kalır**, günün kaydının altında | mevcut |

## 2. Durum planı

**Eylem kartı** (öncelik sırasıyla, ilk tutan kazanır):
1. **Aktif seans** (taslak var, veri içeriyor) → "Seansa dön" kartı; başka
   başlatma düğmesi yarışmaz. Dokununca `workoutActiveResume`.
2. **Antrenman günü** (bugüne planlı rutin) → "BUGÜNÜN PLANI / {rutin}" + "Antrenmanı başlat".
3. **Dinlenme günü** (plan var, bugün boş) → mevcut dinlenme kartı + sıradaki rutin + "Yine de antrenman yap".
4. **Plan yok** → "Antrenmana başla".

Eylem kartı **yalnız bugüne bakar**; şeritte ya da ay görünümünde seçilen
gün onu değiştirmez (ayrı durum, ayrı widget).

**Ritim kartı** (seri kuralı `streak_calc.dart`, değişmedi):

| Durum | Başlık | Alt satır |
|---|---|---|
| Hiç antrenman yok | Ritmini başlat | Haftalık hedef: {hedef} antrenman · dinlenme günleri seriyi bozmaz |
| İlk hafta, başlandı | İlk haftanı tamamla | Bu hafta {x}/{hedef} · hedefe {k} kaldı |
| Seri sürüyor, hafta devam | {N} haftadır ritimdesin | Bu hafta {x}/{hedef} · hedefe {k} kaldı |
| Seri sürüyor, hafta tamam | {N} haftadır ritimdesin | Bu haftanın hedefi tamam ({x}/{hedef}) |
| Önceki hafta kaçtı (geçmişte kayıt var) | Yeni seri başlıyor | Geçen haftanın hedefi tamamlanmadı · bu hafta {x}/{hedef} |

- Devam eden hafta tamamlanmadı diye kazanılmış seri **sıfırlanmaz** (mevcut hesap).
- Son 30 gün üçlüsü her durumda görünür (boşsa 0); dönem ve birim yazılı.

**Haftalık şerit / ay görünümü:**

| Durum | Davranış |
|---|---|
| Bu hafta | ‹ etkin, › pasif (gelecek hafta yok). "Bugüne dön" görünmez. |
| Geçmiş hafta | "Bugüne dön" görünür; eylem kartı değişmez. |
| Gün işareti | antrenman günü = dolgulu daire + yeşil nokta; yalnız beslenme/su kaydı = gri nokta; bugün = birincil renk dolgu; gelecek gün = soluk, dokunulmaz. |
| Güne dokun (şerit) | alt panel: o günün kayıtları (`DayRecords`). |
| Başlığa dokun (şerit) | ay görünümü, o haftanın ayında ve o gün seçili açılır. |
| Ay görünümü | ‹ › aylar arası; gelecek ay pasif. Seçili gün altında kayıtları; antrenman satırında "Aç" antrenman geçmişini açar (seans başına ayrıntı ekranı yok; özet ekranı bitiş kutlaması). Seçili gün bugün değilse "Bugüne dön". |
| Boş gün | "Bu gün için kayıt yok." — kırmızı/başarısız işareti yok. |
| Yükleniyor / hata | şerit iskeleti; hata olursa işaretsiz gün numaraları (gezinme çalışır). |

## 3. Kapsam dışı

Beslenme kartının yeniden tasarımı, alt gezinme çubuğu, İlerleme sekmesindeki
halkalı takvim, Antrenman sekmesi. Dört kutulu "Bu Hafta" ızgarasındaki hacim
değişimi ve protein uyumu Haftalık Değerlendirme'de zaten var; ana sayfadan
kalkar, bağlantısı ritim kartında durur (docs/23 §3.3).

## 4. Figma'dan bilinçli farklar

1. **İçgörü, Su ve Kilo kartları kalıyor.** Figma'da yoklar; kaldırmak mevcut
   özelliği (+250 ml hızlı ekleme dahil) silmek olurdu. Günün kaydının altına iner.
2. **Günün kaydı**: Figma yalnız enerji + protein gösteriyor; mevcut halka +
   üç makro kartı kalıyor (beslenme kartı bu işin kapsamı dışında).
3. **Profil düğmesi baş harf ("SO") değil ikon** — profilde ad alanı yok,
   uydurulmaz.
4. **Antrenman satırı "6 hareket" yerine set sayısı** gösteriyor — gün verisinde
   hareket sayısı değil set sayısı var; ek sorgu eklemek yerine var olanı yazıyoruz.
5. **Lejant**: Figma'da iki nokta da gri; burada antrenman noktası yeşil
   (`semantic.success`), kayıt noktası gri — ayırt edilebilsin diye.
6. **Kart kenarındaki mor şerit** ritim kartında yok — cam kart dili korunuyor
   (docs/08); vurgu ilerleme çubuğunda.
7. **Seansa dön durumu** Figma'da yok; docs/23 §3.2 gereği eklendi.
8. **"SIRADAKİ ANTRENMAN" dış etiketi yok** — etiket kartın içinde ("BUGÜNÜN
   PLANI" / "DEVAM EDEN SEANS"); dinlenme günü kartının üstünde "sıradaki
   antrenman" yazması yanlış olurdu.
9. **Aynı gün birden çok seans** "Push day +1" diye yazılır — set ve hacim o
   günün toplamı; Figma tek seanslı günü gösteriyor.
10. **Ay görünümünde "Aç"** antrenman geçmişini açar, seans ayrıntısını değil
    (seans başına ayrıntı ekranı yok).

## 5. Doğrulama (2026-09-23)

- **Testler:** `calendar_logic_test` (hafta günleri, yaz saati, gün işareti,
  6 ritim durumu), `home_week_strip_test` (geçmiş hafta → "Bugüne dön",
  ay sınırı etiketi, gelecek gün dokunulmaz, kayıtsız gün, eylem kartı
  değişmez, aktif seans, boş veri, dinlenme günü), `streak_calc_test`
  (önceki kayıt bayrağı). Toplam 604 yeşil, `flutter analyze` temiz.
- **iOS simülatörü (iPhone 17, gerçek hesap, yalnız okuma):** önce
  [before-ios-top](assets/home-v2/before-ios-top.png) → sonra
  [üst](assets/home-v2/after-ios-top.png), [alt](assets/home-v2/after-ios-bottom.png),
  [geçmiş hafta](assets/home-v2/after-ios-past-week.png),
  [gün paneli](assets/home-v2/after-ios-day-sheet.png),
  [ay görünümü](assets/home-v2/after-ios-month.png),
  [koyu tema](assets/home-v2/after-ios-dark.png). Şeritteki antrenman
  noktaları veritabanındaki seans günleriyle birebir (14, 16, 22 Eylül).
- **Doğrulamada bulunan yan hata:** eşitlemeyle inen satırlar ekran
  akışlarını uyandırmıyordu (eski ızgara "0/1", seri kartı "1/1" diyordu).
  Ayrı commit'te düzeltildi (`1e36dd9`).
- **Android telefon:** bekliyor (cihaz bağlı değildi).
