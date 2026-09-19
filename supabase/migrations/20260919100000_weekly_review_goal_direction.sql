-- Fit Pack — Haftalık değerlendirme: profilde hedef yönü (docs/22 §6)
--
-- KARAR ÖZETİ
-- Uygulamanın yerel şeması v12'de `user_profile`'a iki nullable kolon ekledi:
-- `goal_direction` ('lose' | 'maintain' | 'gain') ve `goal_direction_since`.
-- `user_profile` senkron edilen bir tablo → aynı kolonlar sunucuda da olmalı.
--
-- ⚠️ SIRA ŞART: bu SQL, v12 uygulamasından ÖNCE (ya da aynı anda) üretime
--    uygulanır. Kolon sunucuda yoksa v12 istemcinin profil gönderimi "kolon
--    bulunamadı" (PGRST204) ile düşer; profil gönderim sırasında İLK tablo
--    olduğu için arkasındaki bütün tablolar da beklemede kalır.
--
-- ⚠️ ESKİ İSTEMCİ: kolonları hiç göndermez → NULL kalır, hiçbir şey bozulmaz.
--
-- CHECK kısıtı BİLİNÇLİ OLARAK YOK: değer kümesi istemcide tip olarak
-- (`GoalDirection`) korunuyor. Kısıt, ileride eklenecek bir değeri gönderen
-- istemcinin profil gönderimini (ve arkasındaki kuyruğu) kilitlerdi; tek
-- kullanıcılı bu uygulamada bu risk, kısıtın getirdiği korumadan büyük.
--
-- GERİ DÖNÜŞ: kolonlar nullable ve eklemeli; geri almak gerekmez.

alter table public.user_profile
  add column if not exists goal_direction text;

alter table public.user_profile
  add column if not exists goal_direction_since timestamptz;

comment on column public.user_profile.goal_direction is
  'Kilo hedefinin yonu: lose | maintain | gain. NULL = secilmemis (docs/22 §3.4).';
comment on column public.user_profile.goal_direction_since is
  'Yonun secildigi an. Haftalik degerlendirme bu tarihten onceki haftalari yon bilinmiyor sayar.';
