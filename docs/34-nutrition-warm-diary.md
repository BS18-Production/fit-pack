# Beslenme — Sıcak Günlük (2026-10-09)

## Karar özeti

Samet’in “Bu şekilde değiştir” onayıyla rafine Sıcak Günlük prototipi Beslenme dalına uygulandı. Özet tek enerji halkasıyla kalan kaloriyi öne çıkarır; günlükte öğün başlığı, besin sayısı ve kcal görünür, yiyecek makroları isteğe bağlıdır. Alt eylemler ayrı alanda sabit kalır.

Şema v14, hedef formülleri, mevcut DAO/provider’lar ve kayıt/senkron mantığı değişmedi. Ana Sayfa’nın ortak `NutritionSummaryCard` bileşeni korunur. Yeni palet `NutritionTheme` ile yalnız Beslenme ve buradan açılan panellerde kullanılır; ortak Velocity gezinme ve Signature SVG ailesi korunur.

## Bileşenler ve davranış

- Koyu sıcak kömür / açık krem yüzeyler; lime ana eylem, amber yardımcı eylem, mercan karbonhidrat ve lila yağ.
- Tek kalori halkası: ince iç yüzey, 11 birim çizgi, lime–amber geçiş ve konum noktası. İlk gösterim anlık; kayıt değişimi 360 ms. Hareket azaltma açıkken animasyon yok. Kalan/üzerinde/hedefte durumları metinle ve ekran okuyucu etiketiyle belirtilir; halka %100’de sınırlandırılır.
- Standart genişlikte üç makro sütunu; dar ekran/büyük metinde satırlar. Büyük metinde halka üstte, alınan enerji/hedef altta yan yana.
- Dört öğün, ince ayraçlar ve aç/kapa başlıkları. İlk yüklemede en son eklenmiş kaydın öğünü açık. Yeni kayıt gelen öğün açılır; diğer öğünlerin yerel daraltma tercihi aynı günün veri güncellemelerinde korunur. Tarih değişince günün kendi ilk düzeni kurulur.
- Yiyecek adı/miktarı/kcal; “Makroları göster” ile P/K/Y. Görünür sil ve kaydırarak sil, mevcut geri alma ile çalışır.
- Öğün menüsünden geçmişten kopyalama; boş günde önceki günün tamamını kopyalama; mevcut busy/transaction korumaları aynı.
- “Her zamanki öğün” uygun öğünün içinde kısa satır. Mevcut kayıtlarda fotoğraf alanı olmadığı için stok somon fotoğrafı kullanıcı yemeğine atanmaz; tutarlı öğün simgesi ve gerçek ad/değerler kullanılır. “Şimdi değil”, tek dokunuş ekleme ve geri alma korunur.
- Haftalık kayıt ritmi/hatırlatıcı günlüğün altında.
- Yemek ekleme ve doğrudan barkod eylemi safe area ve Velocity çubuğu üzerinde. Barkod `AddFoodSheet(startWithBarcode: true)` üzerinden aynı tarama → ürün → miktar akışını başlatır; kamera iptalinde panel açık kalır.
- Hedefler mevcut Ayarlar rotasına açılır. Karbonhidrat/yağ bağımsız düzenlenmez; `deriveMacroGoals` korunur.

## Doğrulama

`warm_nutrition_test.dart` izole bellek DB’de öğün daraltma/yeni kayıt, silme/geri alma, makro görünümü, kaydırırken sabit eylem, gerçek ekleme panelinde art arda ekleme ve panel içi geri almayı kontrol eder. Halka testi sıfır/hedef/üstü, erişilebilir etiket ve hareket azaltmayı kontrol eder.

`neon_design_test.dart` gerçek router/sağlayıcılarla TR/EN, koyu/açık, 393/320 pt ve %130/%160 metin render’larını kontrol eder. Gerçek iPhone 17 simülatöründe yeni derleme açıldı; geçmiş gündeki halka ve gerçek kayıtlar, öğün hizası, kaydırma ve sabit alt eylemler görsel olarak kontrol edildi. Cihazdaki hesap verisine QA kaydı eklenmedi; yazma senaryoları yalnız izole test DB’sinde çalıştırıldı.

Android arm64 debug APK kaynaklardan derlendi. Android emülatörü bu oturumda Qt `neon` / başlatıcı hatasıyla açılamadı; Android cihaz görsel QA açık. Gerçek iPhone’a kurulum sonraki kullanıcı isteğiyle tamamlandı (aşağıda).

Sonuç: analiz 0 sorun, tüm 742 test geçti. Son takvim kenar boşluğu düzeninden sonra 6 odaklı işlev/layout testi tekrar geçti; analiz ve Android APK yeniden alındı. Son Xcode çalıştırması 09:26’da iPhone 17 simülatöründe açıldı.

Görsel kanıtlar (yerel çalışma çıktısı):
- `outputs/nutrition-warm-implementation/iphone17-summary-final.png` — gerçek simülatör, 09:28.
- `outputs/nutrition-warm-implementation/iphone17-diary.png` — gerçek simülatör, öğün günlüğü.
- Aynı klasördeki `dark-tr--nutrition.png`, `light-en--nutrition.png`, `narrow-tr--nutrition.png`, `large-en--nutrition.png` — izole örnek verili gerçek Flutter render’ları.

## Gerçek iPhone güncellemesi — 2026-10-09 09:50 (+03)

Samet’in “iPhone’uma gönder” isteğiyle mevcut test edilmiş kaynaklardan
`flutter build ios --release --no-pub` çalıştırıldı. Xcode derlemesi başarılı
(61,5 sn), çıktı `build/ios/iphoneos/Runner.app` (36,5 MB).
`codesign --verify --deep --strict` başarılı; paket kimliği
`com.sametorhan.fitPack`.

Samet’s iPhone (iPhone 17, iOS 26.6) üzerine `devicectl device install app`
ile yerinde güncelleme başarılı. Uninstall veya veri konteyneri değiştirme
yapılmadı. `devicectl device process launch --terminate-existing` başarılı;
sonraki süreç sorgusunda yeni kurulum yolundaki Runner, PID 8436 ile çalışıyor.
Telefonun ekran paylaşımı iOS 27+ istediği için bu kurulumda uzaktan görsel
kontrol yapılmadı; yeni Beslenme görünümünün telefon kontrolü Samet’te.

Yerel kanıtlar: `/private/tmp/fitpack-warm-iphone-build.log`,
`/private/tmp/fitpack-warm-iphone-install.json`,
`/private/tmp/fitpack-warm-iphone-launch.json`.
