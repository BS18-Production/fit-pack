#!/usr/bin/env python3
"""Mola sayacı seslerini üretir (assets/sounds/).

Neden üretiyoruz, indirmiyoruz: ses varlıklarının lisansı ve kaynağı belli
olmalı. Burada üretilen tonlar tamamen sentetik — telif yok, istenirse
parametreleri değiştirip yeniden üretilir, dosyalar "nereden geldi belli
olmayan binary" olmaz.

Kullanım:
    python3 tools/make_rest_sounds.py            # 5 sesi assets/sounds/'a yazar
    python3 tools/make_rest_sounds.py --demo DIR # WAV olarak DIR'e (dinlemek için)

**Tek parça geri sayım (2026-09-30).** Her ses = 3 tık (0, 1, 2. sn) + bitiş
(3. sn) tek dosyada. Bitişten tam 3 sn önce bir kez başlatılır — aralıklar
örnek (sample) hassasiyetinde sabit (eski "her saniye durdur/başlat" yolunda
2. ve 3. bip kayıyordu).

**Ses seçimi (2026-10-11, docs/45 §3).** Ayarlar'dan seçilen 5 ses. Her ses
için iki dosya:
- `rest_<id>.m4a` — geri sayım (tık + bitiş). Uygulama içi (iOS/Android) ve
  Android dinlenme servisi aynı dosyayı çalar. AAC: WAV'ın ~1/8'i.
- `rest_<id>_countdown.caf` — tam geri sayım, iOS bildirim sesi. Bildirim
  bitişten 3 sn önce kurulur: uygulama arkadayken de 3-2-1 + bitiş duyulur
  (2026-10-12; yalnız bitiş sesi çalınca son 3 saniye kayboluyordu).
- `rest_<id>_end.caf` — yalnız bitiş: 3 sn'den az kalmışken kurulan bildirim.
  iOS bildirim sesi AAC kabul etmez (doğrusal PCM / IMA4 ister) → IMA4.
Dönüştürme macOS'taki `afconvert` ile yapılır.

Tasarım notları:
- **Tık** kısa olmalı (~100-150 ms): geri sayım 1 sn aralıklı, uzun ses üst
  üste biner. Salon gürültüsünde duyulsun diye 700-1300 Hz bandında.
- Her tonun 3-4 ms'lik yumuşak girişi var; onsuz hoparlörde "tık" duyulur.
- Çan tınısı uyumsuz kısmi seslerle (inharmonik) kurulur: gerçek çanın
  kısmi oranları ~1 : 2 : 2,76 : 5,4 : 8,93 (Rossing, *Science of
  Percussion Instruments*); yüksek kısmiler daha hızlı söner.
"""

import argparse
import math
import os
import random
import struct
import subprocess
import tempfile
import wave

SAMPLE_RATE = 22050  # 11 kHz'e kadar — çan parlaklığı için yeterli, dosya yarı


def _ton(frekans, sure_s, harmonikler=(1.0,), tau_s=0.035, giris_s=0.003):
    """Üstel sönümlü tek nota (tam katlı harmonikler)."""
    return _kismi(frekans, sure_s, [(k, a, tau_s) for k, a in
                                    enumerate(harmonikler, start=1)], giris_s)


def _kismi(frekans, sure_s, kismiler, giris_s=0.003):
    """[(oran, genlik, sönüm_s)] kısmi seslerinden nota. Çan için oranlar
    tam sayı değil; her kısmi kendi hızında söner."""
    n = int(SAMPLE_RATE * sure_s)
    toplam_genlik = sum(a for _, a, _ in kismiler) or 1.0
    ornekler = []
    for i in range(n):
        t = i / SAMPLE_RATE
        deger = 0.0
        for oran, genlik, tau in kismiler:
            deger += genlik * math.exp(-t / tau) * math.sin(
                2 * math.pi * frekans * oran * t)
        deger /= toplam_genlik
        if t < giris_s:
            deger *= t / giris_s
        ornekler.append(deger)
    return ornekler


def _kare(frekans, sure_s, tau_s=0.4, giris_s=0.004):
    """Yumuşatılmış kare dalga (tek harmonikler 1, 1/3, 1/5, 1/7) — alarm
    tınısı; tam kare dalga hoparlörde cızırtı yapar."""
    return _ton(frekans, sure_s, harmonikler=(1.0, 0.0, 1 / 3, 0.0, 1 / 5,
                                              0.0, 1 / 7), tau_s=tau_s,
                giris_s=giris_s)


def _vurus(sure_s=0.012, seviye=0.35, tohum=7):
    """Tokmak vuruşu: çok kısa gürültü patlaması (çanın 'tın' başı)."""
    rng = random.Random(tohum)
    n = int(SAMPLE_RATE * sure_s)
    return [seviye * rng.uniform(-1, 1) * (1 - i / n) for i in range(n)]


def _karistir(parcalar):
    """(gecikme_s, ornekler) listesini tek bir tampona toplar."""
    toplam = max(int(g * SAMPLE_RATE) + len(o) for g, o in parcalar)
    cikti = [0.0] * toplam
    for gecikme, ornekler in parcalar:
        ofset = int(gecikme * SAMPLE_RATE)
        for i, v in enumerate(ornekler):
            cikti[ofset + i] += v
    return cikti


def _olcekle(ornekler, tepe):
    en_buyuk = max(abs(v) for v in ornekler) or 1.0
    return [v * tepe / en_buyuk for v in ornekler]


def _yaz_wav(yol, ornekler):
    with wave.open(yol, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767))
            for v in ornekler))


# ───────────────────────────── Sesler ─────────────────────────────
# Her ses: (tık, bitiş, tepe seviyesi). Tepe: yüksek sesler (güçlü alarm)
# daha yüksek normalize edilir; yumuşak çan bilerek kısık.

def _klasik_tik():
    return _kismi(1318.5, 0.16, [(1.0, 1.0, 0.05), (2.0, 0.25, 0.03)])


def _klasik_bitis():
    """Tek çan vuruşu — uzun, temiz kuyruk."""
    return _karistir([
        (0.0, _vurus(seviye=0.25)),
        (0.0, _kismi(880.0, 1.4, [(1.0, 1.0, 0.55), (2.0, 0.5, 0.35),
                                  (2.76, 0.35, 0.22), (5.4, 0.18, 0.10),
                                  (8.93, 0.08, 0.06)])),
    ])


def _boks_tik():
    """Tahta blok — kısa, kuru."""
    return _kismi(1050.0, 0.09, [(1.0, 1.0, 0.018), (2.3, 0.4, 0.012)])


def _boks_vurus():
    return _karistir([
        (0.0, _vurus(sure_s=0.008, seviye=0.4, tohum=3)),
        (0.0, _kismi(1210.0, 0.9, [(1.0, 1.0, 0.45), (1.51, 0.45, 0.30),
                                   (2.0, 0.40, 0.25), (2.74, 0.30, 0.15),
                                   (3.76, 0.15, 0.08)])),
    ])


def _boks_bitis():
    """Ring zili: "ding-ding-ding" — üç hızlı vuruş, metalik kuyruk."""
    return _karistir([(0.0, _boks_vurus()), (0.26, _boks_vurus()),
                      (0.52, _boks_vurus())])


def _dijital_tik():
    """Yarış/start tınısı (2026-09-30'dan beri varsayılan ses)."""
    return _ton(784.0, 0.15, harmonikler=(1.0, 0.0, 0.33, 0.0, 0.2),
                tau_s=0.25, giris_s=0.004)


def _dijital_bitis():
    """Bir oktav yukarı, uzun tek bip — 'başla!'."""
    return _ton(1568.0, 0.55, harmonikler=(1.0, 0.0, 0.25, 0.0, 0.12),
                tau_s=0.45, giris_s=0.004)


def _yumusak_tik():
    return _ton(660.0, 0.12, harmonikler=(1.0,), tau_s=0.035, giris_s=0.008)


def _yumusak_bitis():
    """Do majör arpej, cam çan tınısı — nazik 'tamam'."""
    nota = lambda f: _kismi(f, 1.1, [(1.0, 1.0, 0.40), (2.0, 0.22, 0.20),
                                      (3.0, 0.06, 0.10)], giris_s=0.008)
    return _karistir([(0.00, nota(1046.5)), (0.12, nota(1318.5)),
                      (0.24, nota(1568.0))])


def _guclu_tik():
    return _kare(1000.0, 0.13, tau_s=0.5)


def _guclu_bitis():
    """İki tonlu alarm üç kez (1200/900 Hz) — gürültülü salonda seçilir."""
    parcalar = []
    for i in range(3):
        t = i * 0.34
        parcalar.append((t, _kare(1200.0, 0.15, tau_s=1.0)))
        parcalar.append((t + 0.16, _kare(900.0, 0.15, tau_s=1.0)))
    return _karistir(parcalar)


# id → (tık, bitiş, tepe). id'ler uygulamadaki `RestSound` ile aynı.
SESLER = {
    "classic_bell": (_klasik_tik, _klasik_bitis, 0.80),
    "boxing_bell": (_boks_tik, _boks_bitis, 0.85),
    "digital_beep": (_dijital_tik, _dijital_bitis, 0.72),
    "soft_chime": (_yumusak_tik, _yumusak_bitis, 0.55),
    "strong_alert": (_guclu_tik, _guclu_bitis, 0.95),
}


def geri_sayim(tik, bitis, tepe):
    """3 tık (0, 1, 2. sn) + bitiş (3. sn) — tek parça."""
    return _olcekle(_karistir([(float(i), tik()) for i in range(3)] +
                              [(3.0, bitis())]), tepe)


def _afconvert(girdi, cikti, *args):
    subprocess.run(["afconvert", girdi, cikti, *args], check=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--demo", metavar="DIR",
                    help="WAV olarak bu klasöre yaz (dinleyip seçmek için)")
    args = ap.parse_args()

    if args.demo:
        os.makedirs(args.demo, exist_ok=True)
        for sid, (tik, bitis, tepe) in SESLER.items():
            _yaz_wav(os.path.join(args.demo, f"rest_{sid}.wav"),
                     geri_sayim(tik, bitis, tepe))
        print(f"yazıldı: {args.demo}")
        return

    hedef = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds")
    os.makedirs(hedef, exist_ok=True)
    with tempfile.TemporaryDirectory() as gecici:
        for sid, (tik, bitis, tepe) in SESLER.items():
            tam = os.path.join(gecici, f"{sid}.wav")
            son = os.path.join(gecici, f"{sid}_end.wav")
            _yaz_wav(tam, geri_sayim(tik, bitis, tepe))
            _yaz_wav(son, _olcekle(bitis(), tepe))
            _afconvert(tam, os.path.join(hedef, f"rest_{sid}.m4a"),
                       "-f", "m4af", "-d", "aac", "-b", "64000")
            _afconvert(tam, os.path.join(hedef, f"rest_{sid}_countdown.caf"),
                       "-f", "caff", "-d", "ima4")
            _afconvert(son, os.path.join(hedef, f"rest_{sid}_end.caf"),
                       "-f", "caff", "-d", "ima4")
            print(f"yazıldı: rest_{sid}.m4a + _countdown.caf + _end.caf")


if __name__ == "__main__":
    main()
