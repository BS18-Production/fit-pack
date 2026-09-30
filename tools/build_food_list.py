#!/usr/bin/env python3
"""Genişletilmiş besin listesini üretir → assets/data/foods_extended.json

Neden üretiyoruz: değerlerin kaynağı belli ve tekrar üretilebilir olsun.

Kaynak: **USDA FoodData Central — SR Legacy (2018-04)**. ABD hükümeti eseri,
**kamu malı** (public domain): ticari kullanım serbest, atıf zorunlu değil
(yine de Ayarlar'daki kaynaklar listesinde anılır). TÜRKOMP KULLANILMADI —
ticari kullanımı ücretli sözleşmeye bağlı (Samet kararı 2026-09-30).

İki tür kayıt:
1. **USDA gıdası:** tek bir USDA kaydına birebir eşlenen temel gıda
   (Türkçe ad elle verildi). `source_ref` = "usda:<fdc_id>".
2. **Tarif hesabı:** Türk yemekleri USDA'da yok. Standart ev tarifinin
   malzemeleri (USDA değerleriyle) toplanır, **pişmiş ağırlığa** bölünür
   (su kaybı/emilimi). `source_ref` = "recipe". Değerler TAHMİNDİR —
   tarif, pişirme ve porsiyon farkıyla sapabilir; mevcut elle yazılmış
   111 kayıttaki yemekler de aynı yaklaşımla hazırlanmıştı.

Kullanım:
    # 1) USDA SR Legacy CSV'sini indir ve aç (repo dışında tutulur, 6 MB):
    #    https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_csv_2018-04.zip
    python3 tools/build_food_list.py <açılan klasör>

Kural: ad **benzersiz ve kalıcı** olmalı — senkron hazır gıdayı ADıyla
eşler (sync_apply). Yayınlandıktan sonra ad değiştirmek eşlemeyi koparır.
"""

import csv
import json
import os
import sys

# (ad, grup, fdc_id, porsiyon_g, birim)
USDA = [
    # ── Et, balık, yumurta
    ("Tavuk Kanat (Fırın, Derili)", "meat", 173630, 100, "porsiyon"),
    ("Tavuk Göğsü (Çiğ)", "meat", 171077, 150, "porsiyon"),
    ("Tavuk Ciğeri (Haşlanmış)", "meat", 171061, 100, "porsiyon"),
    ("Dana Kıyma (%5 Yağlı, Pişmiş)", "meat", 174028, 100, "porsiyon"),
    ("Dana Kıyma (%20 Yağlı, Çiğ)", "meat", 174036, 100, "porsiyon"),
    ("Dana Antrikot (Izgara)", "meat", 172144, 200, "porsiyon"),
    ("Dana Ciğer (Tava)", "meat", 168627, 150, "porsiyon"),
    ("Dana Kuşbaşı (Yağsız, Çiğ)", "meat", 171820, 150, "porsiyon"),
    ("Dana Kıyma (Pişmiş, Izgara)", "meat", 175291, 100, "porsiyon"),
    ("Kuzu But (Fırın)", "meat", 172487, 150, "porsiyon"),
    ("Kuzu Kıyma (Pişmiş)", "meat", 172544, 100, "porsiyon"),
    ("Hindi Kıyma (Pişmiş)", "meat", 171506, 100, "porsiyon"),
    ("Sardalya (Konserve, Yağlı)", "meat", 175139, 100, "kutu"),
    ("Uskumru (Izgara)", "meat", 175120, 150, "porsiyon"),
    ("Alabalık (Izgara)", "meat", 173718, 200, "porsiyon"),
    ("Ton Balığı (Taze, Izgara)", "meat", 172006, 150, "porsiyon"),
    ("Karides (Haşlanmış)", "meat", 175180, 100, "porsiyon"),
    ("Kalamar (Tava)", "meat", 171982, 150, "porsiyon"),
    ("Midye (Haşlanmış)", "meat", 174217, 100, "porsiyon"),
    ("Morina (Izgara)", "meat", 171956, 150, "porsiyon"),
    ("Sosis (Tavuk)", "meat", 171624, 40, "adet"),
    ("Yumurta (Sahanda)", "meat", 173423, 50, "adet"),
    ("Yumurta (Çırpılmış)", "meat", 172187, 100, "porsiyon"),
    ("Yumurta (Çiğ)", "meat", 171287, 50, "adet"),
    # ── Süt ürünleri
    ("Kefir (Az Yağlı)", "dairy", 170904, 200, "su bardağı"),
    ("Cheddar Peyniri", "dairy", 170899, 30, "dilim"),
    ("Mozzarella", "dairy", 170845, 30, "dilim"),
    ("Parmesan (Rendelenmiş)", "dairy", 171247, 10, "yemek kaşığı"),
    ("Cottage Peyniri (Az Yağlı)", "dairy", 172182, 100, "porsiyon"),
    ("Krem Peynir", "dairy", 173418, 20, "yemek kaşığı"),
    ("Krema (Sıvı, Yağlı)", "dairy", 170859, 15, "yemek kaşığı"),
    ("Dondurma (Vanilyalı)", "dairy", 167575, 70, "top"),
    ("Kakaolu Süt", "dairy", 170880, 200, "su bardağı"),
    ("Keçi Peyniri (Yumuşak)", "dairy", 173435, 30, "dilim"),
    ("Feta Peyniri", "dairy", 173420, 30, "dilim"),
    ("Ricotta Peyniri", "dairy", 170851, 30, "yemek kaşığı"),
    ("Süt Tozu (Yağsız)", "dairy", 171272, 10, "yemek kaşığı"),
    ("Soya Sütü (Şekersiz)", "dairy", 175215, 200, "su bardağı"),
    ("Badem Sütü (Şekersiz)", "dairy", 174832, 200, "su bardağı"),
    # ── Tahıl ve nişasta
    ("Pirinç (Çiğ)", "grain", 168877, 80, "porsiyon"),
    ("Pirinç (Haşlanmış, Sade)", "grain", 168878, 150, "porsiyon"),
    ("Esmer Pirinç (Haşlanmış)", "grain", 169704, 150, "porsiyon"),
    ("Bulgur (Kuru)", "grain", 170688, 80, "porsiyon"),
    ("Kuskus (Haşlanmış)", "grain", 169700, 150, "porsiyon"),
    ("Erişte (Haşlanmış)", "grain", 169732, 150, "porsiyon"),
    ("Makarna (Kuru)", "grain", 169736, 80, "porsiyon"),
    ("Karabuğday (Haşlanmış)", "grain", 170686, 150, "porsiyon"),
    ("Arpa (Haşlanmış)", "grain", 170285, 150, "porsiyon"),
    ("Mısır Gevreği", "grain", 174648, 30, "kâse"),
    ("Granola", "grain", 171646, 50, "kâse"),
    ("Lavaş", "grain", 167535, 60, "adet"),
    ("Pita Ekmeği", "grain", 174915, 60, "adet"),
    ("Tost Ekmeği", "grain", 174924, 25, "dilim"),
    ("Kraker", "grain", 174982, 30, "avuç"),
    ("Pirinç Patlağı", "grain", 170250, 9, "adet"),
    ("Patlamış Mısır", "grain", 167959, 20, "kâse"),
    ("Buğday Unu (Beyaz)", "grain", 168894, 10, "yemek kaşığı"),
    ("Tam Buğday Unu", "grain", 168893, 10, "yemek kaşığı"),
    ("Yulaf Kepeği", "grain", 168872, 10, "yemek kaşığı"),
    ("İrmik", "grain", 169715, 10, "yemek kaşığı"),
    ("Mısır Unu", "grain", 169697, 10, "yemek kaşığı"),
    ("Mısır Nişastası", "grain", 169698, 10, "yemek kaşığı"),
    ("Kruvasan", "grain", 174987, 60, "adet"),
    ("Kek (Sade)", "grain", 174940, 50, "dilim"),
    ("Pankek", "grain", 175009, 40, "adet"),
    ("Waffle", "grain", 175038, 35, "adet"),
    # ── Baklagil
    ("Kırmızı Mercimek (Kuru)", "legume", 174284, 60, "porsiyon"),
    ("Yeşil Mercimek (Kuru)", "legume", 172420, 60, "porsiyon"),
    ("Nohut (Kuru)", "legume", 173756, 60, "porsiyon"),
    ("Kuru Fasulye (Çiğ)", "legume", 175202, 60, "porsiyon"),
    ("Siyah Fasulye (Haşlanmış)", "legume", 173735, 150, "porsiyon"),
    ("Tofu", "legume", 172475, 100, "porsiyon"),
    ("Edamame", "legume", 168411, 100, "porsiyon"),
    ("Bakla (Taze, Haşlanmış)", "legume", 170378, 150, "porsiyon"),
    ("Yer Fıstığı (Kavrulmuş)", "legume", 173806, 30, "avuç"),
    ("Soya Fasulyesi (Kavrulmuş)", "legume", 172441, 30, "avuç"),
    # ── Sebze
    ("Lahana (Beyaz)", "vegetable", 169975, 100, "porsiyon"),
    ("Kırmızı Lahana", "vegetable", 169977, 100, "porsiyon"),
    ("Mantar", "vegetable", 169251, 100, "porsiyon"),
    ("Pırasa", "vegetable", 169246, 100, "porsiyon"),
    ("Kereviz (Kök)", "vegetable", 170400, 100, "porsiyon"),
    ("Enginar (Haşlanmış)", "vegetable", 168386, 120, "adet"),
    ("Bamya (Haşlanmış)", "vegetable", 169261, 150, "porsiyon"),
    ("Pancar", "vegetable", 169145, 100, "porsiyon"),
    ("Turp", "vegetable", 169276, 50, "porsiyon"),
    ("Göbek Marul", "vegetable", 169248, 100, "porsiyon"),
    ("Ispanak (Çiğ)", "vegetable", 168462, 100, "porsiyon"),
    ("Taze Soğan", "vegetable", 170005, 15, "adet"),
    ("Dereotu", "vegetable", 172233, 10, "porsiyon"),
    ("Nane (Taze)", "vegetable", 173475, 5, "porsiyon"),
    ("Balkabağı", "vegetable", 168448, 150, "porsiyon"),
    ("Kuşkonmaz", "vegetable", 168389, 100, "porsiyon"),
    ("Brüksel Lahanası", "vegetable", 170383, 100, "porsiyon"),
    ("Taze Fasulye (Çiğ)", "vegetable", 169961, 100, "porsiyon"),
    ("Domates Salçası", "vegetable", 170459, 15, "yemek kaşığı"),
    ("Acı Sivri Biber", "vegetable", 170497, 15, "adet"),
    ("Pazı", "vegetable", 169991, 100, "porsiyon"),
    ("Semizotu", "vegetable", 169274, 100, "porsiyon"),
    ("Kabak (Çiğ)", "vegetable", 169291, 150, "porsiyon"),
    ("Patlıcan (Çiğ)", "vegetable", 169228, 250, "adet"),
    ("Karnabahar (Çiğ)", "vegetable", 169986, 100, "porsiyon"),
    ("Brokoli (Çiğ)", "vegetable", 170379, 100, "porsiyon"),
    ("Salatalık Turşusu", "vegetable", 168558, 30, "adet"),
    ("Patates (Çiğ)", "vegetable", 170026, 150, "adet"),
    # ── Meyve
    ("Greyfurt", "fruit", 174673, 250, "adet"),
    ("Limon", "fruit", 167746, 60, "adet"),
    ("Kivi", "fruit", 168153, 75, "adet"),
    ("Ananas", "fruit", 169124, 100, "dilim"),
    ("Mango", "fruit", 169910, 150, "porsiyon"),
    ("Yaban Mersini", "fruit", 171711, 50, "avuç"),
    ("Ahududu", "fruit", 167755, 60, "avuç"),
    ("Böğürtlen", "fruit", 173946, 60, "avuç"),
    ("Vişne", "fruit", 173954, 100, "porsiyon"),
    ("Ayva", "fruit", 168163, 200, "adet"),
    ("Trabzon Hurması", "fruit", 169941, 170, "adet"),
    ("Dut", "fruit", 169913, 100, "porsiyon"),
    ("Kuru İncir", "fruit", 174665, 20, "adet"),
    ("Kuru Erik", "fruit", 168162, 10, "adet"),
    ("Hindistan Cevizi (Taze)", "fruit", 170169, 30, "porsiyon"),
    ("Yenidünya", "fruit", 169908, 30, "adet"),
    ("Nektarin", "fruit", 169914, 140, "adet"),
    # ── Yağ ve kuruyemiş
    ("Ayçiçek Yağı", "fat", 171025, 10, "yemek kaşığı"),
    ("Mısırözü Yağı", "fat", 171029, 10, "yemek kaşığı"),
    ("Hindistan Cevizi Yağı", "fat", 171412, 10, "yemek kaşığı"),
    ("Margarin", "fat", 172346, 10, "yemek kaşığı"),
    ("Mayonez", "fat", 171009, 15, "yemek kaşığı"),
    ("Chia Tohumu", "fat", 170554, 10, "yemek kaşığı"),
    ("Keten Tohumu", "fat", 169414, 10, "yemek kaşığı"),
    ("Kabak Çekirdeği (İç)", "fat", 170556, 30, "avuç"),
    ("Susam", "fat", 170150, 10, "yemek kaşığı"),
    ("Çam Fıstığı", "fat", 170591, 10, "yemek kaşığı"),
    ("Badem Ezmesi", "fat", 168588, 15, "yemek kaşığı"),
    ("Kestane (Kavrulmuş)", "fat", 170190, 50, "porsiyon"),
    # ── Tatlı ve atıştırmalık
    ("Toz Şeker", "sweet", 169655, 5, "çay kaşığı"),
    ("Esmer Şeker", "sweet", 168833, 5, "çay kaşığı"),
    ("Bitter Çikolata (%70-85)", "sweet", 170273, 10, "kare"),
    ("Sütlü Çikolata", "sweet", 167587, 10, "kare"),
    ("Kakaolu Fındık Kreması", "sweet", 168000, 15, "yemek kaşığı"),
    ("Reçel", "sweet", 169641, 20, "yemek kaşığı"),
    ("Bisküvi (Tereyağlı)", "sweet", 174950, 10, "adet"),
    ("Kurabiye (Çikolata Parçacıklı)", "sweet", 172716, 15, "adet"),
    ("Donut (Şekerli)", "sweet", 174992, 60, "adet"),
    ("Patates Cipsi", "sweet", 169677, 30, "avuç"),
    # ── Diğer
    ("Ketçap", "other", 168556, 15, "yemek kaşığı"),
    ("Hardal", "other", 172234, 10, "yemek kaşığı"),
    ("Pesto Sos", "other", 171579, 15, "yemek kaşığı"),
    ("Kakao (Şekersiz)", "other", 169593, 5, "tatlı kaşığı"),
    ("Pizza (Peynirli)", "dish", 170317, 110, "dilim"),
    ("Hamburger", "dish", 170693, 110, "adet"),
    # ── İçecek
    ("Portakal Suyu (Taze)", "drink", 169098, 200, "su bardağı"),
    ("Elma Suyu", "drink", 173933, 200, "su bardağı"),
    ("Nar Suyu", "drink", 167787, 200, "su bardağı"),
    ("Kola", "drink", 174852, 330, "kutu"),
    ("Filtre Kahve", "drink", 171890, 240, "kupa"),
    ("Türk Kahvesi (Şekersiz)", "drink", 171890, 70, "fincan"),
    ("Çay (Şekersiz)", "drink", 173227, 100, "bardak"),
    ("Bira", "drink", 168746, 330, "kutu"),
    ("Kırmızı Şarap", "drink", 173190, 150, "kadeh"),
]

# Tarif malzemeleri (USDA kimlikleri). WATER = 0 besin.
WATER = None
OLIVE_OIL, SUNFLOWER_OIL, BUTTER = 171413, 171025, 173430
ONION, GARLIC, TOMATO, PASTE = 170000, 169230, 170457, 170459
PEPPER, EGG, BEEF80, LAMB = 170427, 171287, 174036, 174370
CHICKEN, RICE, BULGUR, RED_LENTIL = 171077, 168877, 170688, 174284
FLOUR, MILK, YOGURT, GREEK_YOGURT = 168894, 171265, 171284, 171304
FETA, MOZZ, EGGPLANT, ZUCCHINI = 173420, 170846, 169228, 169291
POTATO, GREEN_BEANS, CHICKPEA, WHITE_BEAN = 170026, 169961, 173756, 175202
PARSLEY, SUGAR, SEMOLINA, PHYLLO = 170416, 169655, 169715, 172791
WALNUT, GRAPE_LEAF, CUCUMBER, LEMON = 170187, 168575, 168409, 167746
PITA, WHITE_BREAD, PASTA_DRY, FIG_DRY = 174915, 174924, 169736, 174665
CORNSTARCH, YEAST, RAISIN = 169698, 175043, 168165

# (ad, grup, porsiyon_g, birim, pişmiş_toplam_g, [(malzeme, gram)])
RECIPES = [
    ("Menemen", "dish", 200, "porsiyon", 480,
     [(EGG, 150), (TOMATO, 300), (PEPPER, 100), (OLIVE_OIL, 20)]),
    ("Karnıyarık", "dish", 250, "porsiyon", 800,
     [(EGGPLANT, 600), (BEEF80, 150), (ONION, 100), (TOMATO, 150),
      (PEPPER, 50), (SUNFLOWER_OIL, 60)]),
    ("İmam Bayıldı", "dish", 200, "porsiyon", 750,
     [(EGGPLANT, 600), (ONION, 200), (TOMATO, 200), (OLIVE_OIL, 80),
      (GARLIC, 10)]),
    ("Mantı (Yoğurtlu)", "dish", 250, "porsiyon", 980,
     [(FLOUR, 200), (EGG, 50), (WATER, 80), (BEEF80, 150), (ONION, 50),
      (YOGURT, 300), (BUTTER, 30)]),
    ("Kısır", "dish", 150, "porsiyon", 900,
     [(BULGUR, 200), (WATER, 300), (PASTE, 30), (OLIVE_OIL, 50),
      (ONION, 50), (PARSLEY, 50), (TOMATO, 100), (CUCUMBER, 100),
      (LEMON, 30)]),
    ("Ezogelin Çorbası", "dish", 250, "kâse", 2000,
     [(RED_LENTIL, 150), (BULGUR, 30), (RICE, 30), (ONION, 80),
      (PASTE, 30), (BUTTER, 30), (WATER, 1800)]),
    ("Yayla Çorbası", "dish", 250, "kâse", 1650,
     [(RICE, 60), (YOGURT, 400), (EGG, 50), (FLOUR, 20), (BUTTER, 20),
      (WATER, 1200)]),
    ("Domates Çorbası", "dish", 250, "kâse", 1600,
     [(TOMATO, 800), (FLOUR, 30), (BUTTER, 30), (MILK, 200),
      (WATER, 600)]),
    ("Zeytinyağlı Taze Fasulye", "dish", 200, "porsiyon", 1100,
     [(GREEN_BEANS, 750), (ONION, 150), (TOMATO, 250), (OLIVE_OIL, 70),
      (SUGAR, 5), (WATER, 200)]),
    ("Yaprak Sarma (Zeytinyağlı)", "dish", 20, "adet", 1100,
     [(GRAPE_LEAF, 150), (RICE, 250), (ONION, 200), (OLIVE_OIL, 120),
      (WATER, 500), (LEMON, 30)]),
    ("Peynirli Börek (Yufka)", "dish", 100, "dilim", 1000,
     [(PHYLLO, 500), (FETA, 300), (EGG, 100), (MILK, 200),
      (SUNFLOWER_OIL, 100)]),
    ("Sigara Böreği", "dish", 30, "adet", 450,
     [(PHYLLO, 200), (FETA, 200), (SUNFLOWER_OIL, 100)]),
    ("Gözleme (Peynirli)", "dish", 200, "adet", 530,
     [(FLOUR, 250), (WATER, 150), (FETA, 150), (BUTTER, 30)]),
    ("Poğaça (Peynirli)", "dish", 60, "adet", 1000,
     [(FLOUR, 500), (YOGURT, 150), (SUNFLOWER_OIL, 150), (BUTTER, 50),
      (EGG, 50), (MILK, 100), (FETA, 150), (SUGAR, 10), (YEAST, 10)]),
    ("Açma", "dish", 80, "adet", 850,
     [(FLOUR, 500), (MILK, 150), (BUTTER, 100), (SUNFLOWER_OIL, 50),
      (SUGAR, 30), (EGG, 50), (YEAST, 10)]),
    ("Etli Kuru Fasulye", "dish", 250, "porsiyon", 2000,
     [(WHITE_BEAN, 500), (BEEF80, 200), (ONION, 150), (PASTE, 40),
      (SUNFLOWER_OIL, 40), (WATER, 1600)]),
    ("Etli Nohut", "dish", 250, "porsiyon", 1900,
     [(CHICKPEA, 500), (BEEF80, 150), (ONION, 150), (PASTE, 40),
      (SUNFLOWER_OIL, 40), (WATER, 1500)]),
    ("Etli Patates Yemeği", "dish", 250, "porsiyon", 1500,
     [(POTATO, 800), (BEEF80, 200), (ONION, 150), (PASTE, 30),
      (SUNFLOWER_OIL, 40), (WATER, 500)]),
    ("Türlü", "dish", 250, "porsiyon", 1450,
     [(EGGPLANT, 300), (ZUCCHINI, 300), (GREEN_BEANS, 200), (POTATO, 300),
      (PEPPER, 100), (TOMATO, 300), (ONION, 150), (OLIVE_OIL, 80)]),
    ("İzmir Köfte", "dish", 250, "porsiyon", 1100,
     [(BEEF80, 400), (POTATO, 500), (TOMATO, 300), (PEPPER, 100),
      (SUNFLOWER_OIL, 40)]),
    ("İskender", "dish", 350, "porsiyon", 450,
     [(BEEF80, 150), (PITA, 100), (TOMATO, 100), (BUTTER, 50),
      (YOGURT, 100)]),
    ("Adana Kebap", "dish", 190, "porsiyon", 190,
     [(LAMB, 150), (BEEF80, 100), (PEPPER, 20)]),
    ("Tavuk Şiş", "dish", 190, "porsiyon", 190,
     [(CHICKEN, 250), (OLIVE_OIL, 15), (YOGURT, 30)]),
    ("Tavuk Sote", "dish", 250, "porsiyon", 850,
     [(CHICKEN, 500), (PEPPER, 150), (TOMATO, 200), (ONION, 100),
      (SUNFLOWER_OIL, 40)]),
    ("Tavuklu Pilav", "dish", 250, "porsiyon", 1150,
     [(RICE, 300), (CHICKEN, 300), (BUTTER, 30), (WATER, 600)]),
    ("Mercimek Köftesi", "dish", 30, "adet", 1300,
     [(RED_LENTIL, 250), (BULGUR, 250), (ONION, 150), (OLIVE_OIL, 80),
      (PASTE, 40), (WATER, 650)]),
    ("Mücver", "dish", 50, "adet", 700,
     [(ZUCCHINI, 600), (EGG, 100), (FLOUR, 80), (FETA, 80),
      (SUNFLOWER_OIL, 60)]),
    ("Makarna (Domates Soslu)", "dish", 250, "porsiyon", 900,
     [(PASTA_DRY, 250), (TOMATO, 300), (OLIVE_OIL, 30), (WATER, 350)]),
    ("Kaşarlı Tost", "dish", 160, "adet", 160,
     [(WHITE_BREAD, 100), (MOZZ, 50), (BUTTER, 10)]),
    ("Omlet (Peynirli)", "dish", 190, "porsiyon", 190,
     [(EGG, 150), (FETA, 40), (BUTTER, 10)]),
    ("Cacık", "dish", 200, "kâse", 865,
     [(YOGURT, 500), (CUCUMBER, 200), (WATER, 150), (GARLIC, 5),
      (OLIVE_OIL, 10)]),
    ("Çoban Salatası", "dish", 200, "porsiyon", 730,
     [(TOMATO, 300), (CUCUMBER, 200), (PEPPER, 80), (ONION, 80),
      (PARSLEY, 20), (OLIVE_OIL, 30), (LEMON, 20)]),
    ("Haydari", "dish", 20, "yemek kaşığı", 525,
     [(GREEK_YOGURT, 400), (FETA, 100), (GARLIC, 5), (OLIVE_OIL, 20)]),
    # Tatlılar
    ("Baklava (Cevizli)", "sweet", 30, "adet", 1950,
     [(PHYLLO, 500), (BUTTER, 350), (WALNUT, 300), (SUGAR, 600),
      (WATER, 200)]),
    ("Sütlaç", "sweet", 200, "kâse", 1050,
     [(MILK, 1000), (RICE, 80), (SUGAR, 150), (CORNSTARCH, 30)]),
    ("Muhallebi", "sweet", 150, "kâse", 1050,
     [(MILK, 1000), (SUGAR, 150), (CORNSTARCH, 60)]),
    ("Revani", "sweet", 80, "dilim", 1500,
     [(SEMOLINA, 200), (FLOUR, 100), (SUGAR, 550), (EGG, 200),
      (YOGURT, 150), (SUNFLOWER_OIL, 100), (WATER, 300)]),
    ("Künefe", "sweet", 150, "porsiyon", 900,
     [(PHYLLO, 250), (BUTTER, 150), (MOZZ, 250), (SUGAR, 250),
      (WATER, 50)]),
    ("Aşure", "sweet", 200, "kâse", 3000,
     [(BULGUR, 250), (CHICKPEA, 100), (WHITE_BEAN, 100), (SUGAR, 300),
      (FIG_DRY, 100), (RAISIN, 100), (WALNUT, 50), (WATER, 2000)]),
]


def load_usda(folder):
    want = {"1008": "kcal", "1003": "p", "1005": "c", "1004": "f"}
    out = {}
    with open(os.path.join(folder, "food_nutrient.csv"), encoding="utf-8") as fh:
        for r in csv.DictReader(fh):
            k = want.get(r["nutrient_id"])
            if k:
                out.setdefault(int(r["fdc_id"]), {})[k] = float(r["amount"])
    return out


def entry(name, cat, kcal, p, c, f, portion, unit, ref):
    return {
        "name": name,
        "category": cat,
        "kcal_per_100g": round(kcal),
        "protein_per_100g": round(p, 1),
        "carb_per_100g": round(c, 1),
        "fat_per_100g": round(f, 1),
        "default_portion_g": portion,
        "unit_label": unit,
        "source_ref": ref,
    }


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    usda = load_usda(sys.argv[1])
    out = []
    for name, cat, fdc, portion, unit in USDA:
        n = usda[fdc]
        out.append(entry(name, cat, n.get("kcal", 0), n.get("p", 0),
                         n.get("c", 0), n.get("f", 0), portion, unit,
                         f"usda:{fdc}"))
    for name, cat, portion, unit, cooked, items in RECIPES:
        tot = {"kcal": 0.0, "p": 0.0, "c": 0.0, "f": 0.0}
        for fdc, grams in items:
            if fdc is None:
                continue  # su
            n = usda[fdc]
            for k in tot:
                tot[k] += n.get(k, 0) * grams / 100
        s = 100 / cooked
        out.append(entry(name, cat, tot["kcal"] * s, tot["p"] * s,
                         tot["c"] * s, tot["f"] * s, portion, unit, "recipe"))

    here = os.path.dirname(os.path.abspath(__file__))
    base = json.load(open(os.path.join(here, "..", "assets/data/turkish_foods.json"),
                          encoding="utf-8"))
    taken = {f["name"] for f in base}
    names = [e["name"] for e in out]
    dup = [n for n in names if n in taken or names.count(n) > 1]
    if dup:
        sys.exit(f"ad çakışması: {sorted(set(dup))}")

    path = os.path.join(here, "..", "assets/data/foods_extended.json")
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(out, fh, ensure_ascii=False, indent=1)
        fh.write("\n")
    print(f"yazıldı: {len(out)} kayıt ({len(USDA)} USDA + {len(RECIPES)} tarif)"
          f" → toplam {len(base) + len(out)}")


if __name__ == "__main__":
    main()
