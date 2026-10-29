# Fit Pack — Faz 1 yönetim arayüzü

Yerel, bağımlılıksız web arayüzü. Eski Claude bağlayıcılı sayfalardan bağımsızdır;
mevcut Supabase Auth hesabı ve `product-data` sunucu ucu kullanılır.

## Yerel önizleme

Depo kökünde:

```sh
python3 -m http.server 8787 --bind 127.0.0.1 --directory tools/admin/phase1
```

Tarayıcıda `http://127.0.0.1:8787` açılır. **Sentetik demoyu aç** seçeneği
hiçbir ağ/auth isteği yapmaz; `example.test` adresleri ve sayılar uydurmadır.
Demo bir canlı backend doğrulaması değildir. Dosyalar `file://` yerine yerel
HTTP üzerinden açılmalıdır (ES module yükleme).

## Kontroller

```sh
node --test tools/admin/phase1/*.test.mjs
node --check tools/admin/phase1/app.mjs
```

Saf veri projeksiyonu, izinli alanlar, anahtar/adres doğrulaması, auth/MFA
protokolü, oturum yarışları ve destek istekleri sahte fetch ile doğrulanır.
`ui.test.mjs` gerçek uygulama olay işleyicilerini küçük bir DOM yüzeyiyle
çalıştırır: demo ağ yapmaz; geç yanıt çıkış sonrası hesabı açamaz; hatada eski
hesap temizlenir; bilinmeyen kurulum ve maskelenmiş alanlar doğru gösterilir.
Canlı kullanıcı veya sağlık kaydı kullanılmaz. Gerçek Supabase MFA/rol/CORS
ve SQL davranışı bu tarayıcı birim testleriyle kanıtlanmış sayılmaz.

## Canlı erişim — ayrı etkinleştirme onayı gerekir

1. İncelenmiş sunucu göçleri ve Edge Function ayrıca yayımlanmış olmalıdır.
2. `PRODUCT_ADMIN_ENABLED` kapalı başlar. Yönetici listesi boş başlar.
3. `PRODUCT_ADMIN_ORIGINS`, panelin **tam origin** adresini içermelidir;
   varsayılan CORS erişimi yoktur. Yerelde örnek: `http://127.0.0.1:8787`.
4. Mevcut Supabase hesabında doğrulanmış TOTP yöntemi ve sunucuda ilgili
   `overview` / `support` yetkisi gerekir. Panel yöntem kaydetmez, yetki atamaz.
5. Formda proje adresi, yalnız publishable/anon anahtar ve mevcut hesapla
   giriş yapılır. `sb_secret_` / service-role anahtarları kabul edilmez.

Bu klasör hiçbir rolü/ayarını etkinleştirmez ve otomatik yayın yapmaz.
Üretim rolü, sunucu bayrağı, CORS, alan adı ve yayın ayrı inceleme konusudur.
Gerçek sunumda HTTPS ve HTTP `Content-Security-Policy: frame-ancestors 'none'`
başlığı eklenmeli; HTML meta etiketi frame-ancestors uygulayamaz.

## Veri ve erişim sınırı

- Ürün özeti yalnız izinli ölçüm kapsamını gösterir. Kayıt tarihleri ve son
  giriş kullanım ziyareti sayılmaz. Bilinmeyen sayı `—`, bulunmayan tarih
  **Henüz bildirilmedi** olur. Geçmişten olay üretilmez.
- A4 kurulum adımları cevaplar olmadan, bağımsız gözlenen erişim olarak
  gösterilir; sıralı dönüşüm hunisi sayılmaz. A2 sürüm/build/platform/ana OS
  gruplarında ziyaret ve farklı hesap sayısı vardır; bir hesap birden fazla
  grupta bulunabileceğinden grup hesapları toplanmaz. Bu iki dizi eski sunucu
  yanıtında yoksa arayüz boş ölçüm açıklaması gösterir.
- Kullanıcı desteği: tam e-posta/UUID ve sabit destek amacı gerekir. Tam
  e-posta yalnız isteğin JSON gövdesinde gönderilir, URL'ye yazılmaz ve arama
  alanından hemen temizlenir. Yanıtta yalnız maskeli adres gösterilir.
- Kategori sayıları ve son kayıt/sunucu değişikliği tarihleri gösterilir;
  set, kilo, tekrar, besin, gram, kalori, ölçüm değeri, fotoğraf ve not yoktur.
- Yanıtlar izinli alanlara projekte edilir; sunucudan gelen fazladan alanlar
  render edilmez. Metinler `textContent` ile yazılır.
- Destek yetkisi ve denetim kaydı **sunucu işidir**. 403/503 yanıtı veya
  bozuk veri halinde eski hesap sonucu temizlenir; sıfır kayıt gibi sunulmaz.
- Oturum ve anahtarlar yalnız bellekte; parola formdan temizlenir. Sekmeyi
  yenilemek oturumu sonlandırır. Yeni kayıt/parola sıfırlama/impersonation yoktur.
- Ham ürün olayları 30 gün, tercih/erişim geçmişi 180 gün politikasının
  uygulanması sunucu saklama işinin ayrıca etkinleştirilmesine bağlıdır.
- Analitik tercihi, işlevsel bildirim ve pazarlama/kişiselleştirme izinleri
  farklı amaçlardır. Panel kampanya, gönderim veya sağlık profillemesi yapmaz.

## Supabase kaynakları (REST yolları doğrulaması)

- [MFA challenge](https://supabase.com/docs/reference/javascript/auth-mfa-challenge)
- [MFA verify](https://supabase.com/docs/reference/javascript/auth-mfa-verify)
- [Resmî Auth istemci kaynağı](https://github.com/supabase/auth-js/blob/master/src/GoTrueClient.ts)

TOTP faktörleri `GET /auth/v1/user` yanıtındaki doğrulanmış `totp` öğelerinden
seçilir; `/factors/:id/challenge` ve `/factors/:id/verify` çağrılır. Sunucu
son yetkiyi yeniden denetler. Yöntem yoksa gerekli kurulum ayrı yapılmalıdır.
