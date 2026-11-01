"""Prototip bölüm sesleri (tamamen sentez, numpy/scipy): godot/proto/ses/*.wav
Adımlar (yaprak, toprak, kaya, tahta), iniş, kumaş, nefes, çaba; orman ambiyansı (döngü), Sisli uğultusu (döngü),
kalp atışı, Sisli yakalama, final müziği (yumuşak yaylı pad + çan tonları, yankılı).
Çalıştırma: python3 tools_audio_proto.py"""
import os
import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 22050
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = f'{HERE}/godot/proto/ses'
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(4)


def t_(d):
    return np.arange(int(SR * d)) / SR


def bp(x, lo, hi, order=2):
    b, a = signal.butter(order, [lo / (SR / 2), min(hi, SR / 2 - 100) / (SR / 2)], 'band')
    return signal.lfilter(b, a, x)


def lp(x, f, order=2):
    b, a = signal.butter(order, f / (SR / 2), 'low')
    return signal.lfilter(b, a, x)


def hp(x, f, order=2):
    b, a = signal.butter(order, f / (SR / 2), 'high')
    return signal.lfilter(b, a, x)


def env(n, att, dec, curve=3.0):
    t = np.arange(n) / SR
    e = np.minimum(1.0, t / max(att, 1e-4)) * np.exp(-np.maximum(0, t - att) / max(dec, 1e-4) * curve / 3.0)
    return e


def reverb(x, secs=1.6, mix=0.25, damp=3000):
    n = int(SR * secs)
    ir = rng.standard_normal(n) * np.exp(-np.arange(n) / SR * 4.5 / secs)
    ir = lp(ir, damp)
    ir /= np.sqrt(np.sum(ir ** 2))
    wet = signal.fftconvolve(x, ir)
    dry = np.concatenate([x, np.zeros(len(wet) - len(x))])
    return dry * (1 - mix) + wet * mix


def save(name, x, peak=0.85):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x)) + 1e-9
    x = x / m * peak
    fade = min(len(x) // 10, int(SR * 0.01))
    if fade > 0:
        x[-fade:] *= np.linspace(1, 0, fade)
    wavfile.write(f'{OUT}/{name}.wav', SR, (x * 32767).astype(np.int16))


def crackle(d, density, lo, hi):
    n = int(SR * d)
    x = np.zeros(n)
    k = int(density * d)
    for _ in range(k):
        p = rng.integers(0, n - 200)
        L = rng.integers(20, 160)
        x[p:p + L] += rng.standard_normal(L) * np.exp(-np.arange(L) / (L / 4)) * rng.uniform(0.3, 1.0)
    return bp(x, lo, hi)


def thump(d, f_lo, f_hi, dec):
    n = int(SR * d)
    x = lp(rng.standard_normal(n), f_hi) * env(n, 0.003, dec)
    return hp(x, f_lo)


# ----------------------------------------------------------------- adımlar
for i in range(5):
    d = 0.22
    n = int(SR * d)
    # yaprak/toprak: yumuşak gövde + kuru yaprak çıtırtısı (topuk ve parmak iki vuruş)
    x = thump(d, 50, 380, 0.05) * 1.2
    c = crackle(d, 260, 1800, 7500) * env(n, 0.006, 0.07) * 0.9
    c2 = np.roll(crackle(d, 160, 2000, 7000) * env(n, 0.004, 0.05) * 0.6, int(SR * rng.uniform(0.045, 0.07)))
    save(f'adim_yaprak_{i}', x + c + c2, 0.7)
    # toprak (az çıtırtı)
    save(f'adim_toprak_{i}', thump(d, 40, 300, 0.06) * 1.3 + crackle(d, 60, 900, 3500) * env(n, 0.004, 0.05) * 0.35, 0.6)
    # kaya: kısa sert tık + çakıl
    tick = hp(rng.standard_normal(n), 2500) * env(n, 0.0005, 0.012)
    grav = crackle(d, 180, 2500, 9000) * env(n, 0.01, 0.06) * 0.5
    save(f'adim_kaya_{i}', tick * 0.7 + grav + thump(d, 60, 500, 0.03) * 0.8, 0.6)
    # tahta (kasanın üstü): rezonanslı tok ses
    tt = t_(d)
    modes = sum(np.sin(2 * np.pi * f * rng.uniform(0.95, 1.05) * tt) * np.exp(-tt * k) * a for f, k, a in [(170, 30, 1.0), (330, 45, 0.6), (560, 60, 0.35), (910, 80, 0.2)])
    save(f'adim_tahta_{i}', modes * env(n, 0.002, 0.2) + thump(d, 60, 800, 0.02) * 0.6, 0.7)

# iniş (ağır): gövde + yaprak savrulması
for i in range(3):
    d = 0.5
    n = int(SR * d)
    x = thump(d, 30, 250, 0.12) * 1.6 + crackle(d, 500, 1500, 7000) * env(n, 0.01, 0.15) * 0.8
    save(f'inis_{i}', x, 0.9)

# kumaş hışırtısı
for i in range(4):
    d = 0.35
    n = int(SR * d)
    x = bp(rng.standard_normal(n), 900, 4200) * env(n, 0.06, 0.18) * (0.6 + 0.4 * np.sin(2 * np.pi * rng.uniform(9, 16) * t_(d)))
    save(f'kumas_{i}', x, 0.45)

# nefes (al/ver) ve çaba
def breath(d, lo, hi, att, rel, amp=1.0):
    n = int(SR * d)
    x = bp(rng.standard_normal(n), lo, hi)
    x += bp(rng.standard_normal(n), 2400, 3600) * 0.25
    e = np.minimum(1.0, t_(d) / att) * np.minimum(1.0, (d - t_(d)) / rel)
    return x * e ** 1.5 * amp


for i in range(3):
    save(f'nefes_al_{i}', breath(0.42, 700, 1900, 0.18, 0.15), 0.35)
    save(f'nefes_ver_{i}', breath(0.38, 450, 1500, 0.04, 0.25), 0.42)
for i in range(2):
    x = breath(0.45, 350, 1300, 0.03, 0.3) + bp(rng.standard_normal(int(SR * 0.45)), 200, 500) * env(int(SR * 0.45), 0.02, 0.12) * 0.6
    save(f'caba_{i}', x, 0.5)

# kasa sürtünmesi (tahta zeminde)
d = 0.6
n = int(SR * d)
g = np.zeros(n)
pos = 0
while pos < n - 400:
    L = int(rng.integers(150, 500))
    g[pos:pos + L] += rng.standard_normal(L) * rng.uniform(0.3, 1.0)
    pos += int(rng.integers(80, 300))
g = bp(g, 120, 1400) + lp(rng.standard_normal(n), 120) * 0.8
save('kasa_surt', g * env(n, 0.05, 0.4), 0.55)

# ----------------------------------------------------------------- orman ambiyansı (60 sn döngü)
D = 60.0
n = int(SR * D)
tt = t_(D)
brown = np.cumsum(rng.standard_normal(n))
brown = hp(brown - np.mean(brown), 20)
gust = 0.55 + 0.25 * np.sin(2 * np.pi * tt / 17.0) + 0.2 * np.sin(2 * np.pi * tt / 7.3 + 1.0)
wind = lp(brown, 400) / np.std(lp(brown, 400)) * 0.35 * gust
leaves = hp(rng.standard_normal(n), 3000) * 0.05 * np.clip(gust - 0.45, 0, None) ** 1.5 * 3
amb = wind + lp(leaves, 8000)
# uzak dal çatırtıları
for k in range(6):
    p = int(rng.uniform(2, D - 3) * SR)
    L = int(SR * rng.uniform(0.3, 0.9))
    f0 = rng.uniform(140, 260)
    tk = np.arange(L) / SR
    cr = np.sin(2 * np.pi * np.cumsum(f0 * (1 + 0.3 * np.sin(2 * np.pi * 5 * tk))) / SR) * crackle(L / SR, 120, 200, 1500) * 2
    amb[p:p + L] += lp(cr, 1200) * 0.12 * np.exp(-tk * 3)
# uzak kuş cıvıltıları
for k in range(7):
    p = int(rng.uniform(1, D - 2) * SR)
    for j in range(int(rng.integers(2, 5))):
        L = int(SR * rng.uniform(0.06, 0.14))
        tk = np.arange(L) / SR
        f = rng.uniform(2800, 4200) + np.linspace(0, rng.uniform(-900, 900), L)
        ch = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * tk / tk[-1]) ** 2
        q = p + j * int(SR * rng.uniform(0.12, 0.2))
        if q + L < n:
            amb[q:q + L] += ch * 0.025
amb = reverb(amb, 2.2, 0.3)[:n]
# kusursuz döngü: son 2 sn başa karışsın
X = int(SR * 2)
amb[:X] = amb[:X] * np.linspace(0, 1, X) + amb[-X:] * np.linspace(1, 0, X)
amb = amb[:-X]
wavfile.write(f'{OUT}/ambiyans.wav', SR, (amb / np.max(np.abs(amb)) * 0.7 * 32767).astype(np.int16))

# ----------------------------------------------------------------- Sisli uğultusu (20 sn döngü)
D = 20.0
n = int(SR * D)
tt = t_(D)
dr = np.zeros(n)
for f, a in [(48.0, 1.0), (48.6, 0.8), (72.3, 0.45), (96.5, 0.25), (143.0, 0.12)]:
    dr += np.sin(2 * np.pi * f * tt + rng.uniform(0, 6)) * a
dr *= 0.6 + 0.4 * np.sin(2 * np.pi * tt / 5.0) ** 2
hiss = bp(rng.standard_normal(n), 300, 1800) * (0.5 + 0.5 * np.sin(2 * np.pi * tt / 2.5) ** 4) * 0.35   # nefes gibi soluyan sis
dr = reverb(dr * 0.5 + hiss, 2.5, 0.4)[:n]
dr[:X] = dr[:X] * np.linspace(0, 1, X) + dr[-X:] * np.linspace(1, 0, X)
dr = dr[:-X]
wavfile.write(f'{OUT}/sisli_ugultu.wav', SR, (dr / np.max(np.abs(dr)) * 0.75 * 32767).astype(np.int16))

# kalp atışı (tek "lüp-düp")
d = 0.7
n = int(SR * d)
tt = t_(d)
def beat(t0, f, amp):
    e = np.exp(-np.maximum(0, tt - t0) * 28) * (tt >= t0)
    return np.sin(2 * np.pi * f * (tt - t0)) * e * amp
hb = beat(0.0, 55, 1.0) + beat(0.17, 48, 0.75)
save('kalp', lp(hb + thump(d, 20, 120, 0.05) * 0.3, 200), 0.9)

# Sisli yakalama: içe çeken fısıltı + derin darbe
d = 2.2
n = int(SR * d)
tt = t_(d)
sw = bp(rng.standard_normal(n), 400, 3000) * (tt / d) ** 3
boom = np.sin(2 * np.pi * 38 * tt) * np.exp(-np.maximum(0, tt - 1.55) * 3.0) * (tt > 1.55) * 2.2
save('yakalandi', reverb(sw + boom, 2.0, 0.45)[:n + int(SR * 1.0)], 0.9)

# ----------------------------------------------------------------- final müziği (yumuşak, hüzünlü)
D = 26.0
n = int(SR * D)
tt = t_(D)
def saw_voice(f, t0, t1, amp):
    m = (tt >= t0) & (tt < t1 + 2.5)
    x = np.zeros(n)
    tl = tt[m] - t0
    v = np.zeros(m.sum())
    for det in (-0.006, 0.0, 0.007):
        ph = 2 * np.pi * f * (1 + det) * tl
        v += signal.sawtooth(ph) / 3
    a = np.minimum(1.0, tl / 2.2) * np.where(tt[m] < t1, 1.0, np.exp(-(tt[m] - t1) * 1.8))
    x[m] = v * a * amp
    return x
# Am  F  C  G  Am (yavaş)
chords = [([220.0, 261.6, 329.6], 0), ([174.6, 220.0, 261.6], 5), ([130.8, 196.0, 261.6], 10), ([196.0, 246.9, 293.7], 15), ([220.0, 261.6, 329.6], 20)]
pad = np.zeros(n)
for fs, st in chords:
    for f in fs:
        pad += saw_voice(f / 2, st, st + 5.0, 0.22)
        pad += saw_voice(f, st, st + 5.0, 0.12)
pad = lp(pad, 1100)
# çan tonları (piyano/müzik kutusu gibi)
mel = [(659.3, 1.5), (587.3, 3.5), (523.3, 6.5), (440.0, 8.5), (523.3, 11.5), (493.9, 13.0), (392.0, 16.5), (440.0, 19.5), (329.6, 21.5)]
bell = np.zeros(n)
for f, st in mel:
    m = tt >= st
    tl = tt[m] - st
    bell[m] += (np.sin(2 * np.pi * f * tl) + 0.35 * np.sin(2 * np.pi * f * 2.0 * tl) + 0.12 * np.sin(2 * np.pi * f * 3.01 * tl)) * np.exp(-tl * 1.4) * 0.35
music = reverb(pad + bell, 3.5, 0.45, 2500)
music = music[:n + int(SR * 3)]
music *= np.minimum(1.0, np.arange(len(music)) / (SR * 2.0))
save('final_muzik', music, 0.8)
print('sesler yazıldı:', sorted(os.listdir(OUT)))
