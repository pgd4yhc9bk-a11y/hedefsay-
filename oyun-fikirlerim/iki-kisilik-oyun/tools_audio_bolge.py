"""Çark ve nehir bölgesinin sesleri (sentez): akan su döngüsü, sıçrama, halat gıcırtısı, çark tıkırtısı, kapı gümbürtüsü.
Çalıştırma: python3 tools_audio_bolge.py  -> godot/proto/ses/*.wav"""
import os
import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'godot/proto/ses')
rng = np.random.default_rng(7)


def save(name, x, peak):
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    wavfile.write(f'{OUT}/{name}.wav', SR, (x * 32767).astype(np.int16))


def band(x, lo, hi, o=2):
    b, a = signal.butter(o, [lo / (SR / 2), hi / (SR / 2)], 'band')
    return signal.lfilter(b, a, x)


def lowp(x, f, o=2):
    b, a = signal.butter(o, f / (SR / 2), 'low')
    return signal.lfilter(b, a, x)


# akan su: yumuşak hışırtı + rastgele küçük şıpırtılar (döngü, uçları birleşik)
d = 6.0
n = int(SR * d)
t = np.arange(n) / SR
base = band(rng.standard_normal(n), 200, 1400) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.23 * t) ** 2)
drops = np.zeros(n)
for _ in range(90):
    p = rng.integers(0, n - 2000)
    f = rng.uniform(600, 1800)
    L = int(SR * rng.uniform(0.03, 0.08))
    tt = np.arange(L) / SR
    drops[p:p + L] += np.sin(2 * np.pi * (f + 900 * tt / tt[-1]) * tt) * np.exp(-tt / 0.02) * rng.uniform(0.2, 0.6)
x = base * 0.5 + drops
fade = int(SR * 0.5)
x[:fade] = x[:fade] * np.linspace(0, 1, fade) + x[-fade:] * np.linspace(1, 0, fade)
save('su_dongu', x[:n - fade], 0.5)

# sıçrama: geniş gürültü patlaması + damlalar
n = int(SR * 1.2)
t = np.arange(n) / SR
sp = band(rng.standard_normal(n), 300, 5000) * np.exp(-t / 0.18)
sp += lowp(rng.standard_normal(n), 300) * np.exp(-t / 0.08) * 2
save('su_sicrama', sp, 0.85)

# halat gıcırtısı (ip gerilir): sürtünmeli tiz ses
for i in range(3):
    n = int(SR * 0.5)
    t = np.arange(n) / SR
    f0 = rng.uniform(380, 520)
    saw = signal.sawtooth(2 * np.pi * (f0 + 60 * np.sin(2 * np.pi * 7 * t)) * t)
    x = band(saw * (rng.random(n) < 0.6), 500, 3000) * np.sin(np.pi * t / t[-1]) ** 2
    save(f'halat_{i}', x, 0.4)

# çark tıkırtısı (cırcır)
for i in range(3):
    n = int(SR * 0.12)
    t = np.arange(n) / SR
    x = band(rng.standard_normal(n), 1800, 6000) * np.exp(-t / 0.01) + np.sin(2 * np.pi * 900 * t) * np.exp(-t / 0.015) * 0.5
    save(f'cark_{i}', x, 0.6)

# kapı: ağır tahta kalkar, zincir şıngırtısı ve sonda gümbürtü
n = int(SR * 2.2)
t = np.arange(n) / SR
rum = lowp(rng.standard_normal(n), 140) * 3 * np.minimum(1, t / 0.2) * np.exp(-np.maximum(0, t - 1.6) / 0.15)
ch = np.zeros(n)
for k in range(26):
    p = int(SR * rng.uniform(0.05, 1.7))
    L = int(SR * 0.05)
    tt = np.arange(L) / SR
    ch[p:p + L] += np.sin(2 * np.pi * rng.uniform(2500, 4200) * tt) * np.exp(-tt / 0.012) * 0.4
save('kapi_kalk', rum + ch, 0.8)
print('yazildi')
