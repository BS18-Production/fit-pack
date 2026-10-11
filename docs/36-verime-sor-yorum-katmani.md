# 36 — "Verime sor" v1: veri + yorum katmanı

> **Durum:** ✅ Samet onayı (2026-10-10) · kaynaklar doğrulandı (Claude) ·
> Codex incelemesi bekliyor (kota 16:53'te açılıyor). Uygulama kodu yok;
> docs/35 betiği sözleşme v2'ye taşınıyor.
> **Tarih:** 2026-10-10 · **Sahip:** Claude · **İnceleyen:** Codex
> (yazışma: `collab/threads/yorum-katmani.md`)
> **İlgili:** [docs/35 — Jev soru eşleme deneyi](35-jev-soru-esleme.md) ·
> [docs/22 — Haftalık değerlendirme (A1)](22-weekly-review.md) ·
> [docs/21 #10](21-feature-roadmap.md)

---

## 0. Karar özeti

**Neden.** Samet'in ilk gerçek soruları (`tools/jev_eval/discovery_samet.jsonl`)
tasarımı değiştirdi: 5 sorunun 4'ü **sayı + yorum** istiyor ("kaç set göğüs
çalıştım, hipertrofi için yeterli mi?", "son 1 ayda kaç kilo verdim, sağlıklı
mı?", "50k hacim ne ifade ediyor?"), biri bugüne dönük öneri ("akşam ne
yiyeyim?"), biri sözleşmede olmayan bir sorgu ("en çok hangi hareket?").
docs/35 sözleşmesi v1 bunların hepsini "tavsiye/kapsam dışı" diye reddederdi —
Jev testi geçse bile özellik gerçek kullanımda işe yaramazdı.

**Ne değişecek.** Cevap iki parça olur: **veri** (hesap motoru, değişmedi) +
**yorum** (yeni, **kural tabanlı**, kaynağı yazılı). Jev'e "yorum istiyor mu?"
sorusu eklenir; yorum isteyen soru artık reddedilmez, veri + yorumla
cevaplanır. Sözleşmeye iki sorgu eklenir: `today_remaining`, `top_exercises`.

**Seçilen yol: kural tabanlı yorum, yapay zekâ metni yok.** Her yorum bir
kılavuza (kaynaklı) ya da kullanıcının **kendi geçmişine** dayanır; cümleleri
şablondur. *Elenen:* yorumu bir dil modeline (Claude Haiku) yazdırmak —
esnek ama sağlıkla ilgili cümlelerde doğrulanamaz, maliyet ve gizlilik kararı
ister. Kuralı olmayan yorum isteği v1'de "bunu yorumlayamıyorum, verin şu"
der; dil modeli ileride ayrı karar.

**Gerçek veriye etkisi.** Yok; yalnız okuma. Şema değişmez (§5'teki açık
soru hariç).

**docs/35'e etkisi.** Sözleşme v2 → Jev isteği değişir → parmak izi değişir →
**ayar yeniden yapılır ve yeniden dondurulur** (betik eski dondurmayı zaten
reddeder). Kabul ölçütü ve süreç aynı.

---

## 1. Sözleşme v2 — eklenenler

| Kimlik | Kullanıcının sorduğu | Hesap | Dönem |
|---|---|---|---|
| `today_remaining` | Bugün hedefime ne kadar kaldı, akşam ne yiyebilirim | **yeni:** günlük hedef − bugünkü kayıtlar (kalori, protein) | yalnız bugün |
| `top_exercises` | En çok hangi hareketi yaptım | **yeni:** set sayısına göre ilk 5 hareket | hafta, son 30 gün, tümü |

Jev isteğine yeni `noul`: **`wants_interpretation`** — "Kullanıcı yalnız sayıyı
değil, sayının **ne anlama geldiğini** de soruyor mu (yeterli mi, iyi mi,
sağlıklı mı, anlamlı mı, normal mi)?" Eski `advice` sorusu daralır: **eylem
veya kişiye özel reçete** (program yaz, kaç kilo basayım, ilaç/takviye, kayıt
sil, sakatlık) → hâlâ geri dönüş.

| Soru tipi | Örnek | v1 (docs/35) | v2 |
|---|---|---|---|
| Yalnız veri | "bu hafta kaç set" | veri | veri |
| Veri + yorum | "…hipertrofi için yeterli mi" | **ret** | veri + kural yorumu |
| Yorumun kuralı yok | "bench'im iyi mi" (norm yok) | ret | veri + "kendi geçmişine göre" yorumu ya da "yorumlayamıyorum" |
| Reçete/eylem/tıbbi | "dizim ağrıyor devam edeyim mi", "programı yaz" | ret | ret (değişmedi) |

## 2. Yorum kuralları

Her yorum kartında: **sayı · kılavuz aralığı · senin durumun · kaynak · "genel
kılavuz, kişisel tıbbi tavsiye değil"**. Aralık dışı durumlar suçlayıcı değil,
dikkat notu dilinde (docs/22 ile aynı ton).

| Sorgu | Yorum kuralı | Kaynak | Not |
|---|---|---|---|
| `muscle_balance` (kas grubu set) — **yalnız tamamlanmış hafta** ya da devam eden haftada "şu ana kadar" notuyla | Haftalık set: <10 "araştırmalarda daha fazla kas kazanımıyla ilişkilendirilen ~10 set/hafta düzeyinin altında"; ≥10 "bu düzeyde"; >20 "bu düzeyin ötesi için kanıt sınırlı" (uyarı değil, bilgi) | Schoenfeld, Ogborn, Krieger, *J Sports Sci* 2017;35:1073–82 (çevrim içi 2016): 15 çalışma; ≥10 set/kas/hafta, <5 ve 5–9'a göre daha fazla kazanım **eğilimi** (P = 0,074); set başına ~%0,37 ek kazanım | Bizim sayımız **birincil kasa yazılan tamamlanmış set**; çalışmalar zorlayıcı set sayar → kartta yazılır. "Yeterli" kelimesi kullanılmaz; kanıt bir eğilim |
| `weight_trend` + hedef yönü "ver" | Haftalık kayıp **kg olarak** CDC aralığıyla (~0,45–0,9 kg/hafta) karşılaştırılır: içinde "genel önerilen aralıkta", üstünde "önerilenden hızlı", altında "önerilenden yavaş". Ek bilgi (yargı değil): "kuvvet sporcularında ~%0,7/hafta kayıp yağsız kütleyi daha iyi korudu". **Kilo artışı** varsa "hedefinin tersi" (docs/22 dili), "yavaş kayıp" denmez. %1,5/hafta üstü uyarı notu **ürün tercihidir**, kaynak değil | CDC (kg aralığı). Garthe ve ark., *IJSNEM* 2011 (PMID 21558571): hedeflenen %0,7 ve %1,4/hafta, gerçekleşen ~%0,7 ve ~%1,0; yavaş grup diyet süresince daha çok yağsız kütle ve güç kazandı. 12 aylık takip **ayrı yayın** (PMID 21896944): gruplar arasında fark kalmadı | Yüzde aralığı (%0,5–1) kaynakla doğrudan gerekçelenmediği için kullanılmaz (Codex) | ≥2 ölçüm ve ≥14 gün yoksa yorum yok ("tek ölçüm trend sayılmaz", docs/22 kuralı) |
| `weight_trend` + yön "al" | %0,25–0,5/hafta "önerilen aralıkta"; üstü "önerilenden hızlı" | Iraki, Fitschen, Espinar, Helms, *Sports* 2019;7(7):154 (PMID 31247944, anlatı derlemesi): başlangıç/orta seviye için %0,25–0,5/hafta; ileri seviye daha temkinli | Seviye bilgisi yok → aralık "başlangıç/orta için" diye yazılır |
| `weight_trend` + yön "koru" / yok | Kendi ortalamasına göre ±%1 içinde "sabit" | — (kendi geçmişi) | Yön yoksa "hedef yönünü seçersen yorumlarım" |
| `workout_summary` (hacim, set, seans) | **Mutlak norm yok.** Önceki **8 tamamlanmış haftanın medyanına** göre: "%X üstünde/altında". Devam eden hafta "şu ana kadar" diye yazılır, tam haftayla yargılanmaz | — (kendi geçmişi) | "50k tek başına anlamlı değil; son 8 haftanın medyanı 42k" — "ortalama" yazılmaz |
| `strength_progress` / `exercise_history` | e1RM eğilimi: artıyor / sabit (3 hafta aynı = plato, A1 odak kuralı) / düşüyor | — (kendi geçmişi; docs/22 §3.3) | Hareketler arası norm ("bench'in iyi mi") yok |
| `protein_goal`, `nutrition_summary` | Hedefe göre: tutturulan gün oranı; ortalama/hedef. **İsteğe bağlı (§5):** ortalama g/kg, "~1,6 g/kg civarı ve üstü" ile karşılaştırma | Kendi hedefi; Morton ve ark., *Br J Sports Med* 2018;52:376–84 (49 çalışma, 1.863 kişi): ~1,6 g/kg/gün üstünde ek yağsız kütle kazanımı görülmedi (kırılma noktası, güven aralığı geniş); Iraki 2019: 1,6–2,2 g/kg | Kayıtsız gün ortalamaya girmez (docs/22 kuralı) |
| `today_remaining` | Kalan kalori/protein; **öneri:** son 30 günde o öğünde (ör. akşam) yediği yemeklerden kalan makroya sığanlar, en çok 3 | — (kendi geçmişi, deterministik) | Yeni yemek önermez; kayıt yoksa yalnız kalan miktar |

**Sağlık sınırı:** "sağlıklı mı" sorusu genel kılavuz **karşılaştırmasıyla**
cevaplanır, asla "sağlıklısın" sonucu üretilmez; her zaman "tıbbi
değerlendirme için uzmana danış" notu eklenir; haftalık kayıp %1,5'i aşarsa
not öne çıkar (ürün tercihi). **Hastalık/semptom bağlamı önceliklidir:**
"böbrek hastasıyım, bu protein sağlıklı mı?" → ret. Ağrı, sakatlık, ilaç,
takviye → ret (değişmedi).

**Hesap dili (Codex):** kilo yorumu ≥14 günlük pencere ister — kullanılan
pencere ve ölçüm sayısı kartta yazılır; yalnız bu haftanın verisiyle kilo
yorumu yapılmaz. Kısmi beslenme kayıtları "kaydedilen protein" diye
adlandırılır (#8 tamamlanmış gün yoksa). g/kg hesabında kullanılan kilo ve
tarihi görünür. Morton ~1,6 g/kg kişisel yeterlilik ya da güvenlik sınırı
olarak sunulmaz: "araştırmada bu düzeyin üstünde ek kazanım görülmedi".

## 3. Jev'e etkisi (docs/35 sözleşme v2)

- Sorgu seçeneklerine `today_remaining`, `top_exercises`; `out_of_scope`
  açıklaması daralır (yorum artık kapsam içi).
- Yeni `noul` `wants_interpretation`; `advice` açıklaması "reçete/eylem/tıbbi"
  diye daralır.
- `multi_intent` tanımı **ayrı hazır sorgular** üzerinden: aynı özetteki
  kalori+protein ya da set+hacim tek niyettir (Codex).
- `advice` tanımına hastalık/semptom bağlamı eklenir ("böbrek hastasıyım…").
- Karar sırası: çoklu niyet → reçete/eylem/kapsam dışı/düşük güven (geri
  dönüş) → eksik alan (netleştirme) → otomatik (**veri + yorum isteniyorsa yorum**).
- Yorum isteğinin yanlış algılanması zararsız tarafta kalır (fazladan yorum
  ya da eksik yorum; sayı yine doğru) — kabul ölçütüne girmez, ayrıca raporlanır.
- **Ölçüm (Codex):** yorum algılamada toplam doğruluğa ek olarak **yorum
  isteyen soruları yakalama oranı** (özellikle sağlık soruları); "dün / yarın"
  karşı örnekleri (`today_remaining`'e yanlış gitmesin); kabul setinde iki
  yorum etiketi de zorunlu.
- **Ayar seti v2:** mevcut 72 soru yeniden etiketlenir (`interp: true/false`);
  iki taraftan 15'er yeni "veri + yorum", `today_remaining`, `top_exercises`
  sorusu (kör). Samet'in 5 keşif sorusu ayar setine **girebilir** (tasarım
  girdisi), kabul setine **giremez**.
- Yeniden dondurma → kabul seti (Samet'in **yeni** 30 sorusu + bizimkiler).

## 4. İş sırası

1. Bu doküman: Codex incelemesi → Samet onayı.
2. docs/35 betiği sözleşme v2 + ayar seti v2 → ayar → Codex incelemesi → dondurma.
3. Kabul seti (boyut: §5) → tek seferlik kabul ölçümü → rapor.
4. Kabul çıkarsa uygulama işleri (ayrı iş, ayrı sahip): hazır sorular ekranı +
   yorum kuralları (`lib/features/insights/`, birim testli) → Supabase fonksiyonu
   → serbest soru ekranı.

## 5. Samet'in kararları (2026-10-10)

1. ✅ Kurallar ve dil (§2) uygun — "yeterli" denmez, kaynak ve "genel bilgi" notu her kartta.
2. ✅ Protein g/kg yorumu **eklenir** (Morton 2018; kayıtsız gün ortalamaya girmez).
3. ✅ Akşam yemeği önerisi **yalnız kendi geçmişinden** (o öğünde daha önce yedikleri); yeni yemek önerisi ayrı karar.
4. ✅ Kabul seti **120 soru** — sonradan (docs/35 §8.8) Samet'in soruları beklenmeden **60 Claude + 60 Codex**.
5. Antrenman hedefi türü profilde yok; set yorumu hipertrofi araştırmasıyla yapılır (hedef türü alanı ileride ayrı iş).

---

## 6. Kalite paneli (Samet onayı: 2026-10-11)

**Neden.** Kabul testi bizim yazdığımız sorularla ölçer; asistanın gerçek
kullanımda ne kadar doğru çalıştığını ancak gerçek kullanım gösterir. Samet'in
ilk önerisi "tüm kullanıcıların sohbetlerini gören admin paneli"ydi; sorular
**sağlık verisi** içerdiği için (KVKK'da özel nitelikli kişisel veri) ve bu
doküman "sorular saklanmaz" dediği için onun yerine **metinsiz** bir kalite
paneli seçildi. Ham metin yalnız kullanıcının açık rızasıyla.

### 6.1 Ne kaydedilir — soru başına bir olay (metin YOK)

| Alan | Örnek | Neden |
|---|---|---|
| zaman, sözleşme sürümü, model, dondurma parmak izi | `2`, `jev-1.13.0`, `319234e4` | Sürüm değişince oranları ayırmak |
| karar | `auto` / `clarify` / `multi` / `fallback` / `blocked` | Geri dönüş ve süzgeç oranı |
| seçilen sorgu + güven, dönem + güven, hareket türü (`ex`/`fam`/`none`) | `muscle_balance` 0,99 | Hangi sorguda zorlanıyor |
| yorum istendi mi (noul ≥ 0,5) | evet | Yorum katmanının kullanımı |
| **kullanıcı düzeltmesi** | "değiştir" → `workout_summary` | **En değerli sinyal:** yanlış eşlemenin gerçek kanıtı |
| netleştirmede seçilen seçenek | `last_30_days` | Belirsiz dönemlerin dağılımı |
| gecikme, token | 0,41 sn · 2.100 | Hız ve maliyet |

**Kaydedilmez:** soru metni, kullanıcının sayıları (kilo, kalori), hareket
**adı** (yalnız türü), cevap metni.

### 6.2 Panelde görünenler

- Haftalık oranlar: otomatik / netleştirme / geri dönüş / süzgeç; **düzeltme
  oranı** (otomatik cevaplardan "değiştir"e basılanlar ≈ gerçek yanlış oranı —
  kabul ölçütündeki %3 ile karşılaştırılır).
- Karışıklık listesi: "Jev X seçti → kullanıcı Y'ye düzeltti" çiftleri.
- Sorgu dağılımı (en çok ne soruluyor → hangi hesaba yatırım yapılmalı).
- Gecikme (medyan, %95) ve aylık maliyet.
- **Alarm:** düzeltme oranı iki hafta üst üste %3'ü aşarsa panelde uyarı → yeni
  ayar turu (docs/35 betiği, yeni kabul seti).

### 6.3 Ham metin — yalnız açık rızayla

- Ayarlar'da kapalı başlayan **"Sorularımı asistanı geliştirmek için paylaş"**
  anahtarı. Açıkken yalnız **düzeltilen** ve **geri dönüşe düşen** soruların
  metni saklanır (doğru giden soru gerekmez).
- Saklama **30 gün**, sonra kendiliğinden silinir; kullanıcı istediği an
  "paylaştıklarımı sil" ile siler; hesap silinince gider.
- Bu metinler yeni ayar setinin hammaddesidir (gerçek kullanıcı dili — kabul
  setinde en çok eksik kalan şey).

### 6.4 Aşamalar

| Aşama | Ne | Nerede | Kim görür |
|---|---|---|---|
| **K1** (asistanla birlikte) | Olaylar **cihazda** yerel tabloda; gizli "Geliştirici → Asistan kalitesi" ekranı | Telefon | Yalnız cihaz sahibi (Samet) |
| **K2** (uygulama başkalarına açılınca) | Olaylar Supabase'e (metinsiz); günlük toplama; panel | Supabase + yönetici ekranı | Yalnız yönetici rolü; kullanıcı kendi olaylarını görür (RLS) |
| **K3** (isteğe bağlı) | Açık rızalı metin örnekleri, 30 gün | Supabase, ayrı tablo, ayrı RLS | Yalnız yönetici |

K2/K3 öncesinde: gizlilik politikası metni, KVKK aydınlatma metni ve açık rıza
akışı (ayrı tasarım dokümanı). Yönetici rolü sunucu tarafında (Supabase
`service_role` yalnız Edge Function'da; istemciye asla gömülmez).

### 6.5 Açık noktalar

- K1 yerel tablo şema değişikliği ister (v16) → asistan işiyle aynı dalda,
  şema kilidi alınarak.
- "Değiştir" düzeltmesi bazen yanlış eşleme değil fikir değişikliği olabilir;
  oran bir **üst tahmin** olarak okunur.
