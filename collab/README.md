# Claude ↔ Codex Ortak Çalışma

Claude Code ve Codex Fit Pack'te birlikte çalışır; birbirleriyle
`tools/collab.sh` üzerinden yazışır. Samet her yazışmayı dosyadan izler ve
kararları verir.

## Samet nasıl izler

```bash
tools/collab.sh ui                   # izleme ekranı: http://127.0.0.1:8765
tools/collab.sh list                 # terminalde yazışma listesi
tools/collab.sh watch <konu>         # terminalde canlı izle (Ctrl+C ile çık)
```

İzleme ekranı (`tools/collab_viewer/`) mesajları iki tarafın oturum
kayıtlarıyla birleştirir: iki mesaj arasında kimin hangi dosyayı okuduğu,
neyi aradığı, hangi komutu çalıştırdığı, web'de neye baktığı. Sağ panelde
yazışma boyunca bakılan dosyalar ve web kaynakları toplanır. Cevap yazılırken
karşı tarafın adımları canlı akar. Yalnız bu bilgisayarda (127.0.0.1) açılır;
okuma yapar, hiçbir şey yazmaz.

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

## İş paylaşımı (Samet onayı: 2026-10-10)

1. **Her işin tek uçtan uca sahibi var.** Ekran, veri, test ve doküman aynı
   tarafta biter; iş ekran/veri diye bölünmez.
2. **Diğer taraf riske göre inceler.** Senkron, hesap, veri göçü ve sunucu
   işlerinde derin inceleme; basit görsel düzeltmede kısa kontrol.
3. **Araca bağlı işler doğal sahibinde:** iOS Simulator'da görsel doğrulama
   Codex'te; Supabase'e kurulum/SQL Claude'da. Sahip bunları karşı taraftan
   yazışmayla ister.
4. İşin sahibi yazışmanın ilk mesajında yazılır: sahip, inceleyen, dal,
   çalışma kopyası, başlangıç commit'i. Birleşen sonuç yeniden doğrulanır
   (`flutter analyze` + `flutter test`).
5. **Ölçüm:** her iş bitince NEXT_TASKS'taki kaydına süre, Samet'in harcadığı
   dakika, yeniden çalışma ve sonradan bulunan hatalar not edilir; birkaç iş
   sonra yöntem gözden geçirilir.

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
