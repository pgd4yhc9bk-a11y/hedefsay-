"""Önsöz sesleri (sentez): rüzgâr hamlesi (tavşanı uçuran), karda adım, uzak köpek yok; sessiz ve soğuk.
Çalıştırma: python3 tools_audio_onsoz.py  -> godot/proto/ses/ruzgar_*.wav, adim_kar_*.wav"""
import os
import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'godot/proto/ses')
rng = np.random.default_rng(11)


def save(name, x, peak):
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    wavfile.write(f'{OUT}/{name}.wav', SR, (x * 32767).astype(np.int16))


def gust(d, seed):
    r = np.random.default_rng(seed)
    n = int(SR * d)
    t = np.arange(n) / SR
    x = r.standard_normal(n)
    # rüzgârın uğultusu: zamanla kayan dar bant (ıslık gibi) + geniş hışırtı
    out = np.zeros(n)
    blk = 512
    zi = None
    for s in range(0, n, blk):
        k = s / n
        f = 300 + 500 * np.sin(np.pi * k) + 80 * np.sin(2 * np.pi * 3.1 * k)
        b, a = signal.butter(2, [max(60, f * 0.6) / (SR / 2), (f * 1.5) / (SR / 2)], 'band')
        if zi is None:
            zi = signal.lfilter_zi(b, a) * 0
        y, zi = signal.lfilter(b, a, x[s:s + blk], zi=zi)
        out[s:s + blk] = y
    b, a = signal.butter(2, [1500 / (SR / 2), 6000 / (SR / 2)], 'band')
    hiss = signal.lfilter(b, a, r.standard_normal(n)) * 0.25
    e = np.sin(np.pi * np.clip(t / d, 0, 1)) ** 1.6
    return (out + hiss) * e


for i in range(2):
    save(f'ruzgar_{i}', gust(3.2, 40 + i), 0.8)
for i in range(4):   # karda adım: yumuşak gıcırtı
    n = int(SR * 0.22)
    t = np.arange(n) / SR
    b, a = signal.butter(2, [700 / (SR / 2), 4200 / (SR / 2)], 'band')
    cr = signal.lfilter(b, a, rng.standard_normal(n)) * (rng.random(n) < 0.35)
    e = np.minimum(1, t / 0.02) * np.exp(-t / 0.07)
    b2, a2 = signal.butter(2, 250 / (SR / 2), 'low')
    th = signal.lfilter(b2, a2, rng.standard_normal(n)) * np.exp(-t / 0.04)
    save(f'adim_kar_{i}', cr * e + th * 1.5, 0.55)
print('yazildi')
