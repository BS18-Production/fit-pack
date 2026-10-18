# Besin kaydı miktar düzenleme

## Karar özeti

Yanlış porsiyon bugün silip yeniden ekleniyor. Satıra dokununca mevcut miktar
paneli açılır, Güncelle aynı kaydın gramını ve hesaplanmış dört makrosunu
birlikte değiştirir. Yeni satır/silme yerine mevcut kaydı güncellemek seçildi:
kayıt kimliği, günü, öğünü ve kaynak besini korunur.

Şema/senkron kodu değişmez. Drift güncellemesi mevcut SQL güncelleme
tetikleyicisinden geçer; yerel sıra ve gönderim kuyruğu mevcut mekanizmayla
oluşur. Eski sürüm de yeni miktarı okur; geri dönüş uyumludur.

Samet'in görevde verdiği düzenleme yetkisi yeterli; ek karar yok.
Doğrulama: kimlik korunması, toplamların değişimi, geçersiz miktarın reddi,
reaktif ekran ve mevcut senkron tetikleyicisinde bekleyen güncelleme.
