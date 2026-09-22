#!/usr/bin/env python3
"""Mola sayacı seslerini üretir (assets/sounds/*.wav).

Neden üretiyoruz, indirmiyoruz: ses varlıklarının lisansı ve kaynağı belli
olmalı. Burada üretilen tonlar tamamen sentetik — telif yok, istenirse
parametreleri değiştirip yeniden üretilir, dosyalar "nereden geldi belli
olmayan binary" olmaz.

Kullanım:
    python3 tools/make_rest_sounds.py            # seçilen varyantları yazar
    python3 tools/make_rest_sounds.py --demo DIR # bütün adayları DIR'e yazar

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


TIKLAR = {"marimba": tik_marimba, "yumusak": tik_yumusak, "cam": tik_cam}
BITISLER = {"beslik": bitis_beslik, "akor": bitis_akor}

# Uygulamaya giren seçim.
SECILI_TIK = "yumusak"
SECILI_BITIS = "akor"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--demo", metavar="DIR",
                    help="bütün adayları bu klasöre yaz (dinleyip seçmek için)")
    ap.add_argument("--tik", default=SECILI_TIK, choices=sorted(TIKLAR))
    ap.add_argument("--bitis", default=SECILI_BITIS, choices=sorted(BITISLER))
    args = ap.parse_args()

    if args.demo:
        os.makedirs(args.demo, exist_ok=True)
        for ad, uret in TIKLAR.items():
            _yaz(os.path.join(args.demo, f"tik_{ad}.wav"), uret())
        for ad, uret in BITISLER.items():
            _yaz(os.path.join(args.demo, f"bitis_{ad}.wav"), uret())
        print(f"adaylar yazıldı: {args.demo}")
        return

    kok = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds")
    _yaz(os.path.join(kok, "rest_tick.wav"), TIKLAR[args.tik]())
    _yaz(os.path.join(kok, "rest_done.wav"), BITISLER[args.bitis]())
    print(f"yazıldı: rest_tick.wav ({args.tik}), rest_done.wav ({args.bitis})")


if __name__ == "__main__":
    main()
