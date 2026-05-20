# Fit Pack — Geliştirme Workflow'u (DevOps & Çalışma Şekli)

> **Doküman versiyonu:** 1.0 (taslak)
> **Tarih:** 2026-05-18
> **Sahibi:** Samet Orhan
> **Durum:** Onay bekliyor
> **Bağlı doküman:** [01-product-spec.md](01-product-spec.md), [02-architecture.md](02-architecture.md), [03-ux-flows.md](03-ux-flows.md), [04-roadmap.md](04-roadmap.md), [05-testing.md](05-testing.md)

Bu doküman, **kod yazılırken günlük olarak uyulacak süreci** tanımlar: nasıl branch açılır, nasıl commit edilir, kod nasıl üretilir/çalıştırılır, dispatch ile mobilden nasıl çalışılır, release nasıl yapılır, oturumlar arası süreklilik nasıl korunur. Bu **son dokümandır** — onaylanınca kod yazımı başlar.

> **Kısaltma sözlüğü:** CI = Continuous Integration (Sürekli Entegrasyon) · CD = Continuous Delivery (Sürekli Teslim) · PR = Pull Request (Birleştirme İsteği) · APK = Android Package Kit (Android kurulum paketi) · SemVer = Semantic Versioning (Anlamsal Versiyonlama) · WIP = Work In Progress (Devam Eden İş) · dispatch = Claude Code'a uzaktan (telefondan) komut gönderme yöntemi · DoD = Definition of Done (Bitti Tanımı).

---

## 1. Çalışma Modeli Özeti

Fit Pack **solo geliştirici + AI-asistanlı + lokal pilot** bir proje. Workflow buna göre **hafif** tutulur — ekip süreçleri (kod review board, çok aşamalı onay) yok; ama **disiplin** var, çünkü 3 aylık pilot data'sı değerli.

```
Samet (akşam/hafta sonu, ~7-10 saat/hafta)
        │
        ├──→ Masaüstü: Claude Code + emülatör/cihaz
        │
        └──→ Yolda: telefondan DISPATCH → Mac'teki Claude Code çalışır
                                              │
                                              ▼
                                  kod yaz → build_runner → flutter run
                                              │
                                              ▼
                              cihazda (SM A075F) otomatik çalışır
                                              │
                                              ▼
                          sprint sonu: test + commit + push + doc güncelle
```

---

## 2. Geliştirme Ortamı

| Bileşen | Değer |
|---------|-------|
| Flutter SDK | 3.x (sdk ^3.11) |
| Repo (lokal) | `/Users/sametorhan/dev/fit_pack` |
| Repo (uzak) | GitHub `anox2077/fit-pack` (private) |
| Birincil test cihazı | Android SM A075F — device id `R96YB00XJPB` |
| İkincil | iOS Simulator `92EFAB82-82C1-459D-A925-27DAA867E869` |
| Emülatör | `MemoRush_Test` AVD (homebrew commandlinetools) |
| Paket adı | `com.sametorhan.fit_pack` |

**İlk kurulum (yeni makinede / sıfırdan):**
```bash
cd /Users/sametorhan/dev/fit_pack
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d R96YB00XJPB
```

---

## 3. Repo & Branch Stratejisi

Solo proje için **hafif trunk-based**:

```
main  ──●──────●──────●──────●────────●──→  (her zaman çalışır durumda)
         \    /        \    /
          feat/         feat/
          sprint-0.1    sprint-0.2
```

**Kurallar:**
1. **`main` her zaman derlenir + çalışır.** Yarım iş `main`'e gitmez.
2. Her **sprint** (veya büyük task grubu) için kısa ömürlü dal: `feat/sprint-0.1-migration`, `feat/sprint-1.3-foto`.
3. Tek dosyalık küçük fix → doğrudan `main` kabul (solo pragmatizmi; PR zorunluluğu yok).
4. Dal **sprint sonunda** `main`'e merge edilir (fast-forward veya squash).
5. Uzun yaşayan dal YOK — bir sprintten uzun süren dal = planı parçala sinyali (Roadmap §13).
6. WIP commit'leri dalda serbest; `main`'e merge öncesi anlamlı commit'lere toparla (gerekirse).

**Branch isimlendirme:**
- `feat/<sprint>-<konu>` — yeni özellik (örn: `feat/sprint-1.1-rir`)
- `fix/<konu>` — bug fix
- `chore/<konu>` — bakım (paket güncelleme, doc)

---

## 4. Commit Kuralları

**Conventional Commits** formatı (V1 commit'i bu stildeydi — sürdürülür):

```
<tip>: <kısa özet (İngilizce, emir kipi)>

<opsiyonel gövde — neden, ne değişti>

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

| Tip | Ne Zaman |
|-----|----------|
| `feat` | Yeni özellik / kullanıcıya görünen yetenek |
| `fix` | Bug düzeltme |
| `refactor` | Davranış değişmeden kod iyileştirme |
| `test` | Test ekleme/düzeltme |
| `docs` | Doküman (`docs/`, README, PROJECT_STATE) |
| `chore` | Paket, config, build ayarı |

**Kurallar:**
1. **Commit küçük ve atomik** — bir commit bir mantıksal değişiklik.
2. **Migration değişikliği + migration testi AYNI commit'te** (Testing §12 kuralı — kritik).
3. Claude Code commit yaparken **`Co-Authored-By` footer'ı zorunlu** (harness kuralı).
4. Commit/push **sadece Samet isteyince** yapılır — otomatik push yok.
5. `main`'e push öncesi → §6 pre-push checklist.

---

## 5. Kod Üretimi (Code Generation) Workflow'u

Drift (DB) ve Riverpod (`@riverpod`) **code generation** kullanır. `*.g.dart` / `*.drift.dart` dosyaları elle düzenlenmez.

**Ne zaman `build_runner` çalıştır:**
- Drift tablo/DAO ekledin/değiştirdin
- `@riverpod` provider ekledin/değiştirdin
- `freezed`/model annotation değiştirdin (eklenirse)

```bash
# Tek seferlik
dart run build_runner build --delete-conflicting-outputs

# Geliştirme sırasında sürekli (watch)
dart run build_runner watch --delete-conflicting-outputs
```

**Kurallar:**
1. Üretilen dosyalar **repo'ya commit edilir** (CI yok, build hızı için).
2. `build_runner` hatası → önce `flutter clean` + cache temizle, sonra tekrar (Mimari §16 riski).
3. Schema değişti → `schemaVersion` artır + migration yaz + migration testi (Testing §3.1).

---

## 6. Pre-Push Checklist (main'e gitmeden önce)

Testing §10'daki disiplinin workflow'a bağlanmış hali. CI olmadığı için **bu manuel kapıdır:**

```
[ ] 1. flutter analyze            → 0 warning
[ ] 2. flutter test               → tüm testler yeşil
[ ] 3. (migration değiştiyse)     → migration_test özellikle koş
[ ] 4. build_runner güncel mi     → üretilen dosyalar commit'li
[ ] 5. Emülatörde smoke test      → R-01 (açılış+şifreli DB) + R-11 (veri kalıcı)
[ ] 6. Sprint sonuysa             → R-01..R-11 tam regresyon (Testing §8)
[ ] 7. Doc güncel mi              → PROJECT_STATE / NEXT_TASKS / README (§10)
[ ] 8. commit (Co-Authored footer) + push
```

> Adım 5 her push'ta; adım 6 sadece sprint sonu push'unda.

---

## 7. Otomatik Çalıştırma Kuralı (Samet'in Kuralı)

**Her kod değişikliğinden sonra emülatörde/cihazda otomatik çalıştır** (kullanıcı tercihi — memory):

```bash
flutter run -d R96YB00XJPB
```

- Hot reload (`r`) küçük UI değişikliklerinde; **hot restart (`R`)** provider/DB değişikliğinde.
- Schema/native paket değişti → tam yeniden başlat (hot reload yetmez).
- Cihaz bağlı değilse → emülatör (`MemoRush_Test` AVD) fallback.
- Çalıştırma sonucu (crash/hata) Samet'e raporlanır, sessizce geçilmez.

---

## 8. Dispatch ile Mobilden Çalışma

Samet yolda/dışarıda telefondan **dispatch** ile Mac'teki Claude Code'a komut gönderebilir. Bu workflow'un birinci sınıf parçası.

**Dispatch sırasında Claude'un sorumluluğu:**
1. Komutu uygula, **izin sorma** (kullanıcı tercihi: `--dangerously-skip-permissions` gibi davran).
2. Build/test sonucunu **net özetle** — Samet ekranı göremiyor olabilir.
3. Riskli/geri alınamaz işlemde (örn: DB silen migration, force push) **önce kısa onay iste**, çünkü Samet bağlamı göremiyor.
4. Sprint ilerlemesini PROJECT_STATE/NEXT_TASKS'a yaz ki dönüşte Samet senkron olsun.

**Mac uyku ayarı (dispatch için kritik):**
- Yola çıkmadan: `sudo pmset -a disablesleep 1` (Mac uyumasın, dispatch komutları işlensin)
- **Dönüşte geri al:** `sudo pmset -a disablesleep 0` — Claude bunu Samet'e **hatırlatır** (memory'de aktif not).

> Not: dispatch sırasında `build_runner watch` açık kalması verimli — her değişiklikte elle tetiklemeye gerek kalmaz.

---

## 9. Sprint Ritmi (Roadmap §12 ile Hizalı)

| Gün | Aktivite |
|-----|----------|
| Pazartesi | Sprint planning — `NEXT_TASKS.md`'den task çek, Definition of Ready kontrol |
| Salı-Cuma | Geliştirme (akşam) — kod + build_runner + otomatik run + commit (dalda) |
| Cumartesi | Test + tam regresyon (R-01..R-11) + push + demo |
| Pazar | Retrospektif + sonraki sprint planı + doc güncelle |

**Task akışı:**
```
NEXT_TASKS'tan task seç → dalda kod → build_runner → flutter run →
manuel doğrula → (gerekiyorsa) test yaz → commit → task'ı [x] işaretle
```

---

## 10. Doküman Güncelleme Disiplini (Samet'in Kuralı)

**Her oturum sonunda / commit-kapanışta otomatik güncelle** (kullanıcı tercihi — memory):

| Doküman | Ne Zaman | Ne Güncellenir |
|---------|----------|----------------|
| `PROJECT_STATE.md` | Her oturum sonu | Canlı durum, doc/versiyon tablosu, karar noktaları |
| `NEXT_TASKS.md` | Her oturum sonu | Biten task `[x]`, yeni sıradakiler |
| `README.md` | İlgili değişiklikte | Kurulum/çalıştırma/mimari özeti değişince |
| `docs/0X-*.md` | Karar değişince | İlgili doc v1.x bump + "Onay & Versiyon" tablosu |
| Memory (`project_fit_pack.md`) | Oturum sonu | "ŞU AN NEREDE KALDIK" güncel tutulur |

> **Neden kritik:** Bu oturumda görüldü — stale memory yanlış bilgi verdirdi. Doc/memory güncel değilse bir sonraki oturum (veya dispatch) yanlış başlar.

---

## 11. Versiyonlama (SemVer)

`pubspec.yaml` → `version: <major>.<minor>.<patch>+<build>`

| Bölüm | Ne Zaman Artar |
|-------|----------------|
| major | Kırıcı/büyük dönüm (V1→V2 = 1.x → 2.0.0) |
| minor | Yeni aşama/özellik grubu tamam (Aşama 1 bitti → 2.1.0) |
| patch | Bug fix, küçük tweak (pilot dönemi patch'leri) |
| build (+N) | Her cihaza kurulan derlemede +1 (Play Store versionCode mantığı) |

**Kural:** Release/kurulum öncesi build numarasını **MUTLAKA artır ve kaydet** — MemoRush'ta `versionCode` çakışması yaşandı (memory: `project_memorush_version_log` disiplini). Fit Pack için de bir version log tutulur (V2 release'e doğru).

| Milestone | Versiyon |
|-----------|----------|
| V1 (mevcut) | 1.0.0+1 |
| Aşama 0 bitti | 2.0.0-alpha.1 |
| Aşama 1/2/3 bitti | 2.0.0-beta.x |
| V2 RELEASE (pilot lock) | 2.0.0+N |
| Pilot patch'ler | 2.0.x |

---

## 12. Release Süreci

### V2 (Pilot — Play Store YOK)

Pilot lokal; mağaza yayını yok. "Release" = Samet'in cihazına stabil sürüm kurmak.

```bash
flutter analyze                       # 0 warning
flutter test                          # hepsi yeşil
flutter build apk --release           # release APK üret
# APK'yı SM A075F'e kur, gerçek kullanım başlat
```

**Release checklist (Roadmap §7.1 ile):**
- [ ] Tüm aşama acceptance kriterleri geçti
- [ ] Emülatör + gerçek cihaz regresyon (R-01..R-11)
- [ ] `flutter analyze` 0 warning, manuel testte crash yok
- [ ] Versiyon + build numarası artırıldı ve loglandı
- [ ] PROJECT_STATE "pilot dönem" girişi yazıldı
- [ ] DB yedeği alındı (§13)

### V3 (Public — Play Store)

Aşama 4'te detaylanır. Mevcut **Play Store checklist** (memory: `project_play_store_checklist` — 7 maddelik liste) + gerçek AdMob ID'leri (memory: `reference_admob_ids`) referans alınır. CI/CD (GitHub Actions) burada devreye girer (Mimari §13.3).

---

## 13. Veri Yedekleme (Pilot Data Koruması)

Pilot data 3 ay birikecek ve değerli (PRD başarı kriteri buna bağlı). Kayıp = pilot ölümü.

**Kurallar:**
1. **Aşama 0 T-002:** "Export to JSON" yedek helper'ı — her major migration **öncesi** otomatik çalışır.
2. SQLCipher migration öncesi (Aşama 0): yedek export → şifreli kopya → başarısızsa rollback (Testing §12).
3. Pilot dönemde Samet'e **haftalık manuel export** hatırlatılır (Settings → Export → all/json).
4. Export dosyaları repo'ya **commit EDİLMEZ** (kişisel sağlık verisi) — `.gitignore`'da.

---

## 14. Sırlar Yönetimi (Secrets)

| Sır | Geliştirmede | Runtime'da | Repo'da |
|-----|--------------|------------|---------|
| Gemini API key | Geçici: secure storage'a manuel gir | `flutter_secure_storage` (Mimari §2) | **ASLA** — `.gitignore` |
| SQLCipher anahtarı | — | Android Keystore (otomatik üretilir) | Asla (cihazda yaşar) |

**Kurallar:**
1. API key **hiçbir zaman** koda hard-code edilmez, log'a yazılmaz, commit edilmez.
2. `.gitignore` kontrol: `*.env`, `secrets.dart`, export `*.json`, `*.db`.
3. Key sızarsa → Google AI Studio'dan revoke + yeni key.

---

## 15. Workflow Riskleri ve Azaltma

| Risk | Etki | Azaltma |
|------|------|---------|
| Stale doc/memory → yanlış başlangıç | Orta | §10 disiplini; oturum başı PROJECT_STATE+NEXT_TASKS oku |
| Dispatch sırasında build_runner takılır | Orta | `flutter clean` + cache temizle; Samet'e net rapor |
| Mac uyur, dispatch komutu işlenmez | Orta | `pmset disablesleep 1` yolda; dönüşte 0'a al hatırlatması |
| Üretilen dosya commit'lenmez → derleme bozuk | Düşük | Pre-push adım 4 |
| Migration commit'i testsiz push | Yüksek | Commit kuralı 2 + pre-push adım 3 |
| Pilot data kaybı | Yüksek | §13 yedekleme; migration öncesi otomatik export |
| Burnout (solo, akşam mesai) | Orta | Sprint sonu mola; dispatch ile esneklik (Roadmap §11) |

---

## 16. Oturum Sürekliliği (Claude için Protokol)

Her yeni oturum / dispatch başında Claude:

```
1. PROJECT_STATE.md oku        → canlı durum
2. NEXT_TASKS.md oku           → bugün ne yapılacak
3. memory project_fit_pack     → "ŞU AN NEREDE KALDIK" (doğrula, stale olabilir)
4. Samet'in doc feedback'i var mı sor → varsa öncelik
5. Yoksa NEXT_TASKS'tan devam
6. Oturum sonu: §10 disiplini (PROJECT_STATE/NEXT_TASKS/memory güncelle)
```

> Memory point-in-time'dır, canlı state değil — repo'daki PROJECT_STATE/NEXT_TASKS **doğruluk kaynağıdır**, çelişki olursa repo kazanır.

---

## 17. Sonraki Adım

Bu doküman onaylanınca **dokümantasyon fazı biter (6/6).** Sıradaki:

➡️ **KOD — Aşama 0 Sprint 0.1** (Roadmap §3.2):
- **T-001:** Drift `schemaVersion` 1'de kilit + `MigrationStrategy` iskeleti
- Aynı commit'te ilk `migration_test.dart` (Testing §3.1 kuralı)
- `feat/sprint-0.1-migration` dalında başla

---

## 18. Onay & Versiyon

| Versiyon | Tarih | Değişiklik | Onay |
|----------|-------|------------|------|
| 1.0 (taslak) | 2026-05-18 | İlk taslak — 5 dokümanın workflow'a bağlanması; son doküman | ⏳ Beklemede |
