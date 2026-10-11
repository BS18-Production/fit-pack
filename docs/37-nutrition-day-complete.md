# 37 — Beslenme günü tamamlandı (docs/21 #8)

> **Durum:** 🔧 Uygulanıyor — Samet onayı (öneriler) 2026-10-10; Codex incelemesi bekliyor. Aşama 1 dalda.
> **Tarih:** 2026-10-10 · **Sahip:** Claude · **İnceleyen:** Codex (derin:
> şema + senkron + hesap) · görsel doğrulama Codex'ten istenir (iOS Simulator)
> **Temel:** `main` · şema **v14** · docs/21 §2 #8
> **İlgili:** [docs/20 — Senkron v2](20-sync-v2.md) ·
> [docs/22 — Haftalık değerlendirme](22-weekly-review.md) ·
> [docs/36 — Verime sor yorum katmanı](36-verime-sor-yorum-katmani.md) ·
> [CONVENTIONS §3, §7b](../CONVENTIONS.md)

---

## 0. Karar özeti

**Ne değişecek, neden.** Uygulama bugün "kayıt girilmemiş" ile "az yenmiş"i
ayıramıyor: yarım girilmiş bir gün haftalık protein uyumunu düşük gösteriyor
(`dashboard_stats.dart:76-78`), haftalık değerlendirme bu yüzden "hedefi
tutturamadın" diyemiyor (docs/22 Samet kuralı). Asistanın "protein hedefimi
tutturdum mu?" cevabı da aynı nedenle yalnız "kaydedilen" diyebiliyor (Codex,
docs/35). Kullanıcı bir günü **"kaydım tamamlandı"** diye işaretler; o gün
artık "bilinen" gündür.

**Önerilen seçenek.** Yeni senkronlu tablo `nutrition_days`: gün başına **tek
satır**, kimliği **tarihten türetilir** (UUIDv5) — iki cihaz aynı günü
işaretlerse aynı satırı yazar, çift kayıt olmaz. İşaret kaldırma **silme
değil, durum güncellemesi** (`status = open`): senkron v2'de silinen kimlik bir
daha kullanılamıyor (docs/20 §5.3), silseydik o güne bir daha işaret
konamazdı. "Tamamlandıktan sonra değişti" bilgisi **saklanmaz, hesaplanır**
(o günün kayıtlarının son değişimi > tamamlanma anı).

*Elenenler:* (a) `food_logs`'a gün kolonu eklemek — gün kavramı satır başına
değil, boş günde satır yok; (b) rastgele kimlik + gün tekillik kısıtı — iki
cihazda çakışır, sunucuda ek kural ister; (c) yalnız yerel tutmak — iki cihazda
(telefon + simülatör aynı hesap) farklı sonuç verir.

**Gerçek veriye etkisi.** Yeni tablo; mevcut hiçbir satır değişmez. İşaretsiz
geçmiş günler "bilinmiyor" sayılır (eksik değil) — bugünkü davranışla aynı
sonuç. Şema v14 → **v15**, sunucuya yeni tablo + senkron listesine 13. tablo.

**Geri dönüş.** Yerel: v15 göçü yalnız tablo ekler (yıkıcı değil, ADR-007).
Sunucu: tablo boş kalırsa zararsız; geri almak için istemci tabloyu okumayı
bırakır. Üretime çıkış Samet onayıyla, senkron v2 yayın provası düzeniyle.

**Efor:** M (~1,5–2 gün): şema + sunucu + senkron kaydı + hesap + ekran + test.

---

## 1. Davranış

| Durum | Ne görünür |
|---|---|
| Bugün, işaretsiz | Beslenme ekranının altında **"Bugünkü kaydım tamamlandı"** düğmesi |
| Bugün, işaretli | ✓ "Kaydın tamam" + küçük "geri al" bağlantısı |
| İşaretli güne sonradan kayıt eklendi/silindi | İşaret **korunur**; "tamamlandıktan sonra değişti" notu (kullanıcı unuttuğunu ekliyor) |
| Geçmiş gün | Aynı düğme o günün görünümünde; geçmişi sonradan işaretlemek serbest |
| Takvim | Tamamlanmış günde küçük ✓ rozeti |
| Hiç işaretlenmemiş gün | **Bilinmiyor** — "eksik" denmez |

İşaretlemek kayıt girmeyi zorunlu kılmaz: hiç kayıt olmayan günü "tamam"
işaretlemek "o gün bir şey yemedim / kaydetmeyeceğim" anlamına gelir mi?
→ §6 Soru 1.

## 2. Veri modeli

**Yerel (Drift, şema v15):**

```
nutrition_days
  id            INTEGER PK autoincrement
  day           TEXT NOT NULL UNIQUE   -- 'YYYY-MM-DD', yerel takvim günü
  status        TEXT NOT NULL          -- 'complete' | 'open'
  completed_at  INTEGER NULL           -- ms; status=complete olduğu an
  + SyncColumns (uid, user_id, updated_at, sync_state, changed_at_ms, local_seq, server_rev)
```

- **Gün metin** (`YYYY-MM-DD`): saat dilimi kayması olmasın; sorgular
  `[başlangıç, bitiş)` kuralını gün metniyle karşılaştırarak uygular
  (CONVENTIONS §3).
- **Kimlik:** `uid = UUIDv5(fitpack ad alanı, "fitpack:nutrition_day:" + day)`.
  Kullanıcıdan bağımsız; sunucu anahtarı `(user_id, uid)` olduğu için iki
  kullanıcı çakışmaz (docs/20 §7.2 ile aynı mantık). Bugün `uid` SQL
  tetikleyicisinde `COALESCE(NEW.uid, <v4>)` ile üretiliyor
  (`sync_columns.dart`) → ekleme sırasında Dart'tan verilen belirlenimci `uid`
  korunur, tetikleyici değişmez. UUIDv5 (SHA-1, RFC 4122 §4.3) küçük bir yerel
  fonksiyon + RFC test vektörü; SHA-1 için `crypto` paketi (lock'ta varsa
  doğrudan bağımlılık yapılır). Aynı fonksiyon docs/20 Aşama 6'nın
  belirlenimci katalog kimliğinde de kullanılır.
- **Silinmez:** işaret kaldırma `status = 'open'`, `completed_at = NULL`.
  Satır sonsuza dek o gün için tek kalır. Hesap silme / hesap değişimi
  temizliği (docs/20 §7.3) diğer kullanıcı tablolarıyla aynı.
- **Tetikleyiciler:** senkron v2'nin 3 tetikleyici kalıbı (ekle/güncelle/sil
  izi) bu tabloya da (docs/20 §4.1, `capture` bayraklı).

**Sunucu (Supabase, yeni göç):** `nutrition_days` tablosu, `(user_id, uid)`
tekil, `changed_at_ms`/`server_rev`, `sync_guard` tetikleyicisi, RLS
("yalnız kendi satırların"), `sync_mark_deleted` tetikleyicisi (silme olmasa
da kalıp eksiksiz kalsın), `sync_delete` sabit tablo listesine ekleme. pgTAP
testleri Aşama 3/5 testlerinin kopyası.

**İstemci senkron kaydı:** `syncedTableNames`'e `'nutrition_days'`; gönderim/
çekme sırası (bağımlılığı yok, en sona); `SyncApply` alan eşlemesi.

**Çakışma:** satır bütün olarak LWW (`changed_at_ms`). Telefon "tamam",
simülatör sonra "geri al" → son yazan kazanır. Bu kabul edilebilir: tek
kullanıcı, iki niyetten sonuncusu.

## 3. Hesaplara etkisi

| Yer | Bugün | #8 sonrası |
|---|---|---|
| Haftalık değerlendirme beslenme (docs/22 A1) | Kayıt girilmiş günlerin ortalaması | Haftada ≥1 **tamamlanmış** gün varsa ortalama yalnız onlardan; metin "3 tamamlanmış gün (2 gün eksik olabilir, hesaba katılmadı)". Hiç yoksa bugünkü davranış + "günlerini tamamlandı işaretlersen daha doğru hesaplarım" |
| Ana ekran haftalık protein uyumu (`dashboard_stats.dart:76-78`) | Kayıtlı her gün | Tamamlanmış günler varsa yalnız onlar; yoksa bugünkü |
| Asistan `protein_goal` (docs/36) | "Kaydedilen" | Tamamlanmış günlerde "hedefi tutturdun / tutturamadın" **diyebilir**; diğerleri "bilinmiyor" |
| "Tamamlandıktan sonra değişti" | — | `max(food_logs.changed_at_ms of day) > completed_at` — hesap, kolon değil |

Hesap motoru saf Dart kalır; girdiye "tamamlanmış günler kümesi" eklenir.
Kurallar birim testleriyle kilitlenir (docs/22 kalıbı).

## 4. Uygulama aşamaları

| # | İş | Doğrulama |
|---|---|---|
| 1 | Şema v15 + göç testi (v14→v15), UUIDv5 + test vektörü, DAO (`markDay`, `unmarkDay`, `watchDays(range)`) | `migration_test`, DAO testleri |
| 2 | Senkron kaydı + tetikleyiciler + `SyncApply` | sync testleri (iki cihaz aynı gün → tek satır; işaret/geri al/işaret) |
| 3 | Sunucu göçü + pgTAP (`Fit Pack Dev`) | pgTAP yeşil, gerçek HTTP doğrulaması |
| 4 | Hesap: A1 + `dashboard_stats` | birim testleri (tamamlanmış var/yok, sonradan değişen gün) |
| 5 | Ekran: düğme, ✓, geri al, takvim rozeti, "sonra değişti" notu | widget testi + **Codex: iOS Simulator görsel kontrol** |
| 6 | Üretime çıkış: sunucu göçü önce, sonra istemci | Samet onayı; yayın provası (docs/20 §10.6 düzeni) |

Şema değişikliği, `schemaVersion` artışı, `onUpgrade` ve göç testi **aynı
commit'te** (CLAUDE.md).

## 5. Riskler

- **Eski istemci + yeni sunucu:** eski sürüm `nutrition_days`'i bilmez →
  çekmede yok sayar (tablo listesi sabit). Zararsız; doğrulanacak.
- **Yeni istemci + eski sunucu (göç uygulanmadan):** gönderim 404 → kalıcı
  hata sınıfı → yalnız bu tablo `sync_state = 2`, kuyruğun geri kalanı durmaz
  (docs/20 Aşama 7). Yine de sıra: önce sunucu.
- **Saat dilimi:** gün metni cihazın yerel takvimi; seyahatte gün kayabilir —
  tek kullanıcı için kabul, not edilir.

## 6. Samet'in kararları (2026-10-10 — "devam edebilirsin, bekleme": öneriler kabul)

1. ✅ Kayıtsız gün işaretlenebilir; ortalamaya **0 kalori** olarak girer (bilinçli beyan).
2. ✅ Akşam hatırlatması v1'de **yok**.
3. ✅ Tamamlanmış gün varsa haftalık değerlendirme **yalnız onları** kullanır; diğerleri "hesaba katılmadı" yazılır.

## 7. Uygulama durumu

- ✅ **Aşama 1** (dal `feat/nutrition-day-complete`): şema v15, `nutrition_days`,
  dondurulmuş `syncedTableNamesV14` (eski göç adımları), onarım rutininde
  "tablo yoksa atla", UUIDv5 (`lib/core/ids/deterministic_uid.dart`, `uuid`
  doğrudan bağımlılık), DAO (`markDayComplete`, `reopenDay`,
  `getCompletedDays`, `watchDay`, `changedAfterComplete`), göç testi v14→v15,
  DAO testleri. Tüm paket yeşil.
- ✅ **Aşama 2** (senkron): ek kod gerekmedi — senkron katmanı tablo
  listesinden ve sütun tiplerinden genel çalışıyor. İki cihaz testi
  (`test/features/nutrition_day_sync_test.dart`): aynı gün → sunucuda ve iki
  cihazda tek satır; geri al öteki cihaza `open` iner (silinmez); geri alınan
  gün yeniden işaretlenebilir.
- ✅ **Aşama 3** (sunucu): `supabase/migrations/20261010120000_nutrition_days.sql`
  — PK **(user_id, uid)** (gün kimliği kullanıcıdan bağımsız; diğer tablolarda
  PK hâlâ yalnız `uid`, docs/20 Aşama 6), `unique (user_id, day)`, RLS, yetki,
  imleç dizini, `sync_guard` + silme izi tetikleyicileri, `sync_delete` izin
  listesi 13 tablo. **`Fit Pack Dev`'e uygulandı (2026-10-11)**; pgTAP
  (`supabase/tests/nutrition_days.sql`) **9/9 yeşil** (2026-10-11): iki
  kullanıcı aynı gün aynı uid, LWW, gün biçimi, RLS ve `sync_delete` gerçek
  istemci rolüyle. Eski Aşama 3/5 testlerinin 13 tablo beklentisi henüz
  yeniden koşulmadı. Eski testlerde global tetikleyici sayıları
  12 → 13. **Üretime UYGULANMADI.**
- ✅ **Aşama 4** (hesap): `WeeklyReviewInput.completedDays`;
  `NutritionSection` → `basis` (tamamlanmış/kayıtlı günler), `completedDays`,
  `excludedLoggedDays`, `proteinHitDays` (yalnız tamamlanmış günlerde). Kayıtsız
  tamamlanmış gün 0 kalori. Sağlayıcı `nutrition_days` tablosunu da izliyor
  (işaretlenince değerlendirme kendiliğinden yenilenir — eksikti, düzeltildi).
  Yol haritasındaki `dashboard_stats.dart:76-78` protein uyumu kodda artık yok;
  ana ekranda değişecek hesap kalmadı. W-10 testleri (4) + paket 758 yeşil.
- ⚠️ `changedAfterComplete` silinen kaydı görmez (satır kalmıyor); mezar taşı
  tablosundan okumak açık iş.
- ⛔ **Dal sunucu göçünden (Aşama 3) önce `main`'e birleşmez / cihaza kurulmaz**:
  istemci `nutrition_days`'i gönderir, sunucu tablosu yoksa o tablo kalıcı
  hataya düşer (kuyruğun geri kalanı durmaz ama hata göstergesi yanar).
