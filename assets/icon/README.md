# FP monogram — 2026-10-07

Samet'in seçtiği neon lime zeminli siyah FP görseli uygulama ikonudur.

- `icon_master.png`: seçilen görselin değişmeden saklanan 1254 × 1254 kaynağı.
- `icon_full.png`: iOS ve standart Android için 1024 × 1024, opak PNG.
- `icon_bg.png`: uyarlanabilir Android ikonunun `#CCFF00` zemini.
- `icon_fg.png`: kenar yumuşaklığı korunmuş, şeffaf FP katmanı.

## Yeniden üretme

Proje kökünde:

```sh
dart run tools/prepare_launcher_icon.dart
dart run flutter_launcher_icons
```

Android XML katmanı %18 içeriden yerleştirir. Monogramın en uzak noktası
108 dp tuvalin merkezinden 31,78 dp uzaktadır; 66 dp güvenli dairenin
içindedir. Kaynağa önceden yuvarlak köşe uygulanmaz; maskeyi platform sağlar.

İkonlar yerel uygulama kaynaklarıdır. Telefonda görünmeleri için yeni
derlemenin kurulması gerekir; yalnız hot reload yeterli değildir.
