# 55 — Antrenman sürerken küçült (Faz 3B, P07b)

18 Ekim 2026 · Kaynak: review/A6 §2.2 (mimari taslak ve 14 senaryo), docs/53
(kaydet-çık sözleşmesi), Codex ikinci inceleme R2. Durum: **öneri, Samet onayı
bekliyor.**

## Karar özeti

- **Ne:** Antrenmandan çıkmadan başka sekmeye geçilebilir. Seans arka planda
  sürer:
  - Süre işler.
  - Mola alarmı zamanında çalar.
  - Kilit ekranı kartı ve düğmeleri çalışır.

  Alt menünün hemen üstünde ince bir **seans şeridi** görünür, örneğin
  "Bench · Set 3/4 · Mola 1:12". Şeride dokununca seansa dönülür.
- **Nasıl:** Seansın sahibi ekran olmaktan çıkar; uygulama ömrü boyunca yaşayan
  bir `ActiveSessionController` (Riverpod Notifier, autoDispose **değil**) olur.
  Ekran yalnız gösterir ve komut gönderir. Bugünkü taslak, devam rotası ve
  kilit ekranı köprüsü bu denetleyiciye bağlanır.
- **Neden şimdi değil, sonra:** Bu, projenin en riskli refaktörü.
  - Sayaçlar, ses, iki platformun kilit ekranı yolu ve taslak tek yere taşınır.
  - 470 satırlık mevcut test bu yeni yapıya taşınır.

  docs/53 "kaydet ve çık" bugün aynı ihtiyacın çoğunu karşılıyor (kayıp yok,
  geri dönüş tek dokunuş). Önerim: Samet "kaydet ve çık"ı **iki hafta**
  kullansın. Molada beslenmeye bakmak gerçekten sık oluyorsa bu iş yapılsın.
- **Bedel:**
  - Kod 2–4 oturum.
  - Cihaz turu 2–3 akşam: iOS ve Android'de 14 senaryo.
  - Şema ve senkron değişmez. Taslak biçimi aynı kalır.

## 1. Mimari (A6 §2.2'den, karar hâline getirildi)

1. **Tek sahip:** `ActiveSessionController`. Durumu:
   - Seans (hareketler ve setler).
   - Başlangıç ve son set anı.
   - Mola bitiş anı.
   - Rutin bağı.

   Değişken model korunur; değişiklikler `revision` sayacıyla yayınlanır.
2. **Komutlar denetleyicide:** tamamla/geri al, ±, set türü, set ekle/sil,
   hareket ekle/taşı/sil, mola ±15/atla, bitir, sil. Kilit ekranındaki
   `setKey` koruması (`active_session_screen.dart:190–218`) aynen taşınır.
3. **Zaman:** Denetleyicide saniyelik sayaç yok. Süre başlangıçtan, mola bitiş
   anından türetilir. Saniyelik çizimi yalnız görünen widget (ekran ya da
   şerit) kendi küçük sayacıyla yapar. Böylece çift sayaç hatası yapısal olarak
   imkânsız olur.
4. **Metinler:** Kilit ekranı ve bildirim metinleri `context` yerine
   `lookupAppL10n(locale)` ile alınır (bugün `AppL10n.of(context)`:
   `:293, :836, :182`).
5. **Kilit ekranı:** İşleyici uygulama açılışında bir kez denetleyiciye
   bağlanır; ekran kapalıyken de eylem uygulanır. Süreç ölmüşse bugünkü
   davranış kalır: eylem reddedilir, kart kaldırılır, açılışta taslaktan kurulur.
6. **Şerit:** `AppShell` içinde, alt menünün üstünde. Sekme listelerinin alt
   boşluğu şerit yüksekliği kadar artar. Kök navigatördeki sayfalarda (Profil,
   Ayarlar, Besinler) şerit görünmez. → **K-1**
7. **Rota:** `/workout/active/:routineId`, denetleyicide seans varken yeni seans
   kurmaz; "Süren seansa dön / Onu bitir ve yenisini başlat" sorar. İki seans
   yarışını denetleyici önler.
8. **Ekran uyanık kalma:** Yalnız seans ekranı görünürken. Küçükken telefon
   uyuyabilir.
9. **Hesap değişimi:** `account_switch.dart` ve taslak `clearCount` mekanizması
   denetleyiciyi de sıfırlar.
10. **Geçmiş kayıt modu** (`manualDate`) denetleyiciye alınmaz, ekran-yerel
    kalır.

## 2. Geçiş planı (tek dalda, adım adım yeşil)

1. Denetleyici + birim testleri (komutlar ve zaman). Ekran henüz eski.
2. Ekran denetleyiciyi okur; eski durum alanları silinir. Mevcut 470 satırlık
   test yeni yapıda geçer.
3. Kilit ekranı ve mola sesi denetleyiciye taşınır.
4. Şerit ve "küçült" düğmesi. Çıkış penceresine "Küçült" eklenir; "Kaydet ve
   çık" ile "Sil ve çık" kalır.
5. 14 senaryoluk matris iOS ve Android'de (A6 §2.2 tablosu). Hepsi geçmeden
   main'e alınmaz.

## 3. Riskler

- **Çift kaynak dönemi** (adım 2): Ekran ve denetleyici aynı anda yazarsa veri
  kaybı olabilir. Önlem: adım 2 tek commit; ekranın durum alanları aynı
  commit'te silinir.
- **Bitirirken gelen kilit ekranı eylemi.** Önlem: bitirme sırasında
  denetleyici "kapanıyor" durumundadır ve eylem reddedilir.
- **iOS ön planda mola bitişi:** Ekran kapalıyken uygulama içi ses yolu yoktur.
  Ön planda yerel bildirim gösterilmesi gerekir. Cihazda doğrulanmalı.
- **Android ön plan servisi ve bildirim sırası:** Cihazda doğrulanmalı.

## 4. Samet'ten karar

- **K-1:** Şerit yalnız dört ana sekmede mi görünsün (önerim), yoksa her sayfada
  mı?
- **K-2:** Bu iş şimdi mi yapılsın, yoksa "kaydet ve çık" iki hafta denendikten
  sonra mı? (Önerim: sonra.)
