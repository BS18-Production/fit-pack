# Fit Pack — Proje Durumu (PROJECT_STATE)

> **Son güncelleme:** 2026-06-21
> **Faz:** V2 Geliştirme — **Sprint D: Tasarım Reskin (Ana Sayfa)** tamam
> **Sahibi:** Samet Orhan

## 🆕 Sprint D — Claude Design Reskin: Ana Sayfa (2026-06-21)

Claude Design'da Apple Fitness vibe + Indigo/Teal paletiyle tasarım yapıldı (HTML export `design/code/`). Mevcut uygulamaya geçirme başladı — **Ana Sayfa tamam**:
- **Font:** Inter → **Manrope** (tasarım fontu, `app_theme.dart`)
- **Şema v3→v4:** `water_intake` tablosu + `user_profile.waterGoalMl` (default 2500). Migration lossless, test 3/3.
- **Onboarding (P-10):** önceki session'dan zaten kodluydu — bu cihazda sıfır kurulumda çalıştı, doğrulandı.
- **Ana Sayfa yeniden kuruldu** (`home_screen.dart`): özel header (BUGÜN + tarih, safe-area fix), durum-duyarlı birincil kart (**dinlenme günü zekası** — plandan türetiliyor: antrenman günü→gradient CTA, dinlenme→sakin kart + "Yarın: X" + yürüyüş önerisi), beslenme hero halkası (196px, ölçeklenen 48px sayı), **su takibi kartı** (+250ml/+1 bardak, DB-backed, uzun bas=sıfırla), sessiz Seri+Kilo satırı (dikey ayraç, ↓0.4 trend rozeti).
- **Doğrulama:** analyze 0 · test 30/30 · emülatörde dark+light + su etkileşimi (0.7L) + dinlenme günü + onboarding akışı ekran görüntüsüyle doğrulandı.
- **Sıradaki reskin ekranları:** Antrenman, Beslenme, İlerleme, Ayarlar (aynı token sistemi hazır).

Bu doküman, projenin **şu andaki canlı durumunu** anlatır. Her session sonunda güncellenir.

---

## 🟢 Aktif Durum

**Şu an neredeyiz:** **Sprint P (Premium Cila) tamam** (2026-06-11). Uygulamanın "premium ürün" analizinden çıkan tüm yüksek öncelikli bulgular kodlandı:
- **Antrenman:** seans ekranında geçen seansın ghost değerleri (alan ipuçları + "Geçen seans" satırı), seans başlığı düzeltildi (FullA → Full Body A), geri tuşunda çıkış onayı (PopScope), set ekle/çıkar, antrenman ön izleme ekranı (`/workout/preview/:type` — karta dokununca kronometre değil önizleme), **Antrenman Geçmişi ekranı** (`/workout/history` — seans listesi + set dökümü + toplam hacim; ölü "yakında" butonu gerçek ekrana bağlandı).
- **İlerleme:** fl_chart kilo trend grafiği (hedef kilo kesikli çizgi, dokunma tooltip'i), çift "Ölçüm Ekle" CTA teke indirildi.
- **Beslenme:** Son kullanılanlar şeridi (Yemek Ekle'de chip'ler), "Dünün öğünlerini kopyala" (gün boşken), karb/yağ hedefi kalori+proteinden türetiliyor (`macro_goals.dart`), P/K/Y kısaltmaları makro renkleriyle kodlu (`MacroInlineText`), arama placeholder temizliği.
- **Ana sayfa:** boş haller davet eder ("Seri yok/Bugün başlat" → Antrenman, "Ekle/İlk kilonu gir" → İlerleme; kartlar tıklanır), 7+ gün arada "Yeniden başlamak için harika bir gün".

Önceki sprint: Beslenme V2 (`9ceb223`), tasarım [docs/07-nutrition-v2.md](docs/07-nutrition-v2.md). Dal: `feat/sprint-0.1-migration`.

**Engelleyici:** Yok. Samet'in 6 doc'a okuma feedback'i bekleniyor (engelleyici değil — kod paralel başlayabilir, doc'lar v1.x bump edilir).

**Aktif geliştirici:** Samet (solo) + Claude Code (dispatch ile mobil destek)

---

## 📊 Versiyon

| Bileşen | Versiyon | Durum |
|---------|----------|-------|
| Uygulama | V1.0.0+1 | Prod (lokal, Samet pilot) |
| V2 hedef | 2.0.0 | Geliştirme — Sprint N (Beslenme V2) tamam |
| DB schema | **v6** | v2(Beslenme), v3(Onboarding), v4(Su), v5(Hareket kütüphanesi), v6(Rutinler+gelişmiş set) — hepsi lossless test geçti |
| GitHub | anox2077/fit-pack | private |

---

## 📄 Dokümantasyon Durumu

| Doc | Versiyon | Durum | Notlar |
|-----|----------|-------|--------|
| `docs/01-product-spec.md` (PRD) | 1.1 | ✅ Hazır, final onay bekliyor | Q-01..Q-05 tüm açık sorular cevaplandı |
| `docs/02-architecture.md` (Mimari) | 1.0 | ✅ Taslak hazır | 18 bölüm; ADR'lar, katmanlar, SQLCipher, foto hibrit detay |
| `docs/03-ux-flows.md` (UX) | 1.0 | ✅ Taslak hazır | 20 bölüm; ASCII wireframe'ler, tüm akışlar |
| `docs/04-roadmap.md` (Yol haritası) | 1.0 | ✅ Taslak hazır | Aşama 0-4, sprint planı, milestone'lar |
| `docs/05-testing.md` (Test) | 1.0 | ✅ Taslak hazır | 14 bölüm; test hedef tahtası, migration testi zorunlu, manuel regresyon checklist |
| `docs/06-workflow.md` (DevOps) | 1.0 | ✅ Taslak hazır | 18 bölüm; branch/commit, pre-push checklist, dispatch, release, secrets, yedekleme |

---

## 🎯 Aktif Hedef

**V2 RELEASE hedef tarihi:** 2026-08-15 (pilot lock)

**Bugünden V2 release'e kadar:**
1. ✅ Dokümantasyon 6/6 + 07-nutrition-v2.md (2026-05-18)
2. ✅ Aşama 0 T-001 (migration iskeleti) + **Sprint N Beslenme V2 tamam** (2026-05-18): şema v1→v2, adet/birim, Yemekler ekranı, OpenFoodFacts/barkod, backfill — analyze 0 · test 18/18 · gerçek cihaz DB'sinde lossless doğrulandı
3. ✅ **Sprint P Premium Cila tamam** (2026-06-11): ghost değerler, geçmiş/ön izleme ekranları, kilo grafiği, beslenme kısayolları, boş hal cilası — analyze 0 · test 24/24 · emülatörde tüm akışlar doğrulandı
4. **← SIRADA:** Premium analizden ertelenenler (NEXT_TASKS "Sprint P+") **veya** Aşama 0 kalan (T-002..T-008: yedek + SQLCipher şifreleme) **veya** Samet'in cihaz testi geri bildirimi
5. Aşama 1, 2, 3 sırayla

---

## ✅ Tamamlanan Karar Noktaları

- ✅ Strateji: Lokal, tek kullanıcı pilot
- ✅ Stack: Flutter + Drift + Riverpod + go_router + fl_chart kilitli
- ✅ AI: Switchable provider, Gemini başlangıç
- ✅ Q-01: Gemini API key var
- ✅ Q-02: Foto saklama hibrit (DB sıkıştırılmış + galeri orijinal)
- ✅ Q-03: API limit dolarsa hata göster + sonraki güne ertele
- ✅ Q-04: Bildirim reddi sessiz devam + in-app reminder
- ✅ Q-05: SQLite şifreleme açık (SQLCipher + Android Keystore)

---

## ⏳ Bekleyen Onaylar (Engelleyici Değil)

Samet 3 doc'u sırasıyla okuyacak ve "değişiklik var mı" diye karar verecek:
- PRD v1.1
- Mimari v1.0
- UX v1.0
- (yeni eklendi) Roadmap v1.0

Değişiklik istenirse v1.x bump yapılır, yoksa final lock.

---

## 🚫 Bilinçli Olarak Yapılmayanlar (V2)

- Çoklu kullanıcı / auth (V3'e)
- Bulut sync (V3'e)
- Social feature (asla)
- Reklam (anti-hedef)
- Apple Watch / Wear OS (V3 sonrası)

---

## 🛠 Mevcut V1 Eksiklikleri (Aşama 0'da Düzeltilecek)

- ✅ Migration sistemi + v1→v2 (Beslenme V2) — lossless, gerçek cihaz DB'sinde doğrulandı
- ❌ Error handling katmanı yok
- ❌ Input validation yok
- ❌ Workout history ekranı TODO durumunda (workout_list_screen.dart:66)
- ❌ Achievements UI yok (tablo var ama ekran yok)
- ❌ Progress analytics dedicated chart yok
- ❌ README boş (Flutter starter) — ✅ Bu session düzeltildi

---

## 🔗 Önemli Yollar

- **Repo:** `/Users/sametorhan/dev/fit_pack`
- **Docs:** `/Users/sametorhan/dev/fit_pack/docs/`
- **Cihazlar:** Android SM A075F `R96YB00XJPB`, iOS sim `92EFAB82-82C1-459D-A925-27DAA867E869`
- **Hafıza:** `~/.claude/projects/-Users-sametorhan/memory/project_fit_pack.md`
