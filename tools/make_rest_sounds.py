#!/usr/bin/env python3
"""Mola sayacı seslerini üretir (assets/sounds/*.wav).

Neden üretiyoruz, indirmiyoruz: ses varlıklarının lisansı ve kaynağı belli
olmalı. Burada üretilen tonlar tamamen sentetik — telif yok, istenirse
parametreleri değiştirip yeniden üretilir, dosyalar "nereden geldi belli
olmayan binary" olmaz.

Kullanım:
    python3 tools/make_rest_sounds.py            # seçilen varyantları yazar
    python3 tools/make_rest_sounds.py --demo DIR # bütün adayları DIR'e yazar

**Tek parça geri sayım (2026-09-30).** Uygulama artık tık ve bitişi ayrı
ayrı çalmıyor: `rest_countdown.wav` = 3 tık (0, 1, 2. sn) + bitiş (3. sn)
tek dosyada. Bitişten tam 3 sn önce bir kez başlatılır. Neden: her saniye
oynatıcıyı durdurup yeniden başlatmak (stop + resume) zayıf telefonlarda
50-300 ms değişken gecikme veriyordu → 2. ve 3. bip "kayıyordu". Tek dosyada
aralıklar örnek (sample) hassasiyetinde sabit. Aynı dosya Android'de
`res/raw/`a da yazılır — arka plan servisi oradan çalar.

Tasarım notları:
- **Tik** kısa olmalı (~100 ms): geri sayım 1 sn aralıklı, uzun ses üst üste
  biner. Salon gürültüsünde duyulsun diye temel frekans 700-1000 Hz bandında.
- **Bitiş** bir "alarm" değil, bir **çözülme** olmalı: yükselen iki-üç nota.
- Her tonun 3 ms'lik yumuşak girişi var; onsuz hoparlörde "tık" duyulur.
"""

import argparse
import math
import os
import struct
import wave

SAMPLE_RATE = 44100


def _ton(frekans, sure_s, harmonikler=(1.0,), tau_s=0.035, giris_s=0.003):
    """Üstel sönümlü tek nota. [(-1, 1)] aralığında örnek listesi döner."""
    n = int(SAMPLE_RATE * sure_s)
    ornekler = []
    for i in range(n):
        t = i / SAMPLE_RATE
        deger = 0.0
        for k, agirlik in enumerate(harmonikler, start=1):
            deger += agirlik * math.sin(2 * math.pi * frekans * k * t)
        deger /= sum(harmonikler)
        # Sönüm: üstel. Giriş: kısa doğrusal rampa (hoparlör tıkını önler).
        zarf = math.exp(-t / tau_s)
        if t < giris_s:
            zarf *= t / giris_s
        ornekler.append(deger * zarf)
    return ornekler


def _karistir(parcalar):
    """(gecikme_s, ornekler) listesini tek bir tampona toplar."""
    toplam = max(int(g * SAMPLE_RATE) + len(o) for g, o in parcalar)
    cikti = [0.0] * toplam
    for gecikme, ornekler in parcalar:
        ofset = int(gecikme * SAMPLE_RATE)
        for i, v in enumerate(ornekler):
            cikti[ofset + i] += v
    return cikti


def _yaz(yol, ornekler, tepe=0.72):
    """Tepe değerine göre ölçekleyip 16-bit mono WAV yazar."""
    en_buyuk = max(abs(v) for v in ornekler) or 1.0
    olcek = tepe / en_buyuk
    with wave.open(yol, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(
            b"".join(
                struct.pack("<h", int(max(-1.0, min(1.0, v * olcek)) * 32767))
                for v in ornekler
            )
        )


# ─────────────────────────── Tik adayları ───────────────────────────

def tik_marimba():
    """Ahşap/marimba tınısı — sıcak, keskin değil. Varsayılan."""
    return _ton(784.0, 0.12, harmonikler=(1.0, 0.32, 0.10), tau_s=0.030)


def tik_yumusak():
    """Saf sinüs pip — en sade, en 'generic'."""
    return _ton(880.0, 0.10, harmonikler=(1.0,), tau_s=0.028, giris_s=0.006)


def tik_cam():
    """Cam/çan — parlak, daha uzun kuyruk."""
    return _ton(1046.5, 0.20, harmonikler=(1.0, 0.0, 0.18), tau_s=0.055)


# ────────────────────────── Bitiş adayları ──────────────────────────

def bitis_beslik():
    """Yükselen beşli (D5 → A5): kısa, nazik bir 'tamam'."""
    return _karistir([
        (0.00, _ton(587.33, 0.22, (1.0, 0.28, 0.08), tau_s=0.055)),
        (0.13, _ton(880.00, 0.32, (1.0, 0.25, 0.07), tau_s=0.080)),
    ])


def bitis_akor():
    """Do majör arpej (C5-E5-G5) — daha 'bitti, aferin' hissi."""
    return _karistir([
        (0.00, _ton(523.25, 0.24, (1.0, 0.30, 0.09), tau_s=0.060)),
        (0.11, _ton(659.25, 0.26, (1.0, 0.28, 0.08), tau_s=0.065)),
        (0.22, _ton(783.99, 0.38, (1.0, 0.25, 0.07), tau_s=0.095)),
    ])


def tik_yaris():
    """Yarış/start tınısı — kısa, net, hafif 'dijital'. Salon gürültüsünde
    sinüsten daha iyi seçilir (tek harmonikler kulağa 'bip' gibi gelir)."""
    return _ton(784.0, 0.15, harmonikler=(1.0, 0.0, 0.33, 0.0, 0.2),
                tau_s=0.25, giris_s=0.004)


def bitis_yaris():
    """Yarış başlangıcı: bir oktav yukarı, uzun tek bip — 'başla!'."""
    return _ton(1568.0, 0.55, harmonikler=(1.0, 0.0, 0.25, 0.0, 0.12),
                tau_s=0.45, giris_s=0.004)


TIKLAR = {"marimba": tik_marimba, "yumusak": tik_yumusak, "cam": tik_cam,
          "yaris": tik_yaris}
BITISLER = {"beslik": bitis_beslik, "akor": bitis_akor, "yaris": bitis_yaris}

# Uygulamaya giren seçim. 2026-09-30: Samet sesi değiştirmek istedi →
# "yarış" (3 kısa + 1 uzun yüksek bip; spor saatlerinin tanıdık geri sayımı).
SECILI_TIK = "yaris"
SECILI_BITIS = "yaris"

# Demo'da dinletilen tam geri sayım çiftleri (tik, bitiş).
DEMO_CIFTLER = [("yaris", "yaris"), ("yumusak", "akor"),
                ("marimba", "beslik"), ("cam", "akor")]


def geri_sayim(tik, bitis):
    """3 tık (0, 1, 2. sn) + bitiş (3. sn) — tek parça."""
    return _karistir([(float(i), tik()) for i in range(3)] + [(3.0, bitis())])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--demo", metavar="DIR",
                    help="bütün adayları bu klasöre yaz (dinleyip seçmek için)")
    ap.add_argument("--tik", default=SECILI_TIK, choices=sorted(TIKLAR))
    ap.add_argument("--bitis", default=SECILI_BITIS, choices=sorted(BITISLER))
    args = ap.parse_args()

    if args.demo:
        os.makedirs(args.demo, exist_ok=True)
        for t, b in DEMO_CIFTLER:
            _yaz(os.path.join(args.demo, f"geri_sayim_{t}_{b}.wav"),
                 geri_sayim(TIKLAR[t], BITISLER[b]))
        print(f"adaylar yazıldı: {args.demo}")
        return

    kok = os.path.join(os.path.dirname(__file__), "..")
    ornekler = geri_sayim(TIKLAR[args.tik], BITISLER[args.bitis])
    for yol in ("assets/sounds/rest_countdown.wav",
                "android/app/src/main/res/raw/rest_countdown.wav"):
        tam = os.path.join(kok, yol)
        os.makedirs(os.path.dirname(tam), exist_ok=True)
        _yaz(tam, ornekler)
    print(f"yazıldı: rest_countdown.wav ({args.tik} + {args.bitis})")


if __name__ == "__main__":
    main()
