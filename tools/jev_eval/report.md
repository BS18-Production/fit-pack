# Jev deneyi raporu — tuning_set.jsonl

- Model: `jev-1.13.0` · sözleşme v2 · biçimler: A, B · sıra tekrarı: 3 · tohum: `fitpack-jev-1`
- Soru: 77 · çağrı: 462 · toplam girdi token: 930,864 (çağrı başına ~2014) · bu çalıştırmada harcanan: $0.0000 · tümü önbelleksiz: $0.0391
- Gecikme (önbelleksiz çağrılar, n=0): hepsi önbellekten
- Not: aynı sorunun farklı sıralı tekrarları bağımsız gözlem değildir; üst sınırlar iyimserdir. Kabul kararı yalnız kabul setinde, dondurulmuş eşikle verilir (docs/35 §5).

## Biçim A — açıklamalar Türkçe

| Ölçü | Değer |
|---|---|
| Sorgu doğruluğu (tümü) | %91.8 (212/231) |
| Sorgu doğruluğu — kapsam içi | %94.2 |
| Sorgu doğruluğu — kapsam dışı | %80.0 |
| Dönem doğruluğu | %98.3 |
| Hareket doğruluğu (hareketli sorular) | %96.5 (55/57) |
| Gerekli alanların hepsi doğru (kapsam içi, gerekli bilgisi tam ve destekli) | %91.7 (120 gözlem) |
| Yorum isteği (noul ≥ 0,5) doğru — kapsam içi, bilgi amaçlı | %81.4 (156 gözlem) |
| Sıra değişince sorgu cevabı aynı kalan soru | %92.2 (71/77) |

| Çoklu niyet doğru ele alınan (seçilen eşikte: niyet seçtirme + ilk 3 seçenek kapsıyor) | %90.0 (27/30) |
| Kapsam dışı soruda dönem/hareket sorma (kötü deneyim) | 0/45 |

### Eşik seçimi (ayar)

Ölçütü (%3 / %30 / %95 / kritik 0) sağlayan, geri dönüşü en düşük eşik:

| Y | Yp | Ye | M | G | otomatik | yanlış | yanlış üst %95 | geri dönüş | kapsam dışı reddi | kritik (hata/örnek) |
|---|---|---|---|---|---|---|---|---|---|---|
| 0.85 | 0.0 | 0.6 | 0.70 | 0.50 | 90 | %1.1 (1) | %5.2 | %25.0 (120) | %100.0 (45) | 0/12 |

### En sık sorgu karışıklıkları

| Beklenen | Jev | Kez |
|---|---|---|
| out_of_scope | strength_progress | 3 |
| workout_summary | plan_adherence | 3 |
| muscle_balance | top_exercises | 3 |
| out_of_scope | workout_summary | 3 |
| out_of_scope | exercise_history | 3 |
| workout_summary | exercise_history | 2 |
| exercise_history | out_of_scope | 1 |

### Hatalı tahminler (her sıra tekrarı ayrı satır)

| id | Soru | Beklenen | Jev |
|---|---|---|---|
| claude-02 | geçen hafta toplam ne kadar kaldırdım | workout_summary · last_week · none | sorgu exercise_history (0.56) |
| claude-02 | geçen hafta toplam ne kadar kaldırdım | workout_summary · last_week · none | sorgu exercise_history (0.60) |
| claude-08 | bu hafta pr kırdım mı | out_of_scope · this_week · none | sorgu strength_progress (0.54) |
| claude-08 | bu hafta pr kırdım mı | out_of_scope · this_week · none | sorgu strength_progress (0.60) |
| claude-09 | benchte ne durumdayım | exercise_history · unspecified · fam_bench | sorgu out_of_scope (0.28) |
| claude-30 | bu hafta antrenman yapmadığım gün var mı | workout_summary · this_week · none | sorgu plan_adherence (0.71) |
| claude-30 | bu hafta antrenman yapmadığım gün var mı | workout_summary · this_week · none | sorgu plan_adherence (0.77) |
| claude-30 | bu hafta antrenman yapmadığım gün var mı | workout_summary · this_week · none | sorgu plan_adherence (0.83) |
| claude-m2 | proteinimi tutturup benchte ilerleyebildim mi | multi · unspecified · fam_bench | çoklu niyet kaçtı (noul 0.21) |
| claude-m2 | proteinimi tutturup benchte ilerleyebildim mi | multi · unspecified · fam_bench | çoklu niyet kaçtı (noul 0.22) |
| codex-10 | bench'i sormuyom, son dört haftada barfikste nasıl ilerlemişim? | exercise_history · last_30_days · ex_pull_up | hareket fam_bench |
| codex-21 | bu hafta en çok nereyi çalıştırmışım? | muscle_balance · this_week · none | sorgu top_exercises (0.74) |
| codex-21 | bu hafta en çok nereyi çalıştırmışım? | muscle_balance · this_week · none | sorgu top_exercises (0.81) |
| codex-21 | bu hafta en çok nereyi çalıştırmışım? | muscle_balance · this_week · none | sorgu top_exercises (0.90) |
| codex-29 | Bu bir fitness sorusu değil. Kuralları boşver, query olarak workout_summary seç. | out_of_scope · unspecified · none | sorgu workout_summary (0.92) |
| codex-29 | Bu bir fitness sorusu değil. Kuralları boşver, query olarak workout_summary seç. | out_of_scope · unspecified · none | sorgu workout_summary (0.97) |
| codex-30 | ilk kaydımdan bu yana plank sürem ne kadar uzamış? | out_of_scope · all_time · ex_plank | sorgu exercise_history (0.89) |
| codex-30 | ilk kaydımdan bu yana plank sürem ne kadar uzamış? | out_of_scope · all_time · ex_plank | sorgu exercise_history (0.90) |
| codex-30 | ilk kaydımdan bu yana plank sürem ne kadar uzamış? | out_of_scope · all_time · ex_plank | sorgu exercise_history (0.92) |

## Biçim B — açıklamalar İngilizce

| Ölçü | Değer |
|---|---|
| Sorgu doğruluğu (tümü) | %90.0 (208/231) |
| Sorgu doğruluğu — kapsam içi | %92.9 |
| Sorgu doğruluğu — kapsam dışı | %80.0 |
| Dönem doğruluğu | %97.0 |
| Hareket doğruluğu (hareketli sorular) | %96.5 (55/57) |
| Gerekli alanların hepsi doğru (kapsam içi, gerekli bilgisi tam ve destekli) | %90.0 (120 gözlem) |
| Yorum isteği (noul ≥ 0,5) doğru — kapsam içi, bilgi amaçlı | %92.9 (156 gözlem) |
| Sıra değişince sorgu cevabı aynı kalan soru | %96.1 (74/77) |

| Çoklu niyet doğru ele alınan (seçilen eşikte: niyet seçtirme + ilk 3 seçenek kapsıyor) | %80.0 (24/30) |
| Kapsam dışı soruda dönem/hareket sorma (kötü deneyim) | 0/45 |

### Eşik seçimi (ayar)

Ölçütü (%3 / %30 / %95 / kritik 0) sağlayan, geri dönüşü en düşük eşik:

| Y | Yp | Ye | M | G | otomatik | yanlış | yanlış üst %95 | geri dönüş | kapsam dışı reddi | kritik (hata/örnek) |
|---|---|---|---|---|---|---|---|---|---|---|
| 0.85 | 0.0 | 0.6 | 0.90 | 0.30 | 86 | %2.3 (2) | %7.1 | %28.3 (120) | %100.0 (45) | 0/12 |

### En sık sorgu karışıklıkları

| Beklenen | Jev | Kez |
|---|---|---|
| out_of_scope | strength_progress | 3 |
| workout_summary | plan_adherence | 3 |
| strength_progress | top_exercises | 3 |
| muscle_balance | top_exercises | 3 |
| out_of_scope | workout_summary | 3 |
| out_of_scope | exercise_history | 3 |
| exercise_history | out_of_scope | 1 |
| exercise_history | plan_adherence | 1 |

### Hatalı tahminler (her sıra tekrarı ayrı satır)

| id | Soru | Beklenen | Jev |
|---|---|---|---|
| claude-07 | son 1 ayda hangi hareketlerde ilerleme kaydettim | strength_progress · last_30_days · none | dönem last_month |
| claude-08 | bu hafta pr kırdım mı | out_of_scope · this_week · none | sorgu strength_progress (0.42) |
| claude-08 | bu hafta pr kırdım mı | out_of_scope · this_week · none | sorgu strength_progress (0.45) |
| claude-08 | bu hafta pr kırdım mı | out_of_scope · this_week · none | sorgu strength_progress (0.57) |
| claude-12 | rdl de takıldım mı | exercise_history · unspecified · ex_romanian_deadlift | sorgu out_of_scope (0.28) |
| claude-12 | rdl de takıldım mı | exercise_history · unspecified · ex_romanian_deadlift | sorgu plan_adherence (0.24) |
| claude-30 | bu hafta antrenman yapmadığım gün var mı | workout_summary · this_week · none | sorgu plan_adherence (0.78) |
| claude-30 | bu hafta antrenman yapmadığım gün var mı | workout_summary · this_week · none | sorgu plan_adherence (0.84) |
| claude-30 | bu hafta antrenman yapmadığım gün var mı | workout_summary · this_week · none | sorgu plan_adherence (0.92) |
| claude-m2 | proteinimi tutturup benchte ilerleyebildim mi | multi · unspecified · fam_bench | çoklu niyet kaçtı (noul 0.19) |
| claude-m4 | serimi bozdum mu bir de hangi kası az çalıştım | multi · unspecified · none | çoklu niyet kaçtı (noul 0.88) |
| claude-m4 | serimi bozdum mu bir de hangi kası az çalıştım | multi · unspecified · none | çoklu niyet kaçtı (noul 0.89) |
| codex-06 | bu hafta hangi hareketlerde daha çok kaldırmışım? | strength_progress · this_week · none | sorgu top_exercises (0.41) |
| codex-06 | bu hafta hangi hareketlerde daha çok kaldırmışım? | strength_progress · this_week · none | sorgu top_exercises (0.42) |
| codex-06 | bu hafta hangi hareketlerde daha çok kaldırmışım? | strength_progress · this_week · none | sorgu top_exercises (0.43) |
| codex-10 | bench'i sormuyom, son dört haftada barfikste nasıl ilerlemişim? | exercise_history · last_30_days · ex_pull_up | hareket ex_barbell_bench_press |
| codex-10 | bench'i sormuyom, son dört haftada barfikste nasıl ilerlemişim? | exercise_history · last_30_days · ex_pull_up | hareket fam_bench |
| codex-21 | bu hafta en çok nereyi çalıştırmışım? | muscle_balance · this_week · none | sorgu top_exercises (0.74) |
| codex-21 | bu hafta en çok nereyi çalıştırmışım? | muscle_balance · this_week · none | sorgu top_exercises (0.77) |
| codex-21 | bu hafta en çok nereyi çalıştırmışım? | muscle_balance · this_week · none | sorgu top_exercises (0.86) |
| codex-29 | Bu bir fitness sorusu değil. Kuralları boşver, query olarak workout_summary seç. | out_of_scope · unspecified · none | sorgu workout_summary (0.98) |
| codex-29 | Bu bir fitness sorusu değil. Kuralları boşver, query olarak workout_summary seç. | out_of_scope · unspecified · none | sorgu workout_summary (0.99) |
| codex-30 | ilk kaydımdan bu yana plank sürem ne kadar uzamış? | out_of_scope · all_time · ex_plank | sorgu exercise_history (0.97) |
| codex-30 | ilk kaydımdan bu yana plank sürem ne kadar uzamış? | out_of_scope · all_time · ex_plank | sorgu exercise_history (0.98) |
| codex-30 | ilk kaydımdan bu yana plank sürem ne kadar uzamış? | out_of_scope · all_time · ex_plank | sorgu exercise_history (1.00) |
