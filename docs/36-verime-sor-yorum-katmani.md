# 36 — "Verime sor" v1: veri + yorum katmanı

> **Durum:** 📝 Taslak — kaynaklar doğrulandı (Claude); Samet kararları ve
> Codex incelemesi bekliyor (Codex kotası 16:53'te açılıyor). Kod yok.
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
| `muscle_balance` (kas grubu set) | Haftalık set: <10 "araştırmalarda daha fazla kas kazanımıyla ilişkilendirilen ~10 set/hafta düzeyinin altında"; ≥10 "bu düzeyde"; >20 "bu düzeyin ötesi için kanıt sınırlı" (uyarı değil, bilgi) | Schoenfeld, Ogborn, Krieger, *J Sports Sci* 2017;35:1073–82 (çevrim içi 2016): 15 çalışma; ≥10 set/kas/hafta, <5 ve 5–9'a göre daha fazla kazanım **eğilimi** (P = 0,074); set başına ~%0,37 ek kazanım | Bizim sayımız **birincil kasa yazılan tamamlanmış set**; çalışmalar zorlayıcı set sayar → kartta yazılır. "Yeterli" kelimesi kullanılmaz; kanıt bir eğilim |
| `weight_trend` + hedef yönü "ver" | Haftalık değişim, vücut ağırlığının yüzdesi: %0,5–1 "genel önerilen aralıkta"; >%1 "önerilenden hızlı"; <%0,25 "yavaş" | CDC: haftada ~1–2 pound (~0,45–0,9 kg), yavaş ve istikrarlı kayıp kalıcılıkla ilişkili. Garthe ve ark., *IJSNEM* 2011: 24 sporcu, kuvvet antrenmanıyla %0,7/hafta kaybeden grup diyet süresince %1,4'e göre daha çok yağsız kütle ve güç kazandı (12 ayda fark kalmadı) | | ≥2 ölçüm ve ≥14 gün yoksa yorum yok ("tek ölçüm trend sayılmaz", docs/22 kuralı) |
| `weight_trend` + yön "al" | %0,25–0,5/hafta "önerilen aralıkta"; üstü "önerilenden hızlı" | Iraki, Fitschen, Espinar, Helms, *Sports* 2019;7(7):154 (PMID 31247944, anlatı derlemesi): başlangıç/orta seviye için %0,25–0,5/hafta; ileri seviye daha temkinli | Seviye bilgisi yok → aralık "başlangıç/orta için" diye yazılır |
| `weight_trend` + yön "koru" / yok | Kendi ortalamasına göre ±%1 içinde "sabit" | — (kendi geçmişi) | Yön yoksa "hedef yönünü seçersen yorumlarım" |
| `workout_summary` (hacim, set, seans) | **Mutlak norm yok.** Kendi son 8 haftasının medyanına göre: "%X üstünde/altında" | — (kendi geçmişi) | "50k tek başına anlamlı değil; senin ortalaman 42k" |
| `strength_progress` / `exercise_history` | e1RM eğilimi: artıyor / sabit (3 hafta aynı = plato, A1 odak kuralı) / düşüyor | — (kendi geçmişi; docs/22 §3.3) | Hareketler arası norm ("bench'in iyi mi") yok |
| `protein_goal`, `nutrition_summary` | Hedefe göre: tutturulan gün oranı; ortalama/hedef. **İsteğe bağlı (§5):** ortalama g/kg, "~1,6 g/kg civarı ve üstü" ile karşılaştırma | Kendi hedefi; Morton ve ark., *Br J Sports Med* 2018;52:376–84 (49 çalışma, 1.863 kişi): ~1,6 g/kg/gün üstünde ek yağsız kütle kazanımı görülmedi (kırılma noktası, güven aralığı geniş); Iraki 2019: 1,6–2,2 g/kg | Kayıtsız gün ortalamaya girmez (docs/22 kuralı) |
| `today_remaining` | Kalan kalori/protein; **öneri:** son 30 günde o öğünde (ör. akşam) yediği yemeklerden kalan makroya sığanlar, en çok 3 | — (kendi geçmişi, deterministik) | Yeni yemek önermez; kayıt yoksa yalnız kalan miktar |

**Sağlık sınırı:** "sağlıklı mı" sorusu genel kılavuzla cevaplanır, her zaman
"tıbbi değerlendirme için uzmana danış" notu eklenir; haftalık kayıp %1,5'i
aşarsa not öne çıkar. Ağrı, sakatlık, ilaç, takviye → ret (değişmedi).

## 3. Jev'e etkisi (docs/35 sözleşme v2)

- Sorgu seçeneklerine `today_remaining`, `top_exercises`; `out_of_scope`
  açıklaması daralır (yorum artık kapsam içi).
- Yeni `noul` `wants_interpretation`; `advice` açıklaması "reçete/eylem/tıbbi"
  diye daralır.
- Karar sırası: çoklu niyet → reçete/eylem/kapsam dışı/düşük güven (geri
  dönüş) → eksik alan (netleştirme) → otomatik (**veri + yorum isteniyorsa yorum**).
- Yorum isteğinin yanlış algılanması zararsız tarafta kalır (fazladan yorum
  ya da eksik yorum; sayı yine doğru) — kabul ölçütüne girmez, ayrıca raporlanır.
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

## 5. Samet'e sorular

1. **Kural kaynakları** (§2) uygun mu? Kaynaklar birincil yayınlardan
   doğrulandı (2026-10-10, Claude). Düzeltme: Schoenfeld 2017 "10–20 set"
   demiyor; ~10 set/hafta üstü daha fazla kazanım **eğilimi** gösteriyor, 20
   üstü için kanıt sınırlı → kart "yeterli" demez, "araştırmalarda ilişkili
   düzey" der.
2. **Protein için g/kg yorumu** eklensin mi? (ör. "kas kazanımı için genelde
   ~1,6 g/kg önerilir" — kaynak Codex incelemesinde doğrulanır.) Hedefin zaten
   var; ek yorum ister misin?
3. **Akşam yemeği önerisi** yalnız kendi geçmişinden (daha önce yediklerin)
   olsun mu? Yeni yemek önermek yapay zekâ ister.
4. **Kabul seti 100 mü 120 mi?** (önceki mesaj; öneri 120 — 30 senden.)
5. Antrenman hedefi türü (hipertrofi / güç) profilde yok; set yorumu şimdilik
   **hipertrofi kılavuzuyla** yapılır. Hedef türü alanı ileride ayrı iş.
