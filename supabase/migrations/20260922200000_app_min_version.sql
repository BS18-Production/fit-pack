-- Fit Pack — Asgari istemci sürümü kapısı (docs/23 §3)
--
-- KARAR ÖZETİ
-- Sunucu, desteklediği en eski istemci build numarasını söyler. Altındaki
-- istemci kullanıcıyı zorunlu güncelleme ekranına alır ve uygulamayı
-- kullandırmaz.
--
-- NE ÇÖZÜYOR
-- Bugünkü yayın kuralı (docs/20 §11) "sunucu ile telefon BİRLİKTE güncellenir"
-- diyor. Tek kullanıcıda bu bir zamanlama meselesiydi; mağazada imkânsız —
-- güncelleme kademeli yayılır, kullanıcıların bir kısmı haftalarca eski
-- sürümde kalır. Eklemeli yapılamayan bir sunucu değişikliği gerektiğinde
-- (ör. senkron v2 Aşama 6'nın birincil anahtar değişimi) eski istemci sessizce
-- yazamaz hale gelirdi; bu tablo onun yerine açık bir "güncelle" ekranı verir.
--
-- ⚠️ TABLO ATIL BAŞLAR: min_build = 1, bugünkü build 1 → hiç kimse kapıya
--    takılmaz. Kapıyı yükseltmek panelden tek bir UPDATE'tir. Amaç, kapının
--    İLK SÜRÜMDE cihazlarda bulunmasıdır: sonradan eklenirse ondan önceki
--    sürümdeki kullanıcılar zaten güncellemeye zorlanamaz.
--
-- ⚠️ GERİ DÖNÜŞ: tablo salt okunur ve kullanıcı verisine dokunmuyor.
--    Kapıyı kapatmak = min_build'i 1'e çekmek. Tabloyu düşürmek de güvenli:
--    istemci okuyamadığı durumu "kapı yok" sayar (docs/18 Kural 1).

create table if not exists public.app_min_version (
  platform   text        primary key,   -- 'android' | 'ios'
  min_build  integer     not null,
  -- Kullanıcıya gösterilecek kısa açıklama. NULL ise istemci kendi
  -- yerelleştirilmiş varsayılan metnini kullanır (dil bilgisi sunucuda yok).
  message    text,
  updated_at timestamptz not null default now()
);

alter table public.app_min_version enable row level security;

-- HERKES OKUR, oturum açmamış kullanıcı dahil: kapı girişten ÖNCE de
-- çalışmalı. Eski bir istemci giriş ekranında takılıp kalmasın, "güncelle"
-- desin.
drop policy if exists "read min version" on public.app_min_version;
create policy "read min version" on public.app_min_version
  for select using (true);

grant select on public.app_min_version to anon, authenticated;

-- Yazma yetkisi YOK (ne anon ne authenticated): kapıyı yalnız panel
-- (service_role) yükseltir. Bir istemcinin kendi kapısını indirebilmesi
-- kapının tamamını anlamsız kılardı.
revoke insert, update, delete on public.app_min_version from anon, authenticated;

-- Atıl başlangıç: bugünkü build 1, kapı kimseyi durdurmaz.
insert into public.app_min_version (platform, min_build)
values ('android', 1), ('ios', 1)
on conflict (platform) do nothing;
