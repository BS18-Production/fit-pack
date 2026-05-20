# Fit Pack — Proje Durumu (PROJECT_STATE)

> **Son güncelleme:** 2026-05-18
> **Faz:** V2 Geliştirme — **Sprint N: Beslenme V2** (pilot geri bildirimi, kod fazı)
> **Sahibi:** Samet Orhan

Bu doküman, projenin **şu andaki canlı durumunu** anlatır. Her session sonunda güncellenir.

---

## 🟢 Aktif Durum

**Şu an neredeyiz:** Pilot beslenme geri bildirimi → **Sprint N (Beslenme V2)** kod fazı: birim/adet porsiyon (şema v1→v2), Yemekler yönetim ekranı, OpenFoodFacts/barkod. Tasarım: [docs/07-nutrition-v2.md](docs/07-nutrition-v2.md). Aşama 0-1 arasına araya alındı. Dal: `feat/sprint-0.1-migration` (devam).

**Engelleyici:** Yok. Samet'in 6 doc'a okuma feedback'i bekleniyor (engelleyici değil — kod paralel başlayabilir, doc'lar v1.x bump edilir).

**Aktif geliştirici:** Samet (solo) + Claude Code (dispatch ile mobil destek)

---

## 📊 Versiyon

| Bileşen | Versiyon | Durum |
|---------|----------|-------|
| Uygulama | V1.0.0+1 | Prod (lokal, Samet pilot) |
| V2 hedef | 2.0.0 | Geliştirme — Sprint N (Beslenme V2) tamam |
| DB schema | **v2** | Migration sistemi + v1→v2 (Beslenme V2) canlı, lossless test geçti |
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
3. **← SIRADA:** Aşama 0 kalan (T-002..T-008: yedek + SQLCipher şifreleme) **veya** Samet'in Beslenme V2 cihaz testi geri bildirimi
4. Aşama 1, 2, 3 sırayla

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
