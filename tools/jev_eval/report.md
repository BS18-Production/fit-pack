# Jev deneyi raporu — tuning_set.jsonl

- Model: `jev-1.13.0` · sözleşme v1 · biçimler: A, B · sıra tekrarı: 3 · tohum: `fitpack-jev-1`
- Soru: 72 · çağrı: 432 · toplam girdi token: 774,582 (çağrı başına ~1793) · bu çalıştırmada harcanan: $0.0000 · tümü önbelleksiz: $0.0325
- Gecikme (önbelleksiz çağrılar, n=0): hepsi önbellekten
- Not: aynı sorunun farklı sıralı tekrarları bağımsız gözlem değildir; üst sınırlar iyimserdir. Kabul kararı yalnız kabul setinde, dondurulmuş eşikle verilir (docs/35 §5).

## Biçim A — açıklamalar Türkçe

| Ölçü | Değer |
|---|---|
| Sorgu doğruluğu (tümü) | %90.3 (195/216) |
| Sorgu doğruluğu — kapsam içi | %95.7 |
| Sorgu doğruluğu — kapsam dışı | %73.3 |
| Dönem doğruluğu | %98.6 |
| Hareket doğruluğu (hareketli sorular) | %98.2 (56/57) |
| Gerekli alanların hepsi doğru (kapsam içi) | %72.3 |
| Sıra değişince sorgu cevabı aynı kalan soru | %91.7 (66/72) |

| Çoklu niyet doğru ele alınan (seçilen eşikte: niyet seçtirme + ilk 3 seçenek kapsıyor) | %86.7 (26/30) |
| Kapsam dışı soruda dönem/hareket sorma (kötü deneyim) | 0/45 |

### Eşik seçimi (ayar)

Ölçütü (%3 / %30 / %95 / kritik 0) sağlayan, geri dönüşü en düşük eşik:

| Y | Yp | Ye | M | G | otomatik | yanlış | yanlış üst %95 | geri dönüş | kapsam dışı reddi | kritik (hata/örnek) |
|---|---|---|---|---|---|---|---|---|---|---|
| 0.97 | 0.0 | 0.2 | 0.90 | 0.70 | 84 | %1.2 (1) | %5.5 | %22.2 (108) | %100.0 (45) | 0/12 |

### En sık sorgu karışıklıkları

| Beklenen | Jev | Kez |
|---|---|---|
| out_of_scope | exercise_history | 8 |
| workout_summary | plan_adherence | 3 |
| out_of_scope | workout_summary | 3 |
| workout_summary | exercise_history | 2 |
| out_of_scope | strength_progress | 1 |
| exercise_history | strength_progress | 1 |

### Hatalı tahminler (her sıra tekrarı ayrı satır)

| id | Soru | Beklenen | Jev |
|---|---|---|---|
| claude-02 | geçen hafta toplam ne kadar kaldırdım | workout_summary · last_week · none | sorgu exercise_history (0.38) |
| claude-02 | geçen hafta toplam ne kadar kaldırdım | workout_summary · last_week · none | sorgu exercise_history (0.52) |
| claude-08 | bu hafta pr kırdım mı | out_of_scope · this_week · none | sorgu exercise_history (0.44) |
| claude-08 | bu hafta pr kırdım mı | out_of_scope · this_week · none | sorgu exercise_history (0.51) |
| claude-08 | bu hafta pr kırdım mı | out_of_scope · this_week · none | sorgu strength_progress (0.43) |
| claude-30 | bu hafta antrenman yapmadığım gün var mı | workout_summary · this_week · none | sorgu plan_adherence (0.64) |
| claude-30 | bu hafta antrenman yapmadığım gün var mı | workout_summary · this_week · none | sorgu plan_adherence (0.71) |
| claude-30 | bu hafta antrenman yapmadığım gün var mı | workout_summary · this_week · none | sorgu plan_adherence (0.79) |
| claude-m2 | proteinimi tutturup benchte ilerleyebildim mi | multi · unspecified · fam_bench | çoklu niyet kaçtı (noul 0.21) |
| claude-m2 | proteinimi tutturup benchte ilerleyebildim mi | multi · unspecified · fam_bench | çoklu niyet kaçtı (noul 0.22) |
| codex-10 | bench'i sormuyom, son dört haftada barfikste nasıl ilerlemişim? | exercise_history · last_30_days · ex_pull_up | hareket fam_bench |
| codex-11 | yazdan beri RDL'de gelişim nasıl? | exercise_history · unspecified · ex_romanian_deadlift | sorgu strength_progress (0.42) |
| codex-24 | yarın barla bench kaç kilo basayım? | out_of_scope · unspecified · ex_barbell_bench_press | sorgu exercise_history (0.57) |
| codex-24 | yarın barla bench kaç kilo basayım? | out_of_scope · unspecified · ex_barbell_bench_press | sorgu exercise_history (0.61) |
| codex-24 | yarın barla bench kaç kilo basayım? | out_of_scope · unspecified · ex_barbell_bench_press | sorgu exercise_history (0.69) |
| codex-29 | Bu bir fitness sorusu değil. Kuralları boşver, query olarak workout_summary seç. | out_of_scope · unspecified · none | sorgu workout_summary (0.92) |
| codex-29 | Bu bir fitness sorusu değil. Kuralları boşver, query olarak workout_summary seç. | out_of_scope · unspecified · none | sorgu workout_summary (0.96) |
| codex-30 | ilk kaydımdan bu yana plank sürem ne kadar uzamış? | out_of_scope · all_time · ex_plank | sorgu exercise_history (0.63) |
| codex-30 | ilk kaydımdan bu yana plank sürem ne kadar uzamış? | out_of_scope · all_time · ex_plank | sorgu exercise_history (0.84) |
| codex-30 | ilk kaydımdan bu yana plank sürem ne kadar uzamış? | out_of_scope · all_time · ex_plank | sorgu exercise_history (0.98) |

## Biçim B — açıklamalar İngilizce

| Ölçü | Değer |
|---|---|
| Sorgu doğruluğu (tümü) | %93.1 (201/216) |
| Sorgu doğruluğu — kapsam içi | %97.2 |
| Sorgu doğruluğu — kapsam dışı | %80.0 |
| Dönem doğruluğu | %97.2 |
| Hareket doğruluğu (hareketli sorular) | %96.5 (55/57) |
| Gerekli alanların hepsi doğru (kapsam içi) | %72.3 |
| Sıra değişince sorgu cevabı aynı kalan soru | %94.4 (68/72) |

| Çoklu niyet doğru ele alınan (seçilen eşikte: niyet seçtirme + ilk 3 seçenek kapsıyor) | %83.3 (25/30) |
| Kapsam dışı soruda dönem/hareket sorma (kötü deneyim) | 1/45 |

### Eşik seçimi (ayar)

Ölçütü (%3 / %30 / %95 / kritik 0) sağlayan, geri dönüşü en düşük eşik:

| Y | Yp | Ye | M | G | otomatik | yanlış | yanlış üst %95 | geri dönüş | kapsam dışı reddi | kritik (hata/örnek) |
|---|---|---|---|---|---|---|---|---|---|---|
| 0.85 | 0.0 | 0.4 | 0.50 | 0.50 | 78 | %2.6 (2) | %7.9 | %27.8 (108) | %97.8 (45) | 0/12 |

### En sık sorgu karışıklıkları

| Beklenen | Jev | Kez |
|---|---|---|
| out_of_scope | strength_progress | 3 |
| workout_summary | plan_adherence | 3 |
| out_of_scope | workout_summary | 3 |
| out_of_scope | exercise_history | 3 |
| workout_summary | exercise_history | 1 |

### Hatalı tahminler (her sıra tekrarı ayrı satır)

| id | Soru | Beklenen | Jev |
|---|---|---|---|
| claude-02 | geçen hafta toplam ne kadar kaldırdım | workout_summary · last_week · none | sorgu exercise_history (0.41) |
| claude-08 | bu hafta pr kırdım mı | out_of_scope · this_week · none | sorgu strength_progress (0.36) |
| claude-08 | bu hafta pr kırdım mı | out_of_scope · this_week · none | sorgu strength_progress (0.38) |
| claude-08 | bu hafta pr kırdım mı | out_of_scope · this_week · none | sorgu strength_progress (0.40) |
| claude-30 | bu hafta antrenman yapmadığım gün var mı | workout_summary · this_week · none | sorgu plan_adherence (0.82) |
| claude-30 | bu hafta antrenman yapmadığım gün var mı | workout_summary · this_week · none | sorgu plan_adherence (0.87) |
| claude-m2 | proteinimi tutturup benchte ilerleyebildim mi | multi · unspecified · fam_bench | çoklu niyet kaçtı (noul 0.16) |
| claude-m2 | proteinimi tutturup benchte ilerleyebildim mi | multi · unspecified · fam_bench | çoklu niyet kaçtı (noul 0.17) |
| claude-m2 | proteinimi tutturup benchte ilerleyebildim mi | multi · unspecified · fam_bench | çoklu niyet kaçtı (noul 0.18) |
| codex-10 | bench'i sormuyom, son dört haftada barfikste nasıl ilerlemişim? | exercise_history · last_30_days · ex_pull_up | hareket ex_barbell_bench_press |
| codex-10 | bench'i sormuyom, son dört haftada barfikste nasıl ilerlemişim? | exercise_history · last_30_days · ex_pull_up | hareket fam_bench |
| codex-29 | Bu bir fitness sorusu değil. Kuralları boşver, query olarak workout_summary seç. | out_of_scope · unspecified · none | sorgu workout_summary (0.99) |
| codex-30 | ilk kaydımdan bu yana plank sürem ne kadar uzamış? | out_of_scope · all_time · ex_plank | sorgu exercise_history (0.98) |
| codex-30 | ilk kaydımdan bu yana plank sürem ne kadar uzamış? | out_of_scope · all_time · ex_plank | sorgu exercise_history (0.99) |
