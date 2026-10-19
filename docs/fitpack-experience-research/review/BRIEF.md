# Derin inceleme turu — ortak brif (18 Ekim 2026)

Bu klasör, `docs/fitpack-experience-research/` paketinin **bağımsız derin
incelemesi** içindir. Paket: 02–10 Codex, 01/11/12 Claude (hızlı). Samet hızlı
incelemeyi yetersiz buldu; bu tur onu telafi eder. Her ajan yalnız KENDİ çıktı
dosyasına/klasörüne yazar.

## Proje
- Fit Pack: Flutter · Drift (SQLite, yerel-öncelikli) · Riverpod · GoRouter ·
  Supabase senkron. Yol: `/Users/sametorhan/dev/fit_pack`, kaynak anı `main` = `07104d1`.
- Önce oku: `CLAUDE.md`, `CONVENTIONS.md` (gerekeni), `lib/core/router/app_router.dart`.
- Araştırma paketi: `docs/fitpack-experience-research/01…12`, `workstreams/`, `visuals/`.

## Kesin kurallar
1. **Üretim kodunu değiştirme.** `lib/`, `test/`, `pubspec*`, `android/`, `ios/`
   dosyalarına yazma. Gerekirse deneysel kod yalnız scratchpad'de ya da ayrı bir
   `git worktree` içinde, commit'siz; iş bitince worktree'yi kaldır.
2. **Gerçek telefonlara dokunma:** iPhone `00008150-000214C02E03C01C` ve Samsung
   `R96YB00XJPB`'ye kurulum/komut YOK. `flutter install` YOK.
3. **Üretim Supabase'ine (`jkviihbyogktwboreydn`) yazma.** Emülatör/simülatör
   derlemesi Dev'e bağlanır:
   `--dart-define=SUPABASE_URL=https://qecbnrkbordkqeogmevi.supabase.co --dart-define=SUPABASE_ANON_KEY=sb_publishable_aQZzc4k4q8DSZ5VQdCujTQ_nfOMZmw4`
4. **Uydurma yok.** Ölçmediğin sayıyı yazma. Her iddiaya kanıt sınıfı ver:
   **K** (kod, dosya:satır), **G** (çalışan uygulamada gözlem, ekran görüntüsüyle),
   **Q1/Q2** (resmî yardım / tanıtım, URL + erişim tarihi), **S** (standart),
   **H** (hipotez). "Bilinmiyor" demek serbest ve değerlidir.
5. **Türkçe yaz**, kısaltmaları ilk geçtiği yerde aç (ör. RPE = Rating of
   Perceived Exertion, algılanan zorluk). Hitap yok.
6. Mevcut raporlarla **anlaşmazlığı açıkça yaz**: "Rapor X şunu diyor; bulgum
   şu; kanıt şu."

## Çıktı biçimi (her rapor)
- Başta "Karar özeti" (5–10 satır): en önemli sonuçlar.
- "Yöntem ve sınırlar": ne yaptın, ne yapamadın.
- Bulgular tablo/listesi; her biri kanıt sınıfıyla.
- Sonda "Pakete etkisi": hangi rapordaki hangi iddia güçlendi / zayıfladı /
  yanlış çıktı; önerilen düzeltme.
