# 26 — Beslenme kaydı alışkanlığı

> **Durum:** ✅ Kodlandı (2026-09-30) · emülatörde doğrulandı (Dev, test hesabı)
> **Yazan:** Claude · **Kaynak:** Samet: "kullanıcıyı her gün besin girmesi için
> nasıl motive ederiz?" → öneriler → "hayata geçir".

---

## 0. Karar özeti

**Ne değişti, neden.** Beslenme takibini bırakmanın ana sebebi kayıt yükü;
hatırlatmanın etkisi var ama sınırlı; günlük seri tek kaçan günde sıfırlanınca
kaygı yaratıp bıraktırıyor (kaynaklar §4). Sıra buna göre:

1. **Her zamanki öğün — tek dokunuş.** Son 14 günde aynı içerikle en az 2 gün
   girilmiş öğün, saatine uygun olarak (kahvaltı <11, öğle <16, ara <18,
   akşam) Ana sayfada ve Beslenme'de "Ekle" kartı olarak çıkar. O öğün bugün
   girildiyse ya da "Şimdi değil" dendiyse görünmez. Ekle = kullanıcı onayı
   (kendiliğinden kayıt yok); "Geri al" tam eklenen satırları siler.
2. **Hızlı giriş — kcal + protein.** Besin ekleme panelinde. Değerler özel
   besin olur (`source = 'quick'`, 1 porsiyon = 100 g), listede kalır.
3. **Öğün hatırlatıcısı.** Kahvaltı/öğle/akşam; saat = kişinin o öğünü
   **genelde girdiği saatin medyanı + 60 dk** (son 21 gün, en az 3 örnek; yoksa
   10:30 / 14:00 / 20:30), öğün penceresine kırpılır. **O öğün bugün girildiyse
   bildirim gitmez.** İzin bağlam içinde istenir (Beslenme'deki öneri kartı ya
   da Ayarlar → Bildirimler); varsayılan kapalı.
4. **Haftalık kayıt hedefi — haftada 5 gün.** Günlük seri yerine: boş gün
   kopma sayılmaz. Ana sayfa ve Beslenme'de "Bu hafta 3/5 gün kayıt · 2 gün
   daha" + 5 nokta.

*Elenen:* günlük seri (kaygı/terk riski), otomatik öğün doldurma (onaysız
kayıt — veri doğruluğu kuralı), tekrar eden günlük bildirim ("girildiyse
gönderme" koşulu kurulamıyor).

**Gerçek veriye etkisi.** Şema değişmedi. Hızlı giriş normal özel besin +
kayıt üretir (senkron edilir). Hatırlatıcı ve "Şimdi değil" cihaz tercihi.

**Samet'ten gereken kararlar.**
1. ☐ Haftalık hedef 5 gün uygun mu? (Tek sabit: `weeklyLogGoalDays`.)
2. ☐ Hatırlatma "+60 dk" ve pencereler uygun mu? (`nutrition_habits.dart`.)
3. ☐ Ana ekran widget'ı (öneri 5) — ayrı iş, yerel Android kodu ister.

## 1. Hatırlatıcı nasıl kurulur

Tek seferlik bildirimler, bugün + 2 gün, öğün başına (id 20–28). Her
`food_logs` değişiminde (1 sn birleştirme), uygulama öne gelince ve ayar
değişince hepsi silinip yeniden kurulur (`app.dart` → `syncMealReminders`).
Böylece girilen öğünün bugünkü bildirimi düşer, saat alışkanlıkla kayar,
uygulama 1-2 gün açılmasa da hatırlatma sürer. Dokununca Beslenme açılır.

Saat kaynağı `food_logs.updated_at` (yerel tetikleyici ekleme anında
yazar); yalnız öğünün kendi gününde girilmiş kayıtlar — geçmişe sonradan
girilenler alışkanlık sayılmaz.

## 2. Dosyalar

- `lib/features/nutrition/nutrition_habits.dart` — saf mantık (test:
  `test/features/nutrition_habits_test.dart`).
- `nutrition_habit_providers.dart`, `nutrition_habit_widgets.dart` — kart,
  haftalık satır, hatırlatıcı önerisi.
- `meal_reminders.dart` — zamanlama; `NutritionDao.addFoodsToMealIds`,
  `deleteFoodLogs`, `quickAddLog`.

## 3. Doğrulama (emülatör, 2026-09-30)

28 Eylül'e hızlı giriş "Tavuk pilav 650 kcal / 32 g", 29'una aynı besin
aranarak → bugün (22:59) Beslenme'de "Her zamanki akşam yemeğin · 1 besin ·
650 kcal · 32 g protein" → Ekle → kart kalktı, "Akşam eklendi · Geri al",
haftalık satır 2/5 → 3/5. Hatırlatıcı "Aç" → `dumpsys alarm`: 1 ve 2 Ekim
10:30 / 14:00 / 20:30; bugün (akşam girildi, saatler geçti) yok.

## 4. Kaynaklar

- Kayıt yükü ve bırakma: [JMIR Formative 2022](https://formative.jmir.org/2022/2/e33603/PDF),
  [PMC8900900](https://pmc.ncbi.nlm.nih.gov/articles/PMC8900900)
- Hatırlatma etkisi: [JMIR mHealth 2020](https://doaj.org/article/018c7fb1116141d1a1c1aa09ad7aa3b3),
  [NCT07555262](https://clinicaltrials.gov/study/NCT07555262)
- Seri kaygısı: [Plotline](https://plotline.so/blog/streaks-for-gamification-in-mobile-apps),
  [HabitDoom](https://habitdoom.com/blog/streak-anxiety-habit-trackers)
