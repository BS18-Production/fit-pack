-- Fit Pack — Tartıdan kilo (docs/40) + sağlık verisi açık rızası (docs/41)
--
-- KARAR ÖZETİ
-- Yerel şema v17: `body_measurements`'a ölçümün kaynağı (elle / Apple Sağlık /
-- Health Connect), platform örnek kimliği, kaynak uygulama ve gizleme bayrağı;
-- `user_profile`'a sağlık verisi açık rızasının zamanı ve metin sürümü
-- (KVKK md. 6, GDPR md. 9/2-a — rızanın ispatı). Samet kararı: içe alınan
-- kilo bulutta tutulur.
--
-- ⚠️ SIRA ŞART: bu SQL v17 uygulamasından ÖNCE uygulanır. Kolon sunucuda
--    yoksa v17 istemcinin ölçüm/profil gönderimi "kolon bulunamadı"
--    (PGRST204) ile düşer ve arkasındaki tablolar kuyrukta bekler.
-- ⚠️ ESKİ İSTEMCİ: kolonları göndermez → NULL kalır (= elle giriş, rıza yok).
--
-- Tekillik sunucuda kısıtla değil `uid` ile sağlanır: içe alınan satırın
-- `uid`'i platform örnek kimliğinden türetilir (UUID v5), iki cihaz aynı
-- örneği alırsa aynı satıra yazar (docs/40 W-2).
--
-- GERİ DÖNÜŞ: nullable ve eklemeli; geri almak gerekmez.

alter table public.body_measurements
  add column if not exists source text,
  add column if not exists source_ref text,
  add column if not exists source_app text,
  add column if not exists hidden boolean;

comment on column public.body_measurements.source is
  'NULL/manual = elle giris; health = Apple Saglik / Health Connect (docs/40).';
comment on column public.body_measurements.source_ref is
  'Platform ornek kimligi (HealthKit UUID / Health Connect kayit kimligi).';
comment on column public.body_measurements.source_app is
  'Olcumu yazan uygulama (ornek: Withings).';
comment on column public.body_measurements.hidden is
  'Kullanici ice alinan olcumu gizledi; yeniden ice alinmaz (docs/40 W-6).';

alter table public.user_profile
  add column if not exists health_consent_at timestamptz,
  add column if not exists health_consent_version integer;

comment on column public.user_profile.health_consent_at is
  'Saglik verisi acik rizasi zamani; NULL = riza yok (docs/41 §3).';
comment on column public.user_profile.health_consent_version is
  'Rizanin verildigi metin surumu; metin degisince riza yeniden istenir.';
