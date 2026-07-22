# Operatör panelleri

Supabase'deki veriyi okuyan iki HTML sayfası. **claude.ai artifact olarak
yayınlanır** ve orada çalışırlar — bu klasör kaynak kopyadır (artifact'ler
kaybolursa buradan yeniden yayınlanır).

| Dosya | Ne işe yarar |
|---|---|
| `users.html` | Kullanıcı listesi + kullanıcı profili (antrenman/beslenme/ölçüm logları) |
| `dashboard.html` | Kişisel veri panosu (özet, harekete göre hacim, son seanslar) |

## Nasıl çalışıyorlar

Veriye **claude.ai Supabase bağlayıcısı** üzerinden ulaşıyorlar
(`window.claude.mcp.callTool('…','execute_sql',…)`). Bağlayıcı yönetim
yetkisiyle çalıştığı için `auth.users` okunabiliyor ve RLS aşılıyor.

**Bu yüzden sayfalar yalnız claude.ai içinde ve yalnız bağlayıcısı olan
kullanıcıda çalışır.** Linki başkasına verirsen sayfa açılır ama veri gelmez.

## Yayınlama

Claude Code oturumunda: `Artifact` aracına dosya yolunu ver, yanına
`capabilities: {mcp: {servers: [{server: 'claude_ai_Supabase',
tools: ['execute_sql']}]}}` (users.html ayrıca `downloads: true` ister — CSV).

## Bilinen tuzaklar

1. **Bağlayıcının çağrı adı manifestteki ön ekle aynı değil.** Manifestte
   `claude_ai_Supabase` yazılır, çağrıda bağlayıcının *görünen adı* istenir
   ("Supabase"). Sayfalar bu yüzden adı sabitlemiyor, `listTools()` ile
   `execute_sql` sunan bağlayıcıyı bulup onu kullanıyor.
2. **Cevap zarfı.** `execute_sql` sonucu düz JSON değil; metin gövdesi içinde
   `<untrusted-data-…>` sınırları arasında geliyor. **Etiket uyarı cümlesinde
   de geçtiği için** ilk eşleşmeden ayrıştırmak JSON'un başına düz metin
   karıştırır — `extract()` bu yüzden SON açılış etiketini baz alır.
3. **Supabase ücretsiz planı ~1 hafta hareketsizlikte projeyi duraklatır.**
   Panel o zaman veri çekemez; Supabase panelinden "Restore project" yeter.

## Gerçek ürün yapmak istenirse

Artifact yerine kendi alan adında bir panel: statik site (Cloudflare Pages /
Vercel, ücretsiz) + `@supabase/supabase-js` + anon anahtar. Kritik kısım
yetkilendirme: `admins` tablosu + `is_admin()` + **security-definer** SQL
fonksiyonları (service role anahtarı tarayıcıya ASLA konmaz). Tahmini ~2 akşam.
Karar: yayından sonra — gerçek kullanıcı olmadan admin paneli erken iş
(2026-07-22).
