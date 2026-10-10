# Claude ↔ Codex Ortak Çalışma

Claude Code ve Codex Fit Pack'te birlikte çalışır; birbirleriyle
`tools/collab.sh` üzerinden yazışır. Samet her yazışmayı dosyadan izler ve
kararları verir.

## Samet nasıl izler

```bash
tools/collab.sh list                 # yazışmalar (en yeni üstte)
tools/collab.sh watch <konu>         # canlı izle (Ctrl+C ile çık)
```

Dosyalar: `collab/threads/<konu>.md`. Her tur `### Gönderen → Alıcı · tarih`
başlığıyla eklenir. Oturum kimlikleri aynı klasörde `.<konu>.*-session`
dosyalarında durur (sonraki tur aynı oturumu sürdürür). Ham kayıt: Codex `~/.codex/sessions/…`, Claude
`claude --resume <kimlik>`.

Yazışmalar git'e girmez (depo herkese açık); kalıcı kararlar dokümanlara
(docs/, NEXT_TASKS.md) yazılır.

## Yazışma nasıl yapılır

```bash
tools/collab.sh new   jev-deneyi "Jev Türkçe eşleme deneyi"
tools/collab.sh codex  jev-deneyi "mesaj"   # Claude yazar, Codex cevaplar
tools/collab.sh claude jev-deneyi "mesaj"   # Codex yazar, Claude cevaplar
```

- Cevap veren taraf **salt okuma** modundadır (Codex `read-only` sandbox;
  Claude yalnız Read/Glob/Grep araçları, MCP yok): tartışırken dosya değişmez.
  Değişiklik önerisi metin ya da fark (diff) olarak yazılır.
- Konu başına aynı anda tek çağrı (kilit). Başarısız/iptal edilen tur dosyaya
  durum satırıyla yazılır.
- Worktree'den çağrılsa da kayıt ana klasördeki `collab/threads/`e düşer.
- Her mesaja yazışma dosyasının yolu eklenir; cevap veren önceki turları
  oradan okuyabilir.
- Bir konu en fazla ~4 tur sürer. Anlaşma olmazsa iki görüş yazılır, karar
  Samet'e bırakılır.
- Her cevabın sonunda karar gerekiyorsa **"Samet'e soru:"** bölümü olur.

## Rol dağılımı (önerilen — Samet onayı bekliyor)

| Alan | Sahibi | Diğeri |
|---|---|---|
| Ekran, tema, etkileşim, erişilebilirlik, iOS Simulator'da görsel doğrulama | Codex | inceler |
| Hesap mantığı, veritabanı/şema göçü, senkron, sunucu (Edge Function), testler, dokümanlar | Claude | inceler |

Bu, uzmanlığa göre **varsayılan** paylaşımdır. İşi uygulayan, o işin
testlerinden ve doküman güncellemesinden de sorumludur.

Bir işte iki taraf da varsa önce **sözleşme** (veri tipi, sorgu kimlikleri,
rota) yazışmada sabitlenir, sonra paralel çalışılır. Her iş yazışmasının
başında şunlar yazılır: dal, çalışma kopyası, başlangıç commit'i, ortak
dosyaların sahibi, birleştirecek taraf. Birleşen sonuç yeniden doğrulanır
(`flutter analyze` + `flutter test`).

## Kod yazarken çakışmama kuralları

1. Her iş **ayrı dal + ayrı `git worktree`** (`../fit_pack-<iş>`); ana
   klasörde (`main`) eşzamanlı kod yazılmaz.
2. Ortak dosyaların (rota tanımları, `.arb` çevirileri, `pubspec.yaml`,
   üretilen `*.g.dart`, şema) her işte **tek sahibi** vardır; sahip
   yazışmanın başında belirtilir.
3. Biri yazar, diğeri inceler: inceleme yazışmaya
   `tools/collab.sh <diğeri> <konu> "inceleme: <dal>"` ile istenir.
4. Commit'te yalnız kendi dosyaları açık yolla eklenir (`git add -A` yok).
5. **Push ve cihaza kurulum Samet onayından sonra** — görev verilirken
   açıkça yetki verildiyse tekrar sorulmaz. Tasarım dokümanı yalnız
   CONVENTIONS §7b ölçütlerine giren işlerde gerekir; o doküman da Samet
   onayıyla koda geçer.

## Samet'in rolü

- Yazışmayı başlatabilir ("Codex'le şunu konuşun") ya da sonradan okur.
- "Samet'e soru:" bölümlerini cevaplar; cevap, işi yürüten tarafa iletilir.
- Sıra ve kapsam kararları yalnız Samet'tedir (NEXT_TASKS.md).
