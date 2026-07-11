# 17 — Kapsamlı İyileştirme Analizi (Özellik · Teknik · Monetizasyon · Pazar)

> **Tarih:** 2026-07-11 · **Hazırlayan:** Claude (kod envanteri + web araştırması)
> **Girdi:** lib/ tam envanter, CODE_REVIEW.md (2026-07-04), NEXT_TASKS.md, memory monetizasyon araştırması (2026-06-30), güncel web araştırması (Hevy/Strong/hibrit pazar, retention pattern'leri)
> **Durum:** Öneri — Samet önceliklendirecek

---

## 1. Mevcut Durum Envanteri (koddan)

- **Stack:** Flutter · Riverpod 2.6 · drift/SQLite şema v8 (kayıpsız migration zinciri) · go_router `StatefulShellRoute.indexedStack` · Supabase (manuel bulut yedek + auth) · EN/TR i18n (UI tamam, içerik Faz B) · 84 dosya / ~38.5K satır / 137 test / analyze 0.
- **Ekranlar (18):** 4 tab (Ana Sayfa, Antrenman, Beslenme, İlerleme=BodyMetrics) + Onboarding V2, aktif seans (+devam/geçmişe giriş), özet, geçmiş, rutin oluşturucu/önizleme, kütüphane (1022 hareket) + detay (Nasıl/Geçmiş/Grafik-e1RM/Rekorlar), Yemekler, barkod+OFF araması, Export, Cloud, Profil, Ayarlar, Bildirimler, Atıf.
- **Tablolar (13):** workout (sessions/sets/routines/routine_exercises/exercises), nutrition (foods/food_logs/recipe_items/water_intake), body (body_measurements/progress_photos), user_profile, achievements.
- **Mevcut retention mekanikleri:** basit streak, ghost/PREV, dinlenme günü zekası, su takibi, coach mark'lı onboarding, dinlenme + günlük bildirimler.
- **Kanıtlı sorunlar:**
  - `android/app/build.gradle.kts:30,39` — targetSdk 34 + debug imza (H-04 duruyor, yayın engeli)
  - Manuel `ref.invalidate/refresh` **58 çağrı**, drift `watch()` stream **0** (H-05 yapısal borç büyümüş)
  - `Achievements` tablo + DAO var, **ekran yok** (ölü kod — P-14 kararı bekliyor)
  - `progress_photos` tablosu var; foto çekme/karşılaştırma UI akışı **doğrulanmalı** (görülmedi)
  - H-01 (gün sınırı çift sayım) **düzeltilmiş** (nutrition_dao yorumu "bitiş HARİÇ")
  - C-01 (restore veri kaybı riski) durumu **doğrulanmalı**

---

## 2. Özellik & UX Önerileri — EN YÜKSEK ÖNCELİK

### 🔴 Kritik bulgu: streak matematiği yanlış
`home_providers.dart:41-77` ardışık **takvim günü** sayıyor. Haftada 3-4 gün antrenman yapan herkesin serisi her dinlenme gününde kırılır — uygulamanın kendi "dinlenme günü zekası"yla çelişiyor. Kullanıcı plana sadıkken cezalandırılıyor → streak motivasyon yerine hayal kırıklığı üretir (araştırma: yanlış kurgulanan streak "streak anksiyetesi" yaratır ve gamification etkisini sıfırlar).

| # | Öneri | Neden / hangi ihtiyaç | Efor |
|---|-------|----------------------|------|
| 1 | **Haftalık hedef bazlı seri** — "bu hafta 4/4" → hafta serisi; dinlenme günü kırmaz | Mevcut serinin düzeltilmesi; streak mekaniği doğru kurulunca alışkanlık oluşumunu ~%40 artırıyor | Düşük |
| 2 | **PR kutlaması** — set girildiğinde e1RM/ağırlık rekoru anında rozet; özet ekranda "N yeni rekor" | Veri hazır (Rekorlar sekmesi); anlık geri bildirim = Hevy/Strong'un en sevilen ânı | Düşük |
| 3 | **Achievements'ı canlandır veya tabloyu sil** — 20-30 rozet; ödül yoğunluğunu 30-90 gün penceresine kur (ilk 2 haftaya değil — habit konsolidasyonu orada kırılır) | Ölü kod kararı (P-14) + uzun vadeli retention | Orta |
| 4 | **Haftalık özet** — Pazar akşamı bildirim → hacim, PR, kalori uyumu, kilo trendi | 7. gün retention kancası; bildirim altyapısı hazır | Orta |
| 5 | **Seansta "nasıl yapılır"** (NEXT_TASKS #2) | Veri hazır; seans kartına info | Düşük |
| 6 | **Android home-screen widget** — seri + bugünkü antrenman/kalori | Açmadan görünürlük = en ucuz günlük dönüş tetikleyicisi | Orta |
| 7 | **Progress photos akışını tamamla** + ölçüm karşılaştırma | Tablo var; görsel ilerleme = cut kitlesinin 1 no'lu motivasyonu | Orta |
| 8 | **AI foto ile yemek loglama** (Gemini — Q-01 kararı var) | 2026'da beslenme app'lerinde standartlaşıyor; premium kancası | Yüksek |
| 9 | **30 gün kişisel challenge** (sosyalsiz, kendine karşı) | Zaman sınırlı challenge kopan kullanıcıyı geri getirmede en güçlü mekanik; "social asla" kararıyla uyumlu | Orta |

Bilinçli önerilmeyenler: leaderboard/sosyal (Samet kararı "asla" + sosyal karşılaştırma demoralize edebiliyor), adım sayar (backlog'da doc-first bekliyor).

---

## 3. Teknik Mimari & Performans — İKİNCİ ÖNCELİK

1. **Manuel refresh → drift `watch()` stream'leri (en büyük refactor).** 58 invalidate → reaktif stream'ler; "veri girdim, öbür ekran güncellenmedi" bug sınıfı kökten biter. Kademeli: önce Ana Sayfa dashboard provider'ları, sonra Beslenme günlük toplamları. Etki en yüksek / efor orta.
2. **Yayın engeli (H-04):** release keystore + targetSdk 35 (Play, Ağu 2025'ten beri 35 istiyor). Yarım gün, kod değil yapılandırma.
3. **C-01 restore güvenliği:** geri yükleme öncesi mevcut DB emniyet kopyası + WAL sıralaması — düzeltildi mi doğrula; değilse veri kaybı senaryosu açık.
4. **Blur bütçesi:** SM A075F testi bekliyor; test edilmeden yeni blur yüzeyi ekleme. Fallback hazır (`GlassCard.blur=false` + navbar sigma).
5. **SQLCipher (T-003..007):** sağlık verisi; gizlilik politikasında "şifreli" diyebilmek için yayın öncesi iyi zamanlama.
6. **Error handling katmanı (T-010..013):** hâlâ yok; restore/cloud/OFF ağ hatalarında kullanıcıya tutarlı mesaj için gerekli.

---

## 4. Monetizasyon — ÜÇÜNCÜ ÖNCELİK

Benchmark (2026-06-30 araştırması + 2026-07-11 doğrulaması): Hevy Pro **$2.99/ay · $23.99/yıl · $74.99 ömür**; freemium dönüşüm %2-5; kullanıcıların ~%68'i yıllık alıyor. Samet anti-hedefi: reklam. Bu, Hevy'nin kanıtlanmış **reklamsız-freemium** modeliyle örtüşür:

- **Free (cömert):** tüm loglama + 1022 hareket + beslenme + yerel yedek. Cömert free = Hevy'nin Strong'u yenme sebebi.
- **Pro (yıllık öncelikli, TR fiyat lokalizasyonu):** bulut senkron/otomatik yedek + gelişmiş analitik (kas grubu hacim dağılımı, e1RM karşılaştırma) + AI (foto loglama, ileride koç) + sınırsız rutin.
- **Ömür boyu seçeneği** sun (Hevy'de tercih sebebi).
- **Sıra:** önce yayın + organik kullanıcı; ilk sürümde paywall yok, kullanım ölçümü altyapısı kur → fiyat/paket kararını veriyle ver.

---

## 5. Rakip Analizi & Konumlandırma — DÖRDÜNCÜ

| Rakip | Durum (2026) | Fit Pack'e göre |
|-------|--------------|-----------------|
| **Hevy** | Şub 2026: Hevy Trainer (adaptif AI programlama, Pro'ya dahil) + HevyGPT | Antrenman-only; beslenme yok |
| **Strong** | v6.2 (Mar 2026) bakım sürümü; AI yol haritası yok, gelişme durgun | Pazar payı kayıyor |
| **MacroFactor** | En iyi makro-koç algoritması | Antrenman takibi yok |
| **Ellim/Nutrola/Vora** | Yeni hibrit oyuncular (AI foto loglama, wearable) | Hepsi bulut-bağımlı |

**Boşluk:** kullanıcılar 2-3 app kullanıyor ve tek app istiyor. **Fit Pack ayrışması:** *offline-first + gizlilik* (hesapsız çalışır, veri cihazda) + antrenman+beslenme+su+vücut hibrit kapsam + EN/TR. **Geride:** AI foto loglama, adaptif programlama, wearable (bilinçli V3), sosyal (bilinçli asla).

Kaynaklar: setgraph.app, sensai.fit, prpath.app (Hevy/Strong 2026), ellim.app, nutrola.app (hibrit pazar), orangesoft.co, getfitcraft.com (retention/gamification benchmark'ları).

---

## İlk 3 Somut Adım

> **Samet kararı (2026-07-11):** Yayın paketi (keystore/targetSdk/gizlilik URL) uygulama
> hazır olana kadar GÜNDEM DIŞI — önerilmeyecek, konuşulmayacak.

1. **Seri düzeltmesi + PR kutlaması** (1 oturum) — `workoutStreakProvider` haftalık-hedef bazlıya + seans içi rekor rozeti. En düşük efor / en yüksek his farkı.
2. **Reaktif veri katmanı dilim 1** (1-2 oturum) — Ana Sayfa dashboard'unu drift `watch()` stream'lerine geçir; kalıbı kanıtla, ekran ekran yay.
3. **Seansta "nasıl yapılır"** (1 oturum) — NEXT_TASKS #2; veri hazır, seans hareket kartına info erişimi.
