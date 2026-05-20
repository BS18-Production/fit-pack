# Fit Pack — Yol Haritası (Roadmap)

> **Doküman versiyonu:** 1.0 (taslak)
> **Tarih:** 2026-05-13
> **Sahibi:** Samet Orhan
> **Durum:** Onay bekliyor
> **Bağlı doküman:** [01-product-spec.md](01-product-spec.md), [02-architecture.md](02-architecture.md), [03-ux-flows.md](03-ux-flows.md)

Bu doküman, **Fit Pack V2'nin Aşama 0'dan Aşama 4'e kadar olan zaman planını, sprint dağılımını, her aşamanın "Definition of Done (Bitti Tanımı)"nı ve milestone'larını** tanımlar.

---

## 1. Yol Haritası Genel Bakış

```
2026-05-13 başlangıç
       │
       ▼
┌─────────────────┐  ~1.5 hafta
│  Aşama 0        │  KRİTİK: Sağlamlaştırma
│  Sağlamlaştırma │  Migration, encryption, error handling
└────────┬────────┘
         ▼
┌─────────────────┐  ~3 hafta
│  Aşama 1        │  Veri modeli genişletme
│  Programa       │  Daily log, supplement, foto, RIR
│  yansıt         │
└────────┬────────┘
         ▼
┌─────────────────┐  ~3 hafta
│  Aşama 2        │  Grafikler ve AI
│  Görselleştirme │  Chart, weekly summary, achievements UI
└────────┬────────┘
         ▼
┌─────────────────┐  ~3-4 hafta
│  Aşama 3        │  Kullanım kalitesi
│  QoL            │  Plate calc, AI chat, notifications, alternates
└────────┬────────┘
         ▼
   [V2 RELEASE — Pilot Lock]
   2026-08-15 hedef tarih (~3 ay)
         │
         ▼
   ~3 ay pilot kullanım (Samet test eder)
         │
         ▼
┌─────────────────┐  V3 fazı
│  Aşama 4        │  Public release hazırlığı
│  Multi-user     │  Auth, cloud sync, premium, Play Store
└─────────────────┘
   2026-11-XX hedef başlangıç
```

---

## 2. Zaman Çerçevesi Varsayımları

**Samet'in çalışma kapasitesi:**
- Tam zamanlı CSS rolü (Inveon.ai) — gündüz mesai
- Side project zamanı: **akşam + hafta sonu**
- Tahmini haftalık: **5-8 saat aktif kod + 2-3 saat doc/planlama**
- AI-asistanlı geliştirme (Claude Code + dispatch ile mobilden)
- Solo geliştirici (1 kişi)

**Buna göre 1 sprint = 1 hafta = ~7-10 saat efor.**

---

## 3. Aşama 0 — Sağlamlaştırma (Hardening)

**Hedef:** V1 kodunu V2'ye taşımak için **sağlam temel** atmak. Hiç yeni feature yok; sadece eksik altyapı.

### 3.1 Süre

**1.5 hafta** (Sprint 0.1 + 0.2)

| Sprint | Tarih (hedef) | Kapsam |
|--------|---------------|--------|
| 0.1 | 13-19 Mayıs 2026 | Migration sistemi + SQLCipher |
| 0.2 | 20-23 Mayıs 2026 | Error handling + validation + history + README |

### 3.2 İş Listesi (Backlog)

#### Sprint 0.1 — Migration + Şifreleme

- [ ] **T-001** Drift schema versionunu 1'de kilitle, `MigrationStrategy` iskeletini yaz
- [ ] **T-002** Mevcut DB'yi yedek alma helper'ı (export to JSON)
- [ ] **T-003** `drift_sqlcipher` paketini ekle, `LazyDatabase` connection'ını güncelle
- [ ] **T-004** `SecureKeyManager` — Android Keystore'dan key oku/üret
- [ ] **T-005** `flutter_secure_storage` paketini ekle (Gemini API key için)
- [ ] **T-006** Mevcut V1 DB'sini şifreli DB'ye taşıma migration script'i yaz
- [ ] **T-007** Emülatörde V1 → V2 göç test'i (veri kayıpsız geçmeli)
- [ ] **T-008** Drift migration integration test örneği (1 test)

#### Sprint 0.2 — Error Handling + Kalan TODO'lar

- [ ] **T-010** `core/errors/app_exception.dart` — sealed class hiyerarşisi
- [ ] **T-011** Global error handler (`FlutterError.onError`, `PlatformDispatcher.onError`)
- [ ] **T-012** `shared/widgets/error_card.dart` + `empty_state.dart`
- [ ] **T-013** Snackbar tabanlı UI hata gösterimi pattern'i
- [ ] **T-014** Input validation — kg/rep/RIR/stres alanları için validator'lar
- [ ] **T-015** Workout history screen — `workout_list_screen.dart:66` TODO bitir
- [ ] **T-016** README gerçek doc — kurulum, çalıştırma, mimari özeti
- [ ] **T-017** Emülatörde tüm V1 akışlarını test et — regression yok mu?

### 3.3 Definition of Done (Aşama 0 Bitti Tanımı)

- ✅ Schema versiyon 2'ye geçildi, migration test geçti
- ✅ DB şifreli açılıyor (SQLCipher + Keystore)
- ✅ V1 verisi kayıpsız taşındı (Samet'in test DB'sinde)
- ✅ Yeni tablo/kolon eklenince mevcut veri silinmiyor
- ✅ Tüm async operasyonlar try/catch içinde, kullanıcıya Türkçe mesaj
- ✅ Workout history ekranı çalışıyor
- ✅ README minimum kurulum + run komutları içeriyor
- ✅ V1'deki bütün akışlar emülatörde regression testi geçti

### 3.4 Riskler

| Risk | Olasılık | Etki | Plan |
|------|----------|------|------|
| SQLCipher entegrasyonu V1 DB'yi bozar | Orta | Yüksek | Önce yedek export, sonra şifreli kopya, başarısızsa rollback |
| Drift code gen hatası | Düşük | Orta | `build_runner` cache temizle, Drift versiyon kilitli |
| Migration test edilemez | Düşük | Yüksek | İlk migration için manuel + otomatik test |

---

## 3.5 Sprint N — Beslenme V2 (Pilot Geri Bildirimi) — ARA EKLEME

> **Tetikleyici:** Pilot kullanımda Samet beslenme akışında 3 eksik bildirdi (bkz. [07-nutrition-v2.md](07-nutrition-v2.md)). Aşama 0 ile Aşama 1 arasına **araya alındı** (kullanıcı sürtünmesi yüksek, doğrudan günlük kullanımı engelliyor).

**Kapsam:** Birim/adet porsiyon (şema v1→v2) + Yemekler yönetim ekranı + OpenFoodFacts/barkod.

| Task | İş |
|------|-----|
| **T-050** | `Foods` şema v2: `defaultPortionGrams` + `unitLabel` (nullable, additive migration) + v1→v2 lossless test |
| **T-051** | `turkish_foods.json` 111 yemeğe porsiyon/birim seed + `seed_manager` map |
| **T-052** | DAO: `updateFood` + `deleteFood` (FK guard) |
| **T-053** | Add-food sheet: adet/g birim seçici; custom dialog birim alanları |
| **T-054** | `Yemekler` yönetim ekranı + `/foods` route + Settings girişi |
| **T-055** | `http` + `mobile_scanner`; `OpenFoodFactsService`; barkod tarama ekranı; AndroidManifest CAMERA/INTERNET |
| **T-056** | Test (migration/birim/OFF mapping/DAO) + analyze + emülatör smoke |

**Bitti tanımı:** schemaVersion 2 + migration testi geçti; yemek adet/gram girilebiliyor; Yemekler ekranı listele/ara/düzenle/sil çalışıyor; barkod tara → lokal/OFF eşleme; V1 verisi kayıpsız; analyze 0 uyarı. Şema sürüm devamı: Aşama 1 v3+.

**Not:** Aşama 1'in (rir/daily_log/supplement) hedef tarihleri ~1 sprint kayar — pilot sürtünmesi önceliği haklı çıkarır (§13 re-planning tetikleyicisi).

---

## 4. Aşama 1 — Programa Yansıt

**Hedef:** Samet'in fitness programının tüm metrikleri uygulamada **veri olarak** tutulabilsin. Hesaplama henüz yok, sadece kayıt.

### 4.1 Süre

**3 hafta** (Sprint 1.1 - 1.3)

| Sprint | Tarih (hedef) | Kapsam |
|--------|---------------|--------|
| 1.1 | 24-30 Mayıs | Yeni tablolar + RIR + workout güncelleme |
| 1.2 | 31 Mayıs - 6 Haziran | Daily log + supplement + water UI |
| 1.3 | 7-13 Haziran | Foto akışı (hibrit) |

### 4.2 İş Listesi

#### Sprint 1.1 — Veri Modeli

- [ ] **T-101** `workout_sets.rir` kolonu ekle (migration v2→v3)
- [ ] **T-102** `workout_sessions.elbow_status` kolonu ekle
- [ ] **T-103** `daily_log` tablosu (stres/uyku/mood/diz_ağrı/dirsek_ağrı/water_ml)
- [ ] **T-104** `supplement_log` tablosu
- [ ] **T-105** İlgili DAO'lar (`daily_log_dao`, `supplement_dao`)
- [ ] **T-106** Workout session ekranına RIR field'ı ekle
- [ ] **T-107** Workout session'a elbow_status toggle ekle
- [ ] **T-108** workout_plan.json'u Upper/Lower x2 programına güncelle (4 günlük program)
- [ ] **T-109** Auto-progression önerisi mantığı (kg suggest)
- [ ] **T-110** Suggestion UI'da göster (workout session ekranı)

#### Sprint 1.2 — Daily Log UI

- [ ] **T-115** Daily log ekranı (tek scroll, 30sn UX)
- [ ] **T-116** Su counter + quick add UI
- [ ] **T-117** Takviye listesi + checklist UI
- [ ] **T-118** Default takviye listesi yönetimi (settings)
- [ ] **T-119** Home ekranına "bugünü kaydet" kartı ekle
- [ ] **T-120** Pre-WO checklist UI iskelet (Aşama 2'de canlanır)

#### Sprint 1.3 — Foto

- [ ] **T-125** `flutter_image_compress`, `gal`, `image_picker` paketleri ekle
- [ ] **T-126** `PhotoService` sınıfı (hibrit saklama mantığı)
- [ ] **T-127** Foto çekme ekranı (açı seç + kamera/galeri)
- [ ] **T-128** Foto karşılaştırma ekranı (önce/sonra side-by-side)
- [ ] **T-129** Galeri izni reddi sessiz fallback
- [ ] **T-130** Foto listesi (tarih bazlı timeline)

### 4.3 Definition of Done (Aşama 1 Bitti Tanımı)

- ✅ RIR girilebilir + DB'ye yazıyor
- ✅ Daily log her gün 30sn'de girilebilir
- ✅ Su ve takviye log çalışıyor
- ✅ Foto çekilebiliyor, sıkıştırılıyor (~500KB), galeriye de gidiyor
- ✅ İki tarih seçip foto karşılaştırma çalışıyor
- ✅ 4 günlük Upper/Lower x2 programı workout listesinde
- ✅ Migration v2 → v3 → v4 lossless test geçti
- ✅ Tüm yeni ekranlar empty state + error state içeriyor

### 4.4 Riskler

| Risk | Olasılık | Etki | Plan |
|------|----------|------|------|
| Foto sıkıştırma kalitesi tartışmalı | Orta | Düşük | A/B test %85 vs %90, Samet karar versin |
| Galeri izinleri Android sürümleri arası tutarsız | Orta | Orta | `gal` paketi platform-specific yetenekleri test edilir |
| RIR konsepti yeni — UX karmaşa | Düşük | Orta | Tooltip + örnek değer önerisi |

---

## 5. Aşama 2 — Görselleştirme

**Hedef:** Toplanan veriyi **anlamlı içgörüye** çevirmek. Grafikler + AI ilk haftalık özet + achievement UI.

### 5.1 Süre

**3 hafta** (Sprint 2.1 - 2.3)

| Sprint | Tarih (hedef) | Kapsam |
|--------|---------------|--------|
| 2.1 | 14-20 Haziran | Grafikler (fl_chart) |
| 2.2 | 21-27 Haziran | AI haftalık özet |
| 2.3 | 28 Haziran - 4 Temmuz | Achievements UI + Pre-WO checklist |

### 5.2 İş Listesi

#### Sprint 2.1 — Grafikler

- [ ] **T-201** `core/services/ai_provider.dart` interface
- [ ] **T-202** `GeminiProvider` somut implementasyonu
- [ ] **T-203** Riverpod ile AI provider injection
- [ ] **T-204** API key settings ekranı (secure storage'a yazar)
- [ ] **T-210** Kilo trend grafiği (fl_chart)
- [ ] **T-211** Toplam haftalık hacim trend grafiği
- [ ] **T-212** Günlük protein bar chart
- [ ] **T-213** Ağrı seviyesi (diz + dirsek) trend grafiği
- [ ] **T-214** Aralık filtre (7g / 30g / 90g / all)
- [ ] **T-215** Gelişim sekmesi route'unu ekle

#### Sprint 2.2 — AI Haftalık Özet

- [ ] **T-220** Haftalık veri agregator (son 7 günü özetle)
- [ ] **T-221** AI prompt template tasarımı (Türkçe + sistematik)
- [ ] **T-222** Genel skor hesaplama (0-10) — kural tabanlı
- [ ] **T-223** Pattern detection — örn: "3 hafta peş peşe protein az"
- [ ] **T-224** Haftalık özet ekranı UI
- [ ] **T-225** Pazar 21:00 / ilk Pazar açılışı tetikleyici
- [ ] **T-226** Rate limit handling (PRD Q-03 uygulaması)
- [ ] **T-227** AI cevabı parse + render (markdown destekli)

#### Sprint 2.3 — Achievement + Pre-WO

- [ ] **T-235** Achievement tetikleyici servis (event-driven)
- [ ] **T-236** Achievement listesi tanımı (20 rozet)
- [ ] **T-237** Achievement listesi ekranı
- [ ] **T-238** Achievement modal (yeni kazanılınca)
- [ ] **T-239** Pre-WO checklist UI canlandır
- [ ] **T-240** Foto önce/sonra paylaşma (share_plus)

### 5.3 Definition of Done

- ✅ 4 trend grafiği çalışıyor + zoom/pan + tarih filter
- ✅ Haftalık özet Pazar tetikleniyor, AI cevabı ekranda
- ✅ AI rate limit dolduğunda kullanıcı dostu mesaj
- ✅ 20 rozet tanımlı, en az 5'i tetikleniyor
- ✅ Pre-WO checklist antrenman öncesi gösteriliyor
- ✅ Foto karşılaştırma paylaşılabilir

### 5.4 Riskler

| Risk | Olasılık | Etki | Plan |
|------|----------|------|------|
| AI cevap kalitesi düşük | Orta | Yüksek | Prompt iterasyonu, örnek output kalitesi denemesi |
| Gemini quota beklenmedik hızlı dolar | Düşük | Orta | Önbellek (aynı hafta tekrar sorulmasın) |
| fl_chart performans 200+ data point'te düşer | Düşük | Düşük | Veri aggregation (haftalık ortalama) |

---

## 6. Aşama 3 — Quality of Life (QoL)

**Hedef:** Günlük kullanım sürtüncesini azaltmak. Akıllı küçük özellikler.

### 6.1 Süre

**3-4 hafta** (Sprint 3.1 - 3.4)

| Sprint | Tarih (hedef) | Kapsam |
|--------|---------------|--------|
| 3.1 | 5-11 Temmuz | Plate calculator + alternatif hareket |
| 3.2 | 12-18 Temmuz | Bildirim sistemi |
| 3.3 | 19-25 Temmuz | AI sohbet ekranı |
| 3.4 | 26 Temmuz - 1 Ağustos | Adım sayacı + final polish |

### 6.2 İş Listesi

#### Sprint 3.1 — Plate Calc + Alternatif

- [ ] **T-301** Plate calculator widget (hedef kg → bar + plakalar)
- [ ] **T-302** Workout session içinde her hareket için "?" buton → plate calc
- [ ] **T-303** Sakatlık tag sistemi (exercise tablosuna ekle)
- [ ] **T-304** Alternatif hareket önerisi (knee/elbow durumuna göre)
- [ ] **T-305** Settings'te kullanıcı sakatlık durumu

#### Sprint 3.2 — Bildirim

- [ ] **T-315** `flutter_local_notifications` ekle
- [ ] **T-316** `NotificationService` sınıfı
- [ ] **T-317** Antrenman günü hatırlatma
- [ ] **T-318** Takviye saat hatırlatması
- [ ] **T-319** Pre-WO 1 saat önce
- [ ] **T-320** Streak risk bildirim (22:00 gece)
- [ ] **T-321** Bildirim izni reddi in-app reminder fallback
- [ ] **T-322** Settings'te bildirim kapama/açma per-tip

#### Sprint 3.3 — AI Sohbet

- [ ] **T-330** Sohbet ekranı UI (chat bubble)
- [ ] **T-331** Önerilen sorular kartları
- [ ] **T-332** Context window — son 7 gün özet veri AI'ya gönder
- [ ] **T-333** Conversation history (DB tablosu + UI)
- [ ] **T-334** Token sayım uyarısı (limit yaklaşırsa)

#### Sprint 3.4 — Adım Sayacı + Polish

- [ ] **T-340** `health` paketi entegrasyonu (Google Fit)
- [ ] **T-341** Adım sayısı home kartı
- [ ] **T-342** Adım sayısı trend grafiği
- [ ] **T-343** Genel UX polish (animasyon, haptic ince ayar)
- [ ] **T-344** Karanlık mod kontrast review
- [ ] **T-345** Erişilebilirlik (Semantics label) ilk pas

### 6.3 Definition of Done

- ✅ Plate calc workout session içinde 2 tap'te açılıyor
- ✅ Sakatlık durumuna göre alternatif öneri çalışıyor
- ✅ Bildirimler 4 tipte çalışıyor + izin reddi gracefully handled
- ✅ AI sohbet ekranı çalışıyor, son 7 günlük context ile
- ✅ Adım sayacı Google Fit'ten geliyor (Android)
- ✅ Karanlık mod review geçti

### 6.4 Riskler

| Risk | Olasılık | Etki | Plan |
|------|----------|------|------|
| `health` paketi izinleri karmaşık | Orta | Orta | Doc oku + native test |
| AI sohbet token maliyeti hızlı yer | Orta | Orta | Sistem prompt'u kısa, response cap |
| Bildirim timing fonksiyonu Android farkları | Orta | Düşük | timezone paketi + test edilir |

---

## 7. V2 RELEASE — Pilot Lock (2026-08-15 hedef)

**V2 release demek:**
- Samet pilot olarak uygulamayı **günlük kullanır**
- En az **3 ay** pilot data toplar
- Bu sürede minor patch'ler yapılır (bug fix, UX tweak)
- **Aşama 4 (Multi-user) hemen başlamaz** — pilot data yeterli olmalı önce

### 7.1 Release Checklist

- [ ] Tüm Aşama 0-3 acceptance kriterleri geçti
- [ ] Emülatörde + gerçek cihazda (SM A075F) regression test
- [ ] Build APK release modu çalışıyor
- [ ] Crash-free (`flutter analyze` warning sıfır + manuel test sırasında crash yok)
- [ ] Tüm açık TODO'lar dosyalanmış (gelecek faza referans)
- [ ] `PROJECT_STATE.md` güncel (pilot dönem girişi)
- [ ] V1.5 minor patch süreci tanımlı

---

## 8. Pilot Dönem (Ağustos-Ekim 2026)

**Süre:** ~3 ay
**Hedef kullanım:** Günde en az 1 açılış, haftada 5+ yemek log, 3-4 antrenman

### 8.1 Aktiviteler

- **Haftalık review** — Samet uygulamayı kullanırken pain point'leri kaydet
- **Minor patch'ler** — Acil bug + küçük UX iyileştirmeleri
- **AI prompt iterasyonları** — Cevap kalitesi gözlemleyip tune et
- **Veri kalitesi check** — DB sağlığı, foto saklama performansı
- **3 aylık başarı metrikleri ölçümü** (PRD bölüm 4)

### 8.2 Pilot Başarı Kriterleri (PRD'den)

| # | Kriter | Ölçüm |
|---|--------|-------|
| 1 | Fiziksel değişim grafik+foto ile bariz | Grafikler net trend; foto karşılaştırma |
| 2 | Günde en az 1 açılış (90 günün %80'i) | App-open log |
| 3 | Haftada 5+ yemek log | Ortalama |

**Geç kal: pilot başarısız → V3 ertelenir veya iptal.**
**Erken kal: pilot başarılı → Aşama 4 başlat.**

---

## 9. Aşama 4 — Multi-User & Public Release (V3)

**Hedef:** Pilot başarılıysa, uygulamayı **public release'e hazır hale getirmek.**

### 9.1 Süre Tahmini

**~3-4 ay** (Aşama 4 başlangıcından Play Store launch'a)

### 9.2 Kapsam (özet)

- Auth (Firebase Auth veya custom)
- Cloud sync (Firestore veya custom backend)
- User profile multi-row
- Premium / Freemium model
- Public release marketing materyali (ekran görüntüleri, video)
- Play Store + App Store kayıt
- Beta tester programı
- Crash reporting (Firebase Crashlytics)
- Analytics (Firebase Analytics veya Plausible)

### 9.3 Bağımlılıklar

- Pilot dönem başarısı
- Samet'in stack genişletmeye hazır olması (backend)
- Backend hosting kararı (Firebase vs self-host vs Cloudflare)
- Legal: kullanım koşulları + GDPR (Türkiye KVKK)

> **Detay roadmap V3 başlayınca yazılır** — şu an için sadece kapsam.

---

## 10. Milestone Özeti

| Milestone | Tarih (hedef) | Anlam |
|-----------|---------------|-------|
| M-01 | 23 Mayıs 2026 | Aşama 0 bitti — temel sağlam |
| M-02 | 13 Haziran 2026 | Aşama 1 bitti — tüm veri kaydedilebiliyor |
| M-03 | 4 Temmuz 2026 | Aşama 2 bitti — grafikler + AI çalışıyor |
| M-04 | 1 Ağustos 2026 | Aşama 3 bitti — QoL feature'lar tamam |
| **M-05** | **15 Ağustos 2026** | **V2 RELEASE — Pilot kullanım başlar** |
| M-06 | 15 Kasım 2026 | Pilot 3 ay tamamlandı, başarı kriterleri ölçüldü |
| M-07 | ~Şubat 2027 | V3 (Aşama 4) başlangıç |
| M-08 | ~Mayıs 2027 | Public release (Play Store) |

---

## 11. Bağımlılıklar ve Riskler (Genel)

### 11.1 Kritik Bağımlılıklar

| Bağımlılık | Etki | Plan B |
|------------|------|--------|
| Samet'in günlük disiplini (pilot için) | V2 başarısı | Akıllı bildirimler + hızlı UX |
| Gemini API erişimi (free tier yeterli olmalı) | Aşama 2/3 | Switchable provider — Claude/GPT'ye geçiş |
| Mezura (vücut ölçümü için) | Aşama 1 veri kalitesi | Sipariş edildi 2026-05-10, gelecek |
| Cihaz dayanıklılığı (SM A075F primary test) | Geliştirme | iOS Simulator de mevcut, ikinci platform |

### 11.2 Genel Risk Matrisi

| Risk | Olasılık | Etki | Strateji |
|------|----------|------|----------|
| Aşama 0 SQLCipher migration sorunlu | Orta | Yüksek | Önce yedek export, sonra şifreli |
| Aşamalar arası bağımlılık kırılması | Düşük | Orta | Her aşama bağımsız test ediliyor |
| Burnout — side project enerji | Orta | Yüksek | Sprint sonu mola, dispatch ile flexibility |
| Stack değişiklik baskısı (yeni framework merakı) | Düşük | Orta | Stack kilitli, V3 öncesi değişmez |
| Pilot kötü sonuç → motivasyon kaybı | Düşük | Yüksek | Pilot kriterleri esnek, kısmi başarı da kabul |

---

## 12. Sprint Ritmi ve Süreç

### 12.1 Sprint Yapısı

- **1 sprint = 1 hafta** (Pazartesi başlar)
- **Pazartesi:** Sprint planning — backlog'dan task çek
- **Pazartesi-Cuma:** Geliştirme (akşam saatleri)
- **Cumartesi:** Test + push + demo
- **Pazar:** Retrospektif + sonraki sprint planı

### 12.2 Definition of Ready (Task Hazır mı?)

- Task description net
- Acceptance criteria yazılı
- Bağımlılık varsa belirtilmiş
- Tahmini efor 1-5 saat (büyükse parçalanır)

### 12.3 Definition of Done (Task Bitti mi?)

- Kod yazıldı + compile geçiyor
- Emülatörde manuel test edildi
- `flutter analyze` warning'siz
- Commit + push yapıldı
- Doc/README güncel (gerekiyorsa)

---

## 13. Esneklik ve Kaymalar

**Bu roadmap statik değildir.**

- Aşamalar **+/- 1 hafta** kayabilir.
- Aşama 3 ve 4 arasında **buffer** koymak makul.
- Tehlike işaretleri:
  - Sprint sonu task'ların %50'sinden fazla devredilirse → planı revize et
  - Aynı bug 2 sprint üst üste açıkta kalırsa → öncelik artır
  - Burnout sinyali → bir hafta pause

### 13.1 Re-planning Tetikleyicileri

- 1 aşama %50'den fazla gecikti
- Yeni kritik bug fix gerekti (örn: data loss riski)
- Stack değişikliği zorunluluk doğdu
- Pilot kullanımdan radikal feedback geldi

---

## 14. Sonraki Adım

Bu doküman onaylanınca:
- `docs/05-testing.md` — Test stratejisi (unit/widget/integration kapsamı)
- `docs/06-workflow.md` — DevOps workflow (commit, branch, CI/CD, dispatch kullanımı)
- Sonra → **kod yazımı: Aşama 0 Sprint 0.1 başlangıç**

---

## 15. Onay & Versiyon

| Versiyon | Tarih | Değişiklik | Onay |
|----------|-------|------------|------|
| 1.0 (taslak) | 2026-05-13 | İlk taslak — PRD + Mimari + UX üzerine inşa | ⏳ Beklemede |
| 1.1 | 2026-05-18 | §3.5 eklendi — Sprint N Beslenme V2 (pilot geri bildirimi, [07-nutrition-v2.md](07-nutrition-v2.md)) Aşama 0-1 arasına alındı | ✅ Yön onaylı |
