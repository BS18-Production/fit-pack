# 54 — Ana sayfa: "Bugün" hiyerarşisi (Faz 3A)

18 Ekim 2026 · Kaynak: deneyim araştırması 06 §"Bugün hiyerarşisi" ve
"Belirlenimci bağlam kuralları", 12 v2 §4, review/A2 ve A4. Durum: **öneri,
Samet onayı bekliyor.**

## Karar özeti

**Samet kararı (18 Ekim 2026):** D1 evet, D2 evet — önerildiği gibi; kodlama başladı.

- Ana sayfada sabit **beş katman** olur:
  1. Başlık.
  2. Tek birincil görev.
  3. İki bağlam satırı.
  4. Günlük kayıt.
  5. Dönemsel kartlar.

  Katmanların yeri değişmez. Duruma göre yalnız birincil görevin içeriği değişir.
- Birincil görevi tek bir **saf fonksiyon** seçer: `todayTask(durum) → görev`.
  Öncelik tablosu (§2) bu fonksiyonun testidir. Bugün bu karar dört ayrı
  kartta dağınık duruyor ("Haftan hazır", "İlk hafta", birincil kart, Bugün
  satırları).
- **Antrenman bugün bittiyse** birincil görev artık "Başlat" değil, "Seans
  kaydedildi · özeti gör" olur (A2: tekrar başlatma ana eylem kalıyordu).
- **Ana sayfadan beslenme kaydı:** "Öğün günlüğü" kartındaki dört öğün düğmesi
  kalır. Bugün satırına doğrudan "+ Ekle" düğmesi gelir.
- **Kaldırılan kart yok.** Yalnız sıra ve görünme koşulu değişir. Verisi olmayan
  kartlar Faz 1a'daki gibi gizli kalır.
- Şema, senkron ve rota değişmez. Kod 1–2 oturum, cihaz turu 1 akşam.

## 1. Bugünkü durum (Faz 1a sonrası)

Sıra:
1. Başlık.
2. Birincil kart.
3. Bugün satırları.
4. Hafta şeridi.
5. "Haftan hazır".
6. Beslenme özeti.
7. İlk hafta kartı.
8. Öğün günlüğü.
9. Her zamanki öğün.
10. Veri varsa: aktivite grafiği, ritim, "Verime sor", içgörü.
11. Sağlık satırı.

(`home_screen.dart:76–103`.)

Sorunlar:
- **Antrenman bittikten sonra** birincil kart yine "Antrenmanı başlat" diyor.
- **Pazar günü** "Haftan hazır" ve birincil kart iki ayrı çağrı yapıyor. İlk
  haftada buna "İlk hafta" kartı da ekleniyor; aynı anda üç çağrı oluyor
  (06'nın çakışma kuralı: aynı anda tek birincil).
- **Ana sayfadan beslenme kaydı** öğün günlüğünde, ilk ekranın altında.

## 2. Birincil görev öncelik tablosu

| # | Koşul | Görev | İkincil satır |
|---|---|---|---|
| 0 | Taslak okunuyor | İskelet (yeni "Başlat" sunulmaz) | — |
| 1 | Taslak okuma hatası | Tekrar dene (Faz 1a) | — |
| 2 | Süren seans var | **Seansa dön** · hareket, set ve mola kalanı | Beslenme satırı |
| 3 | Bugün antrenman bitti | **Seans kaydedildi** · özeti gör | Beslenme satırı + "+ Ekle" |
| 4 | İlk antrenman hiç yok (yeni hesap) | Program seç / sıradaki ilk antrenman | İlk hafta adımları |
| 5 | Bugüne planlı rutin var | **Bugünkü antrenman** · Başlat | İlerleme satırı (docs/50) |
| 6 | Planlı gün yok, döngü var | **Sıradaki** · rutin adı | İlerleme satırı |
| 7 | Bugün planlı dinlenme | **Bugün dinlenme** (bilgi) | Beslenme satırı |
| 8 | Pazar akşamı ve hafta özeti hazır | Haftan hazır, birincilin **altında** ikincil kart | — |

Kurallar:
- Tablo yukarıdan aşağı okunur; ilk eşleşen satır kazanır.
- "Haftan hazır" ve "İlk hafta" hiçbir zaman birincil olmaz; birincilin
  altında tek satırlık kart olarak durur.
- Kaçırılmış gün için "dün kaçırdın" baskısı yok (docs/51 bildirim tarafında
  kalır).

## 3. Katmanlar

1. **Başlık:** Tarih ve profil. Karşılama cümlesi tek satıra iner; ilk ekranda
   yer kazanılır.
2. **Birincil görev:** §2'ye göre içerik.
3. **Bağlam satırları (en çok iki):** antrenman satırı ve beslenme satırı.
   Beslenme satırının sağında "+ Ekle" düğmesi olur; saate göre öğün varsayılan
   gelir, kullanıcı değiştirebilir.
4. **Günlük kayıt:** hafta şeridi, beslenme özeti (ilk günde tek satır), öğün
   günlüğü, her zamanki öğün.
5. **Dönemsel:** aktivite, ritim, "Verime sor", içgörü, sağlık. Hepsi kayıt
   oluşunca görünür.

## 4. Test ve kabul

- `todayTask` için birim testi: 9 koşul ve çakışmaları (Pazar + ilk hafta +
  süren seans gibi).
- Widget testi: her koşulda tek birincil kart. 393 ve 320 genişlikte birincil
  görevin eylem düğmesi ilk ekranda ve alt menünün üstünde.
- Erişilebilirlik kılavuz testi (`app_a11y_guidelines_test`) geçer.
- Cihaz:
  - Samet'in bir haftalık kullanımı: "sonraki eylemi 5 saniyede bul".
  - Berna ile yeni hesapta ilk gün akışı.

## 5. Samet'ten karar

- **D1:** Antrenman bittikten sonra birincil görev "Seans kaydedildi · özeti
  gör" olsun mu? (Önerim: evet. "Yine de antrenman yap" ikincil bağlantı olarak
  kalır.)
- **D2:** Beslenme satırına "+ Ekle" konsun mu? (Önerim: evet. Öğün saate göre
  seçilir.)
