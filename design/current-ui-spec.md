# Fit Pack — Mevcut UI Tasarım Spec'i (ChatGPT devri için)

> Bu dosya, uygulamanın **kod tabanından çıkarılmış gerçek tasarım
> değerleridir** (uydurma değil). ChatGPT'ye bunu + ekran görüntülerini ver;
> tahminle "genel görünüm" üretmesin, birebir bu sistemi kullansın.

## Kimlik
- **Vibe:** Apple Fitness ferahlığı + "Pro" his. Sakin, bol beyaz boşluk, düz
  (flat) kartlar (gölge yok, ince kenarlık var), yuvarlak köşeler.
- **Marka renkleri:** Indigo (mor-mavi) + Teal (turkuaz) ikilisi.
- **Font:** **Manrope** (Google Fonts). Başlıklar çok kalın (w800).
- **Mod:** Dark öncelikli, light tam destekli (sistem takip eder).
- **Dil:** Türkçe arayüz.

---

## 1. Renkler (birebir hex)

### Marka çekirdeği
| Ad | Hex |
|----|-----|
| indigo | `#6366F1` |
| indigoBright | `#818CF8` |
| indigoDeep | `#4F46E5` |
| teal | `#14B8A6` |
| tealBright | `#2DD4BF` |
| **Gradient (CTA kartları)** | `#6366F1 → #4F46E5` (sol-üstten sağ-alta) |
| Gradient üstü metin/ikon | `#FFFFFF` |

### DARK tema (öncelikli)
| Rol | Hex |
|-----|-----|
| Zemin (scaffold) | `#101218` |
| Kart yüzeyi (surface) | `#1B1E27` |
| Yükseltilmiş yüzey | `#232734` |
| Input/yüksek yüzey | `#262A38` |
| primary | `#6366F1` · üzeri `#FFFFFF` |
| primaryContainer | `#3730A3` · üzeri `#E0E1FF` |
| secondary (teal) | `#14B8A6` · üzeri `#03201D` |
| error | `#EF4444` |
| Ana metin (onSurface) | `#E7E9EE` |
| İkincil metin (onSurfaceVariant) | `#9BA1B0` |
| Kenarlık (outline) | `#2F3442` |
| İnce kenarlık (outlineVariant) | `#252A36` |

### LIGHT tema
| Rol | Hex |
|-----|-----|
| Zemin | `#F6F7F9` |
| Kart yüzeyi | `#FFFFFF` |
| Yüksek yüzey | `#EEF0F4` |
| primary | `#4F46E5` · üzeri `#FFFFFF` |
| primaryContainer | `#E0E1FF` · üzeri `#1A1B4B` |
| secondary | `#0D9488` |
| error | `#DC2626` |
| Ana metin | `#1A1C22` |
| İkincil metin | `#5A6072` |
| Kenarlık | `#D8DCE4` · ince `#E7E9EE` |

### Semantik renkler (her iki modda)
| Ad | Dark | Light | Kullanım |
|----|------|-------|----------|
| success | `#22C55E` | `#16A34A` | kilo düşüşü ✓, tamamlanan set |
| warning | `#F59E0B` | `#D97706` | ısınma seti |
| info | `#38BDF8` | `#0284C7` | su takibi |
| macroCalories | `#6366F1` | `#4F46E5` | kalori |
| macroProtein | `#14B8A6` | `#0D9488` | protein (P) |
| macroCarbs | `#38BDF8` | `#0284C7` | karbonhidrat (K) |
| macroFat | `#FBBF24` | `#D97706` | yağ (Y) |

---

## 2. Tipografi (Manrope)
| Stil | Boyut / Ağırlık | Kullanım |
|------|-----------------|----------|
| displaySmall | 32 / 800 (ls −0.5) | büyük sayılar |
| headlineMedium | 26 / 800 (ls −0.5) | ekran başlığı ("Çarşamba, 1 Temmuz") |
| headlineSmall | 22 / 800 | bölüm başlığı, stat sayıları |
| titleLarge | 19 / 700 | kart başlığı |
| titleMedium | 16 / 700 | alt başlık |
| titleSmall | 14 / 700 | küçük başlık |
| bodyLarge | 16 / 500 | gövde |
| bodyMedium | 14 / 500 | gövde |
| bodySmall | 12.5 / 500 | ikincil metin |
| labelLarge | 14 / 700 | buton metni |
| labelMedium | 12.5 / 600 | etiket |
| labelSmall | 11.5 / 600 | üstbaşlık ("BUGÜN", ls +1.6, primary renk) |

---

## 3. Ölçek
- **Boşluk (8pt tabanlı):** 4 · 8 · 12 · 16 · 20 · 24 · 32; bloklar arası nefes **26**. Ekran/kart iç boşluğu genelde **16**.
- **Köşe yarıçapı:** küçük 8 · orta 12 · büyük **16 (kartlar)** · xl **20 (gradient CTA + bottom sheet üstü)** · pill 999.
- **İkon:** 18 · 24 · 32 · 48 · 64.
- **Min dokunma hedefi:** 48px.

---

## 4. Bileşen stilleri
- **Kart:** yüzey rengi zemin, **1px ince kenarlık** (outlineVariant), köşe 16, **gölge YOK, elevation 0** (düz). İç boşluk 16.
- **FilledButton (birincil):** primary zemin, köşe 12, min yükseklik 48, metin labelLarge/beyaz.
- **OutlinedButton:** primary metin + primary/outline kenarlık, köşe 12.
- **Input:** dolgulu (yüksek yüzey), köşe 12, **kenarlık yok** (odaklanınca 2px primary), iç boşluk h16/v12.
- **FAB (Yemek Ekle / Ölçüm Ekle):** primary, köşe 16, extended (ikon + metin).
- **Alt navigasyon:** zemin renginde, yükseklik 68, seçili sekme primary@%16 kapsül + primary ikon/metin, etiketler hep görünür. 4 sekme: Ana Sayfa (ev) · Antrenman (dambıl) · Beslenme (çatal-bıçak) · İlerleme (yükselen ok).
- **SegmentedButton:** seçili = primary zemin/beyaz metin, seçilmemiş = yüksek yüzey/ikincil metin, köşe 8.
- **Chip:** yüksek yüzey + ince kenarlık, köşe 8.
- **Bottom sheet:** yüzey rengi, üst köşeler 20, üstte tutma çubuğu.
- **SnackBar:** floating, ters yüzey rengi, köşe 12.

---

## 5. İmza bileşenler (ekran görüntülerine bak — bunlar uygulamanın kalbi)
1. **Ekran header'ı:** küçük büyük-harf üstbaşlık (örn. "BUGÜN", primary, harf aralıklı) + altında büyük başlık (headlineMedium, örn. tarih) + sağda ikon butonlar (paylaş, ayarlar).
2. **Gradient CTA kartı:** indigo→indigoDeep gradient, köşe 20, beyaz metin, yumuşak indigo gölge; solda beyaz@%20 köşeli ikon kutusu. "Antrenmana başla" / "Bugün: Push Day" gibi.
3. **Beslenme hero kartı:** başlık "Bugünkü Beslenme" + sağda "Düzenle" (primary link); ortada **kalori halkası** (dairesel ilerleme, kalın iz, ortada büyük indigo sayı + "kcal kaldı"); altında 3 **makro barı** (Protein=teal, Karbonhidrat=mavi, Yağ=amber) — her biri "0 / X g" + ince ilerleme çubuğu.
4. **Su kartı:** info-mavi vurgu, damla ikon kutusu, "Su" + sağda "X.X / 2.5 L", ince ilerleme çubuğu, altında iki pill buton "+250 ml" / "+1 bardak".
5. **Stat satırı:** iki sütun, ortada dikey ayraç — "SERİ 🔥 X gün" ve "SON KİLO X.X kg" (kilo düşüşü yeşil ↓ rozet).
6. **Dinlenme günü kartı:** sönük ton, yatak ikonu, "Bugün dinlenme günü" + "Sıradaki: X".
7. **Öğün kartı (Beslenme):** teal tonlu ikon kutusu + öğün adı + toplam kcal + "+" ekle; boşsa "Henüz kayıt yok".
8. **Yemek Ekle sayfası (bottom sheet):** üstte öğün seçici (segmented), arama + barkod + özel-yemek (teal daire butonlar), "son kullanılanlar" çipleri, yemek listesi (her satır: ad + renkli P/K/Y makro + "X kcal /100g" + "1 birim ≈ Xg").
9. **Ayarlar:** büyük-harf sönük bölüm başlıkları; her satır primary-tonlu köşeli ikon kutusu + başlık + sağda değer/ok; "Tahmini Günlük Harcama" primaryContainer zeminli vurgu kartı.

---

## 6. Ekranlar (alt sekmeler + alt sayfalar)
**Ana sekmeler:** Ana Sayfa · Antrenman · Beslenme · İlerleme.
**Alt sayfalar:** Ayarlar, Hareket Kütüphanesi, Aktif Seans (set tablosu KG/tekrar/RPE/✓), Antrenman Geçmişi, Rutin Oluşturucu, Onboarding, Bulut Hesabı, Dışa Aktar, Hareket Detayı (Nasıl/Geçmiş/Grafik/Rekorlar sekmeli).

---

## 7. Notlar (fidelity için)
- Kartlar **gölgesiz + ince kenarlıklı** (yaygın hata: gölge eklemek → yanlış görünür). Tek istisna: gradient CTA'nın renkli yumuşak gölgesi.
- Sayılar tabular (hizalı) rakam kullanır.
- Başlık ağırlıkları **kalın (800)** — zayıf/ince font yanlış görünür.
- Renk asla gelişigüzel seçilmez; hep bu tablodan.
