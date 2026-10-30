"""Godot için basit sesleri üretir (numpy). Gerçek ses/müzik gelince bu dosyalar değiştirilir.
Kullanım: python3 tools_audio.py  -> godot/assets/audio/*.wav (16 bit mono 44.1 kHz)"""
import numpy as np, wave, os
SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'godot/assets/audio'); os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)

def noise(d): return rng.uniform(-1, 1, int(SR * d))
def lp(x, fc):                       # tek kutuplu alçak geçiren
    a = np.exp(-2 * np.pi * fc / SR); y = np.zeros_like(x); s = 0.0
    for i, v in enumerate(x): s = a * s + (1 - a) * v; y[i] = s
    return y
def hp(x, fc): return x - lp(x, fc)
def bp(x, lo, hi): return lp(hp(x, lo), hi)
def env(n, a=0.01, d=None):
    t = np.linspace(0, 1, n); e = np.minimum(1, t / max(a, 1e-4)) * np.exp(-t * (d or 6)); return e
def tone(f, d, f2=None, wave_='sin'):
    n = int(SR * d); fr = np.linspace(f, f2 or f, n); ph = np.cumsum(2 * np.pi * fr / SR)
    return np.sin(ph) if wave_ == 'sin' else np.sign(np.sin(ph))
def save(name, x, gain=0.8, loop=False):
    x = x / (np.max(np.abs(x)) + 1e-9) * gain
    with wave.open(f'{OUT}/{name}.wav', 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((x * 32767).astype('<i2').tobytes())
    print(name, len(x) / SR)

n = noise(0.09); save('step', lp(n, 900) * env(len(n), 0.005, 9), 0.55)
n = noise(0.16); save('jump', bp(n, 400, 1600) * env(len(n), 0.03, 5), 0.35)
n = noise(0.28); x = lp(n, 380) * env(len(n), 0.005, 7); y = tone(80, 0.28, 38) * env(len(n), 0.005, 8); save('land', x * 0.9 + y * 0.8, 0.8)
t = np.arange(int(SR * 0.5)) / SR; save('clink', (np.sin(2 * np.pi * 1600 * t) + 0.5 * np.sin(2 * np.pi * 2410 * t)) * np.exp(-t * 9), 0.45)
n = noise(0.22); save('whoosh', bp(n, 350, 1800) * env(len(n), 0.05, 4), 0.4)
n = noise(0.15); save('fire', bp(n, 900, 3200) * env(len(n), 0.01, 7), 0.3)
n = noise(0.12); x = hp(n, 1500) * env(len(n), 0.002, 9) * 0.5; y = tone(430, 0.12, 190, 'sq') * env(len(n), 0.002, 8) * 0.4; save('block', x + y, 0.6)
n = noise(0.8); save('door', lp(n, 260) * env(len(n), 0.05, 2.2) * (1 + 0.5 * np.sin(np.arange(len(n)) / SR * 38)), 0.6)
n = noise(0.07); y = tone(140, 0.12, 90, 'sq'); save('plate', np.pad(bp(n, 600, 2500) * env(len(n), 0.002, 8), (0, len(y) - len(n))) * 0.5 + y * env(len(y), 0.003, 8) * 0.5, 0.5)
n = noise(0.18); save('drag', lp(n, 520) * env(len(n), 0.02, 5), 0.4)
n = noise(0.7); x = lp(n, 700) * env(len(n), 0.01, 4); y = tone(120, 0.7, 38) * env(len(n), 0.01, 3.5); save('die', x * 0.6 + y, 0.85)
t = np.arange(int(SR * 1.6)) / SR; save('win', (np.sin(2 * np.pi * 392 * t) + 0.8 * np.sin(2 * np.pi * 587 * t)) * np.exp(-t * 1.4) * np.minimum(1, t / 0.08), 0.5)
# ortam: 6 sn dikişsiz rüzgâr (başı ve sonu çapraz geçişle birleştirilir)
d = 6.0; n = noise(d + 1.0); w = lp(n, 420); lfo = 0.6 + 0.4 * np.sin(np.arange(len(w)) / SR * 2 * np.pi * 0.17); w = w * lfo
h = int(SR * 1.0); body = w[:int(SR * d)].copy(); tail = w[int(SR * d):int(SR * d) + h]; fade = np.linspace(0, 1, h)
body[:h] = body[:h] * fade + tail * (1 - fade); save('wind', body, 0.5)
t = np.arange(int(SR * 8)) / SR; save('drone', (np.sin(2 * np.pi * 49 * t) * (0.7 + 0.3 * np.sin(2 * np.pi * 0.125 * t)) + 0.6 * np.sin(2 * np.pi * 73.5 * t) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.125 * t))), 0.4)
