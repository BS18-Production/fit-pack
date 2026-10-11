# 40 — Sağlık entegrasyonu Faz 1b: akıllı tartıdan kilo

> **Durum:** Taslak — Samet kararı bekliyor (§5). Kod yok.
> **Tarih:** 2026-10-11 · **Sahip:** Claude-2 · **İnceleyen:** Codex
> **İlgili:** [docs/39 — adım](39-health-steps.md) · araştırma raporu §3, §7
> ([FitPack Sağlık Verisi Entegrasyonu](https://claude.ai/code/artifact/47047c15-7754-46fb-87df-294b300de472))

---

## 0. Karar özeti

**Ne değişecek.** Akıllı tartının Apple Sağlık'a / Health Connect'e yazdığı
**kilo ve vücut yağ oranı** Fit Pack'e kendiliğinden gelir. Elle kilo girmek
gerekmez; Ana Sayfa'daki son kilo, kilo eğilimi, haftalık değerlendirme, TDEE
(Toplam Günlük Enerji Harcaması) ve yorum katmanı (docs/36) bu değerleri kullanır.

**Neden.** Samet akıllı tartı kullanıyor. Sık ölçüm kilo eğilimini güvenilir
yapar; docs/36'daki kilo yorumu ≥2 ölçüm ve ≥14 gün istiyor, tartı bunu
kendiliğinden sağlar.

**Asıl risk ve çözümü.** Aynı gün hem elle hem tartıdan kilo gelirse bugünkü
hesaplar **satır başına** ortaladığı için haftalık ortalama kayar ve "tek
ölçüm trend değildir" koruması aşılır (Codex incelemesi). Çözüm: hesaplar tek
bir **"kullanılacak kilo serisi"**nden okur — **günde bir değer, elle giriş
kazanır**.

**Önerilen yol (A):** tartı ölçümleri **ayrı, yalnız cihazda duran** bir
tabloda (`health_samples`) tutulur; `BodyDao`'nun üç okuma sorgusu bu tabloyu
elle girilenlerle birleştirip tek seri döndürür. Bu sorguları kullanan beş
yer (Ana Sayfa, haftalık değerlendirme, panolar, vücut ölçümü ekranı, dışa
aktarma) **değişmeden** doğru seriyi görür.

*Elenen (B):* tartı ölçümünü mevcut `body_measurements` tablosuna "kaynak"
kolonuyla yazmak. Tek tablo daha basit görünür ama tablo Supabase'e
senkronlanıyor: yeni kolon = **sunucu göçü + senkron değişikliği**, sağlık
verisi buluta çıkar (rapor §7–8'e aykırı) ve iki cihaz aynı ölçümü iki kez
içe aktarabilir.

**Gerçek veriye etkisi.** Mevcut elle girilmiş ölçümler **değişmez**, buluta
gidişleri aynı kalır. Yeni tablo yalnız yerel; silinirse Sağlık'tan yeniden
okunur (iOS'ta sınırsız geçmiş, Android'de son 30 gün). Şema v15 → v16
(yeni tablo, yıkıcı değil — ADR-007).

## 1. Kurallar

| # | Kural | Neden |
|---|---|---|
| W-1 | Okunan türler: `WEIGHT`, `BODY_FAT_PERCENTAGE`. Başka tür yok | En az veri; BMI ve yağsız kütle hesaplanır, içe alınmaz (rapor §3) |
| W-2 | Her örnek platform kimliğiyle (`externalId` = HealthKit örnek UUID'si / Health Connect kayıt kimliği) **tek** tutulur; tekrar okuma kopya üretmez | Yeniden okuma ve öne gelişte tazeleme |
| W-3 | **Fit Pack'in kendi yazdığı** kayıtlar okunurken elenir (kaynak uygulama = Fit Pack) | Yankı (Faz 2'de Fit Pack Sağlık'a yazmaya başlarsa) |
| W-4 | Kullanılacak seri: **gün başına tek kilo**. O gün elle giriş varsa **elle giriş**; yoksa tartının **o günkü ilk** (sabah) ölçümü | Elle giriş kullanıcının bilinçli kaydı (MacroFactor ile aynı kural); sabah ölçümü en tutarlı |
| W-5 | Yağ oranı aynı kurala uyar (gün başına bir; elle giriş kazanır) | Tek doğruluk kaynağı |
| W-6 | Tartı ölçümü Fit Pack'te **silinmez, gizlenir** (gizlenen `externalId` defteri); Sağlık'taki kaydı kullanıcı Sağlık uygulamasından siler | Fit Pack başkasının verisini silmez |
| W-7 | `health_samples` **senkron dışı** (`syncRemoteExcluded`), hesap değişiminde silinir | Rapor §7: sağlık verisi buluta gitmez |
| W-8 | Dışa aktarma (CSV) yalnız elle girilenleri içerir | Sağlık verisi dışarı çıkmaz (docs/39 S-7) |
| W-9 | İlk bağlanışta geçmiş: iOS son 90 gün, Android 30 gün (ek "geçmiş" izni istenmez) | 8 haftalık yorum tabanı için yeterli; en az izin |
| W-10 | Vücut ölçümü ekranında tartı satırı kaynak simgesiyle görünür ("Sağlık · <uygulama>"); düzenlenemez, gizlenebilir | Kullanıcı neyin nereden geldiğini görür |

## 2. Uygulama (onaydan sonra)

1. **Şema v16** (şema kilidi gerekir — şu an asistan işinde): `health_samples`
   (id, `externalId` UNIQUE, tür, değer, birim, `measuredAt`, kaynak uygulama,
   `importedAt`, `hidden`), `onUpgrade` adımı + göç testi aynı commit'te.
2. `step_source.dart` yanına `body_source.dart` (W-1, W-3) + içe alma servisi
   (W-2, W-9); docs/39'daki gibi öne gelişte çalışır.
3. `BodyDao`: üç okuma sorgusu birleşik seri döndürür (W-4, W-5); eski ham
   sorgu yalnız vücut ölçümü ekranında ve dışa aktarmada.
4. Ekran: Ayarlar → Sağlık'a "Kilo ve yağ oranı" anahtarı (ayrı izin), vücut
   ölçümü ekranında kaynak simgesi + gizle (çeviri kilidi gerekir).

## 3. Doğrulama

- Birim: W-2 (aynı örnek iki kez → tek satır), W-4 (elle + iki tartı aynı gün
  → elle; yalnız tartı → ilk), W-3, W-7 (senkron kuyruğuna satır girmez).
- Göç testi v15 → v16, mevcut ölçümler aynı.
- Mevcut testler: haftalık değerlendirme, kilo eğilimi, yorum katmanı yeşil.
- iPhone: tartı ölçümü Sağlık'ta görünür → Fit Pack'te aynı gün aynı değer;
  elle giriş yapınca o gün elle değer kullanılır.

## 4. Açık riskler

- Tartı uygulaması Sağlık'a geç yazarsa (ör. tartı uygulaması açılmadan) Fit
  Pack o günü elle girilmemiş sanabilir → "son okuma" saati görünür.
- Birden çok tartı uygulaması aynı ölçümü yazarsa farklı `externalId` ile iki
  örnek gelir → W-4 yine günde tek değer seçer, sorun olmaz.

## 5. Samet'ten gereken kararlar

1. [ ] Yol A (ayrı yerel tablo, buluta gitmez) — önerilen. B istenirse sunucu
   göçü + senkron işi ve KVKK etkisi ayrıca yazılır.
2. [ ] Aynı gün kuralı: **elle giriş kazanır**, yoksa **sabah (ilk) ölçüm** — uygun mu?
3. [ ] Hangi tartı / uygulama? (ör. Withings Health Mate, Xiaomi Zepp Life,
   Eufy) — Sağlık'a kilo ve yağ oranı yazıyor mu, Samet kontrol etsin.
4. [ ] Şema kilidi asistan işinde (Claude-1). Faz 1b asistan birleşince mi
   başlasın, yoksa kilit sırası değişsin mi?
