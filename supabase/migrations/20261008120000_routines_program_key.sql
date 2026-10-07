-- Fit Pack — Hazır program kataloğu: rutinde program anahtarı (docs/28)
--
-- KARAR ÖZETİ
-- Yerel şema v14'te `routines`'a nullable `program_key` eklendi: Keşfet'ten
-- eklenen rutin hangi hazır programdan geldiğini bilir → Rutinlerim'de program
-- adıyla gruplanır. Kullanıcının kendi rutinlerinde NULL.
--
-- ⚠️ SIRA ŞART: bu SQL v14 uygulamasından ÖNCE üretime uygulanır. Kolon
--    sunucuda yoksa v14 istemcinin rutin gönderimi "kolon bulunamadı"
--    (PGRST204) ile düşer ve arkasındaki tablolar kuyrukta bekler.
-- ⚠️ ESKİ İSTEMCİ: kolonu göndermez → NULL kalır, bir şey bozulmaz.
--
-- CHECK kısıtı yok: anahtar kümesi istemcideki katalogla büyür; sunucuda
-- kısıt, yeni program ekleyen istemcinin gönderimini kilitlerdi.
--
-- GERİ DÖNÜŞ: nullable ve eklemeli; geri almak gerekmez.

alter table public.routines
  add column if not exists program_key text;

comment on column public.routines.program_key is
  'Rutinin kopyalandigi hazir program (ornek: ppl_intermediate). NULL = kullanicinin kendi rutini (docs/28).';
